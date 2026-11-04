import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/palette_theme.dart';
import '../ink_sling_game.dart';
import 'player_core.dart';

enum BlockType {
  matchaPad,
  crumblingPad,
  vermilionHazard,
  verticalPatrolHazard,
  pulsingLaserHazard,
  bumperPin,
  hankoSeal,
  shurikenSpinner,
  spikeTrapPad,
}

/// Ostacoli della torre:
/// - [BlockType.matchaPad]: Piattaforma Verde Adesiva su tutti i 4 lati e angoli!
/// - [BlockType.crumblingPad]: Piattaforma Adesiva Fragile che crolla 1.35s dopo l'atterraggio.
/// - [BlockType.vermilionHazard]: Barriera Rossa letale (fissa o mobile orizzontale).
/// - [BlockType.verticalPatrolHazard]: Ostacolo Rosso che pattuglia verticalmente su e giù.
/// - [BlockType.pulsingLaserHazard]: Raggio Laser a impulsi che alterna stato Spento (sicuro) e Attivo (letale).
/// - [BlockType.bumperPin]: Respingente elastico circolare che rimbalza la palla ad alta velocità.
/// - [BlockType.hankoSeal]: Gemma Dorata di Boost che spinge in alto e ricarica i tiri.
/// - [BlockType.shurikenSpinner]: Ruota Shuriken Ninja a 4 lame rotanti letali.
/// - [BlockType.spikeTrapPad]: Piattaforma Verde Adesiva con spuntoni retrattili a tempo (sicura -> avviso -> spuntoni letali).
class ObstacleBlock extends PositionComponent
    with HasGameReference<InkSlingGame> {
  final BlockType type;
  final double movingSpeed;
  final double verticalSpeed;
  final double phaseOffset;

  /// Quota opzionale in metri associata alla piattaforma (es. per sincronizzare
  /// deterministicamente la metrica d'altezza sulla piattaforma di Seconda Chance).
  final double? heightScore;

  late final double _originY;
  double _moveDir = 1.0;
  double _vertDir = 1.0;
  double _pressOffset = 0.0;
  double _sealPulse = 0.0;
  double _spinnerAngle = 0.0;
  double _crumbleTimer = 0.0;
  double _bumperCooldown = 0.0;
  static const double _maxCrumbleTime = 1.35;
  bool _consumed = false;

  // Oggetti Paint e Path pre-allocati per azzerare il Garbage Collector nel render loop
  final Paint _shadowPaint = Paint();
  final Paint _fillPaint = Paint();
  final Paint _stripePaint = Paint()..strokeWidth = 3.0;
  final Paint _stickyBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2;
  final Paint _crumbleFillPaint = Paint();
  final Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2;
  final Paint _laserGlowPaint = Paint();
  final Paint _laserCorePaint = Paint();
  final Paint _dashPaint = Paint();
  final Paint _emitterPaint = Paint();
  final Paint _detailPaint = Paint();
  final Path _gemShadowPath = Path();
  final Path _gemBodyPath = Path();
  final Path _shurikenPath = Path();
  final Path _shurikenShadowPath = Path();
  final Path _spikePath = Path();

  ObstacleBlock({
    required super.position,
    required super.size,
    required this.type,
    this.movingSpeed = 0.0,
    this.verticalSpeed = 0.0,
    this.phaseOffset = 0.0,
    this.heightScore,
  }) : super(anchor: Anchor.center) {
    _originY = position.y;
    _sealPulse = phaseOffset;
    _spinnerAngle = phaseOffset;
  }

  double get originY => _originY;

  // Coordinate deterministiche del bounding box nel world space
  double get left => position.x - size.x / 2;
  double get right => position.x + size.x / 2;
  double get top => position.y - size.y / 2;
  double get bottom => position.y + size.y / 2;

  Rect get worldBounds => Rect.fromCenter(
        center: Offset(position.x, position.y),
        width: size.x,
        height: size.y,
      );

  /// Calcola una coordinata X sicura e confinata nei margini della piattaforma per la pallina
  double clampBallX(double desiredX, double ballRadius) {
    final safeHalfSpan = max(0.0, (size.x / 2) - ballRadius);
    return desiredX.clamp(position.x - safeHalfSpan, position.x + safeHalfSpan);
  }

  bool get isLaserActive {
    if (type != BlockType.pulsingLaserHazard) return false;
    // Ciclo di 2.5s: 1.45s spento/preavviso, 1.05s raggio laser attivo
    final cycle = (_sealPulse % 2.5);
    return cycle >= 1.45;
  }

  double get _laserChargeProgress {
    final cycle = (_sealPulse % 2.5);
    return (cycle / 1.45).clamp(0.0, 1.0);
  }

  /// Vero quando gli spuntoni rossi della piattaforma trappola sono completamente estratti (letali)
  bool get isSpikeTrapActive {
    if (type != BlockType.spikeTrapPad) return false;
    // Ciclo di 2.6s: 0.0-1.45s sicura/adesiva, 1.45-1.85s preavviso tremante, 1.85-2.6s spuntoni letali estratti
    final cycle = (_sealPulse % 2.6);
    return cycle >= 1.85;
  }

  /// Vero durante la fase di preavviso prima dell'uscita degli spuntoni
  bool get isSpikeTrapWarning {
    if (type != BlockType.spikeTrapPad) return false;
    final cycle = (_sealPulse % 2.6);
    return cycle >= 1.45 && cycle < 1.85;
  }

  double get _spikeExtendProgress {
    if (type != BlockType.spikeTrapPad) return 0.0;
    final cycle = (_sealPulse % 2.6);
    if (cycle < 1.45) return 0.0;
    if (cycle < 1.85) return ((cycle - 1.45) / 0.40).clamp(0.0, 0.55);
    return 1.0;
  }

  bool get isDeadlyHazard {
    if (type == BlockType.vermilionHazard ||
        type == BlockType.verticalPatrolHazard ||
        type == BlockType.shurikenSpinner) {
      return true;
    }
    if (type == BlockType.pulsingLaserHazard) return isLaserActive;
    if (type == BlockType.spikeTrapPad) return isSpikeTrapActive;
    return false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_consumed || (!game.isPlaying && !game.isMenuDemo)) return;

    final effDt = game.chronoSealTimer > 0.0 ? dt * 0.35 : dt;
    final pulseFactor = (type == BlockType.pulsingLaserHazard ||
            type == BlockType.spikeTrapPad)
        ? 1.0
        : 3.5;
    _sealPulse += effDt * pulseFactor;
    if (type == BlockType.shurikenSpinner) {
      _spinnerAngle += effDt * 4.2;
    }
    if (_pressOffset > 0) {
      _pressOffset = max(0.0, _pressOffset - dt * 24.0);
    }
    if (_bumperCooldown > 0) {
      _bumperCooldown -= dt;
    }

    // 1. Movimento orizzontale (oppure confinamento entro le mura della torre su schermi stretti)
    final limit = max(16.0, game.towerHalfWidth - size.x / 2 - 8.0);
    if (movingSpeed > 0) {
      position.x += movingSpeed * _moveDir * (game.chronoSealTimer > 0.0 ? dt * 0.35 : dt);
      if (position.x > limit) {
        position.x = limit;
        _moveDir = -1.0;
      } else if (position.x < -limit) {
        position.x = -limit;
        _moveDir = 1.0;
      }
    } else if (position.x.abs() > limit) {
      position.x = position.x.clamp(-limit, limit);
    }

    // 2. Movimento verticale (per verticalPatrolHazard)
    if (verticalSpeed > 0) {
      position.y += verticalSpeed * _vertDir * (game.chronoSealTimer > 0.0 ? dt * 0.35 : dt);
      const patrolRange = 54.0;
      if (position.y > _originY + patrolRange) {
        position.y = _originY + patrolRange;
        _vertDir = -1.0;
      } else if (position.y < _originY - patrolRange) {
        position.y = _originY - patrolRange;
        _vertDir = 1.0;
      }
    }

    final p = game.player;
    if (p.isDead || (p.isShadowPhaseActive && isDeadlyHazard)) return;

    // 3. Se la palla è incollata a una piattaforma fragile (crumblingPad) o a spuntoni (spikeTrapPad)!
    if (p.stuckPlatform == this) {
      if (type == BlockType.spikeTrapPad && isSpikeTrapActive && !game.isMenuDemo) {
        p.stuckPlatform = null;
        if (p.isRespawnFrozen || p.shieldTimer > 0) {
          p.breakShield();
          p.velocity.setValues(0, -340);
          game.addCameraTrauma(0.35);
          game.spawnInkDropsAt(
            position.x,
            position.y,
            game.palette.vermilionHazard,
            count: 18,
          );
          game.spawnFloatingStampAt(
            position.x,
            position.y,
            game.strings.floatingShield,
          );
          game.audioHaptics.onShieldBreak();
        } else {
          game.triggerGameOver(victory: false);
        }
        return;
      }
      if (type == BlockType.crumblingPad && !game.isMenuDemo) {
        _crumbleTimer += dt;
        if (_crumbleTimer >= _maxCrumbleTime) {
          _consumed = true;
          p.stuckPlatform = null;
          p.velocity.setValues(0, 60);
          game.addCameraTrauma(0.22);
          game.spawnInkDropsAt(
            position.x,
            position.y,
            game.palette.ochreSeal,
            count: 18,
          );
          game.audioHaptics.onShieldBreak();
          removeFromParent();
        }
      }
      return;
    }

    // Se il laser a impulsi è spento, la palla lo attraversa a velocità naturale senza alcuna collisione o snapping
    if (type == BlockType.pulsingLaserHazard && !isLaserActive) {
      return;
    }

    // 4. Rilevamento collisione circolare (bumperPin, hankoSeal, shurikenSpinner)
    if (type == BlockType.bumperPin ||
        type == BlockType.hankoSeal ||
        type == BlockType.shurikenSpinner) {
      final radiusFactor = type == BlockType.shurikenSpinner ? 0.44 : 0.5;
      final hitDist = (size.x * radiusFactor) + PlayerCore.radius;
      final dy = p.position.y - position.y;
      if (dy.abs() > hitDist) return;
      final dx = p.position.x - position.x;
      if ((dx * dx + dy * dy) <= hitDist * hitDist) {
        _resolveCollision(p);
      }
      return;
    }

    // Nel menu demo di sottofondo, la palla attraversa dal basso le piattaforme verdi mentre sale
    // e si incolla morbidamente sulla faccia superiore mentre scende dall'apice dell'arco
    if (game.isMenuDemo &&
        (type == BlockType.matchaPad ||
            type == BlockType.crumblingPad ||
            type == BlockType.spikeTrapPad)) {
      if (p.velocity.y < -10.0 || p.prevPosition.y > position.y - size.y * 0.25) {
        return;
      }
    }

    final halfW = size.x / 2;
    final halfH = size.y / 2;
    const hitRadius = PlayerCore.radius + 1.0;
    const hitRadiusSq = hitRadius * hitRadius;

    final p0 = p.prevPosition;
    final p1 = p.position;

    // Bounding-box rapido sul segmento percorso nel frame (Continuous Collision Detection)
    if (max(p0.y, p1.y) < position.y - halfH - hitRadius ||
        min(p0.y, p1.y) > position.y + halfH + hitRadius ||
        max(p0.x, p1.x) < position.x - halfW - hitRadius ||
        min(p0.x, p1.x) > position.x + halfW + hitRadius) {
      return;
    }

    final deltaX = p1.x - p0.x;
    final deltaY = p1.y - p0.y;
    final segLen = sqrt(deltaX * deltaX + deltaY * deltaY);
    final steps = max(1, (segLen / 3.5).ceil());

    for (int s = 1; s <= steps; s++) {
      final t = s / steps;
      final sampleX = p0.x + deltaX * t;
      final sampleY = p0.y + deltaY * t;

      final closestX = sampleX.clamp(position.x - halfW, position.x + halfW);
      final closestY = sampleY.clamp(position.y - halfH, position.y + halfH);
      final dx = sampleX - closestX;
      final dy = sampleY - closestY;

      if ((dx * dx + dy * dy) <= hitRadiusSq) {
        // Riporta la palla al primo punto esatto di contatto sulla superficie esterna
        p.position.setValues(sampleX, sampleY);
        _resolveCollision(p);
        break;
      }
    }
  }

  void _resolveCollision(PlayerCore p) {
    final palette = game.palette;

    if (type == BlockType.hankoSeal) {
      _consumed = true;
      p.stuckPlatform = null;
      p.velocity.y = min(p.velocity.y, -660.0);
      p.recharge('seal');
      if (!game.isMenuDemo) {
        game.triggerHitStop(0.035);
        game.addCameraTrauma(0.28);
        game.audioHaptics.onSealCollected(combo: game.comboNotifier.value);
      }
      game.spawnInkDropsAt(position.x, position.y, palette.ochreSeal, count: 20);
      removeFromParent();
      return;
    }

    if (type == BlockType.bumperPin) {
      if (_bumperCooldown > 0) return;
      _bumperCooldown = 0.16;
      p.stuckPlatform = null;
      final dx = p.position.x - position.x;
      final dy = p.position.y - position.y;
      final len = sqrt(dx * dx + dy * dy);
      final nx = len > 0.01 ? dx / len : 0.0;
      final ny = len > 0.01 ? dy / len : -1.0;
      final hitDist = (size.x / 2) + PlayerCore.radius;
      p.position.setValues(
        position.x + nx * (hitDist + 2.0),
        position.y + ny * (hitDist + 2.0),
      );
      // Spinge con forza verso l'alto/esterno e restituisce 1 lancio aereo
      final bvx = nx * 650.0;
      final bvy = (ny * 650.0) > -260.0 ? -480.0 : (ny * 650.0);
      p.velocity.setValues(bvx, bvy);
      if (p.airCharges < PlayerCore.maxAirCharges) {
        p.airCharges = min(PlayerCore.maxAirCharges, p.airCharges + 1);
        if (!game.isMenuDemo) {
          game.chargesNotifier.value = p.airCharges;
        }
      }
      _pressOffset = 5.0;
      game.addInkStampAt(
        x: position.x,
        y: position.y,
        isWall: false,
        color: palette.ochreSeal,
      );
      game.spawnInkDropsAt(position.x, position.y, palette.ochreSeal, count: 14);
      if (!game.isMenuDemo) {
        game.totalBounces++;
        game.addCameraTrauma(0.22);
        game.spawnFloatingStampAt(
          position.x,
          position.y - 20,
          game.strings.floatingBumper,
        );
        game.audioHaptics.onBumperBounce();
      }
      return;
    }

    if (type == BlockType.pulsingLaserHazard && !isLaserActive) {
      return;
    }

    if (isDeadlyHazard) {
      if (game.isMenuDemo) {
        p.velocity.y = -520.0;
        return;
      }
      // Durante il freeze di invulnerabilità post-respawn o con scudo attivo il giocatore è protetto
      if (p.isRespawnFrozen || p.shieldTimer > 0) {
        p.breakShield();
        game.addCameraTrauma(0.35);
        _consumed = true;
        game.spawnInkDropsAt(
          position.x,
          position.y,
          palette.vermilionHazard,
          count: 18,
        );
        game.spawnFloatingStampAt(
          position.x,
          position.y,
          game.strings.floatingShield,
        );
        game.audioHaptics.onShieldBreak();
        removeFromParent();
      } else {
        game.triggerGameOver(victory: false);
      }
      return;
    }

    if (type == BlockType.matchaPad ||
        type == BlockType.crumblingPad ||
        type == BlockType.spikeTrapPad) {
      if (!p.stickToPlatform(this)) return;
      _pressOffset = 3.5;
      game.addInkStampAt(
        x: p.position.x,
        y: p.position.y,
        isWall: false,
        color: palette.matchaSafe,
      );
      game.spawnInkDropsAt(
        p.position.x,
        p.position.y,
        palette.matchaSafe,
        count: 8,
      );
      if (!game.isMenuDemo) {
        game.totalBounces++;
        game.addCameraTrauma(0.12);
        game.audioHaptics.onPadStick(combo: game.comboNotifier.value);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (_consumed) return;
    // Frustum culling verticale: salta i blocchi fuori dallo schermo (~85% della torre a 120 FPS)
    final screenH = game.size.y;
    if (screenH > 0) {
      final camY = game.camera.viewfinder.position.y;
      if ((position.y - camY).abs() > (screenH * 0.5) + size.y + 96.0) {
        return;
      }
    }
    final p = game.palette;
    final lowQuality = game.isLowQualityMode;

    if (type == BlockType.hankoSeal) {
      _renderBoostGem(canvas, p, lowQuality);
      return;
    }
    if (type == BlockType.bumperPin) {
      _renderBumperPin(canvas, p, lowQuality);
      return;
    }
    if (type == BlockType.shurikenSpinner) {
      _renderShurikenSpinner(canvas, p, lowQuality);
      return;
    }
    if (type == BlockType.pulsingLaserHazard) {
      _renderPulsingLaser(canvas, p);
      return;
    }

    final isHazard = type == BlockType.vermilionHazard ||
        type == BlockType.verticalPatrolHazard;
    final isCrumbling = type == BlockType.crumblingPad;
    final isSpikeTrap = type == BlockType.spikeTrapPad;

    final fillColor = isHazard
        ? p.vermilionHazard
        : (isCrumbling ? p.ochreSeal : p.matchaSafe);

    double shakeX = 0.0;
    if (isCrumbling && _crumbleTimer > 0) {
      shakeX = sin(_crumbleTimer * 48.0) * 2.5;
    } else if (isSpikeTrap && isSpikeTrapWarning) {
      shakeX = sin(_sealPulse * 62.0) * 2.0;
    }

    // 1. Ombra portata sotto il blocco (disattivata automaticamente se FPS < 60)
    if (!lowQuality) {
      _shadowPaint.color = p.shadowColor;
      final shadowRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(3.5 + shakeX, 4.5, size.x, size.y),
        const Radius.circular(6),
      );
      canvas.drawRRect(shadowRect, _shadowPaint);
    }

    // 2. Corpo del blocco (e spuntoni esterni se spikeTrapPad)
    canvas.save();
    canvas.translate(shakeX, _pressOffset * 0.5);

    if (isSpikeTrap) {
      final spikeProgress = _spikeExtendProgress;
      if (spikeProgress > 0.04) {
        final maxSpikeH = 10.5 * spikeProgress;
        _spikePath.reset();
        const int numSpikes = 4;
        final double stepW = (size.x - 16.0) / numSpikes;
        for (int i = 0; i < numSpikes; i++) {
          final sx = 8.0 + i * stepW;
          // Spuntoni superiori
          _spikePath.moveTo(sx + 1.5, 1.0);
          _spikePath.lineTo(sx + stepW * 0.5, -maxSpikeH);
          _spikePath.lineTo(sx + stepW - 1.5, 1.0);
          // Spuntoni inferiori
          _spikePath.moveTo(sx + 1.5, size.y - 1.0);
          _spikePath.lineTo(sx + stepW * 0.5, size.y + maxSpikeH);
          _spikePath.lineTo(sx + stepW - 1.5, size.y - 1.0);
        }
        _spikePath.close();
        _fillPaint.color =
            isSpikeTrapActive ? p.vermilionHazard : p.ochreSeal;
        canvas.drawPath(_spikePath, _fillPaint);
        _strokePaint.color = p.playerStroke;
        canvas.drawPath(_spikePath, _strokePaint);
      }
    }

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(6),
    );
    _fillPaint.color = fillColor;
    canvas.drawRRect(bodyRect, _fillPaint);

    // 3. Dettaglio visivo interno
    canvas.save();
    canvas.clipRRect(bodyRect);
    if (isHazard) {
      _stripePaint.color = p.paperBg.withAlpha((0.30 * 255).round());
      for (double x = -size.y; x < size.x + size.y; x += 11) {
        canvas.drawLine(
          Offset(x, 0),
          Offset(x + size.y, size.y),
          _stripePaint,
        );
      }
      if (type == BlockType.verticalPatrolHazard) {
        _detailPaint.color = p.paperCard;
        canvas.drawCircle(
          Offset(size.x / 2, size.y / 2),
          4.0,
          _detailPaint,
        );
      }
    } else {
      final innerStickyRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(3, 3, size.x - 6, size.y - 6),
        const Radius.circular(4),
      );
      _stickyBorderPaint.color = p.paperCard.withAlpha((0.48 * 255).round());
      canvas.drawRRect(innerStickyRect, _stickyBorderPaint);

      if (isSpikeTrap) {
        // Piccoli fori meccanici da cui fuoriescono gli spuntoni
        _detailPaint.color = isSpikeTrapActive
            ? p.vermilionHazard
            : (isSpikeTrapWarning ? p.ochreSeal : p.inkPrimary.withAlpha(110));
        const int numSlots = 4;
        final double stepW = (size.x - 16.0) / numSlots;
        for (int i = 0; i < numSlots; i++) {
          final cx = 8.0 + (i + 0.5) * stepW;
          canvas.drawCircle(Offset(cx, size.y * 0.5), 2.4, _detailPaint);
        }
      }

      if (isCrumbling && _crumbleTimer > 0) {
        final leftRatio = (1.0 - _crumbleTimer / _maxCrumbleTime).clamp(0.0, 1.0);
        _crumbleFillPaint.color =
            p.vermilionHazard.withAlpha((0.45 * 255).round());
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.x * leftRatio, size.y),
          _crumbleFillPaint,
        );
      }
    }
    canvas.restore();

    // 4. Contorno netto
    _strokePaint.color = p.playerStroke;
    canvas.drawRRect(bodyRect, _strokePaint);

    canvas.restore();
  }

  void _renderShurikenSpinner(
    Canvas canvas,
    RisographPalette p,
    bool lowQuality,
  ) {
    final center = Offset(size.x / 2, size.y / 2);
    final r = size.x / 2;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    if (!lowQuality) {
      canvas.save();
      canvas.translate(3.0, 4.0);
      canvas.rotate(_spinnerAngle);
      _shurikenShadowPath.reset();
      for (int i = 0; i < 4; i++) {
        final a0 = i * (pi / 2);
        final aMid = a0 + (pi / 4);
        final tx = r * cos(a0);
        final ty = r * sin(a0);
        final wx = (r * 0.28) * cos(aMid);
        final wy = (r * 0.28) * sin(aMid);
        if (i == 0) {
          _shurikenShadowPath.moveTo(tx, ty);
        } else {
          _shurikenShadowPath.lineTo(tx, ty);
        }
        _shurikenShadowPath.lineTo(wx, wy);
      }
      _shurikenShadowPath.close();
      _shadowPaint.color = p.shadowColor;
      canvas.drawPath(_shurikenShadowPath, _shadowPaint);
      canvas.restore();
    }

    canvas.rotate(_spinnerAngle);
    _shurikenPath.reset();
    for (int i = 0; i < 4; i++) {
      final a0 = i * (pi / 2);
      final aMid = a0 + (pi / 4);
      final tx = r * cos(a0);
      final ty = r * sin(a0);
      final wx = (r * 0.28) * cos(aMid);
      final wy = (r * 0.28) * sin(aMid);
      if (i == 0) {
        _shurikenPath.moveTo(tx, ty);
      } else {
        _shurikenPath.lineTo(tx, ty);
      }
      _shurikenPath.lineTo(wx, wy);
    }
    _shurikenPath.close();

    _fillPaint.color = p.vermilionHazard;
    canvas.drawPath(_shurikenPath, _fillPaint);

    _strokePaint
      ..color = p.playerStroke
      ..strokeWidth = 2.2;
    canvas.drawPath(_shurikenPath, _strokePaint);

    // Perno centrale forato dello Shuriken
    _detailPaint.color = p.paperCard;
    canvas.drawCircle(Offset.zero, r * 0.22, _detailPaint);
    canvas.drawCircle(Offset.zero, r * 0.22, _strokePaint);

    canvas.restore();
  }

  void _renderPulsingLaser(Canvas canvas, RisographPalette p) {
    final active = isLaserActive;
    final charge = _laserChargeProgress;
    final centerY = size.y / 2;

    final leftEmitter = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, 12, size.y),
      const Radius.circular(3),
    );
    final rightEmitter = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.x - 12, 0, 12, size.y),
      const Radius.circular(3),
    );

    if (active) {
      _laserGlowPaint.color = p.vermilionHazard.withAlpha((0.35 * 255).round());
      _laserCorePaint.color = p.vermilionHazard;
      canvas.drawRect(
        Rect.fromLTWH(10, centerY - 5, size.x - 20, 10),
        _laserGlowPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(10, centerY - 2.5, size.x - 20, 5),
        _laserCorePaint,
      );
    } else {
      _dashPaint
        ..color = p.vermilionHazard
            .withAlpha(((0.20 + charge * 0.55) * 255).round())
        ..strokeWidth = 1.5 + charge * 1.5;
      for (double x = 14; x < size.x - 18; x += 10) {
        canvas.drawLine(Offset(x, centerY), Offset(x + 5, centerY), _dashPaint);
      }
    }

    _emitterPaint.color = p.inkPrimary;
    canvas.drawRRect(leftEmitter, _emitterPaint);
    canvas.drawRRect(rightEmitter, _emitterPaint);
  }

  void _renderBumperPin(Canvas canvas, RisographPalette p, bool lowQuality) {
    final center = Offset(size.x / 2, size.y / 2);
    final r = (size.x / 2) + (_pressOffset * 0.6);

    if (!lowQuality) {
      _shadowPaint.color = p.shadowColor;
      canvas.drawCircle(center + const Offset(3, 4), r, _shadowPaint);
    }
    _fillPaint.color = p.ochreSeal;
    canvas.drawCircle(center, r, _fillPaint);

    _stickyBorderPaint.color = p.paperCard;
    canvas.drawCircle(center, r * 0.58, _stickyBorderPaint);

    _strokePaint
      ..color = p.playerStroke
      ..strokeWidth = 2.4;
    canvas.drawCircle(center, r, _strokePaint);
    _strokePaint.strokeWidth = 2.2;
  }

  void _renderBoostGem(Canvas canvas, RisographPalette p, bool lowQuality) {
    final center = Offset(size.x / 2, size.y / 2);
    final pulseScale = 1.0 + sin(_sealPulse) * 0.08;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(pulseScale);

    if (!lowQuality) {
      _gemShadowPath
        ..reset()
        ..moveTo(0, -size.y / 2 + 3)
        ..lineTo(size.x / 2 + 3, 3)
        ..lineTo(0, size.y / 2 + 3)
        ..lineTo(-size.x / 2 + 3, 3)
        ..close();
      _shadowPaint.color = p.shadowColor;
      canvas.drawPath(_gemShadowPath, _shadowPaint);
    }

    _gemBodyPath
      ..reset()
      ..moveTo(0, -size.y / 2)
      ..lineTo(size.x / 2, 0)
      ..lineTo(0, size.y / 2)
      ..lineTo(-size.x / 2, 0)
      ..close();

    _fillPaint.color = p.ochreSeal;
    canvas.drawPath(_gemBodyPath, _fillPaint);

    _strokePaint.color = p.playerStroke;
    canvas.drawPath(_gemBodyPath, _strokePaint);

    _detailPaint.color = p.paperCard;
    canvas.drawCircle(Offset.zero, size.x * 0.20, _detailPaint);

    canvas.restore();
  }
}

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
}

/// Ostacoli della torre:
/// - [BlockType.matchaPad]: Piattaforma Verde Adesiva su tutti i 4 lati e angoli!
/// - [BlockType.crumblingPad]: Piattaforma Adesiva Fragile che crolla 1.35s dopo l'atterraggio.
/// - [BlockType.vermilionHazard]: Barriera Rossa letale (fissa o mobile orizzontale).
/// - [BlockType.verticalPatrolHazard]: Ostacolo Rosso che pattuglia verticalmente su e giù.
/// - [BlockType.pulsingLaserHazard]: Raggio Laser a impulsi che alterna stato Spento (sicuro) e Attivo (letale).
/// - [BlockType.bumperPin]: Respingente elastico circolare che rimbalza la palla ad alta velocità.
/// - [BlockType.hankoSeal]: Gemma Dorata di Boost che spinge in alto e ricarica i tiri.
class ObstacleBlock extends PositionComponent
    with HasGameReference<InkSlingGame> {
  final BlockType type;
  final double movingSpeed;
  final double verticalSpeed;
  final double phaseOffset;

  late final double _originY;
  double _moveDir = 1.0;
  double _vertDir = 1.0;
  double _pressOffset = 0.0;
  double _sealPulse = 0.0;
  double _crumbleTimer = 0.0;
  double _bumperCooldown = 0.0;
  static const double _maxCrumbleTime = 1.35;
  bool _consumed = false;

  ObstacleBlock({
    required super.position,
    required super.size,
    required this.type,
    this.movingSpeed = 0.0,
    this.verticalSpeed = 0.0,
    this.phaseOffset = 0.0,
  }) : super(anchor: Anchor.center) {
    _originY = position.y;
    _sealPulse = phaseOffset;
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

  @override
  void update(double dt) {
    super.update(dt);
    if (_consumed || (!game.isPlaying && !game.isMenuDemo)) return;

    _sealPulse += dt * (type == BlockType.pulsingLaserHazard ? 1.0 : 3.5);
    if (_pressOffset > 0) {
      _pressOffset = max(0.0, _pressOffset - dt * 24.0);
    }
    if (_bumperCooldown > 0) {
      _bumperCooldown -= dt;
    }

    // 1. Movimento orizzontale (oppure confinamento entro le mura della torre su schermi stretti)
    final limit = max(16.0, game.towerHalfWidth - size.x / 2 - 8.0);
    if (movingSpeed > 0) {
      position.x += movingSpeed * _moveDir * dt;
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
      position.y += verticalSpeed * _vertDir * dt;
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

    // 3. Se la palla è incollata a una piattaforma fragile (crumblingPad), avvia il conto alla rovescia!
    if (p.stuckPlatform == this) {
      if (type == BlockType.crumblingPad && !game.isMenuDemo) {
        _crumbleTimer += dt;
        if (_crumbleTimer >= _maxCrumbleTime) {
          _consumed = true;
          p.stuckPlatform = null;
          p.velocity = Vector2(0, 60);
          game.addCameraTrauma(0.22);
          game.spawnInkDrops(position.clone(), game.palette.ochreSeal, count: 18);
          game.audioHaptics.onShieldBreak();
          removeFromParent();
        }
      }
      return;
    }

    // 4. Rilevamento collisione preciso Cerchio-Rettangolo (include lati e angoli al 100%)
    if (type == BlockType.bumperPin || type == BlockType.hankoSeal) {
      final hitDist = (size.x / 2) + PlayerCore.radius;
      if (p.position.distanceTo(position) <= hitDist) {
        _resolveCollision(p);
      }
      return;
    }

    final halfW = size.x / 2;
    final halfH = size.y / 2;
    const hitRadius = PlayerCore.radius + 1.0;
    const hitRadiusSq = hitRadius * hitRadius;

    final p0 = p.prevPosition;
    final p1 = p.position;

    // Bounding-box rapido sul segmento percorso nel frame (Continuous Collision Detection)
    if (max(p0.x, p1.x) < position.x - halfW - hitRadius ||
        min(p0.x, p1.x) > position.x + halfW + hitRadius ||
        max(p0.y, p1.y) < position.y - halfH - hitRadius ||
        min(p0.y, p1.y) > position.y + halfH + hitRadius) {
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
        // così non può mai attraversare la piattaforma né scavalcarne il centro!
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
      game.spawnInkDrops(position.clone(), palette.ochreSeal, count: 20);
      removeFromParent();
      return;
    }

    if (type == BlockType.bumperPin) {
      if (_bumperCooldown > 0) return;
      _bumperCooldown = 0.16;
      p.stuckPlatform = null;
      final dir = (p.position - position);
      final norm = dir.length > 0.01 ? dir.normalized() : Vector2(0, -1);
      final hitDist = (size.x / 2) + PlayerCore.radius;
      p.position = position + norm * (hitDist + 2.0);
      // Spinge con forza verso l'alto/esterno e restituisce 1 lancio aereo
      final bounceVel = norm * 650.0;
      if (bounceVel.y > -260.0) bounceVel.y = -480.0;
      p.velocity = bounceVel;
      if (p.airCharges < PlayerCore.maxAirCharges) {
        p.airCharges = min(PlayerCore.maxAirCharges, p.airCharges + 1);
        if (!game.isMenuDemo) {
          game.chargesNotifier.value = p.airCharges;
        }
      }
      _pressOffset = 5.0;
      game.spawnInkDrops(position.clone(), palette.ochreSeal, count: 14);
      if (!game.isMenuDemo) {
        game.totalBounces++;
        game.addCameraTrauma(0.22);
        game.spawnFloatingStamp(
          position + Vector2(0, -20),
          game.strings.floatingBumper,
        );
        game.audioHaptics.onBumperBounce();
      }
      return;
    }

    if (type == BlockType.pulsingLaserHazard && !isLaserActive) {
      // Il laser è spento: passaggio sicuro!
      return;
    }

    if (type == BlockType.vermilionHazard ||
        type == BlockType.verticalPatrolHazard ||
        type == BlockType.pulsingLaserHazard) {
      if (game.isMenuDemo) {
        p.velocity.y = -520.0;
        return;
      }
      if (p.shieldTimer > 0) {
        _consumed = true;
        game.spawnInkDrops(position.clone(), palette.vermilionHazard, count: 18);
        game.spawnFloatingStamp(position.clone(), game.strings.floatingShield);
        game.audioHaptics.onShieldBreak();
        removeFromParent();
      } else {
        game.triggerGameOver(victory: false);
      }
      return;
    }

    if (type == BlockType.matchaPad || type == BlockType.crumblingPad) {
      // INCOLLAGGIO SU TUTTI I LATI E ANGOLI DELLA PIATTAFORMA:
      // Esegue effetti e suono SOLO se la palla si è effettivamente incollata ora!
      if (!p.stickToPlatform(this)) return;
      _pressOffset = 3.5;
      game.spawnInkDrops(p.position.clone(), palette.matchaSafe, count: 8);
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
    final p = game.palette;

    if (type == BlockType.hankoSeal) {
      _renderBoostGem(canvas, p);
      return;
    }
    if (type == BlockType.bumperPin) {
      _renderBumperPin(canvas, p);
      return;
    }
    if (type == BlockType.pulsingLaserHazard) {
      _renderPulsingLaser(canvas, p);
      return;
    }

    final isHazard = type == BlockType.vermilionHazard ||
        type == BlockType.verticalPatrolHazard;
    final isCrumbling = type == BlockType.crumblingPad;

    final fillColor = isHazard
        ? p.vermilionHazard
        : (isCrumbling ? p.ochreSeal : p.matchaSafe);

    double shakeX = 0.0;
    if (isCrumbling && _crumbleTimer > 0) {
      shakeX = sin(_crumbleTimer * 48.0) * 2.5;
    }

    // 1. Ombra portata sotto il blocco
    final shadowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(3.5 + shakeX, 4.5, size.x, size.y),
      const Radius.circular(6),
    );
    canvas.drawRRect(shadowRect, Paint()..color = p.shadowColor);

    // 2. Corpo del blocco
    canvas.save();
    canvas.translate(shakeX, _pressOffset * 0.5);

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(6),
    );
    canvas.drawRRect(bodyRect, Paint()..color = fillColor);

    // 3. Dettaglio visivo interno
    canvas.save();
    canvas.clipRRect(bodyRect);
    if (isHazard) {
      final stripePaint = Paint()
        ..color = p.paperBg.withAlpha((0.30 * 255).round())
        ..strokeWidth = 3.0;
      for (double x = -size.y; x < size.x + size.y; x += 11) {
        canvas.drawLine(
          Offset(x, 0),
          Offset(x + size.y, size.y),
          stripePaint,
        );
      }
      if (type == BlockType.verticalPatrolHazard) {
        // Frecce su/giù al centro per indicare il movimento verticale
        final center = Offset(size.x / 2, size.y / 2);
        canvas.drawCircle(
          center,
          4.0,
          Paint()..color = p.paperCard,
        );
      }
    } else {
      // Cornice adesiva su TUTTI i 4 lati e angoli per mostrare l'incollaggio al 100%!
      final innerStickyRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(3, 3, size.x - 6, size.y - 6),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        innerStickyRect,
        Paint()
          ..color = p.paperCard.withAlpha((0.48 * 255).round())
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );

      // Barra di esaurimento per la piattaforma fragile a tempo
      if (isCrumbling && _crumbleTimer > 0) {
        final leftRatio = (1.0 - _crumbleTimer / _maxCrumbleTime).clamp(0.0, 1.0);
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.x * leftRatio, size.y),
          Paint()..color = p.vermilionHazard.withAlpha((0.45 * 255).round()),
        );
      }
    }
    canvas.restore();

    // 4. Contorno netto
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = p.playerStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    canvas.restore();
  }

  void _renderPulsingLaser(Canvas canvas, RisographPalette p) {
    final active = isLaserActive;
    final charge = _laserChargeProgress;
    final centerY = size.y / 2;

    // Emettitori laterali
    final leftEmitter = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, 12, size.y),
      const Radius.circular(3),
    );
    final rightEmitter = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.x - 12, 0, 12, size.y),
      const Radius.circular(3),
    );

    if (active) {
      // Raggio laser letale attivo
      canvas.drawRect(
        Rect.fromLTWH(10, centerY - 5, size.x - 20, 10),
        Paint()..color = p.vermilionHazard.withAlpha((0.35 * 255).round()),
      );
      canvas.drawRect(
        Rect.fromLTWH(10, centerY - 2.5, size.x - 20, 5),
        Paint()..color = p.vermilionHazard,
      );
    } else {
      // Linea tratteggiata di preavviso che si intensifica prima dello sparo
      final dashPaint = Paint()
        ..color = p.vermilionHazard.withAlpha(((0.20 + charge * 0.55) * 255).round())
        ..strokeWidth = 1.5 + charge * 1.5;
      for (double x = 14; x < size.x - 18; x += 10) {
        canvas.drawLine(Offset(x, centerY), Offset(x + 5, centerY), dashPaint);
      }
    }

    canvas.drawRRect(leftEmitter, Paint()..color = p.inkPrimary);
    canvas.drawRRect(rightEmitter, Paint()..color = p.inkPrimary);
  }

  void _renderBumperPin(Canvas canvas, RisographPalette p) {
    final center = Offset(size.x / 2, size.y / 2);
    final r = (size.x / 2) + (_pressOffset * 0.6);

    canvas.drawCircle(
      center + const Offset(3, 4),
      r,
      Paint()..color = p.shadowColor,
    );
    canvas.drawCircle(
      center,
      r,
      Paint()..color = p.ochreSeal,
    );
    canvas.drawCircle(
      center,
      r * 0.58,
      Paint()
        ..color = p.paperCard
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = p.playerStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
  }

  /// Disegna una gemma romboidale per il boost aereo
  void _renderBoostGem(Canvas canvas, RisographPalette p) {
    final center = Offset(size.x / 2, size.y / 2);
    final pulseScale = 1.0 + sin(_sealPulse) * 0.08;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(pulseScale);

    final shadowPath = Path()
      ..moveTo(0, -size.y / 2 + 3)
      ..lineTo(size.x / 2 + 3, 3)
      ..lineTo(0, size.y / 2 + 3)
      ..lineTo(-size.x / 2 + 3, 3)
      ..close();
    canvas.drawPath(shadowPath, Paint()..color = p.shadowColor);

    final gemPath = Path()
      ..moveTo(0, -size.y / 2)
      ..lineTo(size.x / 2, 0)
      ..lineTo(0, size.y / 2)
      ..lineTo(-size.x / 2, 0)
      ..close();

    canvas.drawPath(gemPath, Paint()..color = p.ochreSeal);
    canvas.drawPath(
      gemPath,
      Paint()
        ..color = p.playerStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    canvas.drawCircle(
      Offset.zero,
      size.x * 0.20,
      Paint()..color = p.paperCard,
    );

    canvas.restore();
  }
}

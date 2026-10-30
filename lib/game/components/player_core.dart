import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/ball_skins.dart';
import '../ink_sling_game.dart';
import 'obstacle_block.dart';

/// Il Giocatore: sfera elastica con:
/// - Incollaggio automatico ("Stick") sulle piattaforme verdi per mirare con calma
/// - Riposizionamento deterministico su piattaforma ("Seconda Chance") con freeze temporaneo
/// - 3 lanci disponibili tra una piattaforma e l'altra (ricaricati a ogni appoggio)
/// - Ring buffer pre-allocato per la scia (zero allocazioni GC durante il volo e il salto).
class PlayerCore extends PositionComponent
    with HasGameReference<InkSlingGame> {
  static const double radius = 14.0;
  static const double gravity = 920.0;
  static const int maxAirCharges = 3;
  static const double defaultRespawnFreezeDuration = 0.5;
  static const int _maxTrailPoints = 13;

  Vector2 velocity = Vector2.zero();
  Vector2 acceleration = Vector2.zero();
  Vector2 prevPosition = Vector2.zero();
  int airCharges = maxAirCharges;
  double shieldTimer = 0.0;
  double respawnFreezeTimer = 0.0;
  bool isDead = false;
  double _squashImpactTimer = 0.0;
  double _ringRotation = 0.0;

  // Ring-buffer pre-allocato per la scia (elimina Vector2.clone() e List.removeAt(0) ad ogni frame)
  final List<Vector2> _trailPool = List<Vector2>.generate(
    _maxTrailPoints,
    (_) => Vector2.zero(),
    growable: false,
  );
  int _trailStart = 0;
  int _trailLength = 0;

  // Oggetti Paint riutilizzabili nel loop di rendering
  final Paint _trailPaint = Paint()..style = PaintingStyle.fill;
  final Paint _stuckGlowPaint = Paint()..style = PaintingStyle.fill;
  final Paint _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8;
  final Paint _shieldFillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _shieldStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2;
  final Paint _shadowPaint = Paint()..style = PaintingStyle.fill;
  final Paint _corePaint = Paint()..style = PaintingStyle.fill;
  final Paint _highlightPaint = Paint()..style = PaintingStyle.fill;
  final Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.8;

  /// Se diverso da null, la palla è "incollata" a questa piattaforma verde
  /// e il giocatore può mirare con tutta calma senza cadere!
  ObstacleBlock? stuckPlatform;
  ObstacleBlock? _lastDetachedPlatform;
  final Vector2 _stuckLocalOffset = Vector2.zero();
  final Vector2 _stuckNormal = Vector2(0, -1);
  double _detachCooldown = 0.0;
  double _wallBounceCooldown = 0.0;

  PlayerCore({required super.position})
      : super(size: Vector2.all(radius * 2), anchor: Anchor.center) {
    prevPosition = position.clone();
  }

  bool get isStuck => stuckPlatform != null || position.y >= 0.0;

  /// Flag di freeze/invulnerabilità temporaneo attivo subito dopo la Seconda Chance (0.5s)
  bool get isRespawnFrozen => respawnFreezeTimer > 0.0;

  /// Punto di contatto inferiore della sfera (usato per la calibrazione esatta dell'altezza a 0.0m)
  double get bottomContactY => position.y + radius;

  void clearTrail() {
    _trailStart = 0;
    _trailLength = 0;
  }

  void _pushTrailPoint(double x, double y) {
    if (_trailLength < _maxTrailPoints) {
      final idx = (_trailStart + _trailLength) % _maxTrailPoints;
      _trailPool[idx].setValues(x, y);
      _trailLength++;
    } else {
      _trailPool[_trailStart].setValues(x, y);
      _trailStart = (_trailStart + 1) % _maxTrailPoints;
    }
  }

  void _popOldestTrailPoint() {
    if (_trailLength > 0) {
      _trailStart = (_trailStart + 1) % _maxTrailPoints;
      _trailLength--;
    }
  }

  /// Funzione isolata e deterministica di spawn/respawn per la "Seconda Chance":
  /// 1. Calcola il bound della piattaforma target e assegna X centrata/clamped nei margini
  ///    sicuri della piattaforma e Y esattamente sulla superficie superiore di collisione
  ///    (`platform.top - radius`, così la base inferiore della palla coincide con `platform.top`).
  /// 2. Azzera istantaneamente velocità (`velocity.setZero()`) e accelerazione (`acceleration.setZero()`).
  /// 3. Attiva il freeze/invulnerabilità temporaneo (`respawnFreezeTimer = 0.5s`) e lo scudo.
  void respawnOnPlatform(
    ObstacleBlock platform, {
    double? preferredX,
    double freezeDuration = defaultRespawnFreezeDuration,
    double shieldDuration = 4.5,
  }) {
    isDead = false;
    stuckPlatform = null;
    _lastDetachedPlatform = null;
    _detachCooldown = 0.0;
    _wallBounceCooldown = 0.0;
    clearTrail();

    // 1. Azzera immediatamente velocità e accelerazione per prevenire tunneling o inerzie residue
    velocity.setZero();
    acceleration.setZero();

    // 2. Calcola coordinate deterministiche ancorate al bounding box della piattaforma target
    final safeX = platform.clampBallX(preferredX ?? platform.position.x, radius);
    final surfaceCenterY = platform.top - radius;

    stuckPlatform = platform;
    _lastDetachedPlatform = platform;
    _stuckNormal.setValues(0.0, -1.0);
    _stuckLocalOffset.setValues(
      safeX - platform.position.x,
      surfaceCenterY - platform.position.y,
    );

    position.setValues(safeX, surfaceCenterY);
    prevPosition.setFrom(position);

    // 3. Attiva freeze/invulnerabilità temporanea e ricarica lanci
    respawnFreezeTimer = freezeDuration;
    shieldTimer = shieldDuration;
    _squashImpactTimer = 0.12;
    airCharges = maxAirCharges;
  }

  /// Impedisce di tirare la palla attraverso la piattaforma a cui è incollata
  /// (o attraverso il pavimento a 0m), deviando il vettore lungo l'esterno!
  Vector2 sanitizeLaunchVelocity(Vector2 rawVel) {
    final speed = rawVel.length;
    if (speed <= 0.001) return rawVel;

    if (stuckPlatform != null) {
      final pad = stuckPlatform!;
      final halfW = pad.size.x / 2;
      final halfH = pad.size.y / 2;
      final relX = position.x - pad.position.x;
      final relY = position.y - pad.position.y;

      if (relX.abs() <= halfW + radius * 0.75) {
        if (relY < 0 && rawVel.y > -25.0) {
          final side = rawVel.x.abs() > 1.0
              ? rawVel.x.sign
              : (relX >= 0 ? 1.0 : -1.0);
          return Vector2(side, -0.18).normalized() * speed;
        } else if (relY > 0 && rawVel.y < 25.0) {
          final side = rawVel.x.abs() > 1.0
              ? rawVel.x.sign
              : (relX >= 0 ? 1.0 : -1.0);
          return Vector2(side, 0.14).normalized() * speed;
        }
      }

      if (relY.abs() <= halfH + radius * 0.75) {
        if (relX < -halfW && rawVel.x > -20.0) {
          final vert = rawVel.y.abs() > 1.0 ? rawVel.y.sign : -1.0;
          return Vector2(-0.18, vert).normalized() * speed;
        } else if (relX > halfW && rawVel.x < 20.0) {
          final vert = rawVel.y.abs() > 1.0 ? rawVel.y.sign : -1.0;
          return Vector2(0.18, vert).normalized() * speed;
        }
      }
    }

    Vector2? surfaceNormal;
    if (stuckPlatform != null) {
      surfaceNormal = _stuckNormal;
    } else if (position.y >= -1.0) {
      surfaceNormal = Vector2(0, -1);
    }

    if (surfaceNormal == null) return rawVel;

    final dir = rawVel / speed;
    if (dir.dot(surfaceNormal) < 0.15) {
      Vector2 tangent = dir - surfaceNormal * dir.dot(surfaceNormal);
      if (tangent.length < 0.01) {
        tangent = Vector2(-surfaceNormal.y, surfaceNormal.x);
        if (tangent.y > 0) tangent = -tangent;
      } else {
        tangent.normalize();
      }
      final clampedDir = (tangent + surfaceNormal * 0.18).normalized();
      return clampedDir * speed;
    }
    return rawVel;
  }

  /// Incolla la palla al 100% del perimetro della piattaforma (sopra, sotto,
  /// sui lati sinistro/destro e sugli angoli) e ricarica tutti i lanci!
  bool stickToPlatform(ObstacleBlock pad) {
    if (stuckPlatform != null) return false;

    final halfW = pad.size.x / 2;
    final halfH = pad.size.y / 2;
    final relX = position.x - pad.position.x;
    final relY = position.y - pad.position.y;

    final closestX = relX.clamp(-halfW, halfW);
    final closestY = relY.clamp(-halfH, halfH);
    final diffX = relX - closestX;
    final diffY = relY - closestY;
    final diffLen = sqrt(diffX * diffX + diffY * diffY);

    if (_detachCooldown > 0 && pad == _lastDetachedPlatform) {
      final nx = diffLen > 0.001 ? diffX / diffLen : _stuckNormal.x;
      final ny = diffLen > 0.001 ? diffY / diffLen : _stuckNormal.y;
      final dot = velocity.x * nx + velocity.y * ny;
      if (dot > 0.0 && diffLen >= radius * 0.9) {
        return false;
      }
    }

    stuckPlatform = pad;
    _lastDetachedPlatform = pad;
    velocity.setZero();
    acceleration.setZero();

    if (diffLen > 0.001) {
      final nx = diffX / diffLen;
      final ny = diffY / diffLen;
      _stuckNormal.setValues(nx, ny);
      _stuckLocalOffset.setValues(
        closestX + nx * radius,
        closestY + ny * radius,
      );
    } else {
      final prevRelX = prevPosition.x - pad.position.x;
      final prevRelY = prevPosition.y - pad.position.y;
      final prevClosestX = prevRelX.clamp(-halfW, halfW);
      final prevClosestY = prevRelY.clamp(-halfH, halfH);
      final prevDiffX = prevRelX - prevClosestX;
      final prevDiffY = prevRelY - prevClosestY;
      final prevDiffLen = sqrt(prevDiffX * prevDiffX + prevDiffY * prevDiffY);

      if (prevDiffLen > 0.001) {
        final nx = prevDiffX / prevDiffLen;
        final ny = prevDiffY / prevDiffLen;
        _stuckNormal.setValues(nx, ny);
        _stuckLocalOffset.setValues(
          prevClosestX + nx * radius,
          prevClosestY + ny * radius,
        );
      } else {
        final distLeft = (relX + halfW).abs();
        final distRight = (halfW - relX).abs();
        final distTop = (relY + halfH).abs();
        final distBottom = (halfH - relY).abs();
        final minDist = min(min(distLeft, distRight), min(distTop, distBottom));

        if (minDist == distTop) {
          _stuckNormal.setValues(0, -1);
          _stuckLocalOffset.setValues(closestX, -(halfH + radius));
        } else if (minDist == distLeft) {
          _stuckNormal.setValues(-1, 0);
          _stuckLocalOffset.setValues(-(halfW + radius), closestY);
        } else if (minDist == distRight) {
          _stuckNormal.setValues(1, 0);
          _stuckLocalOffset.setValues(halfW + radius, closestY);
        } else {
          _stuckNormal.setValues(0, 1);
          _stuckLocalOffset.setValues(closestX, halfH + radius);
        }
      }
    }

    position.setValues(
      pad.position.x + _stuckLocalOffset.x,
      pad.position.y + _stuckLocalOffset.y,
    );
    prevPosition.setFrom(position);
    _squashImpactTimer = 0.12;
    recharge('pad');
    return true;
  }

  void launch(Vector2 launchVelocity, {bool silent = false}) {
    if (isRespawnFrozen) return;
    final safeVelocity = sanitizeLaunchVelocity(launchVelocity);

    if (stuckPlatform != null) {
      _lastDetachedPlatform = stuckPlatform;
      stuckPlatform = null;
      _detachCooldown = 0.08;
      position.x += _stuckNormal.x * 2.2;
      position.y += _stuckNormal.y * 2.2;
    }

    prevPosition.setFrom(position);
    acceleration.setZero();
    velocity.setFrom(safeVelocity);
    airCharges = max(0, airCharges - 1);
    if (!game.isMenuDemo) {
      game.chargesNotifier.value = airCharges;
      game.addCameraTrauma(0.18);
    }
    _squashImpactTimer = 0.085;
    game.spawnInkDropsAt(
      position.x,
      position.y,
      game.palette.playerFill,
      count: 9,
    );
    if (!silent && !game.isMenuDemo) {
      game.audioHaptics.onLaunch();
    }
  }

  void recharge(String source) {
    final wasRecharged = airCharges < maxAirCharges;
    airCharges = maxAirCharges;
    if (!game.isMenuDemo) {
      game.chargesNotifier.value = airCharges;
      game.comboNotifier.value += 1;
    }

    if (wasRecharged && source == 'seal' && !game.isMenuDemo) {
      game.spawnFloatingStampAt(
        position.x,
        position.y - 24,
        game.strings.floatingBoost,
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying && !game.isMenuDemo) return;

    _ringRotation += dt * 1.8;
    if (shieldTimer > 0) shieldTimer = max(0.0, shieldTimer - dt);
    if (respawnFreezeTimer > 0) {
      respawnFreezeTimer = max(0.0, respawnFreezeTimer - dt);
    }
    if (_squashImpactTimer > 0) {
      _squashImpactTimer = max(0.0, _squashImpactTimer - dt);
    }
    if (_detachCooldown > 0) _detachCooldown = max(0.0, _detachCooldown - dt);
    if (_wallBounceCooldown > 0) {
      _wallBounceCooldown = max(0.0, _wallBounceCooldown - dt);
    }

    // Se la palla è incollata a una piattaforma verde, resta ancorata deterministicamente!
    if (stuckPlatform != null) {
      final pad = stuckPlatform!;
      // Se la piattaforma è stata rimossa dal mondo, stacca in sicurezza
      if (pad.parent == null && !isRespawnFrozen) {
        stuckPlatform = null;
      } else {
        position.setValues(
          pad.position.x + _stuckLocalOffset.x,
          pad.position.y + _stuckLocalOffset.y,
        );
        prevPosition.setFrom(position);
        velocity.setZero();
        acceleration.setZero();
        _popOldestTrailPoint();

        // Controllo schiacciamento contro il muro per piattaforme mobili
        if (pad.movingSpeed > 0 && !isRespawnFrozen) {
          final wallLimit = game.towerHalfWidth;
          final isCrushedRight =
              _stuckNormal.x > 0.35 && (position.x + radius >= wallLimit - 1.0);
          final isCrushedLeft = _stuckNormal.x < -0.35 &&
              (position.x - radius <= -wallLimit + 1.0);

          if (isCrushedRight || isCrushedLeft) {
            if (game.isMenuDemo) {
              final ejectDir = isCrushedRight ? -1.0 : 1.0;
              launch(Vector2(ejectDir * 320.0, -420.0), silent: true);
              return;
            }

            if (shieldTimer > 0) {
              shieldTimer = 0.0;
              stuckPlatform = null;
              final ejectDir = isCrushedRight ? -1.0 : 1.0;
              velocity.setValues(ejectDir * 360.0, -300.0);
              game.addCameraTrauma(0.55);
              game.audioHaptics.onShieldBreak();
              return;
            }

            stuckPlatform = null;
            game.triggerGameOver(victory: false);
            return;
          }
        }
        return;
      }
    }

    // Durante il freeze temporaneo di respawn (0.5s) sospende la caduta gravitazionale
    if (isRespawnFrozen) {
      velocity.setZero();
      acceleration.setZero();
      prevPosition.setFrom(position);
      return;
    }

    // 1. Salva la posizione precedente per il Continuous Collision Detection (anti-tunneling)
    prevPosition.setFrom(position);
    acceleration.setValues(0.0, gravity);
    velocity.x += acceleration.x * dt;
    velocity.y += acceleration.y * dt;
    position.x += velocity.x * dt;
    position.y += velocity.y * dt;

    // 2. Rimbalzo controllato esattamente sul bordo interno delle mura in pietra!
    final halfWall = game.towerHalfWidth - radius;
    if (position.x < -halfWall) {
      position.x = -halfWall;
      velocity.x = velocity.x.abs() * 0.72;
      if (velocity.y > 120) velocity.y *= 0.65;
      _onWallBounce(isLeftWall: true);
    } else if (position.x > halfWall) {
      position.x = halfWall;
      velocity.x = -velocity.x.abs() * 0.72;
      if (velocity.y > 120) velocity.y *= 0.65;
      _onWallBounce(isLeftWall: false);
    }

    // 3. Base di partenza a 0.0m (incolla/ferma la palla a terra con contatto base a +radius)
    if (position.y > InkSlingGame.platformBaseY) {
      position.y = InkSlingGame.platformBaseY;
      velocity.setZero();
      acceleration.setZero();
      airCharges = maxAirCharges;
      if (!game.isMenuDemo) {
        game.chargesNotifier.value = maxAirCharges;
        game.comboNotifier.value = 0;
      }
    }

    // 4. Scia fluida in volo tramite ring-buffer pre-allocato (zero allocazioni!)
    _pushTrailPoint(position.x, position.y);
  }

  void _onWallBounce({required bool isLeftWall}) {
    if (_wallBounceCooldown > 0) return;
    _wallBounceCooldown = 0.08;
    _squashImpactTimer = 0.09;
    if (!game.isMenuDemo) {
      game.totalBounces++;
    }
    final wallEdgeX = isLeftWall
        ? -game.towerHalfWidth + 3.5
        : game.towerHalfWidth - 3.5;
    game.addInkStampAt(
      x: wallEdgeX,
      y: position.y,
      isWall: true,
      isLeftWall: isLeftWall,
      color: game.palette.playerFill,
    );
    if (!game.isMenuDemo) {
      game.addCameraTrauma(0.14);
      game.audioHaptics.onWallOrPadBounce(combo: game.comboNotifier.value);
    }
    game.spawnInkDropsAt(
      position.x,
      position.y,
      game.palette.matchaSafe,
      count: 6,
    );
  }

  @override
  void render(Canvas canvas) {
    if (isDead) return;
    final p = game.palette;
    final lowQuality = game.isLowQualityMode;
    final center = Offset(size.x / 2, size.y / 2);
    final skin = BallSkinsCatalog.getById(game.storage.selectedBallSkinId);
    final coreColor = skin.getCoreColor(p);
    final strokeColor = skin.getStrokeColor(p);
    final trailColor = skin.getTrailColor(p);

    // 1. Scia fluida personalizzata dal ring-buffer pre-allocato
    if (_trailLength > 0) {
      final step = lowQuality ? 2 : 1;
      for (int i = 0; i < _trailLength; i += step) {
        final bufIdx = (_trailStart + i) % _maxTrailPoints;
        final pt = _trailPool[bufIdx];
        final dx = pt.x - position.x;
        final dy = pt.y - position.y;
        final t = (i + 1) / _trailLength;
        _trailPaint.color = trailColor.withAlpha((t * 0.28 * 255).round());
        canvas.drawCircle(
          Offset(center.dx + dx, center.dy + dy),
          radius * t * 0.82,
          _trailPaint,
        );
      }
    }

    // 2. Indicatore visivo quando sei INCOLLATO a una piattaforma (alone verde stabile)
    if (stuckPlatform != null) {
      _stuckGlowPaint.color = p.matchaSafe.withAlpha((0.30 * 255).round());
      canvas.drawCircle(center, radius + 6.5, _stuckGlowPaint);
    }

    // 3. Anelli che indicano i Lanci disponibili
    final visibleRings = min(airCharges, 3);
    _ringPaint.color = p.ochreSeal.withAlpha((0.85 * 255).round());
    for (int c = 0; c < visibleRings; c++) {
      final ringRadius = radius + 5.0 + (c * 4.2);
      final rect = Rect.fromCircle(center: center, radius: ringRadius);
      for (int seg = 0; seg < 3; seg++) {
        final startAngle =
            _ringRotation * (c.isEven ? 1 : -1) + (seg * 2 * pi / 3) + 0.2;
        canvas.drawArc(
          rect,
          startAngle,
          (2 * pi / 3) - 0.4,
          false,
          _ringPaint,
        );
      }
    }

    // 4. Bolla di protezione "Scudo" (dopo un Revive)
    if (shieldTimer > 0) {
      _shieldFillPaint.color = p.matchaSafe.withAlpha((0.25 * 255).round());
      _shieldStrokePaint.color = p.matchaSafe;
      canvas.drawCircle(center, radius + 13, _shieldFillPaint);
      canvas.drawCircle(center, radius + 13, _shieldStrokePaint);
    }

    // 5. Ombra portata + Corpo elastico Squash & Stretch
    canvas.save();
    canvas.translate(center.dx, center.dy);

    double stretch = 1.0;
    double squash = 1.0;
    double angle = 0.0;
    final speed = velocity.length;
    if (speed > 35.0) {
      angle = atan2(velocity.y, velocity.x);
      stretch = (1.0 + (speed / 2200.0)).clamp(1.0, 1.35);
      squash = 1.0 / stretch;
      if (_squashImpactTimer > 0) {
        final tmp = stretch;
        stretch = squash * 0.85;
        squash = tmp * 1.15;
      }
    } else if (_squashImpactTimer > 0) {
      stretch = 1.18;
      squash = 0.84;
    }

    // Ombra (disattivata se FPS < 60 per preservare fluidità)
    if (!lowQuality) {
      canvas.save();
      canvas.translate(3.5, 4.5);
      canvas.rotate(angle);
      canvas.scale(stretch, squash);
      _shadowPaint.color = p.shadowColor;
      canvas.drawCircle(Offset.zero, radius, _shadowPaint);
      canvas.restore();
    }

    // Nucleo della palla
    canvas.rotate(angle);
    canvas.scale(stretch, squash);

    _corePaint.color = coreColor;
    canvas.drawCircle(Offset.zero, radius, _corePaint);

    // Decorazione ed emblema specifico della Skin equipaggiata
    skin.renderCustomSkin(canvas, radius, p, _ringRotation);

    // Riflesso superiore speculare (sempre avorio caldo, mai scuro in modalità Notte)
    _highlightPaint.color = const Color(0xFFFFFDF8).withAlpha((0.68 * 255).round());
    canvas.drawCircle(const Offset(-4, -4), radius * 0.28, _highlightPaint);

    // Contorno netto ad alto contrasto
    _strokePaint.color = strokeColor;
    canvas.drawCircle(Offset.zero, radius, _strokePaint);

    canvas.restore();
  }
}

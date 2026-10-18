import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../ink_sling_game.dart';
import 'obstacle_block.dart';

/// Il Giocatore: sfera elastica con:
/// - Incollaggio automatico ("Stick") sulle piattaforme verdi per mirare con calma
/// - 3 lanci disponibili tra una piattaforma e l'altra (ricaricati a ogni appoggio)
/// - Squash & Stretch procedurale e scia fluida.
class PlayerCore extends PositionComponent
    with HasGameReference<InkSlingGame> {
  static const double radius = 14.0;
  static const double gravity = 920.0;
  static const int maxAirCharges = 3;

  Vector2 velocity = Vector2.zero();
  Vector2 prevPosition = Vector2.zero();
  int airCharges = maxAirCharges;
  double shieldTimer = 0.0;
  double _squashImpactTimer = 0.0;
  double _ringRotation = 0.0;
  final List<Vector2> _brushTrail = [];

  /// Se diverso da null, la palla è "incollata" a questa piattaforma verde
  /// e il giocatore può mirare con tutta calma senza cadere!
  ObstacleBlock? stuckPlatform;
  ObstacleBlock? _lastDetachedPlatform;
  Vector2 _stuckLocalOffset = Vector2.zero();
  Vector2 _stuckNormal = Vector2(0, -1);
  double _detachCooldown = 0.0;
  double _wallBounceCooldown = 0.0;

  PlayerCore({required super.position})
      : super(size: Vector2.all(radius * 2), anchor: Anchor.center) {
    prevPosition = position.clone();
  }

  bool get isStuck => stuckPlatform != null || position.y >= 0.0;

  /// Impedisce di tirare la palla attraverso la piattaforma a cui è incollata
  /// (o attraverso il pavimento a 0m), deviando il vettore lungo l'esterno!
  Vector2 sanitizeLaunchVelocity(Vector2 rawVel) {
    final speed = rawVel.length;
    if (speed <= 0.001) return rawVel;

    if (stuckPlatform != null) {
      final pad = stuckPlatform!;
      final halfW = pad.size.x / 2;
      final halfH = pad.size.y / 2;
      final rel = position - pad.position;

      // Controllo rigoroso sui 4 lati della piattaforma per impedire qualsiasi
      // tiro che punti dentro il corpo solido della piattaforma:
      if (rel.x.abs() <= halfW + radius * 0.75) {
        if (rel.y < 0 && rawVel.y > -25.0) {
          // Appoggiato SOPRA la piattaforma: non può tirare verso il basso
          final side = rawVel.x.abs() > 1.0
              ? rawVel.x.sign
              : (rel.x >= 0 ? 1.0 : -1.0);
          return Vector2(side, -0.18).normalized() * speed;
        } else if (rel.y > 0 && rawVel.y < 25.0) {
          // Appeso SOTTO la piattaforma: non può tirare verso l'alto attraversandola
          final side = rawVel.x.abs() > 1.0
              ? rawVel.x.sign
              : (rel.x >= 0 ? 1.0 : -1.0);
          return Vector2(side, 0.14).normalized() * speed;
        }
      }

      if (rel.y.abs() <= halfH + radius * 0.75) {
        if (rel.x < -halfW && rawVel.x > -20.0) {
          // Attaccato al LATO SINISTRO: non può tirare verso destra dentro la piattaforma
          final vert = rawVel.y.abs() > 1.0 ? rawVel.y.sign : -1.0;
          return Vector2(-0.18, vert).normalized() * speed;
        } else if (rel.x > halfW && rawVel.x < 20.0) {
          // Attaccato al LATO DESTRO: non può tirare verso sinistra dentro la piattaforma
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
    // Se il tiro punta dentro la superficie (es. sugli angoli o sul pavimento),
    // lo proiettiamo lungo la tangente esterna così non può mai attraversarla!
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
  /// Restituisce `true` solo quando l'incollaggio avviene effettivamente,
  /// evitando qualsiasi ripetizione di suoni mentre la palla si stacca.
  bool stickToPlatform(ObstacleBlock pad) {
    if (stuckPlatform != null) return false;

    final halfW = pad.size.x / 2;
    final halfH = pad.size.y / 2;
    final rel = position - pad.position;

    final closestX = rel.x.clamp(-halfW, halfW);
    final closestY = rel.y.clamp(-halfH, halfH);
    final diff = Vector2(rel.x - closestX, rel.y - closestY);

    // Se ci siamo appena staccati da questa piattaforma, ignoriamola SOLO
    // nei primissimi istanti mentre la palla si sta allontanando all'esterno.
    // Se invece si muove verso la piattaforma, si blocca subito senza attraversarla!
    if (_detachCooldown > 0 && pad == _lastDetachedPlatform) {
      final outDir = diff.length > 0.001 ? diff.normalized() : _stuckNormal;
      if (velocity.dot(outDir) > 0.0 && diff.length >= radius * 0.9) {
        return false;
      }
    }

    stuckPlatform = pad;
    _lastDetachedPlatform = pad;
    velocity.setZero();

    if (diff.length > 0.001) {
      // Attacco preciso su qualsiasi lato (superiore, inferiore, sinistro, destro) o angolo!
      _stuckNormal = diff.normalized();
      _stuckLocalOffset =
          Vector2(closestX, closestY) + _stuckNormal * (radius + 1.0);
    } else {
      // Fallback se il centro era già penetrato nel rettangolo:
      // usa la posizione precedente per determinare il lato di provenienza reale!
      final prevRel = prevPosition - pad.position;
      final prevClosestX = prevRel.x.clamp(-halfW, halfW);
      final prevClosestY = prevRel.y.clamp(-halfH, halfH);
      final prevDiff = Vector2(prevRel.x - prevClosestX, prevRel.y - prevClosestY);

      if (prevDiff.length > 0.001) {
        _stuckNormal = prevDiff.normalized();
        _stuckLocalOffset =
            Vector2(prevClosestX, prevClosestY) + _stuckNormal * (radius + 1.0);
      } else {
        final distLeft = (rel.x + halfW).abs();
        final distRight = (halfW - rel.x).abs();
        final distTop = (rel.y + halfH).abs();
        final distBottom = (halfH - rel.y).abs();
        final minDist = [distLeft, distRight, distTop, distBottom].reduce(min);

        if (minDist == distLeft) {
          _stuckNormal = Vector2(-1, 0);
          _stuckLocalOffset = Vector2(-(halfW + radius + 1.0), closestY);
        } else if (minDist == distRight) {
          _stuckNormal = Vector2(1, 0);
          _stuckLocalOffset = Vector2(halfW + radius + 1.0, closestY);
        } else if (minDist == distTop) {
          _stuckNormal = Vector2(0, -1);
          _stuckLocalOffset = Vector2(closestX, -(halfH + radius + 1.0));
        } else {
          _stuckNormal = Vector2(0, 1);
          _stuckLocalOffset = Vector2(closestX, halfH + radius + 1.0);
        }
      }
    }

    position = pad.position + _stuckLocalOffset;
    prevPosition = position.clone();
    _squashImpactTimer = 0.12;
    recharge('pad');
    return true;
  }

  void launch(Vector2 launchVelocity, {bool silent = false}) {
    final safeVelocity = sanitizeLaunchVelocity(launchVelocity);

    // Stacca la palla dalla piattaforma e la sposta leggermente oltre la soglia di contatto
    // per evitare che strusciando sul bordo ripeta il suono di incollaggio!
    if (stuckPlatform != null) {
      _lastDetachedPlatform = stuckPlatform;
      stuckPlatform = null;
      _detachCooldown = 0.08;
      position += _stuckNormal * 2.2;
    }

    prevPosition = position.clone();
    velocity = safeVelocity;
    airCharges = max(0, airCharges - 1);
    if (!game.isMenuDemo) {
      game.chargesNotifier.value = airCharges;
      game.addCameraTrauma(0.18);
    }
    _squashImpactTimer = 0.085;
    game.spawnInkDrops(
      position.clone(),
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
      game.spawnFloatingStamp(
        position + Vector2(0, -24),
        game.strings.floatingBoost,
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying && !game.isMenuDemo) return;

    _ringRotation += dt * 1.8;
    if (shieldTimer > 0) shieldTimer -= dt;
    if (_squashImpactTimer > 0) _squashImpactTimer -= dt;
    if (_detachCooldown > 0) _detachCooldown -= dt;
    if (_wallBounceCooldown > 0) _wallBounceCooldown -= dt;

    // Se la palla è incollata a una piattaforma verde, resta ferma lì sopra!
    if (stuckPlatform != null) {
      position = stuckPlatform!.position + _stuckLocalOffset;
      prevPosition = position.clone();
      velocity.setZero();
      if (_brushTrail.isNotEmpty) {
        _brushTrail.removeAt(0);
      }
      return;
    }

    // 1. Salva la posizione precedente per il Continuous Collision Detection (anti-tunneling)
    prevPosition = position.clone();
    velocity.y += gravity * dt;
    position += velocity * dt;

    // 2. Rimbalzo controllato esattamente sul bordo interno delle mura in pietra!
    final halfWall = game.towerHalfWidth - radius;
    if (position.x < -halfWall) {
      position.x = -halfWall;
      velocity.x = velocity.x.abs() * 0.72;
      if (velocity.y > 120) velocity.y *= 0.65; // Frena la caduta sui muri
      _onWallBounce();
    } else if (position.x > halfWall) {
      position.x = halfWall;
      velocity.x = -velocity.x.abs() * 0.72;
      if (velocity.y > 120) velocity.y *= 0.65;
      _onWallBounce();
    }

    // 3. Base di partenza a 0.0m (incolla/ferma la palla a terra)
    if (position.y > 0) {
      position.y = 0;
      velocity.setZero();
      airCharges = maxAirCharges;
      if (!game.isMenuDemo) {
        game.chargesNotifier.value = maxAirCharges;
        game.comboNotifier.value = 0;
      }
    }

    // 4. Scia fluida in volo
    _brushTrail.add(position.clone());
    if (_brushTrail.length > 13) {
      _brushTrail.removeAt(0);
    }
  }

  void _onWallBounce() {
    if (_wallBounceCooldown > 0) return;
    _wallBounceCooldown = 0.08;
    _squashImpactTimer = 0.09;
    if (!game.isMenuDemo) {
      game.totalBounces++;
    }
    // Toccare il muro restituisce 1 lancio se eri a secco, così non rimani mai bloccato!
    if (airCharges == 0) {
      airCharges = 1;
      if (!game.isMenuDemo) {
        game.chargesNotifier.value = airCharges;
      }
    }
    if (!game.isMenuDemo) {
      game.addCameraTrauma(0.14);
      game.audioHaptics.onWallOrPadBounce(combo: game.comboNotifier.value);
    }
    game.spawnInkDrops(
      position.clone(),
      game.palette.matchaSafe,
      count: 6,
    );
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    final center = Offset(size.x / 2, size.y / 2);

    // 1. Scia fluida
    for (int i = 0; i < _brushTrail.length; i++) {
      final trailOffset = _brushTrail[i] - position;
      final t = (i + 1) / _brushTrail.length;
      final strokePaint = Paint()
        ..color = p.playerFill.withAlpha((t * 0.26 * 255).round())
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        center + Offset(trailOffset.x, trailOffset.y),
        radius * t * 0.82,
        strokePaint,
      );
    }

    // 2. Indicatore visivo quando sei INCOLLATO a una piattaforma (alone verde stabile)
    if (stuckPlatform != null) {
      canvas.drawCircle(
        center,
        radius + 6.5,
        Paint()
          ..color = p.matchaSafe.withAlpha((0.30 * 255).round())
          ..style = PaintingStyle.fill,
      );
    }

    // 3. Anelli che indicano i Lanci disponibili
    final visibleRings = min(airCharges, 3);
    for (int c = 0; c < visibleRings; c++) {
      final ringRadius = radius + 5.0 + (c * 4.2);
      final ringPaint = Paint()
        ..color = p.ochreSeal.withAlpha((0.85 * 255).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;

      for (int seg = 0; seg < 3; seg++) {
        final startAngle =
            _ringRotation * (c.isEven ? 1 : -1) + (seg * 2 * pi / 3) + 0.2;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: ringRadius),
          startAngle,
          (2 * pi / 3) - 0.4,
          false,
          ringPaint,
        );
      }
    }

    // 4. Bolla di protezione "Scudo" (dopo un Revive)
    if (shieldTimer > 0) {
      canvas.drawCircle(
        center,
        radius + 13,
        Paint()
          ..color = p.matchaSafe.withAlpha((0.25 * 255).round())
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        center,
        radius + 13,
        Paint()
          ..color = p.matchaSafe
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
    }

    // 5. Ombra portata + Corpo elastico Squash & Stretch
    canvas.save();
    canvas.translate(center.dx, center.dy);

    double stretch = 1.0;
    double squash = 1.0;
    double angle = 0.0;
    if (velocity.length > 35.0) {
      angle = atan2(velocity.y, velocity.x);
      stretch = (1.0 + (velocity.length / 2200.0)).clamp(1.0, 1.35);
      squash = 1.0 / stretch;
      if (_squashImpactTimer > 0) {
        final tmp = stretch;
        stretch = squash * 0.85;
        squash = tmp * 1.15;
      }
    } else if (_squashImpactTimer > 0) {
      // Piccolo schiacciamento morbido quando ti incolli alla piattaforma
      stretch = 1.18;
      squash = 0.84;
    }

    // Ombra
    canvas.save();
    canvas.translate(3.5, 4.5);
    canvas.rotate(angle);
    canvas.scale(stretch, squash);
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()..color = p.shadowColor,
    );
    canvas.restore();

    // Nucleo della palla
    canvas.rotate(angle);
    canvas.scale(stretch, squash);

    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()..color = p.playerFill,
    );

    // Riflesso superiore
    canvas.drawCircle(
      const Offset(-4, -4),
      radius * 0.32,
      Paint()..color = p.paperCard.withAlpha((0.65 * 255).round()),
    );

    // Contorno netto
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = p.playerStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8,
    );

    canvas.restore();
  }
}

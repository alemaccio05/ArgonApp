import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/daily_seed.dart';
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
  int airCharges = maxAirCharges;
  double shieldTimer = 0.0;
  double _squashImpactTimer = 0.0;
  double _ringRotation = 0.0;
  final List<Vector2> _brushTrail = [];

  /// Se diverso da null, la palla è "incollata" a questa piattaforma verde
  /// e il giocatore può mirare con tutta calma senza cadere!
  ObstacleBlock? stuckPlatform;
  Vector2 _stuckLocalOffset = Vector2.zero();
  double _detachCooldown = 0.0;

  PlayerCore({required super.position})
      : super(size: Vector2.all(radius * 2), anchor: Anchor.center);

  bool get isStuck => stuckPlatform != null || position.y >= 0.0;

  /// Incolla la palla alla piattaforma verde toccata e ricarica tutti i lanci
  void stickToPlatform(ObstacleBlock pad) {
    if (_detachCooldown > 0 || stuckPlatform == pad) return;

    stuckPlatform = pad;
    velocity.setZero();

    // Posiziona la palla ordinatamente sul bordo più vicino della piattaforma
    final halfW = pad.size.x / 2;
    final halfH = pad.size.y / 2;
    final clampedX = (position.x - pad.position.x).clamp(-halfW + 4, halfW - 4);
    final isBelow = position.y > pad.position.y + halfH * 0.5;

    _stuckLocalOffset = Vector2(
      clampedX,
      isBelow ? (halfH + radius + 1.0) : -(halfH + radius + 1.0),
    );
    position = pad.position + _stuckLocalOffset;

    _squashImpactTimer = 0.12;
    recharge('pad');
  }

  void launch(Vector2 launchVelocity) {
    // Stacca la palla dalla piattaforma e avvia un breve cooldown per non riattaccarsi subito
    if (stuckPlatform != null) {
      stuckPlatform = null;
      _detachCooldown = 0.14;
    }

    velocity = launchVelocity;
    airCharges = max(0, airCharges - 1);
    game.chargesNotifier.value = airCharges;
    _squashImpactTimer = 0.085;
    game.addCameraTrauma(0.18);
    game.spawnInkDrops(
      position.clone(),
      game.palette.playerFill,
      count: 9,
    );
    game.audioHaptics.onLaunch();
  }

  void recharge(String source) {
    final wasRecharged = airCharges < maxAirCharges;
    airCharges = maxAirCharges;
    game.chargesNotifier.value = airCharges;
    game.comboNotifier.value += 1;

    if (wasRecharged && source == 'seal') {
      game.spawnFloatingStamp(position + Vector2(0, -24), '+SLANCIO!');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying) return;

    _ringRotation += dt * 1.8;
    if (shieldTimer > 0) shieldTimer -= dt;
    if (_squashImpactTimer > 0) _squashImpactTimer -= dt;
    if (_detachCooldown > 0) _detachCooldown -= dt;

    // Se la palla è incollata a una piattaforma verde, resta ferma lì sopra!
    if (stuckPlatform != null) {
      position = stuckPlatform!.position + _stuckLocalOffset;
      velocity.setZero();
      if (_brushTrail.isNotEmpty) {
        _brushTrail.removeAt(0);
      }
      return;
    }

    // 1. Gravità e integrazione velocità in volo
    velocity.y += gravity * dt;
    position += velocity * dt;

    // 2. Rimbalzo controllato sulle pareti laterali (dà anche una piccola spinta verso l'alto)
    const halfWall = DailySeedEngine.worldWidth / 2 - radius;
    if (position.x < -halfWall) {
      position.x = -halfWall;
      velocity.x = -velocity.x * 0.72;
      if (velocity.y > 120) velocity.y *= 0.65; // Frena la caduta sui muri
      _onWallBounce();
    } else if (position.x > halfWall) {
      position.x = halfWall;
      velocity.x = -velocity.x * 0.72;
      if (velocity.y > 120) velocity.y *= 0.65;
      _onWallBounce();
    }

    // 3. Base di partenza a 0.0m (incolla/ferma la palla a terra)
    if (position.y > 0) {
      position.y = 0;
      velocity.setZero();
      airCharges = maxAirCharges;
      game.chargesNotifier.value = maxAirCharges;
      game.comboNotifier.value = 0;
    }

    // 4. Scia fluida in volo
    _brushTrail.add(position.clone());
    if (_brushTrail.length > 13) {
      _brushTrail.removeAt(0);
    }
  }

  void _onWallBounce() {
    _squashImpactTimer = 0.09;
    game.totalBounces++;
    // Toccare il muro restituisce 1 lancio se eri a secco, così non rimani mai bloccato!
    if (airCharges == 0) {
      airCharges = 1;
      game.chargesNotifier.value = airCharges;
    }
    game.addCameraTrauma(0.14);
    game.spawnInkDrops(
      position.clone(),
      game.palette.matchaSafe,
      count: 6,
    );
    game.audioHaptics.onWallOrPadBounce(combo: game.comboNotifier.value);
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

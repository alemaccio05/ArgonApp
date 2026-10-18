import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/daily_seed.dart';
import '../../core/palette_theme.dart';
import '../ink_sling_game.dart';
import 'player_core.dart';

enum BlockType { matchaPad, vermilionHazard, hankoSeal }

/// Ostacoli generati dal Seed Giornaliero:
/// - [BlockType.matchaPad]: Piattaforma Verde Adesiva! Quando la palla la tocca,
///   ci si incolla sopra permettendo al giocatore di fermarsi, mirare e ripartire.
/// - [BlockType.vermilionHazard]: Ostacolo Rosso letale con strisce diagonali.
/// - [BlockType.hankoSeal]: Gemma Dorata di Boost che spinge in alto e ricarica i tiri.
class ObstacleBlock extends PositionComponent
    with HasGameReference<InkSlingGame> {
  final BlockType type;
  final double movingSpeed;
  double _moveDir = 1.0;
  double _pressOffset = 0.0;
  double _sealPulse = 0.0;
  bool _consumed = false;

  ObstacleBlock({
    required super.position,
    required super.size,
    required this.type,
    this.movingSpeed = 0.0,
  }) : super(anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    if (_consumed || !game.isPlaying) return;

    _sealPulse += dt * 3.5;
    if (_pressOffset > 0) {
      _pressOffset = max(0.0, _pressOffset - dt * 24.0);
    }

    // Movimento orizzontale per le barriere mobili
    if (movingSpeed > 0) {
      position.x += movingSpeed * _moveDir * dt;
      final limit = DailySeedEngine.worldWidth / 2 - size.x / 2 - 10;
      if (position.x > limit) {
        position.x = limit;
        _moveDir = -1.0;
      } else if (position.x < -limit) {
        position.x = -limit;
        _moveDir = 1.0;
      }
    }

    final p = game.player;
    // Se il giocatore è già incollato a questa piattaforma, non ricalcolare l'impatto
    if (p.stuckPlatform == this) return;

    final halfW = size.x / 2 + PlayerCore.radius;
    final halfH = size.y / 2 + PlayerCore.radius;

    if ((p.position.x - position.x).abs() < halfW &&
        (p.position.y - position.y).abs() < halfH) {
      _resolveCollision(p);
    }
  }

  void _resolveCollision(PlayerCore p) {
    final palette = game.palette;

    if (type == BlockType.hankoSeal) {
      _consumed = true;
      p.stuckPlatform = null;
      p.velocity.y = min(p.velocity.y, -660.0);
      p.recharge('seal');
      game.triggerHitStop(0.035);
      game.addCameraTrauma(0.28);
      game.spawnInkDrops(position.clone(), palette.ochreSeal, count: 20);
      game.audioHaptics.onSealCollected(combo: game.comboNotifier.value);
      removeFromParent();
      return;
    }

    if (type == BlockType.vermilionHazard) {
      if (p.shieldTimer > 0) {
        _consumed = true;
        game.spawnInkDrops(position.clone(), palette.vermilionHazard, count: 18);
        game.spawnFloatingStamp(position.clone(), 'SCUDO!');
        game.audioHaptics.onSealCollected(combo: game.comboNotifier.value);
        removeFromParent();
      } else {
        game.triggerGameOver(victory: false);
      }
      return;
    }

    if (type == BlockType.matchaPad) {
      // INCOLLAGGIO ALLA PIATTAFORMA VERDE:
      // La palla si ferma sulla piattaforma e ricarica subito tutti i lanci!
      _pressOffset = 4.5;
      game.totalBounces++;
      p.stickToPlatform(this);
      game.addCameraTrauma(0.12);
      game.spawnInkDrops(p.position.clone(), palette.matchaSafe, count: 8);
      game.audioHaptics.onWallOrPadBounce(combo: game.comboNotifier.value);
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

    final isHazard = type == BlockType.vermilionHazard;
    final fillColor = isHazard ? p.vermilionHazard : p.matchaSafe;

    // 1. Ombra portata sotto il blocco
    final shadowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(3.5, 4.5, size.x, size.y),
      const Radius.circular(6),
    );
    canvas.drawRRect(shadowRect, Paint()..color = p.shadowColor);

    // 2. Corpo del blocco (si abbassa dolcemente quando la palla atterra)
    canvas.save();
    canvas.translate(0, _pressOffset);

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(6),
    );
    canvas.drawRRect(bodyRect, Paint()..color = fillColor);

    // 3. Dettaglio visivo:
    // - Ostacolo rosso: strisce diagonali di pericolo
    // - Piattaforma verde adesiva: striscia superiore morbida di atterraggio
    canvas.save();
    canvas.clipRRect(bodyRect);
    if (isHazard) {
      final stripePaint = Paint()
        ..color = p.paperBg.withAlpha((0.28 * 255).round())
        ..strokeWidth = 3.0;
      for (double x = -size.y; x < size.x + size.y; x += 11) {
        canvas.drawLine(
          Offset(x, 0),
          Offset(x + size.y, size.y),
          stripePaint,
        );
      }
    } else {
      // Striscia chiara superiore che indica la superficie adesiva sicura
      canvas.drawRect(
        Rect.fromLTWH(4, 3, size.x - 8, 4),
        Paint()..color = p.paperCard.withAlpha((0.45 * 255).round()),
      );
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

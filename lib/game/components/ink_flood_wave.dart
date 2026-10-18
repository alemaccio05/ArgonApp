import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/daily_seed.dart';
import '../ink_sling_game.dart';

/// L'onda dal basso: parte subito dopo il primo lancio del giocatore (o dopo 1 secondo),
/// mantenendo una pressione costante dal basso senza rimanere mai troppo indietro.
class InkFloodWave extends PositionComponent
    with HasGameReference<InkSlingGame> {
  double _wavePhase = 0.0;

  InkFloodWave({required double startY})
      : super(
          position: Vector2(0, startY),
          size: Vector2(DailySeedEngine.worldWidth, 950),
          anchor: Anchor.topCenter,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _wavePhase += dt * 4.2;

    // Nel menu principale accompagna dal basso la palla animata dimostrativa
    if (game.isMenuDemo) {
      final targetDemoY = game.player.position.y + 210.0;
      position.y += (targetDemoY - position.y) * (dt * 3.5).clamp(0.0, 1.0);
      return;
    }

    if (!game.isPlaying) return;

    // Parte subito appena il giocatore fa il primo salto (0.8m) o dopo 1.1 secondi!
    if (game.maxMetersReached < 0.8 && game.runTimeSeconds < 1.1) return;

    final levelSpeedBonus =
        game.activeMode == GameMode.levelProgression
            ? min(20.0, (game.currentLevel - 1) * 1.8)
            : 6.0;

    final distanceAhead = position.y - game.player.position.y;
    final baseSpeed =
        (game.player.isStuck ? 44.0 : 62.0) + levelSpeedBonus;
    final catchUpSpeed =
        distanceAhead > 260 ? (distanceAhead - 260) * 0.60 : 0.0;
    position.y -= (baseSpeed + catchUpSpeed) * dt;

    if (game.player.position.y > position.y + 8) {
      game.triggerGameOver(victory: false);
    }
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;

    final backWave = Path()..moveTo(0, 0);
    for (double x = 0; x <= size.x; x += 20) {
      final y = sin((x * 0.035) - _wavePhase * 0.8) * 6.0 - 6.0;
      backWave.lineTo(x, y);
    }
    backWave
      ..lineTo(size.x, size.y)
      ..lineTo(0, size.y)
      ..close();
    canvas.drawPath(
      backWave,
      Paint()..color = p.vermilionHazard.withAlpha((0.55 * 255).round()),
    );

    final frontWave = Path()..moveTo(0, 0);
    for (double x = 0; x <= size.x; x += 16) {
      final y = sin((x * 0.04) + _wavePhase) * 5.0;
      frontWave.lineTo(x, y);
    }
    frontWave
      ..lineTo(size.x, size.y)
      ..lineTo(0, size.y)
      ..close();

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [p.inkFloodTop, p.inkFloodBottom],
    );
    canvas.drawPath(
      frontWave,
      Paint()..shader = gradient.createShader(rect),
    );

    final crestLine = Path();
    for (double x = 0; x <= size.x; x += 16) {
      final y = sin((x * 0.04) + _wavePhase) * 5.0;
      if (x == 0) {
        crestLine.moveTo(x, y);
      } else {
        crestLine.lineTo(x, y);
      }
    }
    canvas.drawPath(
      crestLine,
      Paint()
        ..color = p.playerStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8,
    );
  }
}

import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/daily_seed.dart';
import '../ink_sling_game.dart';

/// L'onda dal basso: inizia a salire solo dopo che il giocatore ha superato i primi
/// 8 metri, procedendo a velocità dolce così da lasciare tempo di mirare sulle piattaforme.
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
    _wavePhase += dt * 3.8;
    if (!game.isPlaying) return;

    // Non sale finché il giocatore non ha superato i primi 8 metri (inizio rilassato)
    if (game.maxMetersReached < 8.0) return;

    // Velocità dolce (circa 1 metro al secondo) e rallenta se il giocatore è fermo a mirare
    final distanceAhead = position.y - game.player.position.y;
    final baseSpeed = game.player.isStuck ? 32.0 : 48.0;
    final catchUpSpeed =
        distanceAhead > 520 ? (distanceAhead - 520) * 0.35 : 0.0;
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

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

  // Path, Paint e Shader pre-allocati / cachati per zero allocazioni nel loop di render
  final Path _backWavePath = Path();
  final Path _frontWavePath = Path();
  final Path _crestPath = Path();
  final Paint _backPaint = Paint();
  final Paint _frontPaint = Paint();
  final Paint _crestPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.8;

  Shader? _cachedShader;
  Color? _lastTopColor;
  Color? _lastBottomColor;

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

    if (!game.isPlaying || game.isPaused) return;

    // Durante il freeze temporaneo di respawn ("Seconda Chance"), l'onda resta sospesa
    if (game.player.isRespawnFrozen) return;

    // Parte subito appena il giocatore fa il primo salto (0.8m) o dopo 1.1 secondi!
    if (game.maxMetersReached < 0.8 && game.runTimeSeconds < 1.1) return;

    final levelSpeedBonus = game.activeMode == GameMode.levelProgression
        ? min(20.0, (game.currentLevel - 1) * 1.8)
        : 6.0;

    final distanceAhead = position.y - game.player.position.y;
    final baseSpeed = (game.player.isStuck ? 44.0 : 62.0) + levelSpeedBonus;
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
    final lowQuality = game.isLowQualityMode;
    final step = lowQuality ? 32.0 : 16.0;

    if (!lowQuality) {
      _backWavePath
        ..reset()
        ..moveTo(0, 0);
      for (double x = 0; x <= size.x; x += 20) {
        final y = sin((x * 0.035) - _wavePhase * 0.8) * 6.0 - 6.0;
        _backWavePath.lineTo(x, y);
      }
      _backWavePath
        ..lineTo(size.x, size.y)
        ..lineTo(0, size.y)
        ..close();
      _backPaint.color = p.vermilionHazard.withAlpha((0.55 * 255).round());
      canvas.drawPath(_backWavePath, _backPaint);
    }

    _frontWavePath
      ..reset()
      ..moveTo(0, 0);
    _crestPath.reset();
    for (double x = 0; x <= size.x; x += step) {
      final y = sin((x * 0.04) + _wavePhase) * 5.0;
      _frontWavePath.lineTo(x, y);
      if (x == 0) {
        _crestPath.moveTo(x, y);
      } else {
        _crestPath.lineTo(x, y);
      }
    }
    _frontWavePath
      ..lineTo(size.x, size.y)
      ..lineTo(0, size.y)
      ..close();

    if (lowQuality) {
      _frontPaint
        ..shader = null
        ..color = p.inkFloodTop;
    } else {
      if (_cachedShader == null ||
          _lastTopColor != p.inkFloodTop ||
          _lastBottomColor != p.inkFloodBottom) {
        _lastTopColor = p.inkFloodTop;
        _lastBottomColor = p.inkFloodBottom;
        final rect = Rect.fromLTWH(0, 0, size.x, size.y);
        _cachedShader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.inkFloodTop, p.inkFloodBottom],
        ).createShader(rect);
      }
      _frontPaint.shader = _cachedShader;
    }
    canvas.drawPath(_frontWavePath, _frontPaint);

    _crestPaint.color = p.playerStroke;
    canvas.drawPath(_crestPath, _crestPaint);
  }
}

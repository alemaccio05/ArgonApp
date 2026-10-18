import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../ink_sling_game.dart';

/// Piccoli timbri/testi tipografici che compaiono nel mondo quando concateni
/// rimbalzi o rompi un sigillo Hanko ("印 RICARICA!", "SCUDO!").
class FloatingStampComponent extends PositionComponent
    with HasGameReference<InkSlingGame> {
  final String label;
  double _life = 0.0;
  static const double _maxLife = 0.65;

  FloatingStampComponent({
    required super.position,
    required this.label,
  }) : super(anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;
    position.y -= 48.0 * dt;
    if (_life >= _maxLife) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final alpha = (1.0 - (_life / _maxLife)).clamp(0.0, 1.0);
    final p = game.palette;

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: p.vermilionHazard.withAlpha((alpha * 255).round()),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  }
}

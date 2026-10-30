import 'dart:math';
import 'package:flutter/material.dart';
import '../core/ball_skins.dart';
import '../core/palette_theme.dart';
import '../game/ink_sling_game.dart';

/// Pagina / Dialog dedicato alla selezione e anteprima delle Skin per la palletta che salta.
class BallSkinsDialog extends StatefulWidget {
  final InkSlingGame game;
  const BallSkinsDialog({super.key, required this.game});

  static Future<void> show(BuildContext context, InkSlingGame game) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => BallSkinsDialog(game: game),
    );
  }

  @override
  State<BallSkinsDialog> createState() => _BallSkinsDialogState();
}

class _BallSkinsDialogState extends State<BallSkinsDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late String _inspectedSkinId;

  @override
  void initState() {
    super.initState();
    _inspectedSkinId = widget.game.storage.selectedBallSkinId;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.game.paletteNotifier,
        widget.game.languageNotifier,
        _animController,
      ]),
      builder: (context, _) {
        final p = widget.game.paletteNotifier.value;
        final s = widget.game.strings;
        final storage = widget.game.storage;
        final inspectedSkin = BallSkinsCatalog.getById(_inspectedSkinId);
        final isEquipped = storage.selectedBallSkinId == inspectedSkin.id;
        final isUnlocked = inspectedSkin.isUnlocked(storage);

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 660),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: p.paperCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: p.inkPrimary, width: 2.6),
                boxShadow: [
                  BoxShadow(
                    color: p.shadowColor,
                    offset: const Offset(5, 6),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Intestazione con Titolo e Bottone Chiusura (X)
                  Row(
                    children: [
                      Icon(Icons.palette_rounded, color: p.ochreSeal, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.skinsTitle,
                          style: TextStyle(
                            color: p.inkPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded, color: p.inkPrimary, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Area di Anteprima Dinamica della Sfera con Animazione Rimbalzo
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: p.paperBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: p.inkPrimary, width: 1.8),
                    ),
                    child: Row(
                      children: [
                        // Scena Canvas Rimbalzante
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: p.paperCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: p.paperGrid, width: 1.5),
                          ),
                          child: CustomPaint(
                            painter: _BallPreviewPainter(
                              skin: inspectedSkin,
                              palette: p,
                              progress: _animController.value,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Dettagli Skin Ispezionata
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    inspectedSkin.emoji,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        inspectedSkin.getName(s),
                                        style: TextStyle(
                                          color: p.inkPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                inspectedSkin.getDescription(s),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: p.inkSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Bottone Stato / Azione
                              if (isEquipped)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: p.matchaSafe,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    s.equippedBadge,
                                    style: TextStyle(
                                      color: p.onMatchaSafe,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                )
                              else if (isUnlocked)
                                SizedBox(
                                  height: 26,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: p.playerFill,
                                      foregroundColor: p.onPlayerFill,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                    ),
                                    onPressed: () async {
                                      await storage.setSelectedBallSkin(inspectedSkin.id);
                                      setState(() {});
                                    },
                                    child: Text(
                                      s.equipBtn,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Row(
                                  children: [
                                    Icon(
                                      Icons.lock_rounded,
                                      size: 13,
                                      color: p.vermilionHazard,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${inspectedSkin.getRequirement(s)} (${inspectedSkin.getProgress(storage, s)})',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: p.vermilionHazard,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Griglia Selezione Skin
                  Expanded(
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: BallSkinsCatalog.allSkins.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 2.1,
                      ),
                      itemBuilder: (context, index) {
                        final skin = BallSkinsCatalog.allSkins[index];
                        final isInspected = skin.id == _inspectedSkinId;
                        final isSkinEquipped = storage.selectedBallSkinId == skin.id;
                        final isSkinUnlocked = skin.isUnlocked(storage);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _inspectedSkinId = skin.id;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isInspected
                                  ? p.paperCard
                                  : p.paperBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isInspected
                                    ? p.ochreSeal
                                    : (isSkinEquipped
                                        ? p.matchaSafe
                                        : p.paperGrid),
                                width: isInspected ? 2.2 : (isSkinEquipped ? 1.8 : 1.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Thumbnail Sfera
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: p.paperCard,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSkinEquipped
                                          ? p.matchaSafe
                                          : p.inkPrimary,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: isSkinUnlocked
                                        ? CustomPaint(
                                            size: const Size(22, 22),
                                            painter: _BallIconPainter(
                                              skin: skin,
                                              palette: p,
                                            ),
                                          )
                                        : Icon(
                                            Icons.lock_rounded,
                                            size: 15,
                                            color: p.inkSecondary.withAlpha(160),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Nome e Stato
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          skin.getName(s),
                                          style: TextStyle(
                                            color: isSkinUnlocked
                                                ? p.inkPrimary
                                                : p.inkSecondary,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      if (isSkinEquipped)
                                        Text(
                                          s.equippedBadge,
                                          style: TextStyle(
                                            color: p.matchaSafe,
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        )
                                      else if (isSkinUnlocked)
                                        Text(
                                          s.unlockedLabel,
                                          style: TextStyle(
                                            color: p.inkSecondary,
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        )
                                      else
                                        Text(
                                          skin.getProgress(storage, s),
                                          style: TextStyle(
                                            color: p.vermilionHazard,
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Disegna la sfera in anteprima animata con rimbalzo verticale e squash & stretch
class _BallPreviewPainter extends CustomPainter {
  final BallSkinItem skin;
  final RisographPalette palette;
  final double progress;

  _BallPreviewPainter({
    required this.skin,
    required this.palette,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    // Rimbalzo sinusoidale
    final bounceCycle = sin(progress * 2 * pi);
    final normY = (bounceCycle + 1.0) / 2.0; // 0.0 (in basso) .. 1.0 (in alto)
    final ballY = size.height * 0.72 - (normY * 26.0);
    const radius = 13.0;

    // Squash a terra
    double stretch = 1.0;
    double squash = 1.0;
    if (normY < 0.12) {
      stretch = 1.25;
      squash = 0.80;
    } else if (normY > 0.4 && normY < 0.7) {
      stretch = 0.88;
      squash = 1.15;
    }

    final p = palette;
    final coreColor = skin.getCoreColor(p);
    final strokeColor = skin.getStrokeColor(p);

    // Ombra a terra
    final shadowScale = 1.0 - (normY * 0.45);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, size.height * 0.84),
        width: radius * 2.2 * shadowScale,
        height: 5.5 * shadowScale,
      ),
      Paint()..color = p.shadowColor.withAlpha((0.35 * 255).round()),
    );

    // Sfera animata
    canvas.save();
    canvas.translate(centerX, ballY);
    canvas.scale(stretch, squash);

    // Corpo
    canvas.drawCircle(Offset.zero, radius, Paint()..color = coreColor);

    // Grafica Skin
    skin.renderCustomSkin(canvas, radius, p, progress * 2 * pi);

    // Riflesso speculare avorio caldo (sempre visibile anche in modalità Notte)
    canvas.drawCircle(
      const Offset(-3.5, -3.5),
      radius * 0.28,
      Paint()..color = const Color(0xFFFFFDF8).withAlpha((0.68 * 255).round()),
    );

    // Contorno
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BallPreviewPainter oldDelegate) => true;
}

/// Disegna l'icona compatta statica per le miniature
class _BallIconPainter extends CustomPainter {
  final BallSkinItem skin;
  final RisographPalette palette;

  _BallIconPainter({required this.skin, required this.palette});

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 9.5;
    final center = Offset(size.width / 2, size.height / 2);
    final p = palette;
    final coreColor = skin.getCoreColor(p);
    final strokeColor = skin.getStrokeColor(p);

    canvas.save();
    canvas.translate(center.dx, center.dy);

    canvas.drawCircle(Offset.zero, radius, Paint()..color = coreColor);
    skin.renderCustomSkin(canvas, radius, p, 0.4);

    canvas.drawCircle(
      const Offset(-2.5, -2.5),
      radius * 0.28,
      Paint()..color = const Color(0xFFFFFDF8).withAlpha((0.68 * 255).round()),
    );

    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BallIconPainter oldDelegate) => false;
}

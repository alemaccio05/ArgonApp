import 'package:flame/components.dart' show Vector2;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../core/daily_seed.dart';
import '../core/palette_theme.dart';
import '../game/ink_sling_game.dart';

/// Schermata di Fine Partita protetta da qualsiasi RenderFlex overflow,
/// con Mini-Mappa 0-100m della traiettoria percorsa, Revive con Scudo e Condivisione.
class GameOverOverlay extends StatelessWidget {
  final InkSlingGame game;
  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RisographPalette>(
      valueListenable: game.paletteNotifier,
      builder: (context, p, _) {
        final meters = game.maxMetersReached;
        final topPct =
            DailySeedEngine.estimateTopPercentile(meters, game.isVictory);
        final receiptText = DailySeedEngine.buildShareReceipt(
          meters: meters,
          isVictory: game.isVictory,
          bounces: game.totalBounces,
          seconds: game.runTimeSeconds,
          attemptNumber: game.currentAttemptNumber,
        );

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 385),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: p.paperCard,
                  borderRadius: BorderRadius.circular(18),
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
                    // Intestazione (Expanded sulla colonna di sinistra per impedire qualsiasi overflow!)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  game.isVictory
                                      ? 'TORRE COMPLETATA!'
                                      : 'FERMATO A ${meters.toStringAsFixed(1)}m',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: game.isVictory
                                        ? p.matchaSafe
                                        : p.vermilionHazard,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                game.lastRunWasNewDailyRecord
                                    ? '★ NUOVO RECORD DI OGGI • TOP $topPct%'
                                    : 'MIGLIORE OGGI: ${game.storage.bestMetersToday.toStringAsFixed(1)}m • TOP $topPct%',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: p.inkSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Badge icona risultato (niente caratteri orientali)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: game.isVictory
                                ? p.matchaSafe
                                : p.vermilionHazard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: p.inkPrimary, width: 2),
                          ),
                          child: Icon(
                            game.isVictory
                                ? Icons.emoji_events_rounded
                                : Icons.flag_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Mini-mappa verticale + Riepilogo condivisibile
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: p.paperBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: p.inkPrimary, width: 1.8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 128,
                            decoration: BoxDecoration(
                              color: p.paperCard,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: p.inkPrimary, width: 1.6),
                            ),
                            child: CustomPaint(
                              painter: RisographFlightMapPainter(
                                flightPath: game.flightPath,
                                isVictory: game.isVictory,
                                palette: p,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'IL TUO TRACCIATO DI OGGI',
                                  style: TextStyle(
                                    color: p.inkSecondary,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SelectableText(
                                  receiptText,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11.5,
                                    color: p.inkPrimary,
                                    fontWeight: FontWeight.w700,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // REWARDED AD REVIVE: Riparti dal metro dell'impatto su una piattaforma verde con Scudo!
                    if (!game.isVictory && !game.reviveUsed && meters >= 5.0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: p.ochreSeal,
                            foregroundColor: p.inkPrimary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              vertical: 13,
                              horizontal: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: p.inkPrimary, width: 2.0),
                            ),
                          ),
                          onPressed: () async {
                            final granted =
                                await game.monetization.showRewardedAd(
                              context: context,
                              rewardTitle:
                                  'Continua da ${meters.toStringAsFixed(1)}m con Piattaforma + Scudo',
                              isProUnlocked: game.storage.proUnlocked,
                            );
                            if (granted) {
                              game.reviveWithShield();
                            }
                          },
                          icon: const Icon(Icons.shield_outlined, size: 18),
                          label: Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'CONTINUA DA ${meters.toStringAsFixed(0)}m CON SCUDO (VIDEO)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Pulsanti Condividi & Riprova
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: p.inkPrimary,
                              side: BorderSide(color: p.inkPrimary, width: 2.0),
                              padding: const EdgeInsets.symmetric(
                                vertical: 13,
                                horizontal: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: receiptText),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: p.inkPrimary,
                                    content: Text(
                                      'Risultato copiato! Incollalo nei commenti!',
                                      style: TextStyle(color: p.paperCard),
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                              try {
                                await Share.share(receiptText);
                              } catch (_) {}
                            },
                            icon:
                                const Icon(Icons.ios_share_rounded, size: 16),
                            label: const Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'CONDIVIDI',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: p.playerFill,
                              foregroundColor: p.paperCard,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                vertical: 13,
                                horizontal: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side:
                                    BorderSide(color: p.inkPrimary, width: 2.0),
                              ),
                            ),
                            onPressed: game.startRun,
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'RIPROVA SUBITO',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: game.returnToMainMenu,
                      child: Text(
                        'Torna al Menu Principale',
                        style: TextStyle(
                          color: p.inkSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Disegna la mini-mappa 0-100m della traiettoria percorsa
class RisographFlightMapPainter extends CustomPainter {
  final List<Vector2> flightPath;
  final bool isVictory;
  final RisographPalette palette;

  RisographFlightMapPainter({
    required this.flightPath,
    required this.isVictory,
    required this.palette,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = palette.paperGrid
      ..strokeWidth = 1.0;
    for (int i = 1; i <= 4; i++) {
      final y = size.height * (i / 5.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (flightPath.isEmpty) return;

    final path = Path();
    for (int i = 0; i < flightPath.length; i++) {
      final pt = flightPath[i];
      final normX = ((pt.x + DailySeedEngine.worldWidth / 2) /
              DailySeedEngine.worldWidth)
          .clamp(0.08, 0.92);
      final normY = (1.0 -
              (-pt.y /
                  (DailySeedEngine.goalMeters *
                      DailySeedEngine.metersToPixels)))
          .clamp(0.06, 0.94);

      final x = normX * size.width;
      final y = normY * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = palette.playerFill
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    final last = flightPath.last;
    final endX = ((last.x + DailySeedEngine.worldWidth / 2) /
            DailySeedEngine.worldWidth)
        .clamp(0.08, 0.92) *
        size.width;
    final endY = (1.0 -
            (-last.y /
                (DailySeedEngine.goalMeters * DailySeedEngine.metersToPixels)))
        .clamp(0.06, 0.94) *
        size.height;

    canvas.drawCircle(
      Offset(endX, endY),
      4.5,
      Paint()
        ..color = isVictory ? palette.matchaSafe : palette.vermilionHazard,
    );
    canvas.drawCircle(
      Offset(endX, endY),
      4.5,
      Paint()
        ..color = palette.inkPrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

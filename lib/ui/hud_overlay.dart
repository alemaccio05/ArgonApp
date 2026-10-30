import 'package:flutter/material.dart';
import '../core/daily_seed.dart';
import '../game/components/player_core.dart';
import '../game/ink_sling_game.dart';

/// HUD superiore compatto e protetto da overflow:
/// - Mostra metri formattati deterministicamente (Punto 2)
/// - Mostra i 3 lanci disponibili per il salto
/// - Sostituisce il vecchio tasto "X" con il pulsante dedicato di Pausa `||`
///   posizionato in area sicura (`SafeArea`) (Punto 5)
/// - Isolato con `RepaintBoundary` per minimizzare i redraw durante il salto (Punto 6)
class HudOverlay extends StatelessWidget {
  final InkSlingGame game;
  const HudOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          game.paletteNotifier,
          game.languageNotifier,
        ]),
        builder: (context, _) {
          final p = game.paletteNotifier.value;
          final s = game.strings;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: p.paperCard.withAlpha((0.94 * 255).round()),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: p.inkPrimary, width: 2.0),
                      boxShadow: [
                        BoxShadow(
                          color: p.shadowColor,
                          offset: const Offset(3, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Contatore Metri + Barra di Avanzamento (Expanded per zero overflow)
                        Expanded(
                          child: RepaintBoundary(
                            child: ValueListenableBuilder<double>(
                              valueListenable: game.metersNotifier,
                              builder: (_, meters, __) {
                                final isInfinite =
                                    game.activeMode == GameMode.infiniteTower;
                                final goal = game.currentGoalMeters;
                                final formattedMeters =
                                    DailySeedEngine.formatMeters(
                                  meters,
                                  maxGoal: isInfinite ? null : goal,
                                );
                                final modeLabel =
                                    game.activeMode == GameMode.levelProgression
                                        ? '${s.levelShort} ${game.currentLevel}'
                                        : (isInfinite
                                            ? s.hudInfiniteBadge
                                            : s.hudDailyBadge);
                                final nextInfMilestone =
                                    DailySeedEngine.getInfiniteNextObstacleMeters(
                                  meters,
                                );
                                final progressVal = isInfinite
                                    ? ((meters % 50.0) / 50.0).clamp(0.0, 1.0)
                                    : (meters / goal).clamp(0.0, 1.0);
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Container(
                                            margin: const EdgeInsets.only(
                                              right: 6,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isInfinite
                                                  ? p.ochreSeal.withAlpha(42)
                                                  : p.paperBg,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              border: Border.all(
                                                color: p.inkPrimary,
                                                width: 1.4,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (isInfinite) ...[
                                                  Icon(
                                                    Icons.all_inclusive_rounded,
                                                    size: 11,
                                                    color: p.inkPrimary,
                                                  ),
                                                  const SizedBox(width: 3),
                                                ],
                                                Text(
                                                  modeLabel,
                                                  style: TextStyle(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w900,
                                                    color: p.inkPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '${formattedMeters}m',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                              color: p.inkPrimary,
                                              height: 1.0,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            isInfinite
                                                ? '• ${nextInfMilestone}m'
                                                : '/ ${goal.toInt()}m',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                              color: p.inkSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    SizedBox(
                                      width: 125,
                                      height: 6,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(3),
                                        child: LinearProgressIndicator(
                                          value: progressVal,
                                          backgroundColor: p.paperGrid,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            p.matchaSafe,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // 3 Lanci Aerei disponibili + Pulsante Pausa dedicato (||)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RepaintBoundary(
                              child: ValueListenableBuilder<int>(
                                valueListenable: game.chargesNotifier,
                                builder: (_, charges, __) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        s.hudLaunchesLabel,
                                        style: TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w900,
                                          color: p.inkSecondary,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: List.generate(
                                          PlayerCore.maxAirCharges,
                                          (index) {
                                            final active = index < charges;
                                            return Container(
                                              margin: const EdgeInsets.only(
                                                left: 5,
                                              ),
                                              width: 14,
                                              height: 14,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: active
                                                    ? p.ochreSeal
                                                    : p.paperBg,
                                                border: Border.all(
                                                  color: p.inkPrimary,
                                                  width: 1.8,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Pulsante dedicato di Pausa (icona standard ||) in safe area
                            Semantics(
                              button: true,
                              label: s.pauseTitle,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(9),
                                  onTap: () {
                                    game.audioHaptics.onButtonTap();
                                    game.pauseGame();
                                  },
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: p.paperBg,
                                      borderRadius: BorderRadius.circular(9),
                                      border: Border.all(
                                        color: p.inkPrimary,
                                        width: 1.8,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.pause_rounded,
                                      color: p.inkPrimary,
                                      size: 21,
                                    ),
                                  ),
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
          );
        },
      ),
    );
  }
}

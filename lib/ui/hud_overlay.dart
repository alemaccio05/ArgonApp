import 'package:flutter/material.dart';
import '../core/palette_theme.dart';
import '../game/components/player_core.dart';
import '../game/ink_sling_game.dart';

/// HUD superiore compatto e protetto da overflow: mostra metri, progresso verso i 100m,
/// i 3 lanci disponibili per il salto e i pulsanti per cambiare tema o uscire.
class HudOverlay extends StatelessWidget {
  final InkSlingGame game;
  const HudOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RisographPalette>(
      valueListenable: game.paletteNotifier,
      builder: (context, p, _) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
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
                        child: ValueListenableBuilder<double>(
                          valueListenable: game.metersNotifier,
                          builder: (_, meters, __) {
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
                                      Text(
                                        '${meters.toStringAsFixed(1)}m',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: p.inkPrimary,
                                          height: 1.0,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        '/ 100m',
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
                                      value: (meters / 100.0).clamp(0.0, 1.0),
                                      backgroundColor: p.paperGrid,
                                      valueColor: AlwaysStoppedAnimation<Color>(
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
                      const SizedBox(width: 8),

                      // 3 Lanci Aerei disponibili + Pulsanti Tema e Menu
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ValueListenableBuilder<int>(
                            valueListenable: game.chargesNotifier,
                            builder: (_, charges, __) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'LANCI',
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
                                          margin:
                                              const EdgeInsets.only(left: 5),
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
                          const SizedBox(width: 6),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            tooltip: 'Cambia Tema',
                            onPressed: game.cyclePalette,
                            icon: Icon(
                              Icons.palette_outlined,
                              color: p.inkPrimary,
                              size: 20,
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            tooltip: 'Menu Principale',
                            onPressed: game.returnToMainMenu,
                            icon: Icon(
                              Icons.close_rounded,
                              color: p.inkPrimary,
                              size: 22,
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
    );
  }
}

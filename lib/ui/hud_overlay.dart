import 'package:flutter/material.dart';
import '../core/climb_abilities.dart';
import '../core/daily_seed.dart';
import '../game/components/player_core.dart';
import '../game/ink_sling_game.dart';

/// HUD superiore + Controllo Abilità Attiva + Banner Spettatore P2P:
/// - Mostra metri formattati deterministicamente (Punto 2)
/// - Mostra i 3 lanci disponibili per il salto
/// - Mostra in tempo reale i metri del Fantasma Avversario P2P e il Banner Spettatore
/// - Mostra il pulsante dell'Abilità Equipaggiata con Cooldown in secondi
/// - Isolato con `RepaintBoundary` per minimizzare i redraw durante il salto
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
          final equippedAbility = ClimbAbilitiesCatalog.getById(
            game.storage.selectedAbilityId,
          );

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Sezione Superiore: Barra Metri + P2P Ghost Status + Banner Spettatore
                  Column(
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
                            // Contatore Metri + Barra di Avanzamento
                            Expanded(
                              child: RepaintBoundary(
                                child: ValueListenableBuilder<double>(
                                  valueListenable: game.metersNotifier,
                                  builder: (_, meters, __) {
                                    final isInfinite =
                                        game.activeMode ==
                                        GameMode.infiniteTower;
                                    final goal = game.currentGoalMeters;
                                    final formattedMeters =
                                        DailySeedEngine.formatMeters(
                                          meters,
                                          maxGoal: isInfinite ? null : goal,
                                        );
                                    final modeLabel = game.isP2PMatch
                                        ? '⚔️ P2P'
                                        : game.activeMode ==
                                              GameMode.levelProgression
                                        ? '${s.levelShort} ${game.currentLevel}'
                                        : (isInfinite
                                              ? s.hudInfiniteBadge
                                              : s.hudDailyBadge);
                                    final nextInfMilestone =
                                        DailySeedEngine.getInfiniteNextObstacleMeters(
                                          meters,
                                        );
                                    final progressVal = isInfinite
                                        ? ((meters % 50.0) / 50.0).clamp(
                                            0.0,
                                            1.0,
                                          )
                                        : (meters / goal).clamp(0.0, 1.0);
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.baseline,
                                            textBaseline:
                                                TextBaseline.alphabetic,
                                            children: [
                                              Container(
                                                margin: const EdgeInsets.only(
                                                  right: 6,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: game.isP2PMatch
                                                      ? p.vermilionHazard
                                                            .withAlpha(42)
                                                      : isInfinite
                                                      ? p.ochreSeal.withAlpha(
                                                          42,
                                                        )
                                                      : p.paperBg,
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                  border: Border.all(
                                                    color: p.inkPrimary,
                                                    width: 1.4,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    if (isInfinite &&
                                                        !game.isP2PMatch) ...[
                                                      Icon(
                                                        Icons
                                                            .all_inclusive_rounded,
                                                        size: 11,
                                                        color: p.inkPrimary,
                                                      ),
                                                      const SizedBox(width: 3),
                                                    ],
                                                    Text(
                                                      modeLabel,
                                                      style: TextStyle(
                                                        fontSize: 9.5,
                                                        fontWeight:
                                                            FontWeight.w900,
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
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
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
                                          borderRadius: BorderRadius.circular(
                                            9,
                                          ),
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

                      // Pill Avversario Fantasma P2P in tempo reale
                      if (game.isP2PMatch) ...[
                        const SizedBox(height: 6),
                        RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: Listenable.merge([
                              game.p2pService.opponentMetersNotifier,
                              game.p2pService.opponentDeadNotifier,
                              game.p2pService.opponentLeftNotifier,
                            ]),
                            builder: (_, __) {
                              final opp = game.p2pService.opponent;
                              final oppLeft = !game.isBotTrainingMatch &&
                                  game.p2pService.opponentLeftNotifier.value;
                              final oppMeters =
                                  game.p2pService.opponentMetersNotifier.value;
                              final oppDead =
                                  game.p2pService.opponentDeadNotifier.value;
                              final iconStr = oppLeft
                                  ? '👋'
                                  : (oppDead
                                      ? '💀'
                                      : (game.isBotTrainingMatch ? '🤖' : '👻'));
                              final labelStr = oppLeft
                                  ? '${opp.name}: ${s.opponentLeftMatchShort}'
                                  : '${opp.name}: ${oppMeters.toStringAsFixed(1)}m';
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: p.paperCard.withAlpha(235),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: (oppDead || oppLeft)
                                        ? p.vermilionHazard
                                        : p.inkPrimary,
                                    width: 1.6,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      iconStr,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        labelStr,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w900,
                                          color: p.inkPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      // Banner Modalità Spettatore (senza tasto Termina: si esce solo dal menu Pausa ||)
                      RepaintBoundary(
                        child: ValueListenableBuilder<bool>(
                          valueListenable: game.spectatingNotifier,
                          builder: (_, isSpectating, __) {
                            if (!isSpectating) return const SizedBox.shrink();
                            return Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: p.inkPrimary,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: p.ochreSeal,
                                  width: 2.0,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    s.spectatorBannerTitle,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: p.ochreSeal,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    s.spectatorBannerSub(
                                      game.p2pService.opponent.name,
                                    ),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 10.5,
                                      color: p.paperBg,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  // Sezione Inferiore: Pulsante Abilità Attiva centrato con Cooldown in secondi
                  RepaintBoundary(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: game.spectatingNotifier,
                      builder: (_, isSpectating, __) {
                        if (isSpectating) return const SizedBox.shrink();
                        return Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ValueListenableBuilder<double>(
                              valueListenable: game.abilityCooldownNotifier,
                              builder: (_, cooldownRem, __) {
                                final isReady = cooldownRem <= 0.05;
                                final progress = isReady
                                    ? 1.0
                                    : (1.0 -
                                              (cooldownRem /
                                                  equippedAbility
                                                      .cooldownSeconds))
                                          .clamp(0.0, 1.0);
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: isReady
                                        ? () => game.activateEquippedAbility()
                                        : null,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isReady
                                            ? p.paperCard.withAlpha(242)
                                            : p.paperGrid.withAlpha(220),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isReady
                                              ? p.ochreSeal
                                              : p.inkPrimary.withAlpha(120),
                                          width: isReady ? 2.4 : 1.6,
                                        ),
                                        boxShadow: isReady
                                            ? [
                                                BoxShadow(
                                                  color: p.shadowColor,
                                                  offset: const Offset(2, 3),
                                                  blurRadius: 0,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            equippedAbility.icon,
                                            style: TextStyle(
                                              fontSize: 20,
                                              color: isReady
                                                  ? null
                                                  : p.inkPrimary.withAlpha(110),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                equippedAbility.getName(s),
                                                style: TextStyle(
                                                  fontFamily: 'monospace',
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w900,
                                                  color: isReady
                                                      ? p.inkPrimary
                                                      : p.inkSecondary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SizedBox(
                                                    width: 44,
                                                    height: 5,
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            3,
                                                          ),
                                                      child:
                                                          LinearProgressIndicator(
                                                            value: progress,
                                                            backgroundColor:
                                                                p.paperBg,
                                                            valueColor:
                                                                AlwaysStoppedAnimation<
                                                                  Color
                                                                >(
                                                                  isReady
                                                                      ? p.matchaSafe
                                                                      : p.ochreSeal,
                                                                ),
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    isReady
                                                        ? s.abilityReadyLabel
                                                        : '${cooldownRem.ceil()}s',
                                                    style: TextStyle(
                                                      fontFamily: 'monospace',
                                                      fontSize: 9.5,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: isReady
                                                          ? p.matchaSafe
                                                          : p.vermilionHazard,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
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

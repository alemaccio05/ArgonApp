import 'package:flame/components.dart' show Vector2;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../core/daily_seed.dart';
import '../core/palette_theme.dart';
import '../core/profile_icons.dart';
import '../game/ink_sling_game.dart';
import '../services/p2p_multiplayer_service.dart';

/// Schermata di Fine Partita (Vittoria o Sconfitta) dal design accattivante,
/// con 5 settori grafici di avanzamento, Mini-Mappa, statistiche dettagliate,
/// classifica contestuale e passaggio diretto al Livello successivo (senza voti S+/A/B).
class GameOverOverlay extends StatelessWidget {
  final InkSlingGame game;
  const GameOverOverlay({super.key, required this.game});

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
          final lang = game.languageNotifier.value;

          final isLevelMode = game.activeMode == GameMode.levelProgression;
          final isInfiniteMode = game.activeMode == GameMode.infiniteTower;
          final rawMeters = DailySeedEngine.roundMeters(
            game.maxMetersReached,
            maxGoal: isInfiniteMode ? null : game.currentGoalMeters,
          );
          final targetMeters = isInfiniteMode
              ? DailySeedEngine.getInfiniteNextObstacleMeters(rawMeters)
                  .toDouble()
              : game.currentGoalMeters;
          final meters = rawMeters;
          final formattedMeters = DailySeedEngine.formatMeters(
            meters,
            maxGoal: isInfiniteMode ? null : targetMeters,
          );
          final progressRatio = (meters / targetMeters).clamp(0.0, 1.0);
          final progressPct = (progressRatio * 100).round();

          final topPct = DailySeedEngine.estimateTopPercentile(
            meters,
            game.isVictory,
            targetMeters: targetMeters,
          );

          final userAvatarEmoji = ProfileIconsCatalog.getById(
            game.storage.selectedProfileIconId,
          ).emoji;
          final leaderboard = isLevelMode
              ? DailySeedEngine.getGlobalLeaderboard(
                  playerName: game.storage.playerName,
                  playerLevel: game.storage.currentTowerLevel,
                  playerBestMeters: game.storage.bestMetersCurrentLevel,
                  playerBounces: game.storage.bestBouncesCurrentLevel,
                  totalLevelsPlayed: game.storage.totalLevelsPlayed,
                  playerAvatarEmoji: userAvatarEmoji,
                )
              : (isInfiniteMode
                  ? DailySeedEngine.getInfiniteLeaderboard(
                      playerName: game.storage.playerName,
                      playerInfiniteBestMeters: game.storage.infiniteBestMeters,
                      playerInfiniteBounces: game.storage.infiniteBestBounces,
                      playerAvatarEmoji: userAvatarEmoji,
                    )
                  : DailySeedEngine.getDailyLeaderboard(
                      playerName: game.storage.playerName,
                      playerBestMetersToday: game.storage.bestMetersToday,
                      completedToday: game.storage.completedToday,
                      playerBouncesToday: game.storage.bestBouncesToday,
                      playerAvatarEmoji: userAvatarEmoji,
                    ));
          final userRank =
              leaderboard.firstWhere((e) => e.isCurrentUser).rank;

          // Il testo di sfida viene usato SOLO nel pulsante CONDIVIDI
          final receiptText = DailySeedEngine.buildShareReceipt(
            meters: meters,
            targetMeters: targetMeters,
            isVictory: game.isVictory,
            bounces: game.totalBounces,
            seconds: game.runTimeSeconds,
            attemptNumber: game.currentAttemptNumber,
            mode: game.activeMode,
            level: game.currentLevel,
            lang: lang,
          );

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 390),
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
                        // Intestazione con Titolo Vittoria/Sconfitta (senza medaglia S+/A/B)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: game.lastRunWasNewDailyRecord
                                    ? p.ochreSeal
                                    : (isInfiniteMode
                                        ? p.ochreSeal.withAlpha(42)
                                        : p.paperBg),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: p.inkPrimary,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isInfiniteMode &&
                                      !game.lastRunWasNewDailyRecord) ...[
                                    Icon(
                                      Icons.all_inclusive_rounded,
                                      size: 12,
                                      color: p.inkPrimary,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    game.lastRunWasNewDailyRecord
                                        ? (game.leveledUpInLastRun
                                            ? s.newLevelUnlockedBadge
                                            : s.newPersonalRecordBadge)
                                        : (isLevelMode
                                            ? '${s.levelShort} ${game.currentLevel} • TOP $topPct%'
                                            : (isInfiniteMode
                                                ? '${s.hudInfiniteBadge} • TIER ${DailySeedEngine.getInfiniteObstacleTier(meters)}'
                                                : '${s.hudDailyBadge} • TOP $topPct%')),
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      color: game.lastRunWasNewDailyRecord
                                          ? p.onOchreSeal
                                          : p.inkPrimary,
                                      letterSpacing: 0.7,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                game.isVictory
                                    ? (isLevelMode
                                        ? s.levelWonTitle(game.currentLevel)
                                        : s.dailyTowerCompletedTitle)
                                    : s.fellAtTitle(formattedMeters),
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w900,
                                  color: game.isVictory
                                      ? p.matchaSafe
                                      : p.vermilionHazard,
                                  height: 1.05,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        if (game.isP2PMatch) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: game.isVictory
                                  ? p.matchaSafe.withAlpha(36)
                                  : p.vermilionHazard.withAlpha(32),
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                color: game.isVictory
                                    ? p.matchaSafe
                                    : p.vermilionHazard,
                                width: 2.2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  game.isVictory
                                      ? s.p2pVictoryTitle(
                                          game.p2pService.opponent.name,
                                        )
                                      : s.p2pDefeatTitle(
                                          game.p2pService.opponent.name,
                                        ),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    color: game.isVictory
                                        ? p.matchaSafe
                                        : p.vermilionHazard,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMiniStatBox(
                                        label: game.storage.playerName,
                                        value: '${formattedMeters}m',
                                        p: p,
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        'VS',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildMiniStatBox(
                                        label:
                                            '👻 ${game.p2pService.opponent.name}',
                                        value:
                                            '${game.p2pService.opponent.maxMeters.toStringAsFixed(1)}m',
                                        p: p,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: p.playerFill,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: p.inkPrimary,
                                          width: 1.2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      s.p2pYourTrailLabel,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: p.inkPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: p.vermilionHazard,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: p.inkPrimary,
                                          width: 1.2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        s.p2pRivalTrailLabel(
                                          game.p2pService.opponent.name,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: p.vermilionHazard,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                        // Banner motivazionale contestuale (senza "mancano tot metri alla vetta" in modalità infinita!)
                        if (!game.isP2PMatch) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: game.isVictory
                                  ? p.matchaSafe.withAlpha((0.15 * 255).round())
                                  : p.ochreSeal.withAlpha((0.16 * 255).round()),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color:
                                    game.isVictory ? p.matchaSafe : p.ochreSeal,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              s.motivatingSubtitle(
                                meters: meters,
                                targetMeters: targetMeters,
                                isVictory: game.isVictory,
                                isLevelMode: isLevelMode,
                                nextLevel: game.currentLevel + 1,
                                isInfiniteMode: isInfiniteMode,
                                isNewRecord: game.lastRunWasNewDailyRecord,
                                bestInfiniteMeters:
                                    game.storage.infiniteBestMeters,
                              ),
                              style: TextStyle(
                                color: p.inkPrimary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Scheda Grafica Risultato:
                        // - In Torre Infinita Singolo: riepilogo dedicato senza grafico della vetta
                        // - In Livelli / Giornaliero / P2P: Mini-Mappa (a 2 colori in P2P) + Settori + Statistiche
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: p.paperBg,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: p.inkPrimary, width: 1.8),
                          ),
                          child: (isInfiniteMode && !game.isP2PMatch)
                              ? Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      s.infiniteSummaryHeader,
                                      style: TextStyle(
                                        color: p.inkSecondary,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildMiniStatBox(
                                            label: s.infiniteReachedHeightLabel,
                                            value: '${formattedMeters}m',
                                            p: p,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildMiniStatBox(
                                            label: s.infiniteRecordLabel,
                                            value:
                                                '${DailySeedEngine.formatMeters(game.storage.infiniteBestMeters)}m',
                                            p: p,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: p.ochreSeal.withAlpha(32),
                                        borderRadius: BorderRadius.circular(7),
                                        border: Border.all(
                                          color: p.inkPrimary,
                                          width: 1.3,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.layers_rounded,
                                            size: 15,
                                            color: p.inkPrimary,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              DailySeedEngine.isInfiniteMaxTier(
                                                meters,
                                              )
                                                  ? s.infiniteObstacleTierMaxInfo(
                                                      DailySeedEngine
                                                          .getInfiniteObstacleTier(
                                                        meters,
                                                      ),
                                                    )
                                                  : s.infiniteObstacleTierInfo(
                                                      DailySeedEngine
                                                          .getInfiniteObstacleTier(
                                                        meters,
                                                      ),
                                                      DailySeedEngine
                                                          .getInfiniteNextObstacleMeters(
                                                        meters,
                                                      ),
                                                    ),
                                              style: TextStyle(
                                                color: p.inkPrimary,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildMiniStatBox(
                                            label: s.timeLabel,
                                            value:
                                                '${game.runTimeSeconds.toStringAsFixed(1)}s',
                                            p: p,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: _buildMiniStatBox(
                                            label: s.bouncesLabel,
                                            value: '${game.totalBounces}',
                                            p: p,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: _buildMiniStatBox(
                                            label: s.rankLabel,
                                            value: '#$userRank',
                                            p: p,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: p.paperCard,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: p.paperGrid,
                                          width: 1.3,
                                        ),
                                      ),
                                      child: Text(
                                        s.globalRankSummary(
                                          userRank,
                                          isLevelMode,
                                          game.storage.currentTowerLevel,
                                          isInfiniteMode: true,
                                          bestInfiniteMeters:
                                              DailySeedEngine.formatMeters(
                                            game.storage.infiniteBestMeters,
                                          ),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: p.inkPrimary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    // Mini-mappa del tracciato
                                    RepaintBoundary(
                                      child: Container(
                                        width: 66,
                                        height: 136,
                                        decoration: BoxDecoration(
                                          color: p.paperCard,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: p.inkPrimary,
                                            width: 1.6,
                                          ),
                                        ),
                                        child: CustomPaint(
                                          painter: RisographFlightMapPainter(
                                            flightPath: game.flightPath,
                                            opponentFlightPath: game.isP2PMatch
                                                ? game.opponentFlightPath
                                                : const <Vector2>[],
                                            isVictory: game.isVictory,
                                            targetMeters: isInfiniteMode
                                                ? (meters >
                                                        game.p2pService.opponent
                                                            .maxMeters
                                                    ? (meters > 100.0
                                                        ? meters
                                                        : 100.0)
                                                    : (game.p2pService.opponent
                                                                .maxMeters >
                                                            100.0
                                                        ? game.p2pService
                                                            .opponent.maxMeters
                                                        : 100.0))
                                                : targetMeters,
                                            palette: p,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Dettagli visuali della scalata
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Flexible(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    s.towerProgressLabel,
                                                    style: TextStyle(
                                                      color: p.inkSecondary,
                                                      fontSize: 9.5,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      letterSpacing: 0.8,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$progressPct% ($formattedMeters/${targetMeters.toInt()}m)',
                                                style: TextStyle(
                                                  color: p.inkPrimary,
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),

                                          // 5 blocchi grafici dei settori della torre
                                          Row(
                                            children:
                                                List.generate(5, (index) {
                                              final sectorNum = index + 1;
                                              final sectorSize =
                                                  targetMeters / 5.0;
                                              final top =
                                                  sectorNum * sectorSize;
                                              final isCompleted = meters >= top;
                                              final isCurrent = !isCompleted &&
                                                  meters >= (top - sectorSize);

                                              Color boxColor = p.paperCard;
                                              if (isCompleted) {
                                                boxColor = p.matchaSafe;
                                              } else if (isCurrent) {
                                                boxColor = game.isVictory
                                                    ? p.matchaSafe
                                                    : p.vermilionHazard;
                                              }

                                              return Expanded(
                                                child: Container(
                                                  height: 16,
                                                  margin: EdgeInsets.only(
                                                    right: index < 4 ? 4 : 0,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: boxColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      4,
                                                    ),
                                                    border: Border.all(
                                                      color: p.inkPrimary,
                                                      width: 1.4,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                          ),
                                          const SizedBox(height: 10),

                                          // Griglia Statistiche (Tempo, Sponde, Posizione Classifica)
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildMiniStatBox(
                                                  label: s.timeLabel,
                                                  value:
                                                      '${game.runTimeSeconds.toStringAsFixed(1)}s',
                                                  p: p,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: _buildMiniStatBox(
                                                  label: s.bouncesLabel,
                                                  value: '${game.totalBounces}',
                                                  p: p,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: _buildMiniStatBox(
                                                  label: s.rankLabel,
                                                  value: '#$userRank',
                                                  p: p,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),

                                          // Badge Riepilogo Posizione Contestuale (Livelli o Torre di Oggi)
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: p.paperCard,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: p.paperGrid,
                                                width: 1.3,
                                              ),
                                            ),
                                            child: Text(
                                              s.globalRankSummary(
                                                userRank,
                                                isLevelMode,
                                                game.storage.currentTowerLevel,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: p.inkPrimary,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 14),

                        // REWARDED AD REVIVE: Riparti dal metro esatto dell'impatto su una piattaforma verde con Scudo!

                        if (!game.isP2PMatch &&
                            !game.isVictory &&
                            !game.reviveUsed &&
                            meters >= 5.0 &&
                            game.monetization.isAdReady)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: p.ochreSeal,
                                foregroundColor: p.onOchreSeal,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                  horizontal: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: p.inkPrimary,
                                    width: 2.0,
                                  ),
                                ),
                              ),
                              onPressed: () async {
                                game.audioHaptics.onButtonTap();
                                final granted =
                                    await game.monetization.showRewardedAd(
                                  context: context,
                                  rewardTitle: s.reviveWithShieldBtn(
                                    formattedMeters,
                                  ),
                                  isProUnlocked: game.storage.proUnlocked,
                                );
                                if (granted) {
                                  game.reviveWithShield();
                                }
                              },
                              icon: const Icon(Icons.shield_outlined, size: 18),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  s.reviveWithShieldBtn(formattedMeters),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Pulsanti Azione:
                        // - In P2P Reale: Rivincita a votazione (1/2 propone -> 2/2 accetta) + "TORNA AL MENU"
                        // - In Allenamento Bot: Rivincita immediata contro il Bot + "TORNA AL MENU"
                        // - In Singolo: "Condividi" + "Riprova / Livello Successivo" + "Torna al Menu"
                        if (game.isP2PMatch) ...[
                          if (game.isBotTrainingMatch)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: p.vermilionHazard,
                                foregroundColor: p.onVermilionHazard,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: p.inkPrimary,
                                    width: 2.2,
                                  ),
                                ),
                              ),
                              onPressed: () {
                                game.audioHaptics.onButtonTap();
                                game.proposeP2PRematch();
                              },
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  s.rematchFriendBtn,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            )
                          else
                            ValueListenableBuilder<P2PRematchVoteStatus>(
                              valueListenable:
                                  game.p2pService.rematchStatusNotifier,
                              builder: (context, voteStatus, _) {
                                final oppName = game.p2pService.opponent.name;
                                switch (voteStatus) {
                                  case P2PRematchVoteStatus.idle:
                                    return ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: p.vermilionHazard,
                                        foregroundColor: p.onVermilionHazard,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                          horizontal: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          side: BorderSide(
                                            color: p.inkPrimary,
                                            width: 2.2,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        game.audioHaptics.onButtonTap();
                                        game.proposeP2PRematch();
                                      },
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          s.proposeRematchBtn,
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    );
                                  case P2PRematchVoteStatus.waitingPeerAccept:
                                  case P2PRematchVoteStatus.acceptedLaunching:
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: p.ochreSeal.withAlpha(45),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: p.inkPrimary,
                                          width: 1.8,
                                        ),
                                      ),
                                      child: Text(
                                        s.rematchWaitingVoteLabel(oppName),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w900,
                                          color: p.inkPrimary,
                                        ),
                                      ),
                                    );
                                  case P2PRematchVoteStatus.incomingPeerRequest:
                                    return Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: p.paperBg,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: p.vermilionHazard,
                                          width: 2.2,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            s.rematchIncomingVoteTitle(oppName),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w900,
                                              color: p.vermilionHazard,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                flex: 3,
                                                child: ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        p.matchaSafe,
                                                    foregroundColor:
                                                        p.onMatchaSafe,
                                                    elevation: 0,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      vertical: 10,
                                                      horizontal: 8,
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        8,
                                                      ),
                                                      side: BorderSide(
                                                        color: p.inkPrimary,
                                                        width: 1.8,
                                                      ),
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    game.audioHaptics
                                                        .onButtonTap();
                                                    game.acceptP2PRematch();
                                                  },
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Text(
                                                      s.acceptRematchVoteBtn,
                                                      style: const TextStyle(
                                                        fontFamily: 'monospace',
                                                        fontSize: 11.5,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                flex: 2,
                                                child: OutlinedButton(
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                    foregroundColor:
                                                        p.inkPrimary,
                                                    side: BorderSide(
                                                      color: p.inkPrimary,
                                                      width: 1.8,
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      vertical: 10,
                                                      horizontal: 8,
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        8,
                                                      ),
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    game.audioHaptics
                                                        .onButtonTap();
                                                    game.declineP2PRematch();
                                                  },
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Text(
                                                      s.declineRematchVoteBtn,
                                                      style: const TextStyle(
                                                        fontFamily: 'monospace',
                                                        fontSize: 11.5,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  case P2PRematchVoteStatus.peerDeclined:
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: p.paperBg,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: p.vermilionHazard,
                                          width: 1.6,
                                        ),
                                      ),
                                      child: Text(
                                        s.rematchDeclinedLabel(oppName),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: p.vermilionHazard,
                                        ),
                                      ),
                                    );
                                  case P2PRematchVoteStatus.peerLeft:
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: p.paperBg,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: p.inkSecondary,
                                          width: 1.6,
                                        ),
                                      ),
                                      child: Text(
                                        s.rematchOpponentLeftLabel(oppName),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: p.inkSecondary,
                                        ),
                                      ),
                                    );
                                }
                              },
                            ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: p.inkPrimary,
                              side: BorderSide(
                                color: p.inkPrimary,
                                width: 1.8,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 11,
                                horizontal: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              game.audioHaptics.onButtonTap();
                              game.returnToMainMenu();
                            },
                            child: Text(
                              s.backToMenuBtn,
                              style: TextStyle(
                                color: p.inkPrimary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: p.inkPrimary,
                                    side: BorderSide(
                                      color: p.inkPrimary,
                                      width: 2.0,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                      horizontal: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () async {
                                    game.audioHaptics.onButtonTap();
                                    await Clipboard.setData(
                                      ClipboardData(text: receiptText),
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          backgroundColor: p.inkPrimary,
                                          content: Text(
                                            s.shareCopiedSnack,
                                            style:
                                                TextStyle(color: p.paperCard),
                                          ),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                    try {
                                      await SharePlus.instance.share(
                                        ShareParams(text: receiptText),
                                      );
                                    } catch (_) {}
                                  },
                                  icon: const Icon(
                                    Icons.ios_share_rounded,
                                    size: 16,
                                  ),
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      s.shareBtn,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: game.isVictory
                                        ? p.matchaSafe
                                        : p.playerFill,
                                    foregroundColor: game.isVictory
                                        ? p.onMatchaSafe
                                        : p.onPlayerFill,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                      horizontal: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(
                                        color: p.inkPrimary,
                                        width: 2.0,
                                      ),
                                    ),
                                  ),
                                  onPressed: () {
                                    game.audioHaptics.onButtonTap();
                                    if (game.isVictory && isLevelMode) {
                                      game.startRun(
                                        mode: GameMode.levelProgression,
                                        level: game.currentLevel + 1,
                                      );
                                    } else {
                                      game.startRun(
                                        mode: game.activeMode,
                                        level: game.currentLevel,
                                      );
                                    }
                                  },
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      game.isVictory && isLevelMode
                                          ? s.nextLevelBtn(
                                              game.currentLevel + 1,
                                            )
                                          : (game.isVictory &&
                                                  !isLevelMode &&
                                                  game.storage
                                                          .officialAttemptsLeft >
                                                      0
                                              ? s.improveDailyRecordBtn(
                                                  game.storage
                                                      .officialAttemptsLeft,
                                                )
                                              : s.retryNowBtn),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: () {
                              game.audioHaptics.onButtonTap();
                              game.returnToMainMenu();
                            },
                            child: Text(
                              s.backToMenuBtn,
                              style: TextStyle(
                                color: p.inkSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniStatBox({
    required String label,
    required String value,
    required RisographPalette p,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: p.paperCard,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: p.paperGrid, width: 1.4),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: p.inkSecondary,
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: p.inkPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Disegna la mini-mappa della traiettoria percorsa fino al traguardo del livello
/// (in modalità P2P disegna anche il tracciato dell'avversario in ROSSO RISOGRAPH `palette.vermilionHazard`).
class RisographFlightMapPainter extends CustomPainter {
  final List<Vector2> flightPath;
  final List<Vector2> opponentFlightPath;
  final bool isVictory;
  final double targetMeters;
  final RisographPalette palette;

  RisographFlightMapPainter({
    required this.flightPath,
    this.opponentFlightPath = const <Vector2>[],
    required this.isVictory,
    required this.targetMeters,
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

    final maxPixels = targetMeters * DailySeedEngine.metersToPixels;

    // 1. Tracciato dell'avversario P2P disegnato in ROSSO RISOGRAPH (vermilionHazard)
    if (opponentFlightPath.isNotEmpty) {
      final oppPath = Path();
      for (int i = 0; i < opponentFlightPath.length; i++) {
        final pt = opponentFlightPath[i];
        final normX = ((pt.x + DailySeedEngine.worldWidth / 2) /
                DailySeedEngine.worldWidth)
            .clamp(0.08, 0.92);
        final normY = (1.0 - (-pt.y / maxPixels)).clamp(0.06, 0.94);

        final x = normX * size.width;
        final y = normY * size.height;
        if (i == 0) {
          oppPath.moveTo(x, y);
        } else {
          oppPath.lineTo(x, y);
        }
      }

      canvas.drawPath(
        oppPath,
        Paint()
          ..color = palette.vermilionHazard
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );

      final oppLast = opponentFlightPath.last;
      final oppEndX = ((oppLast.x + DailySeedEngine.worldWidth / 2) /
              DailySeedEngine.worldWidth)
          .clamp(0.08, 0.92) *
          size.width;
      final oppEndY =
          (1.0 - (-oppLast.y / maxPixels)).clamp(0.06, 0.94) * size.height;

      canvas.drawCircle(
        Offset(oppEndX, oppEndY),
        4.2,
        Paint()..color = palette.vermilionHazard,
      );
      canvas.drawCircle(
        Offset(oppEndX, oppEndY),
        4.2,
        Paint()
          ..color = palette.inkPrimary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3,
      );
    }

    if (flightPath.isEmpty) return;

    // 2. Tracciato del giocatore locale
    final path = Path();
    for (int i = 0; i < flightPath.length; i++) {
      final pt = flightPath[i];
      final normX = ((pt.x + DailySeedEngine.worldWidth / 2) /
              DailySeedEngine.worldWidth)
          .clamp(0.08, 0.92);
      final normY = (1.0 - (-pt.y / maxPixels)).clamp(0.06, 0.94);

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
    final endY = (1.0 - (-last.y / maxPixels)).clamp(0.06, 0.94) * size.height;

    canvas.drawCircle(
      Offset(endX, endY),
      4.5,
      Paint()
        ..color = isVictory ? palette.matchaSafe : palette.playerFill,
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
  bool shouldRepaint(covariant RisographFlightMapPainter oldDelegate) {
    return oldDelegate.flightPath.length != flightPath.length ||
        oldDelegate.opponentFlightPath.length != opponentFlightPath.length ||
        oldDelegate.isVictory != isVictory ||
        oldDelegate.palette != palette ||
        oldDelegate.targetMeters != targetMeters;
  }
}

import 'package:flutter/material.dart';
import '../core/app_strings.dart';
import '../core/ball_skins.dart';
import '../core/daily_seed.dart';
import '../core/palette_theme.dart';
import '../core/profile_icons.dart';
import '../game/ink_sling_game.dart';
import 'ball_skins_overlay.dart';
import 'profile_overlay.dart';

/// Menu Principale di INK TOWER: Climb & Stick, con:
/// - Sottofondo animato di una palla che scala la torre in pietra Risograph
/// - Selettore tra Progressione Livelli Infiniti (+10m ogni 10 liv.) e Torre di Oggi
/// - Classifica contestuale (Classifica Livelli oppure Classifica Torre di Oggi)
/// - Supporto Multilingua (auto-rilevato + selettore 6 lingue) e controllo Audio ON/OFF
class MainMenuOverlay extends StatefulWidget {
  final InkSlingGame game;
  const MainMenuOverlay({super.key, required this.game});

  @override
  State<MainMenuOverlay> createState() => _MainMenuOverlayState();
}

class _MainMenuOverlayState extends State<MainMenuOverlay> {
  late GameMode _selectedMode;
  late int _selectedLevel;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.game.activeMode;
    _selectedLevel = widget.game.storage.currentTowerLevel;
  }

  void _openLanguageDialog(BuildContext context, RisographPalette p) {
    showDialog(
      context: context,
      builder: (ctx) {
        final currentLang = widget.game.languageNotifier.value;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Container(
              padding: const EdgeInsets.all(18),
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
                  Row(
                    children: [
                      Icon(Icons.language_rounded, color: p.matchaSafe, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'LANGUAGE / LINGUA',
                          style: TextStyle(
                            color: p.inkPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: Icon(Icons.close_rounded, color: p.inkPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...AppLanguage.values.map((lang) {
                    final isSelected = lang == currentLang;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          widget.game.setLanguage(lang);
                          Navigator.of(ctx).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? p.matchaSafe.withAlpha((0.18 * 255).round())
                                : p.paperBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? p.matchaSafe : p.paperGrid,
                              width: isSelected ? 2.2 : 1.4,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected ? p.matchaSafe : p.inkPrimary,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  lang.shortLabel,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : p.paperCard,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  lang.displayName,
                                  style: TextStyle(
                                    color: p.inkPrimary,
                                    fontSize: 13.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w900
                                        : FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: p.matchaSafe,
                                  size: 18,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openLeaderboardDialog(BuildContext context, RisographPalette p) {
    final storage = widget.game.storage;
    final s = widget.game.strings;
    final isDaily = _selectedMode == GameMode.dailyTower;
    final nameController = TextEditingController(text: storage.playerName);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final userAvatarEmoji = ProfileIconsCatalog.getById(
              storage.selectedProfileIconId,
            ).emoji;
            final entries = isDaily
                ? DailySeedEngine.getDailyLeaderboard(
                    playerName: storage.playerName,
                    playerBestMetersToday: storage.bestMetersToday,
                    completedToday: storage.completedToday,
                    playerBouncesToday: storage.bestBouncesToday,
                    playerAvatarEmoji: userAvatarEmoji,
                  )
                : DailySeedEngine.getGlobalLeaderboard(
                    playerName: storage.playerName,
                    playerLevel: storage.currentTowerLevel,
                    playerBestMeters: storage.bestMetersCurrentLevel,
                    playerBounces: storage.bestBouncesCurrentLevel,
                    totalLevelsPlayed: storage.totalLevelsPlayed,
                    playerAvatarEmoji: userAvatarEmoji,
                  );

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390, maxHeight: 560),
                child: Container(
                  padding: const EdgeInsets.all(18),
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
                      Row(
                        children: [
                          Icon(
                            Icons.leaderboard_rounded,
                            color: p.ochreSeal,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                isDaily
                                    ? s.leaderboardDailyTitle()
                                    : s.leaderboardLevelsTitle,
                                style: TextStyle(
                                  color: p.inkPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.7,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: Icon(Icons.close_rounded, color: p.inkPrimary),
                          ),
                        ],
                      ),
                      Text(
                        isDaily ? s.leaderboardDailySub : s.leaderboardLevelsSub,
                        style: TextStyle(
                          color: p.inkSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Barra modifica rapida Nickname
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: p.paperBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: p.paperGrid, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 16,
                              color: p.inkSecondary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: TextField(
                                controller: nameController,
                                style: TextStyle(
                                  color: p.inkPrimary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: s.nicknameHint,
                                  hintStyle: TextStyle(
                                    color: p.inkSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                onSubmitted: (val) async {
                                  await storage.setPlayerName(val);
                                  setModalState(() {});
                                  if (mounted) setState(() {});
                                },
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                foregroundColor: p.matchaSafe,
                              ),
                              onPressed: () async {
                                await storage.setPlayerName(
                                  nameController.text,
                                );
                                setModalState(() {});
                                if (mounted) setState(() {});
                              },
                              child: Text(
                                s.saveBtn,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Lista Classifica (Livelli oppure Torre di Oggi)
                      Expanded(
                        child: ListView.separated(
                          itemCount: entries.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (_, idx) {
                            final item = entries[idx];
                            final isTop3 = item.rank <= 3;
                            final medal = item.rank == 1
                                ? '🥇'
                                : (item.rank == 2
                                    ? '🥈'
                                    : (item.rank == 3 ? '🥉' : '#${item.rank}'));

                            final scoreBadgeText = isDaily
                                ? (item.bestMeters > 0
                                    ? '${item.bestMeters.toStringAsFixed(1)}m • ${item.bounces} ${s.bouncesShort}'
                                    : '0.0m / 100m')
                                : '${s.levelShort} ${item.level} • ${item.progressPercent}% • ${item.bounces} ${s.bouncesShort}';

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: item.isCurrentUser
                                    ? p.matchaSafe.withAlpha((0.18 * 255).round())
                                    : p.paperBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: item.isCurrentUser
                                      ? p.matchaSafe
                                      : (isTop3 ? p.ochreSeal : p.paperGrid),
                                  width: item.isCurrentUser ? 2.2 : 1.4,
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 32,
                                    child: Text(
                                      medal,
                                      style: TextStyle(
                                        fontSize: isTop3 ? 15 : 12,
                                        fontWeight: FontWeight.w900,
                                        color: p.inkPrimary,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      item.isCurrentUser
                                          ? '${item.avatarEmoji} ${item.name} (${s.youTag})'
                                          : '${item.avatarEmoji} ${item.name}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: p.inkPrimary,
                                        fontSize: 13,
                                        fontWeight: item.isCurrentUser
                                            ? FontWeight.w900
                                            : FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: item.isCurrentUser
                                          ? p.matchaSafe
                                          : p.inkPrimary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      scoreBadgeText,
                                      style: TextStyle(
                                        color: item.isCurrentUser
                                            ? Colors.white
                                            : p.paperCard,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w900,
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
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.game.paletteNotifier,
        widget.game.languageNotifier,
        widget.game.soundNotifier,
      ]),
      builder: (context, _) {
        final p = widget.game.paletteNotifier.value;
        final s = widget.game.strings;
        final lang = widget.game.languageNotifier.value;
        final soundOn = widget.game.soundNotifier.value;
        final storage = widget.game.storage;
        final maxUnlockedLevel = storage.currentTowerLevel;
        if (_selectedLevel > maxUnlockedLevel) {
          _selectedLevel = maxUnlockedLevel;
        }

        final isDaily = _selectedMode == GameMode.dailyTower;
        final issue = DailySeedEngine.getIssueNumber();
        final dateStr = DailySeedEngine.getFormattedDate();

        final userAvatarEmoji = ProfileIconsCatalog.getById(
          storage.selectedProfileIconId,
        ).emoji;
        final equippedBallSkin = BallSkinsCatalog.getById(
          storage.selectedBallSkinId,
        );
        final levelsLeaderboard = DailySeedEngine.getGlobalLeaderboard(
          playerName: storage.playerName,
          playerLevel: storage.currentTowerLevel,
          playerBestMeters: storage.bestMetersCurrentLevel,
          playerBounces: storage.bestBouncesCurrentLevel,
          totalLevelsPlayed: storage.totalLevelsPlayed,
          playerAvatarEmoji: userAvatarEmoji,
        );
        final dailyLeaderboard = DailySeedEngine.getDailyLeaderboard(
          playerName: storage.playerName,
          playerBestMetersToday: storage.bestMetersToday,
          completedToday: storage.completedToday,
          playerBouncesToday: storage.bestBouncesToday,
          playerAvatarEmoji: userAvatarEmoji,
        );

        final userLevelsRank =
            levelsLeaderboard.firstWhere((e) => e.isCurrentUser).rank;
        final userDailyRank =
            dailyLeaderboard.firstWhere((e) => e.isCurrentUser).rank;
        final activeRank = isDaily ? userDailyRank : userLevelsRank;

        final levelGoal =
            DailySeedEngine.getLevelGoalMeters(_selectedLevel).toInt();

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 385),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: p.paperCard.withAlpha((0.94 * 255).round()),
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
                    // Riga superiore: Posizione Classifica + Lingua + Suono + Tema
                    Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: InkWell(
                              onTap: () => _openLeaderboardDialog(context, p),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: p.inkPrimary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    isDaily
                                        ? s.topRankBadgeDaily(userDailyRank, issue)
                                        : s.topRankBadgeLevels(
                                            userLevelsRank,
                                            storage.currentTowerLevel,
                                          ),
                                    style: TextStyle(
                                      color: p.paperCard,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.7,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Pulsante Lingua
                        InkWell(
                          onTap: () => _openLanguageDialog(context, p),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: p.paperBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: p.inkPrimary,
                                width: 1.6,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.language_rounded,
                                  size: 13,
                                  color: p.inkPrimary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  lang.shortLabel,
                                  style: TextStyle(
                                    color: p.inkPrimary,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        // Pulsante Suoni ON/OFF
                        InkWell(
                          onTap: () => widget.game.toggleSound(),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: soundOn
                                  ? p.matchaSafe.withAlpha((0.16 * 255).round())
                                  : p.paperBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: soundOn ? p.matchaSafe : p.inkPrimary,
                                width: 1.6,
                              ),
                            ),
                            child: Icon(
                              soundOn
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_off_rounded,
                              size: 15,
                              color: soundOn ? p.matchaSafe : p.inkSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        // Pulsante Tema Risograph
                        InkWell(
                          onTap: () => widget.game.cyclePalette(),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: p.paperBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: p.inkPrimary,
                                width: 1.6,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.palette_outlined,
                                  size: 13,
                                  color: p.inkPrimary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  s.paletteName(p.id),
                                  style: TextStyle(
                                    color: p.inkPrimary,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Titolo: INK TOWER: Climb & Stick
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
                                  'INK TOWER',
                                  style: TextStyle(
                                    color: p.inkPrimary,
                                    fontSize: 35,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.6,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  s.subtitleClimbStick,
                                  style: TextStyle(
                                    color: p.matchaSafe,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: p.matchaSafe,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: p.inkPrimary, width: 2),
                          ),
                          child: Text(
                            _selectedMode == GameMode.levelProgression
                                ? '${s.levelShort}\n$_selectedLevel'
                                : '100\n${s.metersUnit}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Card Profilo Giocatore (Avatar, Nome, Statistiche veloci)
                    GestureDetector(
                      onTap: () async {
                        await ProfileDialog.show(context, widget.game);
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: p.paperBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: p.inkPrimary, width: 1.8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: p.paperCard,
                                shape: BoxShape.circle,
                                border: Border.all(color: p.matchaSafe, width: 2),
                              ),
                              child: Center(
                                child: Icon(
                                  ProfileIconsCatalog.getById(
                                    storage.selectedProfileIconId,
                                  ).iconData,
                                  size: 20,
                                  color: p.inkPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            storage.playerName,
                                            style: TextStyle(
                                              color: p.inkPrimary,
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: p.inkPrimary,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          ProfileIconsCatalog
                                              .getPlayerHonorTitle(
                                            storage,
                                            s,
                                          ),
                                          style: TextStyle(
                                            color: p.paperCard,
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${storage.totalBouncesAllTime} ${s.totalBouncesStat.toLowerCase()} • ${s.streakDays(storage.currentStreak)}',
                                    style: TextStyle(
                                      color: p.inkSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: p.inkSecondary,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Card Selezione Skin Sfera
                    GestureDetector(
                      onTap: () async {
                        await BallSkinsDialog.show(context, widget.game);
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: p.paperBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: p.inkPrimary, width: 1.8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: p.paperCard,
                                shape: BoxShape.circle,
                                border: Border.all(color: p.ochreSeal, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  equippedBallSkin.emoji,
                                  style: const TextStyle(fontSize: 19),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            s.skinsTitle,
                                            style: TextStyle(
                                              color: p.inkPrimary,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: p.ochreSeal,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          equippedBallSkin.getName(s),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    equippedBallSkin.getDescription(s),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: p.inkSecondary,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.palette_outlined,
                              color: p.ochreSeal,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Selettore Modalità: SCALATA LIVELLI vs TORRE DI OGGI
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: p.paperBg,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: p.inkPrimary, width: 1.8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _selectedMode = GameMode.levelProgression;
                                _selectedLevel = storage.currentTowerLevel;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _selectedMode ==
                                          GameMode.levelProgression
                                      ? p.inkPrimary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Text(
                                      s.modeLevelsTab,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _selectedMode ==
                                                GameMode.levelProgression
                                            ? p.paperCard
                                            : p.inkSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _selectedMode = GameMode.dailyTower;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _selectedMode == GameMode.dailyTower
                                      ? p.inkPrimary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Text(
                                      s.modeDailyTab(issue),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color:
                                            _selectedMode == GameMode.dailyTower
                                                ? p.paperCard
                                                : p.inkSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Pannello Statistiche in base alla modalità scelta
                    if (_selectedMode == GameMode.levelProgression)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: p.paperBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: p.inkPrimary, width: 1.8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatColumn(
                                    label: s.maxLevelLabel,
                                    value:
                                        '${s.levelShort} ${storage.currentTowerLevel}',
                                    p: p,
                                  ),
                                ),
                                Container(
                                  width: 1.5,
                                  height: 28,
                                  color: p.paperGrid,
                                ),
                                Expanded(
                                  child: _buildStatColumn(
                                    label: s.goalHeightLabel,
                                    value: '${levelGoal}m',
                                    p: p,
                                  ),
                                ),
                                Container(
                                  width: 1.5,
                                  height: 28,
                                  color: p.paperGrid,
                                ),
                                Expanded(
                                  child: _buildStatColumn(
                                    label: s.rankLabel,
                                    value: '#$userLevelsRank',
                                    p: p,
                                  ),
                                ),
                              ],
                            ),
                            if (maxUnlockedLevel > 1) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: _selectedLevel > 1
                                        ? () => setState(() => _selectedLevel--)
                                        : null,
                                    icon: Icon(
                                      Icons.chevron_left_rounded,
                                      color: p.inkPrimary,
                                    ),
                                  ),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        s.selectLevelLabel(
                                          _selectedLevel,
                                          maxUnlockedLevel,
                                        ),
                                        style: TextStyle(
                                          color: p.inkSecondary,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed:
                                        _selectedLevel < maxUnlockedLevel
                                            ? () =>
                                                setState(() => _selectedLevel++)
                                            : null,
                                    icon: Icon(
                                      Icons.chevron_right_rounded,
                                      color: p.inkPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              const SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  s.heightGrowthHint,
                                  style: TextStyle(
                                    color: p.inkSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: p.paperBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: p.inkPrimary, width: 1.8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatColumn(
                                label: s.recordTodayLabel(dateStr),
                                value: storage.completedToday
                                    ? '100m 🏆 (${storage.bestBouncesToday}⚡)'
                                    : '${storage.bestMetersToday.toStringAsFixed(1)}m',
                                p: p,
                              ),
                            ),
                            Container(
                              width: 1.5,
                              height: 28,
                              color: p.paperGrid,
                            ),
                            Expanded(
                              child: _buildStatColumn(
                                label: s.streakLabel,
                                value: s.streakDays(storage.currentStreak),
                                p: p,
                              ),
                            ),
                            Container(
                              width: 1.5,
                              height: 28,
                              color: p.paperGrid,
                            ),
                            Expanded(
                              child: _buildStatColumn(
                                label: s.livesTodayLabel,
                                value:
                                    '${storage.officialAttemptsLeft}/${DailySeedEngine.maxOfficialAttemptsPerDay}',
                                p: p,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Regole chiare del gameplay
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        border: Border.all(color: p.paperGrid, width: 1.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRuleRow(
                            icon: '🟩',
                            text: s.rule1Sticky,
                            p: p,
                          ),
                          const SizedBox(height: 5),
                          _buildRuleRow(
                            icon: '🌊',
                            text: s.rule2Hazards,
                            p: p,
                          ),
                          const SizedBox(height: 5),
                          _buildRuleRow(
                            icon: '⚡',
                            text: s.rule3Charges,
                            p: p,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Pulsante Principale "GIOCA"
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: p.playerFill,
                        foregroundColor: p.paperCard,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: p.inkPrimary, width: 2.2),
                        ),
                      ),
                      onPressed: () => widget.game.startRun(
                        mode: _selectedMode,
                        level: _selectedLevel,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _selectedMode == GameMode.levelProgression
                              ? s.playLevelBtn(_selectedLevel, levelGoal)
                              : (storage.completedToday &&
                                      storage.officialAttemptsLeft > 0
                                  ? s.playDailyImproveBtn(
                                      storage.officialAttemptsLeft)
                                  : s.playDailyBtn(storage.officialAttemptsLeft)),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Pulsante Classifica Contestuale (Livelli oppure Torre di Oggi!)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: p.inkPrimary,
                        side: BorderSide(color: p.inkPrimary, width: 1.8),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _openLeaderboardDialog(context, p),
                      icon: Icon(
                        Icons.emoji_events_outlined,
                        size: 18,
                        color: p.ochreSeal,
                      ),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          isDaily
                              ? s.leaderboardDailyBtn(activeRank)
                              : s.leaderboardLevelsBtn(activeRank),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),

                    if (_selectedMode == GameMode.dailyTower &&
                        storage.officialAttemptsLeft == 0) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: p.vermilionHazard,
                          side: BorderSide(color: p.vermilionHazard, width: 1.8),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final ok =
                              await widget.game.monetization.showRewardedAd(
                            context: context,
                            rewardTitle: s.unlockExtraLifeRewardTitle,
                            isProUnlocked: storage.proUnlocked,
                          );
                          if (ok && mounted) {
                            await storage.grantExtraOfficialAttempt();
                            setState(() {});
                          }
                        },
                        icon: const Icon(Icons.play_circle_outline, size: 18),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            s.unlockExtraLifeBtn,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatColumn({
    required String label,
    required String value,
    required RisographPalette p,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: p.inkSecondary,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: p.inkPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleRow({
    required String icon,
    required String text,
    required RisographPalette p,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: p.inkPrimary,
              fontSize: 11.5,
              height: 1.32,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

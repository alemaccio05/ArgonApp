import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../core/app_strings.dart';
import '../core/ball_skins.dart';
import '../core/daily_seed.dart';
import '../core/palette_theme.dart';
import '../core/profile_icons.dart';
import '../game/ink_sling_game.dart';
import '../services/trusted_time_service.dart';
import 'ball_skins_overlay.dart';
import 'privacy_dialog.dart';
import 'profile_overlay.dart';

/// Menu Principale progettato secondo la nuova struttura:
/// 1. In cima: Titolo "INK TOWER" centrato e sottotitolo con effetto fluttuante continuo.
///    (Nessun tasto rapido di volume o tema nel menù principale: risiedono nelle Impostazioni).
/// 2. Al centro: Le 3 Modalità Disponibili:
///    - Livello Giornaliero (100m, 24h, anti-exploit orario)
///    - Livelli Progressivi (con selettore a Matrice 5×5 da 25 livelli per pagina + frecce infinite)
///    - Torre Infinita (scala più in alto possibile con +1 nuovo ostacolo ogni 50m!)
/// 3. Sotto alle modalità: Impostazioni e Profilo (più accesso rapido a Skin e Classifica).
/// 4. Animazione coreografata di "assemblaggio" a stadi (`_assembleController`) dopo il caricamento.
class MainMenuOverlay extends StatefulWidget {
  final InkSlingGame game;
  const MainMenuOverlay({super.key, required this.game});

  @override
  State<MainMenuOverlay> createState() => _MainMenuOverlayState();
}

class _MainMenuOverlayState extends State<MainMenuOverlay>
    with TickerProviderStateMixin {
  late GameMode _selectedMode;
  late int _selectedLevel;
  late final AnimationController _assembleController;
  late final AnimationController _floatController;
  late final Animation<double> _cardShellScale;
  late final Animation<double> _cardShellOpacity;
  Timer? _monotonicTicker;
  String _dailyCountdown = '';
  bool _verifyingClock = false;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.game.activeMode;
    _selectedLevel = widget.game.storage.currentTowerLevel;
    _dailyCountdown =
        TrustedTimeService.instance.getFormattedRemainingDailyTime();

    // Controller per l'animazione scaglionata di assemblaggio del menù davanti all'utente
    _assembleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );
    _cardShellScale = Tween<double>(begin: 0.91, end: 1.0).animate(
      CurvedAnimation(
        parent: _assembleController,
        curve: const Interval(0.0, 0.44, curve: Curves.easeOutBack),
      ),
    );
    _cardShellOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _assembleController,
        curve: const Interval(0.0, 0.30, curve: Curves.easeOutCubic),
      ),
    );

    // Controller per l'effetto fluttuante continuo del sottotitolo sotto INK TOWER
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    widget.game.menuEntryEpochNotifier.addListener(_triggerMenuAssemble);
    _assembleController.forward(from: 0.0);

    // Aggiorna il countdown giornaliero basato su clock monotonico hardware
    _monotonicTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      TrustedTimeService.instance.verifyRuntimeIntegrity();
      final nextCountdown =
          TrustedTimeService.instance.getFormattedRemainingDailyTime();
      if (nextCountdown != _dailyCountdown) {
        setState(() {
          _dailyCountdown = nextCountdown;
        });
      }
    });
  }

  void _triggerMenuAssemble() {
    if (!mounted) return;
    setState(() {
      _selectedLevel = widget.game.storage.currentTowerLevel;
    });
    _assembleController.forward(from: 0.0);
  }

  @override
  void dispose() {
    widget.game.menuEntryEpochNotifier.removeListener(_triggerMenuAssemble);
    _monotonicTicker?.cancel();
    _floatController.dispose();
    _assembleController.dispose();
    super.dispose();
  }

  /// Apre la finestra delle Impostazioni (Volume singolo unificato, Cambio Tema, Lingua, Privacy)
  void _openSettingsDialog(BuildContext context, RisographPalette p) {
    widget.game.audioHaptics.onButtonTap();
    showDialog(
      context: context,
      builder: (ctx) {
        return AnimatedBuilder(
          animation: Listenable.merge([
            widget.game.paletteNotifier,
            widget.game.languageNotifier,
            widget.game.masterAudioNotifier,
            widget.game.soundNotifier,
          ]),
          builder: (ctx, _) {
            final curP = widget.game.paletteNotifier.value;
            final s = widget.game.strings;
            final currentLang = widget.game.languageNotifier.value;
            final volumeOn = widget.game.soundNotifier.value;

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 20,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 365),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: curP.paperCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: curP.inkPrimary, width: 2.6),
                    boxShadow: [
                      BoxShadow(
                        color: curP.shadowColor,
                        offset: const Offset(5, 6),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Impostazioni
                        Row(
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              color: curP.matchaSafe,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s.settingsTitle,
                                style: TextStyle(
                                  color: curP.inkPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                widget.game.audioHaptics.onButtonTap();
                                Navigator.of(ctx).pop();
                              },
                              icon: Icon(
                                Icons.close_rounded,
                                color: curP.inkPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Controllo Volume Singolo (senza separazione tra SFX e musica ambientale)
                        Text(
                          s.audioSectionLabel,
                          style: TextStyle(
                            color: curP.inkSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _MenuPressableButton(
                          onTap: () {
                            widget.game.toggleVolume();
                          },
                          backgroundColor: volumeOn
                              ? curP.matchaSafe.withAlpha(38)
                              : curP.paperBg,
                          borderColor:
                              volumeOn ? curP.matchaSafe : curP.inkPrimary,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 14,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    volumeOn
                                        ? Icons.volume_up_rounded
                                        : Icons.volume_off_rounded,
                                    size: 20,
                                    color: volumeOn
                                        ? curP.matchaSafe
                                        : curP.inkSecondary,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    s.volumeAudioLabel,
                                    style: TextStyle(
                                      color: curP.inkPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: volumeOn
                                      ? curP.matchaSafe
                                      : curP.paperCard,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: curP.inkPrimary,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  volumeOn ? 'ON' : 'OFF',
                                  style: TextStyle(
                                    color: volumeOn
                                        ? curP.onMatchaSafe
                                        : curP.inkSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Selettore Tema Risograph (spostato nelle Impostazioni come richiesto)
                        Text(
                          s.themeSectionLabel,
                          style: TextStyle(
                            color: curP.inkSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: RisographPalette.all.map((palOpt) {
                            final selected = palOpt.id == curP.id;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: palOpt != RisographPalette.all.last
                                      ? 6
                                      : 0,
                                ),
                                child: _MenuPressableButton(
                                  onTap: () {
                                    widget.game.selectPaletteById(palOpt.id);
                                  },
                                  backgroundColor: selected
                                      ? curP.inkPrimary
                                      : curP.paperBg,
                                  borderColor: selected
                                      ? curP.matchaSafe
                                      : curP.inkPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 9,
                                    horizontal: 6,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          _MiniPaletteDot(
                                            color: palOpt.paperBg,
                                            border: palOpt.inkPrimary,
                                          ),
                                          const SizedBox(width: 3),
                                          _MiniPaletteDot(
                                            color: palOpt.matchaSafe,
                                            border: palOpt.inkPrimary,
                                          ),
                                          const SizedBox(width: 3),
                                          _MiniPaletteDot(
                                            color: palOpt.vermilionHazard,
                                            border: palOpt.inkPrimary,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          s.paletteName(palOpt.id),
                                          style: TextStyle(
                                            color: selected
                                                ? curP.paperCard
                                                : curP.inkPrimary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),

                        // Selettore Lingua compatto
                        Text(
                          'LANGUAGE / LINGUA',
                          style: TextStyle(
                            color: curP.inkSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: AppLanguage.values.map((lang) {
                            final isSelected = lang == currentLang;
                            return SizedBox(
                              width: 96,
                              child: _MenuPressableButton(
                                onTap: () {
                                  widget.game.setLanguage(lang);
                                },
                                backgroundColor: isSelected
                                    ? curP.matchaSafe.withAlpha(42)
                                    : curP.paperBg,
                                borderColor: isSelected
                                    ? curP.matchaSafe
                                    : curP.paperGrid,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 7,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      lang.shortLabel,
                                      style: TextStyle(
                                        color: isSelected
                                            ? curP.matchaSafe
                                            : curP.inkPrimary,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        lang.displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: curP.inkPrimary,
                                          fontSize: 10,
                                          fontWeight: isSelected
                                              ? FontWeight.w900
                                              : FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),

                        // Bottone Privacy & Sicurezza Dati
                        _MenuPressableButton(
                          onTap: () {
                            widget.game.audioHaptics.onButtonTap();
                            Navigator.of(ctx).pop();
                            PrivacyDialog.show(context, widget.game);
                          },
                          backgroundColor: curP.paperBg,
                          borderColor: curP.inkPrimary,
                          padding: const EdgeInsets.symmetric(
                            vertical: 9,
                            horizontal: 10,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 16,
                                color: curP.inkPrimary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Privacy & Sicurezza Dati',
                                style: TextStyle(
                                  color: curP.inkPrimary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
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
      },
    );
  }

  /// Apre la Matrice 5×5 dei Livelli (25 livelli per pagina con frecce per sfogliare all'infinito)
  Future<void> _openLevelMatrixDialog(BuildContext context) async {
    widget.game.audioHaptics.onButtonTap();
    final chosenLevel = await showDialog<int>(
      context: context,
      builder: (ctx) => _LevelMatrixDialog(
        game: widget.game,
        initialSelectedLevel: _selectedLevel,
      ),
    );
    if (chosenLevel != null && mounted) {
      setState(() {
        _selectedMode = GameMode.levelProgression;
        _selectedLevel = chosenLevel;
      });
      widget.game.startRun(
        mode: GameMode.levelProgression,
        level: chosenLevel,
      );
    }
  }

  void _openLeaderboardDialog(BuildContext context, RisographPalette p) {
    widget.game.audioHaptics.onButtonTap();
    showDialog(
      context: context,
      builder: (ctx) => _LeaderboardDialogContent(
        game: widget.game,
        palette: p,
        mode: _selectedMode,
        onProfileUpdated: () {
          if (mounted) setState(() {});
        },
      ),
    );
  }

  Future<void> _handleVerifyClock() async {
    if (_verifyingClock) return;
    widget.game.audioHaptics.onButtonTap();
    setState(() => _verifyingClock = true);
    await TrustedTimeService.instance.syncWithServer();
    TrustedTimeService.instance.verifyRuntimeIntegrity();
    if (mounted) {
      setState(() {
        _verifyingClock = false;
        _dailyCountdown =
            TrustedTimeService.instance.getFormattedRemainingDailyTime();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          widget.game.paletteNotifier,
          widget.game.languageNotifier,
          _assembleController,
        ]),
        builder: (context, _) {
          final p = widget.game.paletteNotifier.value;
          final s = widget.game.strings;
          final storage = widget.game.storage;
          final maxUnlockedLevel = storage.currentTowerLevel;
          if (_selectedLevel > maxUnlockedLevel) {
            _selectedLevel = maxUnlockedLevel;
          }
          if (_selectedLevel < 1) {
            _selectedLevel = 1;
          }

          final isDaily = _selectedMode == GameMode.dailyTower;
          final isInfinite = _selectedMode == GameMode.infiniteTower;
          final isTampered = storage.isDailyLockedByTamper;
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
          final infiniteLeaderboard = DailySeedEngine.getInfiniteLeaderboard(
            playerName: storage.playerName,
            playerInfiniteBestMeters: storage.infiniteBestMeters,
            playerInfiniteBounces: storage.infiniteBestBounces,
            playerAvatarEmoji: userAvatarEmoji,
          );

          final userLevelsRank =
              levelsLeaderboard.firstWhere((e) => e.isCurrentUser).rank;
          final userDailyRank =
              dailyLeaderboard.firstWhere((e) => e.isCurrentUser).rank;
          final userInfiniteRank =
              infiniteLeaderboard.firstWhere((e) => e.isCurrentUser).rank;
          final activeRank = isDaily
              ? userDailyRank
              : (isInfinite ? userInfiniteRank : userLevelsRank);

          final levelGoal =
              DailySeedEngine.getLevelGoalMeters(_selectedLevel).toInt();

          final shellOpacity = _cardShellOpacity.value.clamp(0.0, 1.0);
          final shellScale = _cardShellScale.value;

          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompactHeight = constraints.maxHeight < 700;
                final verticalPad = isCompactHeight ? 8.0 : 14.0;
                final cardPad = isCompactHeight ? 14.0 : 18.0;
                final sectionGap = isCompactHeight ? 10.0 : 13.0;

                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: verticalPad,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 396),
                      child: Opacity(
                        opacity: shellOpacity,
                        child: Transform.scale(
                          scale: shellScale,
                          child: Container(
                            padding: EdgeInsets.all(cardPad),
                            decoration: BoxDecoration(
                              color:
                                  p.paperCard.withAlpha((0.95 * 255).round()),
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: p.inkPrimary, width: 2.6),
                              boxShadow: [
                                BoxShadow(
                                  color: p.shadowColor,
                                  offset: Offset(
                                    5.0 * shellOpacity,
                                    6.0 * shellOpacity,
                                  ),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ========================================================
                                // STADIO 1: HEADER "INK TOWER" IN CIMA + SOTTOTITOLO FLUTTUANTE
                                // (Senza pulsanti volume/tema che ora sono nelle Impostazioni)
                                // ========================================================
                                _AssembleStage(
                                  controller: _assembleController,
                                  startInterval: 0.08,
                                  endInterval: 0.50,
                                  initialOffset: const Offset(0, -18),
                                  initialScale: 0.94,
                                  useSpringCurve: true,
                                  child: Column(
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'INK TOWER',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: p.inkPrimary,
                                            fontSize: 38,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 2.2,
                                            height: 1.0,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Sottotitolo con effetto fluttuante continuo
                                      AnimatedBuilder(
                                        animation: _floatController,
                                        builder: (context, child) {
                                          final phase = _floatController.value;
                                          final dy =
                                              sin(phase * pi) * -4.2; // fluttua su/giù
                                          final shadowDy =
                                              2.5 + sin(phase * pi) * 1.8;
                                          return Transform.translate(
                                            offset: Offset(0, dy),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 4.5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: p.matchaSafe,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: p.inkPrimary,
                                                  width: 1.8,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: p.shadowColor,
                                                    offset: Offset(2, shadowDy),
                                                    blurRadius: 0,
                                                  ),
                                                ],
                                              ),
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            s.subtitleClimbStick,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: p.onMatchaSafe,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.3,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: sectionGap),

                                // ========================================================
                                // STADIO 2: LE 3 MODALITÀ DISPONIBILI
                                // 1. Livello Giornaliero | 2. Livelli Progressivi | 3. Torre Infinita
                                // ========================================================
                                _AssembleStage(
                                  controller: _assembleController,
                                  startInterval: 0.22,
                                  endInterval: 0.66,
                                  initialOffset: const Offset(0, 18),
                                  initialScale: 0.96,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Card 1: LIVELLO GIORNALIERO
                                      _ModeSelectorCard(
                                        isSelected:
                                            _selectedMode == GameMode.dailyTower,
                                        icon: Icons.today_rounded,
                                        accentColor: p.vermilionHazard,
                                        title: s.modeDailyCardTitle,
                                        subtitle: s.modeDailyCardSub,
                                        trailingBadge: storage.completedToday
                                            ? '100m 🏆'
                                            : '${storage.officialAttemptsLeft}/${DailySeedEngine.maxOfficialAttemptsPerDay} ♥',
                                        palette: p,
                                        onTap: () {
                                          widget.game.audioHaptics
                                              .onButtonTap();
                                          setState(() {
                                            _selectedMode = GameMode.dailyTower;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 7),

                                      // Card 2: LIVELLI PROGRESSIVI (con accesso alla Matrice 5x5)
                                      _ModeSelectorCard(
                                        isSelected: _selectedMode ==
                                            GameMode.levelProgression,
                                        icon: Icons.grid_view_rounded,
                                        accentColor: p.matchaSafe,
                                        title: s.modeProgressiveCardTitle,
                                        subtitle: s.modeProgressiveCardSub,
                                        trailingBadge:
                                            '${s.levelShort} $_selectedLevel • ${levelGoal}m',
                                        palette: p,
                                        onTap: () {
                                          widget.game.audioHaptics
                                              .onButtonTap();
                                          setState(() {
                                            _selectedMode =
                                                GameMode.levelProgression;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 7),

                                      // Card 3: TORRE INFINITA (+1 nuovo ostacolo ogni 50m)
                                      _ModeSelectorCard(
                                        isSelected: _selectedMode ==
                                            GameMode.infiniteTower,
                                        icon: Icons.all_inclusive_rounded,
                                        accentColor: p.ochreSeal,
                                        title: s.modeInfiniteCardTitle,
                                        subtitle: s.modeInfiniteCardSub,
                                        trailingBadge:
                                            '${DailySeedEngine.formatMeters(storage.infiniteBestMeters)}m',
                                        palette: p,
                                        onTap: () {
                                          widget.game.audioHaptics
                                              .onButtonTap();
                                          setState(() {
                                            _selectedMode =
                                                GameMode.infiniteTower;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 9),

                                      // Pannello Contestuale ad ALTEZZA FISSA (94px) per tutte e 3 le modalità:
                                      // cliccare sulle modalità non cambia mai la forma del menù né sposta gli elementi!
                                      SizedBox(
                                        height: 94,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: (isDaily && isTampered)
                                                ? p.vermilionHazard
                                                    .withAlpha(22)
                                                : p.paperBg,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: (isDaily && isTampered)
                                                  ? p.vermilionHazard
                                                  : p.inkPrimary,
                                              width: 1.8,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              // RIGA 1: 3 Colonne Statistiche (identica altezza per tutte le modalità)
                                              Row(
                                                children: _selectedMode ==
                                                        GameMode
                                                            .levelProgression
                                                    ? [
                                                        Expanded(
                                                          child:
                                                              _buildStatColumn(
                                                            label:
                                                                s.maxLevelLabel,
                                                            value:
                                                                '${s.levelShort} ${storage.currentTowerLevel}',
                                                            p: p,
                                                          ),
                                                        ),
                                                        Container(
                                                          width: 1.5,
                                                          height: 24,
                                                          color: p.paperGrid,
                                                        ),
                                                        Expanded(
                                                          child:
                                                              _buildStatColumn(
                                                            label: s
                                                                .goalHeightLabel,
                                                            value:
                                                                '${levelGoal}m',
                                                            p: p,
                                                          ),
                                                        ),
                                                        Container(
                                                          width: 1.5,
                                                          height: 24,
                                                          color: p.paperGrid,
                                                        ),
                                                        Expanded(
                                                          child:
                                                              _buildStatColumn(
                                                            label: s.rankLabel,
                                                            value:
                                                                '#$userLevelsRank',
                                                            p: p,
                                                          ),
                                                        ),
                                                      ]
                                                    : (_selectedMode ==
                                                            GameMode
                                                                .infiniteTower
                                                        ? [
                                                            Expanded(
                                                              child:
                                                                  _buildStatColumn(
                                                                label: s
                                                                    .infiniteRecordLabel,
                                                                value:
                                                                    '${DailySeedEngine.formatMeters(storage.infiniteBestMeters)}m',
                                                                p: p,
                                                              ),
                                                            ),
                                                            Container(
                                                              width: 1.5,
                                                              height: 24,
                                                              color:
                                                                  p.paperGrid,
                                                            ),
                                                            Expanded(
                                                              child:
                                                                  _buildStatColumn(
                                                                label: s
                                                                    .nextObstacleLabel,
                                                                value: s
                                                                    .every50mValue,
                                                                p: p,
                                                              ),
                                                            ),
                                                            Container(
                                                              width: 1.5,
                                                              height: 24,
                                                              color:
                                                                  p.paperGrid,
                                                            ),
                                                            Expanded(
                                                              child:
                                                                  _buildStatColumn(
                                                                label:
                                                                    s.rankLabel,
                                                                value:
                                                                    '#$userInfiniteRank',
                                                                p: p,
                                                              ),
                                                            ),
                                                          ]
                                                        : [
                                                            Expanded(
                                                              child:
                                                                  _buildStatColumn(
                                                                label: s
                                                                    .recordTodayLabel(
                                                                  dateStr,
                                                                ),
                                                                value: storage
                                                                        .completedToday
                                                                    ? '100m 🏆'
                                                                    : '${DailySeedEngine.formatMeters(storage.bestMetersToday)}m',
                                                                p: p,
                                                              ),
                                                            ),
                                                            Container(
                                                              width: 1.5,
                                                              height: 24,
                                                              color:
                                                                  p.paperGrid,
                                                            ),
                                                            Expanded(
                                                              child:
                                                                  _buildStatColumn(
                                                                label: s
                                                                    .streakLabel,
                                                                value: s
                                                                    .streakDays(
                                                                  storage
                                                                      .currentStreak,
                                                                ),
                                                                p: p,
                                                              ),
                                                            ),
                                                            Container(
                                                              width: 1.5,
                                                              height: 24,
                                                              color:
                                                                  p.paperGrid,
                                                            ),
                                                            Expanded(
                                                              child:
                                                                  _buildStatColumn(
                                                                label: s
                                                                    .livesTodayLabel,
                                                                value:
                                                                    '${storage.officialAttemptsLeft}/${DailySeedEngine.maxOfficialAttemptsPerDay}',
                                                                p: p,
                                                              ),
                                                            ),
                                                          ]),
                                              ),

                                              // RIGA 2: Barra Azione / Stato di altezza fissa (32px) per tutte le modalità
                                              SizedBox(
                                                height: 32,
                                                child: _selectedMode ==
                                                        GameMode
                                                            .levelProgression
                                                    ? _MenuPressableButton(
                                                        onTap: () =>
                                                            _openLevelMatrixDialog(
                                                          context,
                                                        ),
                                                        backgroundColor:
                                                            p.paperCard,
                                                        borderColor:
                                                            p.matchaSafe,
                                                        borderWidth: 1.8,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 10,
                                                        ),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .apps_rounded,
                                                              size: 15,
                                                              color:
                                                                  p.matchaSafe,
                                                            ),
                                                            const SizedBox(
                                                              width: 6,
                                                            ),
                                                            Flexible(
                                                              child: FittedBox(
                                                                fit: BoxFit
                                                                    .scaleDown,
                                                                child: Text(
                                                                  s.levelMatrixOpenBtn(
                                                                    _selectedLevel,
                                                                    maxUnlockedLevel,
                                                                  ),
                                                                  style:
                                                                      TextStyle(
                                                                    color: p
                                                                        .inkPrimary,
                                                                    fontSize:
                                                                        10.5,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w900,
                                                                    letterSpacing:
                                                                        0.4,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Icon(
                                                              Icons
                                                                  .arrow_forward_rounded,
                                                              size: 14,
                                                              color:
                                                                  p.matchaSafe,
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                    : (_selectedMode ==
                                                            GameMode
                                                                .infiniteTower
                                                        ? _MenuPressableButton(
                                                            onTap: () =>
                                                                _openLeaderboardDialog(
                                                              context,
                                                              p,
                                                            ),
                                                            backgroundColor:
                                                                p.paperCard,
                                                            borderColor:
                                                                p.ochreSeal,
                                                            borderWidth: 1.8,
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                              horizontal: 10,
                                                            ),
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .layers_rounded,
                                                                  size: 15,
                                                                  color: p
                                                                      .ochreSeal,
                                                                ),
                                                                const SizedBox(
                                                                  width: 6,
                                                                ),
                                                                Flexible(
                                                                  child:
                                                                      FittedBox(
                                                                    fit: BoxFit
                                                                        .scaleDown,
                                                                    child: Text(
                                                                      s.leaderboardInfiniteOpenBtn(
                                                                        userInfiniteRank,
                                                                        DailySeedEngine
                                                                            .getInfiniteObstacleTier(
                                                                          storage
                                                                              .infiniteBestMeters,
                                                                        ),
                                                                      ),
                                                                      style:
                                                                          TextStyle(
                                                                        color: p
                                                                            .inkPrimary,
                                                                        fontSize:
                                                                            10.5,
                                                                        fontWeight:
                                                                            FontWeight.w900,
                                                                        letterSpacing:
                                                                            0.4,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          )
                                                        : (isTampered
                                                            ? _MenuPressableButton(
                                                                onTap:
                                                                    _handleVerifyClock,
                                                                backgroundColor:
                                                                    p.vermilionHazard,
                                                                borderColor:
                                                                    p.inkPrimary,
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                  horizontal:
                                                                      10,
                                                                ),
                                                                child: Center(
                                                                  child:
                                                                      FittedBox(
                                                                    fit: BoxFit
                                                                        .scaleDown,
                                                                    child: Text(
                                                                      _verifyingClock
                                                                          ? '...'
                                                                          : '${s.clockTamperTitle} • ${s.clockTamperRetryBtn}',
                                                                      style:
                                                                          TextStyle(
                                                                        color: p
                                                                            .onVermilionHazard,
                                                                        fontSize:
                                                                            10.5,
                                                                        fontWeight:
                                                                            FontWeight.w900,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              )
                                                            : (storage.officialAttemptsLeft ==
                                                                    0
                                                                ? _MenuPressableButton(
                                                                    onTap:
                                                                        () async {
                                                                      widget
                                                                          .game
                                                                          .audioHaptics
                                                                          .onButtonTap();
                                                                      final ok = await widget
                                                                          .game
                                                                          .monetization
                                                                          .showRewardedAd(
                                                                        context:
                                                                            context,
                                                                        rewardTitle:
                                                                            s.unlockExtraLifeRewardTitle,
                                                                        isProUnlocked:
                                                                            storage.proUnlocked,
                                                                      );
                                                                      if (ok &&
                                                                          mounted) {
                                                                        await storage
                                                                            .grantExtraOfficialAttempt();
                                                                        setState(
                                                                          () {},
                                                                        );
                                                                      }
                                                                    },
                                                                    backgroundColor:
                                                                        p.paperCard,
                                                                    borderColor:
                                                                        p.vermilionHazard,
                                                                    borderWidth:
                                                                        1.8,
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .symmetric(
                                                                      horizontal:
                                                                          10,
                                                                    ),
                                                                    child: Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Icon(
                                                                          Icons
                                                                              .play_circle_outline,
                                                                          size:
                                                                              15,
                                                                          color:
                                                                              p.vermilionHazard,
                                                                        ),
                                                                        const SizedBox(
                                                                          width:
                                                                              6,
                                                                        ),
                                                                        Flexible(
                                                                          child:
                                                                              FittedBox(
                                                                            fit:
                                                                                BoxFit.scaleDown,
                                                                            child:
                                                                                Text(
                                                                              s.unlockExtraLifeBtn,
                                                                              style: TextStyle(
                                                                                color: p.vermilionHazard,
                                                                                fontSize: 10.5,
                                                                                fontWeight: FontWeight.w900,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  )
                                                                : Container(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .symmetric(
                                                                      horizontal:
                                                                          10,
                                                                    ),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: p
                                                                          .paperCard,
                                                                      borderRadius:
                                                                          BorderRadius
                                                                              .circular(
                                                                        8,
                                                                      ),
                                                                      border: Border
                                                                          .all(
                                                                        color: p
                                                                            .paperGrid,
                                                                        width:
                                                                            1.4,
                                                                      ),
                                                                    ),
                                                                    child: Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Icon(
                                                                          Icons
                                                                              .timer_outlined,
                                                                          size:
                                                                              13,
                                                                          color:
                                                                              p.inkSecondary,
                                                                        ),
                                                                        const SizedBox(
                                                                          width:
                                                                              5,
                                                                        ),
                                                                        Flexible(
                                                                          child:
                                                                              FittedBox(
                                                                            fit:
                                                                                BoxFit.scaleDown,
                                                                            child:
                                                                                Text(
                                                                              s.nextDailyInLabel(
                                                                                _dailyCountdown,
                                                                              ),
                                                                              style: TextStyle(
                                                                                color: p.inkSecondary,
                                                                                fontSize: 10,
                                                                                fontWeight: FontWeight.w900,
                                                                                letterSpacing: 0.5,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  )))),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: sectionGap),

                                // ========================================================
                                // STADIO 3: BOTTONE PRIMARIO "GIOCA" CENTRATO (altezza fissa)
                                // ========================================================
                                _AssembleStage(
                                  controller: _assembleController,
                                  startInterval: 0.38,
                                  endInterval: 0.82,
                                  initialOffset: const Offset(0, 22),
                                  initialScale: 0.86,
                                  useSpringCurve: true,
                                  child: _MenuPressableButton(
                                    onTap: () {
                                      widget.game.audioHaptics.onButtonTap();
                                      if (isDaily && isTampered) {
                                        _handleVerifyClock();
                                        return;
                                      }
                                      widget.game.startRun(
                                        mode: _selectedMode,
                                        level: _selectedLevel,
                                      );
                                    },
                                    backgroundColor: (isDaily && isTampered)
                                        ? p.inkSecondary.withAlpha(110)
                                        : p.playerFill,
                                    borderColor: p.inkPrimary,
                                    borderWidth: 2.5,
                                    hasShadow: true,
                                    shadowColor: p.shadowColor,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 14,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          (isDaily && isTampered)
                                              ? Icons.lock_clock_rounded
                                              : Icons.play_arrow_rounded,
                                          color: p.onPlayerFill,
                                          size: 25,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              _selectedMode ==
                                                      GameMode.levelProgression
                                                  ? s.playLevelBtn(
                                                      _selectedLevel,
                                                      levelGoal,
                                                    )
                                                  : (_selectedMode ==
                                                          GameMode.infiniteTower
                                                      ? s.playInfiniteBtn(
                                                          DailySeedEngine
                                                              .formatMeters(
                                                            storage
                                                                .infiniteBestMeters,
                                                          ),
                                                        )
                                                      : (storage.completedToday &&
                                                              storage.officialAttemptsLeft >
                                                                  0
                                                          ? s.playDailyImproveBtn(
                                                              storage
                                                                  .officialAttemptsLeft,
                                                            )
                                                          : s.playDailyBtn(
                                                              storage
                                                                  .officialAttemptsLeft,
                                                            ))),
                                              style: TextStyle(
                                                color: p.onPlayerFill,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.9,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                SizedBox(height: sectionGap),

                                // ========================================================
                                // STADIO 4: SOTTO ALLE MODALITÀ -> IMPOSTAZIONI & PROFILO
                                // (+ barra compatta Skin Sfera & Classifica)
                                // ========================================================
                                _AssembleStage(
                                  controller: _assembleController,
                                  startInterval: 0.54,
                                  endInterval: 1.00,
                                  initialOffset: const Offset(0, 24),
                                  initialScale: 0.95,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          // Tasto IMPOSTAZIONI (contiene Volume singolo, Tema, Lingua, Privacy)
                                          Expanded(
                                            child: _MenuPressableButton(
                                              onTap: () => _openSettingsDialog(
                                                context,
                                                p,
                                              ),
                                              backgroundColor: p.paperBg,
                                              borderColor: p.inkPrimary,
                                              borderWidth: 2.0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 11,
                                                horizontal: 10,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.settings_rounded,
                                                    size: 19,
                                                    color: p.inkPrimary,
                                                  ),
                                                  const SizedBox(width: 7),
                                                  Flexible(
                                                    child: FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      child: Text(
                                                        s.settingsNavBtn
                                                            .toUpperCase(),
                                                        style: TextStyle(
                                                          color: p.inkPrimary,
                                                          fontSize: 11.5,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Tasto PROFILO
                                          Expanded(
                                            child: _MenuPressableButton(
                                              onTap: () async {
                                                widget.game.audioHaptics
                                                    .onButtonTap();
                                                await ProfileDialog.show(
                                                  context,
                                                  widget.game,
                                                );
                                                if (mounted) setState(() {});
                                              },
                                              backgroundColor: p.paperBg,
                                              borderColor: p.matchaSafe,
                                              borderWidth: 2.0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 11,
                                                horizontal: 10,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    ProfileIconsCatalog.getById(
                                                      storage
                                                          .selectedProfileIconId,
                                                    ).iconData,
                                                    size: 19,
                                                    color: p.matchaSafe,
                                                  ),
                                                  const SizedBox(width: 7),
                                                  Flexible(
                                                    child: FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      child: Text(
                                                        '${s.profileNavBtn.toUpperCase()} (${storage.playerName})',
                                                        style: TextStyle(
                                                          color: p.inkPrimary,
                                                          fontSize: 11.5,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          letterSpacing: 0.4,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Riga secondaria compatta: Classifica & Skin Sfera
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _SecondaryMenuTile(
                                              icon: Icons.emoji_events_rounded,
                                              iconColor: p.ochreSeal,
                                              badgeText: '#$activeRank',
                                              label: s.levelsNavBtn,
                                              palette: p,
                                              onTap: () =>
                                                  _openLeaderboardDialog(
                                                context,
                                                p,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _SecondaryMenuTile(
                                              emojiIcon: equippedBallSkin.emoji,
                                              iconColor: p.matchaSafe,
                                              badgeText:
                                                  '${BallSkinsCatalog.allSkins.where((sk) => sk.isUnlocked(storage)).length}/${BallSkinsCatalog.allSkins.length}',
                                              label: s.shopNavBtn,
                                              palette: p,
                                              onTap: () async {
                                                widget.game.audioHaptics
                                                    .onButtonTap();
                                                await BallSkinsDialog.show(
                                                  context,
                                                  widget.game,
                                                );
                                                if (mounted) setState(() {});
                                              },
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
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
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
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
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
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card compatta per ciascuna delle 3 Modalità di Gioco nel Menù Principale.
class _ModeSelectorCard extends StatelessWidget {
  final bool isSelected;
  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final String trailingBadge;
  final RisographPalette palette;
  final VoidCallback onTap;

  const _ModeSelectorCard({
    required this.isSelected,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.trailingBadge,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _MenuPressableButton(
      onTap: onTap,
      backgroundColor:
          isSelected ? accentColor.withAlpha(32) : palette.paperBg,
      borderColor: isSelected ? accentColor : palette.inkPrimary,
      borderWidth: 2.0,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isSelected ? accentColor : palette.paperCard,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: palette.inkPrimary,
                width: 1.6,
              ),
            ),
            child: Icon(
              icon,
              size: 19,
              color: isSelected ? Colors.white : accentColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.inkPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    style: TextStyle(
                      color: palette.inkSecondary,
                      fontSize: 9.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withAlpha(42)
                  : palette.paperCard,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: palette.inkPrimary,
                width: 1.4,
              ),
            ),
            child: Text(
              trailingBadge,
              style: TextStyle(
                color: palette.inkPrimary,
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialogo con Matrice Rettangolare 5×5 (25 livelli per pagina: 5 per riga × 5 righe)
/// e frecce di navigazione dopo l'ultimo livello della matrice per sfogliare i livelli infiniti!
class _LevelMatrixDialog extends StatefulWidget {
  final InkSlingGame game;
  final int initialSelectedLevel;

  const _LevelMatrixDialog({
    required this.game,
    required this.initialSelectedLevel,
  });

  @override
  State<_LevelMatrixDialog> createState() => _LevelMatrixDialogState();
}

class _LevelMatrixDialogState extends State<_LevelMatrixDialog> {
  static const int _levelsPerRow = 5;
  static const int _rowsPerPage = 5;
  static const int _levelsPerPage = _levelsPerRow * _rowsPerPage; // 25 livelli per matrice

  late int _currentPage;
  late int _selectedLevel;

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.initialSelectedLevel.clamp(
      1,
      widget.game.storage.currentTowerLevel,
    );
    _currentPage = (_selectedLevel - 1) ~/ _levelsPerPage;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.game.paletteNotifier.value;
    final s = widget.game.strings;
    final maxUnlocked = widget.game.storage.currentTowerLevel;

    final startLevel = _currentPage * _levelsPerPage + 1;
    final endLevel = startLevel + _levelsPerPage - 1;
    final selectedGoal =
        DailySeedEngine.getLevelGoalMeters(_selectedLevel).toInt();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 385),
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
              // Intestazione Matrice Livelli
              Row(
                children: [
                  Icon(
                    Icons.grid_view_rounded,
                    color: p.matchaSafe,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        s.levelMatrixTitle,
                        style: TextStyle(
                          color: p.inkPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      widget.game.audioHaptics.onButtonTap();
                      Navigator.of(context).pop();
                    },
                    icon: Icon(Icons.close_rounded, color: p.inkPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Barra di navigazione tra le matrici (Frecce prima/dopo i 25 livelli)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: p.paperBg,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: p.inkPrimary, width: 1.8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Freccia Matrice Precedente
                    _MenuPressableButton(
                      onTap: () {
                        if (_currentPage > 0) {
                          widget.game.audioHaptics.onButtonTap();
                          setState(() => _currentPage -= 1);
                        }
                      },
                      backgroundColor: _currentPage > 0
                          ? p.paperCard
                          : p.paperBg.withAlpha(120),
                      borderColor:
                          _currentPage > 0 ? p.inkPrimary : p.paperGrid,
                      borderWidth: 1.5,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                        color:
                            _currentPage > 0 ? p.inkPrimary : p.inkSecondary,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.levelMatrixPageLabel(startLevel, endLevel),
                          style: TextStyle(
                            color: p.inkPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          '${DailySeedEngine.getLevelGoalMeters(startLevel).toInt()}m – ${DailySeedEngine.getLevelGoalMeters(endLevel).toInt()}m',
                          style: TextStyle(
                            color: p.matchaSafe,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    // Freccia Matrice Successiva (dopo il 25° livello della matrice, infinita!)
                    _MenuPressableButton(
                      onTap: () {
                        widget.game.audioHaptics.onButtonTap();
                        setState(() => _currentPage += 1);
                      },
                      backgroundColor: p.ochreSeal,
                      borderColor: p.inkPrimary,
                      borderWidth: 1.6,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: p.onOchreSeal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Matrice Rettangolare 5×5 (5 livelli per riga × 5 righe = 25 livelli)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _levelsPerPage,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _levelsPerRow, // 5 livelli per riga
                  crossAxisSpacing: 7,
                  mainAxisSpacing: 7,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (context, idx) {
                  final lvl = startLevel + idx;
                  final isUnlocked = lvl <= maxUnlocked;
                  final isCompleted = lvl < maxUnlocked;
                  final isFrontier = lvl == maxUnlocked;
                  final isSelected = lvl == _selectedLevel;

                  Color bgColor = p.paperBg;
                  Color borderColor = p.paperGrid;
                  Color textColor = p.inkSecondary;

                  if (isSelected) {
                    bgColor = p.playerFill;
                    borderColor = p.inkPrimary;
                    textColor = p.onPlayerFill;
                  } else if (isFrontier) {
                    bgColor = p.ochreSeal.withAlpha(45);
                    borderColor = p.ochreSeal;
                    textColor = p.inkPrimary;
                  } else if (isCompleted) {
                    bgColor = p.matchaSafe.withAlpha(34);
                    borderColor = p.matchaSafe;
                    textColor = p.inkPrimary;
                  }

                  return GestureDetector(
                    onTap: () {
                      if (!isUnlocked) return;
                      widget.game.audioHaptics.onButtonTap();
                      if (_selectedLevel == lvl) {
                        Navigator.of(context).pop(lvl);
                      } else {
                        setState(() => _selectedLevel = lvl);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: borderColor,
                          width: isSelected ? 2.4 : 1.6,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: p.shadowColor,
                                  offset: const Offset(2, 3),
                                  blurRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '$lvl',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (!isUnlocked)
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 11,
                                  color: p.inkSecondary.withAlpha(150),
                                )
                              else
                                Text(
                                  '${DailySeedEngine.getLevelGoalMeters(lvl).toInt()}m',
                                  style: TextStyle(
                                    color: isSelected
                                        ? p.onPlayerFill.withAlpha(220)
                                        : p.inkSecondary,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                            ],
                          ),
                          if (isCompleted && !isSelected)
                            Positioned(
                              top: 3,
                              right: 4,
                              child: Icon(
                                Icons.check_circle_rounded,
                                size: 10,
                                color: p.matchaSafe,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              // Nota informativa e Freccia rapida alla matrice successiva dopo il 25° elemento
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.levelMatrixLockedHint(maxUnlocked),
                      style: TextStyle(
                        color: p.inkSecondary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _MenuPressableButton(
                    onTap: () {
                      widget.game.audioHaptics.onButtonTap();
                      setState(() => _currentPage += 1);
                    },
                    backgroundColor: p.paperBg,
                    borderColor: p.inkPrimary,
                    borderWidth: 1.6,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${endLevel + 1}–${endLevel + _levelsPerPage}',
                          style: TextStyle(
                            color: p.inkPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.east_rounded,
                          size: 14,
                          color: p.inkPrimary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Bottone Gioca Livello Selezionato
              _MenuPressableButton(
                onTap: () {
                  widget.game.audioHaptics.onButtonTap();
                  Navigator.of(context).pop(_selectedLevel);
                },
                backgroundColor: p.matchaSafe,
                borderColor: p.inkPrimary,
                borderWidth: 2.2,
                hasShadow: true,
                shadowColor: p.shadowColor,
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                  horizontal: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      color: p.onMatchaSafe,
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          s.playLevelBtn(_selectedLevel, selectedGoal),
                          style: TextStyle(
                            color: p.onMatchaSafe,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPaletteDot extends StatelessWidget {
  final Color color;
  final Color border;
  const _MiniPaletteDot({required this.color, required this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1.1),
      ),
    );
  }
}

/// Anima l'assemblaggio progressivo di un singolo stadio del Menù Principale
/// (slide + scale + fade sincronizzati sull'intervallo specificato).
class _AssembleStage extends StatelessWidget {
  final AnimationController controller;
  final double startInterval;
  final double endInterval;
  final Offset initialOffset;
  final double initialScale;
  final bool useSpringCurve;
  final Widget child;

  const _AssembleStage({
    required this.controller,
    required this.startInterval,
    required this.endInterval,
    required this.initialOffset,
    this.initialScale = 1.0,
    this.useSpringCurve = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final rawT = ((controller.value - startInterval) /
            (endInterval - startInterval))
        .clamp(0.0, 1.0);
    final opacity = Curves.easeOutCubic.transform(rawT);
    final motionT = useSpringCurve
        ? Curves.easeOutBack.transform(rawT)
        : Curves.easeOutCubic.transform(rawT);

    final dx = initialOffset.dx * (1.0 - motionT);
    final dy = initialOffset.dy * (1.0 - motionT);
    final scale = initialScale + (1.0 - initialScale) * motionT;

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(dx, dy),
        child: Transform.scale(
          scale: scale,
          child: child,
        ),
      ),
    );
  }
}

/// Pulsante secondario compatto per la barra inferiore del Menù Principale.
class _SecondaryMenuTile extends StatelessWidget {
  final IconData? icon;
  final String? emojiIcon;
  final Color iconColor;
  final String badgeText;
  final String label;
  final RisographPalette palette;
  final VoidCallback onTap;

  const _SecondaryMenuTile({
    this.icon,
    this.emojiIcon,
    required this.iconColor,
    required this.badgeText,
    required this.label,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _MenuPressableButton(
      onTap: onTap,
      backgroundColor: palette.paperBg,
      borderColor: palette.inkPrimary,
      borderWidth: 1.8,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (emojiIcon != null)
            Text(emojiIcon!, style: const TextStyle(fontSize: 14))
          else if (icon != null)
            Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 5),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: palette.inkPrimary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 5,
              vertical: 1.5,
            ),
            decoration: BoxDecoration(
              color: palette.inkPrimary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: palette.paperCard,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget riutilizzabile con feedback tattile visivo (scaling + shadow press) per i bottoni del menu.
class _MenuPressableButton extends StatefulWidget {
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry padding;
  final bool hasShadow;
  final Color? shadowColor;
  final Widget child;

  const _MenuPressableButton({
    required this.onTap,
    required this.backgroundColor,
    required this.borderColor,
    this.borderWidth = 1.8,
    required this.padding,
    this.hasShadow = false,
    this.shadowColor,
    required this.child,
  });

  @override
  State<_MenuPressableButton> createState() => _MenuPressableButtonState();
}

class _MenuPressableButtonState extends State<_MenuPressableButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 85),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(11),
            border: widget.borderWidth > 0
                ? Border.all(
                    color: widget.borderColor,
                    width: widget.borderWidth,
                  )
                : null,
            boxShadow: widget.hasShadow && widget.shadowColor != null
                ? [
                    BoxShadow(
                      color: widget.shadowColor!,
                      offset: _pressed
                          ? const Offset(1, 1)
                          : const Offset(3, 4),
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Dialogo Classifica (Livelli Progressivi, Giornaliera o Torre Infinita)
class _LeaderboardDialogContent extends StatefulWidget {
  final InkSlingGame game;
  final RisographPalette palette;
  final GameMode mode;
  final VoidCallback onProfileUpdated;

  const _LeaderboardDialogContent({
    required this.game,
    required this.palette,
    required this.mode,
    required this.onProfileUpdated,
  });

  @override
  State<_LeaderboardDialogContent> createState() =>
      _LeaderboardDialogContentState();
}

class _LeaderboardDialogContentState extends State<_LeaderboardDialogContent> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.game.storage.playerName,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final storage = widget.game.storage;
    final s = widget.game.strings;
    final isDaily = widget.mode == GameMode.dailyTower;
    final isInfinite = widget.mode == GameMode.infiniteTower;

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
        : (isInfinite
            ? DailySeedEngine.getInfiniteLeaderboard(
                playerName: storage.playerName,
                playerInfiniteBestMeters: storage.infiniteBestMeters,
                playerInfiniteBounces: storage.infiniteBestBounces,
                playerAvatarEmoji: userAvatarEmoji,
              )
            : DailySeedEngine.getGlobalLeaderboard(
                playerName: storage.playerName,
                playerLevel: storage.currentTowerLevel,
                playerBestMeters: storage.bestMetersCurrentLevel,
                playerBounces: storage.bestBouncesCurrentLevel,
                totalLevelsPlayed: storage.totalLevelsPlayed,
                playerAvatarEmoji: userAvatarEmoji,
              ));

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
                            : (isInfinite
                                ? s.leaderboardInfiniteTitle
                                : s.leaderboardLevelsTitle),
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
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: p.inkPrimary),
                  ),
                ],
              ),
              Text(
                isDaily
                    ? s.leaderboardDailySub
                    : (isInfinite
                        ? s.leaderboardInfiniteSub
                        : s.leaderboardLevelsSub),
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
                        controller: _nameController,
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
                          if (mounted) setState(() {});
                          widget.onProfileUpdated();
                        },
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: p.matchaSafe,
                      ),
                      onPressed: () async {
                        await storage.setPlayerName(_nameController.text);
                        if (mounted) setState(() {});
                        widget.onProfileUpdated();
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

              // Lista Classifica
              Expanded(
                child: ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
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
                            ? '${DailySeedEngine.formatMeters(item.bestMeters)}m • ${item.bounces} ${s.bouncesShort}'
                            : '0.0m / 100m')
                        : (isInfinite
                            ? '${DailySeedEngine.formatMeters(item.bestMeters)}m ♾️ • ${item.bounces} ${s.bouncesShort}'
                            : '${s.levelShort} ${item.level} • ${item.progressPercent}% • ${item.bounces} ${s.bouncesShort}');

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
  }
}

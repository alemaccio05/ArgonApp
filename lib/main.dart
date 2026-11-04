import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/app_strings.dart';
import 'core/palette_theme.dart';
import 'game/ink_sling_game.dart';
import 'services/audio_haptics_service.dart';
import 'services/monetization_service.dart';
import 'services/p2p_multiplayer_service.dart';
import 'services/storage_service.dart';
import 'ui/game_over_overlay.dart';
import 'ui/hud_overlay.dart';
import 'ui/main_menu_overlay.dart';
import 'ui/pause_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Blocca orientamento verticale e imposta modalità immersiva in modo resiliente
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .catchError((_) {});
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky)
      .catchError((_) {});

  final storage = StorageService();
  try {
    await storage.init();
  } catch (_) {}

  final audioHaptics = AudioHapticsService();
  final monetization = MonetizationService();

  final game = InkSlingGame(
    storage: storage,
    audioHaptics: audioHaptics,
    monetization: monetization,
  );

  runApp(InkSlingApp(game: game));
}

class InkSlingApp extends StatefulWidget {
  final InkSlingGame game;
  const InkSlingApp({super.key, required this.game});

  @override
  State<InkSlingApp> createState() => _InkSlingAppState();
}

class _InkSlingAppState extends State<InkSlingApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    widget.game.navigatorKey = _navigatorKey;
    _lifecycleListener = AppLifecycleListener(
      onStateChange: widget.game.p2pService.onAppLifecycleStateChanged,
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    if (widget.game.navigatorKey == _navigatorKey) {
      widget.game.navigatorKey = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialBg = widget.game.paletteNotifier.value.paperBg;
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'INK TOWER: Climb & Stick',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: initialBg,
      ),
      builder: (context, navigatorChild) {
        return Stack(
          fit: StackFit.expand,
          children: [
            if (navigatorChild != null) navigatorChild,
            _GlobalP2PInvitePopupOverlay(game: widget.game),
          ],
        );
      },
      home: Scaffold(
        backgroundColor: initialBg,
        body: Stack(
          fit: StackFit.expand,
          children: [
            GameWidget<InkSlingGame>(
              game: widget.game,
              overlayBuilderMap: {
                'MainMenu': (context, game) => MainMenuOverlay(game: game),
                'Hud': (context, game) => HudOverlay(game: game),
                'Pause': (context, game) => PauseOverlay(game: game),
                'GameOver': (context, game) => GameOverOverlay(game: game),
              },
              initialActiveOverlays: const ['MainMenu'],
            ),
            _StartupRevealCurtain(game: widget.game),
          ],
        ),
      ),
    );
  }
}

/// Pop-up globale per gli inviti P2P in entrata: viene montato sopra il Navigator
/// così è SEMPRE visibile e cliccabile anche quando il giocatore è nella Lista Amici o in altri dialog.
class _GlobalP2PInvitePopupOverlay extends StatelessWidget {
  final InkSlingGame game;
  const _GlobalP2PInvitePopupOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<P2PIncomingInvite?>(
      valueListenable: game.p2pService.incomingInviteNotifier,
      builder: (context, invite, _) {
        if (invite == null || game.isPlaying) {
          return const SizedBox.shrink();
        }
        return ValueListenableBuilder<RisographPalette>(
          valueListenable: game.paletteNotifier,
          builder: (context, p, _) {
            return ValueListenableBuilder<AppLanguage>(
              valueListenable: game.languageNotifier,
              builder: (context, lang, _) {
                final s = AppStrings(lang);
                final modeName = invite.format == P2PDuelFormat.infiniteSurvival
                    ? s.p2pFormatInfinite
                    : s.p2pFormat100m;
                return SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: p.paperCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: p.vermilionHazard,
                                width: 2.6,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: p.shadowColor,
                                  offset: const Offset(4, 5),
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
                                    Text(
                                      invite.challengerAvatar,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s.incomingInviteTitle(
                                              invite.senderName,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w900,
                                              color: p.vermilionHazard,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            s.incomingInviteSub(
                                              modeName,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: p.inkPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          game.audioHaptics.onButtonTap();
                                          game.acceptIncomingP2PInvite(invite);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: p.matchaSafe,
                                          foregroundColor: p.onMatchaSafe,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 9,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(9),
                                            side: BorderSide(
                                              color: p.inkPrimary,
                                              width: 1.8,
                                            ),
                                          ),
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            s.acceptChallengeBtn,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          game.audioHaptics.onButtonTap();
                                          game.p2pService
                                              .declineIncomingInvite();
                                        },
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: p.paperBg,
                                          foregroundColor: p.inkPrimary,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 9,
                                          ),
                                          side: BorderSide(
                                            color: p.inkPrimary,
                                            width: 1.8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(9),
                                          ),
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            s.declineChallengeBtn,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
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
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Sipario di avvio in stile Risograph che elimina lo scatto brusco al caricamento:
/// attende che il mondo Flame e la demo della torre in sottofondo siano pronti,
/// poi sfuma dolcemente facendo partire l'animazione di assemblaggio del Menù Principale.
class _StartupRevealCurtain extends StatefulWidget {
  final InkSlingGame game;
  const _StartupRevealCurtain({required this.game});

  @override
  State<_StartupRevealCurtain> createState() => _StartupRevealCurtainState();
}

class _StartupRevealCurtainState extends State<_StartupRevealCurtain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _revealController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  bool _dismissed = false;
  bool _revealStarted = false;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fadeAnim = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeInOutCubic,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: Curves.easeOutCubic,
      ),
    );

    _revealController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _dismissed = true);
      }
    });

    widget.game.isGameLoadedNotifier.addListener(_onGameLoadedChanged);
    if (widget.game.isGameLoadedNotifier.value) {
      _scheduleSmoothReveal();
    } else {
      // Fallback di sicurezza se onLoad impiegasse più del previsto
      _fallbackTimer = Timer(const Duration(milliseconds: 900), () {
        _scheduleSmoothReveal();
      });
    }
  }

  void _onGameLoadedChanged() {
    if (widget.game.isGameLoadedNotifier.value) {
      _scheduleSmoothReveal();
    }
  }

  void _scheduleSmoothReveal() {
    if (_revealStarted || !mounted) return;
    _revealStarted = true;
    _fallbackTimer?.cancel();

    // Attende un singolo beat dopo il primo frame del mondo di gioco per
    // avviare in sincrono la dissolvenza del sipario e l'assemblaggio del menù.
    Future<void>.delayed(const Duration(milliseconds: 140), () {
      if (!mounted) return;
      widget.game.menuEntryEpochNotifier.value += 1;
      _revealController.forward();
    });
  }

  @override
  void dispose() {
    widget.game.isGameLoadedNotifier.removeListener(_onGameLoadedChanged);
    _fallbackTimer?.cancel();
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final p = widget.game.paletteNotifier.value;
    return IgnorePointer(
      ignoring: _revealStarted,
      child: AnimatedBuilder(
        animation: _revealController,
        builder: (context, child) {
          final opacity = (1.0 - _fadeAnim.value).clamp(0.0, 1.0);
          if (opacity <= 0.01) return const SizedBox.shrink();

          return Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: child,
            ),
          );
        },
        child: Container(
          color: p.paperBg,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sigillo Risograph di avvio
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: p.paperCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.inkPrimary, width: 2.8),
                    boxShadow: [
                      BoxShadow(
                        color: p.shadowColor,
                        offset: const Offset(4, 5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: p.playerFill,
                        shape: BoxShape.circle,
                        border: Border.all(color: p.playerStroke, width: 2.2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'INK TOWER',
                  style: TextStyle(
                    color: p.inkPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: p.matchaSafe,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'CLIMB & STICK',
                    style: TextStyle(
                      color: p.onMatchaSafe,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

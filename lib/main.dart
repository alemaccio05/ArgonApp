import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/ink_sling_game.dart';
import 'services/audio_haptics_service.dart';
import 'services/monetization_service.dart';
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

class InkSlingApp extends StatelessWidget {
  final InkSlingGame game;
  const InkSlingApp({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final initialBg = game.paletteNotifier.value.paperBg;
    return MaterialApp(
      title: 'INK TOWER: Climb & Stick',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: initialBg,
      ),
      home: Scaffold(
        backgroundColor: initialBg,
        body: Stack(
          fit: StackFit.expand,
          children: [
            GameWidget<InkSlingGame>(
              game: game,
              overlayBuilderMap: {
                'MainMenu': (context, game) => MainMenuOverlay(game: game),
                'Hud': (context, game) => HudOverlay(game: game),
                'Pause': (context, game) => PauseOverlay(game: game),
                'GameOver': (context, game) => GameOverOverlay(game: game),
              },
              initialActiveOverlays: const ['MainMenu'],
            ),
            _StartupRevealCurtain(game: game),
          ],
        ),
      ),
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

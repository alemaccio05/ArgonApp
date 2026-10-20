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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Blocca orientamento verticale e imposta modalità immersiva in modo resiliente
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .catchError((_) {});
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky)
      .catchError((_) {});

  final storage = StorageService();
  try {
    await storage.init().timeout(const Duration(milliseconds: 1200));
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
    return MaterialApp(
      title: 'INK TOWER: Climb & Stick',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4EFE6),
      ),
      home: Scaffold(
        body: GameWidget<InkSlingGame>(
          game: game,
          overlayBuilderMap: {
            'MainMenu': (context, game) => MainMenuOverlay(game: game),
            'Hud': (context, game) => HudOverlay(game: game),
            'GameOver': (context, game) => GameOverOverlay(game: game),
          },
          initialActiveOverlays: const ['MainMenu'],
        ),
      ),
    );
  }
}

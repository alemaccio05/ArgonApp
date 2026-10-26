import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ink_sling_daily/core/ball_skins.dart';
import 'package:ink_sling_daily/core/palette_theme.dart';
import 'package:ink_sling_daily/game/components/obstacle_block.dart';
import 'package:ink_sling_daily/game/components/player_core.dart';
import 'package:ink_sling_daily/game/ink_sling_game.dart';
import 'package:ink_sling_daily/services/audio_haptics_service.dart';
import 'package:ink_sling_daily/services/monetization_service.dart';
import 'package:ink_sling_daily/services/storage_service.dart';

void main() {
  group('Theme Contrast & Legibility Tests', () {
    test('Dynamic contrast getters return legible foreground colors for each palette', () {
      final palettes = [
        RisographPalette.washiIvory,
        RisographPalette.sumiCharcoal,
        RisographPalette.kyotoMatcha,
      ];

      for (final p in palettes) {
        // I contrasti per badges ed elementi di stato non devono mai essere trasparenti
        expect(p.onMatchaSafe.a, equals(1.0));
        expect(p.onOchreSeal.a, equals(1.0));
        expect(p.onVermilionHazard.a, equals(1.0));
        expect(p.onPlayerFill.a, equals(1.0));

        // onMatchaSafe e onOchreSeal devono offrire contrasto cromatico rispetto al fondo
        expect(p.onMatchaSafe, isNot(equals(p.matchaSafe)));
        expect(p.onOchreSeal, isNot(equals(p.ochreSeal)));
        expect(p.onVermilionHazard, isNot(equals(p.vermilionHazard)));
      }
    });

    test('Ball skin core colors adapt appropriately to active palette', () {
      final palette = RisographPalette.washiIvory;
      for (final skin in BallSkinsCatalog.allSkins) {
        final color = skin.getCoreColor(palette);
        expect(color.a, equals(1.0));
      }
    });
  });

  group('PlayerCore & Obstacle Mechanics Tests', () {
    test('PlayerCore initializes with default charges and alive state', () {
      final player = PlayerCore(position: Vector2.zero());
      expect(player.isDead, isFalse);
      expect(player.airCharges, equals(PlayerCore.maxAirCharges));
      expect(PlayerCore.radius, equals(14.0));
      expect(player.isStuck, isTrue); // A y=0 è appoggiato al pavimento
    });

    test('Pulsing laser obstacle defines correct hazard classification', () {
      final laser = ObstacleBlock(
        type: BlockType.pulsingLaserHazard,
        position: Vector2(0, -100),
        size: Vector2(240, 16),
      );

      expect(laser.type, equals(BlockType.pulsingLaserHazard));
      expect(laser.size.y, equals(16.0));
    });

    test('Moving pad obstacle properly defines lateral movement properties', () {
      final movingPad = ObstacleBlock(
        type: BlockType.matchaPad,
        position: Vector2(0, -200),
        size: Vector2(90, 16),
        movingSpeed: 85.0,
      );

      expect(movingPad.movingSpeed, equals(85.0));
      expect(movingPad.type, equals(BlockType.matchaPad));
    });

    test('InkSlingGame player is initialized and alive upon creation without LateInitializationError', () {
      final storage = StorageService();
      final audio = AudioHapticsService();
      final monetization = MonetizationService();
      final game = InkSlingGame(
        storage: storage,
        audioHaptics: audio,
        monetization: monetization,
      );
      expect(game.player, isNotNull);
      expect(game.player.isDead, isFalse);
    });
    test('Player air charges are max 3 and wall bounces do not recharge air charges', () async {
      final storage = StorageService();
      final audio = AudioHapticsService();
      audio.soundEnabled = false;
      final monetization = MonetizationService();
      final game = InkSlingGame(
        storage: storage,
        audioHaptics: audio,
        monetization: monetization,
      );

      game.onGameResize(Vector2(400, 800));
      await game.onLoad();
      game.isPlaying = true;
      game.isMenuDemo = false;

      // Inizialmente il giocatore ha 3 cariche
      expect(game.player.airCharges, equals(3));
      expect(game.chargesNotifier.value, equals(3));

      // Effettua 3 lanci per esaurire tutte le cariche
      game.player.launch(Vector2(100, -200), silent: true);
      expect(game.player.airCharges, equals(2));

      game.player.launch(Vector2(-100, -200), silent: true);
      expect(game.player.airCharges, equals(1));

      game.player.launch(Vector2(100, -200), silent: true);
      expect(game.player.airCharges, equals(0));
      expect(game.chargesNotifier.value, equals(0));

      // Posiziona il giocatore oltre la parete destra per forzare il rimbalzo
      final halfWall = game.towerHalfWidth - PlayerCore.radius;
      game.player.position.setValues(halfWall + 10.0, -50.0);
      game.player.velocity.setValues(200.0, 50.0);

      // Esegue update del player: urta la parete
      game.player.update(0.016);

      // VERIFICA: la sfera rimbalza fisicamente ma le cariche rimangono TASSATIVAMENTE a 0 (nessun salto infinito)
      expect(game.player.position.x, equals(halfWall));
      expect(game.player.velocity.x, lessThan(0.0)); // rimbalzo invertito a sinistra
      expect(game.player.airCharges, equals(0));
      expect(game.chargesNotifier.value, equals(0));

      // Verifica anche la parete sinistra
      game.player.position.setValues(-halfWall - 10.0, -60.0);
      game.player.velocity.setValues(-200.0, 50.0);
      game.player.update(0.016);

      expect(game.player.position.x, equals(-halfWall));
      expect(game.player.velocity.x, greaterThan(0.0)); // rimbalzo invertito a destra
      expect(game.player.airCharges, equals(0));
      expect(game.chargesNotifier.value, equals(0));

      // Incollarsi a una piattaforma verde ripristina invece tutti i 3 salti
      final pad = ObstacleBlock(
        type: BlockType.matchaPad,
        position: Vector2(0, -100),
        size: Vector2(100, 20),
      );
      game.player.position.setValues(0, -100);
      final stuck = game.player.stickToPlatform(pad);

      expect(stuck, isTrue);
      expect(game.player.airCharges, equals(3));
      expect(game.chargesNotifier.value, equals(3));
    });
  });
}

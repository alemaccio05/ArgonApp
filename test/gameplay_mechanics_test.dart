import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ink_sling_daily/core/ball_skins.dart';
import 'package:ink_sling_daily/core/daily_seed.dart';
import 'package:ink_sling_daily/core/palette_theme.dart';
import 'package:ink_sling_daily/game/components/ink_particle_pool.dart';
import 'package:ink_sling_daily/game/components/obstacle_block.dart';
import 'package:ink_sling_daily/game/components/player_core.dart';
import 'package:ink_sling_daily/game/ink_sling_game.dart';
import 'package:ink_sling_daily/services/audio_haptics_service.dart';
import 'package:ink_sling_daily/services/monetization_service.dart';
import 'package:ink_sling_daily/services/storage_service.dart';
import 'package:ink_sling_daily/services/trusted_time_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Theme Contrast & Legibility Tests', () {
    test('Dynamic contrast getters return legible foreground colors for each palette', () {
      final palettes = [
        RisographPalette.washiIvory,
        RisographPalette.sumiCharcoal,
        RisographPalette.kyotoMatcha,
      ];

      for (final p in palettes) {
        expect(p.onMatchaSafe.a, equals(1.0));
        expect(p.onOchreSeal.a, equals(1.0));
        expect(p.onVermilionHazard.a, equals(1.0));
        expect(p.onPlayerFill.a, equals(1.0));

        expect(p.onMatchaSafe, isNot(equals(p.matchaSafe)));
        expect(p.onOchreSeal, isNot(equals(p.ochreSeal)));
        expect(p.onVermilionHazard, isNot(equals(p.vermilionHazard)));
      }
    });

    test('Ball skin core and stroke colors maintain high contrast across all 3 Risograph palettes', () {
      final palettes = [
        RisographPalette.washiIvory,
        RisographPalette.sumiCharcoal,
        RisographPalette.kyotoMatcha,
      ];

      for (final palette in palettes) {
        for (final skin in BallSkinsCatalog.allSkins) {
          final core = skin.getCoreColor(palette);
          final stroke = skin.getStrokeColor(palette);
          final trail = skin.getTrailColor(palette);

          expect(core.a, equals(1.0));
          expect(stroke.a, equals(1.0));
          expect(trail.a, equals(1.0));

          // Core e stroke devono essere distinti tra loro per garantire il bordo Risograph netto
          expect(
            core,
            isNot(equals(stroke)),
            reason: 'Skin ${skin.id} core == stroke in palette ${palette.id}',
          );

          // Né core né stroke devono coincidere contemporaneamente con lo sfondo della torre
          final matchesBgBoth = (core == palette.paperBg && stroke == palette.paperBg);
          expect(
            matchesBgBoth,
            isFalse,
            reason: 'Skin ${skin.id} invisible on paperBg in palette ${palette.id}',
          );

          // In Kyoto Matcha (Salvia), nessuna skin deve avere sia core sia stroke identici alle piattaforme verdi
          if (palette.id == 'kyoto_matcha') {
            expect(
              core == palette.matchaSafe && stroke == palette.matchaSafe,
              isFalse,
              reason: 'Skin ${skin.id} blends into matchaSafe platforms in kyoto_matcha',
            );
          }
        }
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

      expect(game.player.airCharges, equals(3));
      expect(game.chargesNotifier.value, equals(3));

      game.player.launch(Vector2(100, -200), silent: true);
      expect(game.player.airCharges, equals(2));

      game.player.launch(Vector2(-100, -200), silent: true);
      expect(game.player.airCharges, equals(1));

      game.player.launch(Vector2(100, -200), silent: true);
      expect(game.player.airCharges, equals(0));
      expect(game.chargesNotifier.value, equals(0));

      final halfWall = game.towerHalfWidth - PlayerCore.radius;
      game.player.position.setValues(halfWall + 10.0, -50.0);
      game.player.velocity.setValues(200.0, 50.0);

      game.player.update(0.016);

      expect(game.player.position.x, equals(halfWall));
      expect(game.player.velocity.x, lessThan(0.0));
      expect(game.player.airCharges, equals(0));
      expect(game.chargesNotifier.value, equals(0));

      game.player.position.setValues(-halfWall - 10.0, -60.0);
      game.player.velocity.setValues(-200.0, 50.0);
      game.player.update(0.016);

      expect(game.player.position.x, equals(-halfWall));
      expect(game.player.velocity.x, greaterThan(0.0));
      expect(game.player.airCharges, equals(0));
      expect(game.chargesNotifier.value, equals(0));

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

  group('Point 1 & 2: Second Chance Deterministic Respawn & Height Calibration', () {
    test('Level starts at exact 0.0m (no 0.4m initial offset) and subtracts ball radius', () async {
      final storage = StorageService();
      final audio = AudioHapticsService()..soundEnabled = false;
      final monetization = MonetizationService();
      final game = InkSlingGame(
        storage: storage,
        audioHaptics: audio,
        monetization: monetization,
      );

      game.onGameResize(Vector2(400, 800));
      await game.onLoad();
      game.startRun(mode: GameMode.levelProgression, level: 1);

      expect(game.player.position.y, equals(InkSlingGame.platformBaseY));
      expect(game.player.bottomContactY, equals(InkSlingGame.groundSurfaceY));
      expect(game.computeCurrentHeightMeters(), equals(0.0));
      expect(game.maxMetersReached, equals(0.0));
      expect(game.metersNotifier.value, equals(0.0));
      expect(DailySeedEngine.formatMeters(game.metersNotifier.value), equals('0.0'));
    });

    test('Second Chance respawn deterministically anchors X/Y on rescue platform, zeroes velocity/acceleration, freezes for 0.5s, and preserves exact meters', () async {
      final storage = StorageService();
      final audio = AudioHapticsService()..soundEnabled = false;
      final monetization = MonetizationService();
      final game = InkSlingGame(
        storage: storage,
        audioHaptics: audio,
        monetization: monetization,
      );

      game.onGameResize(Vector2(400, 800));
      await game.onLoad();
      game.startRun(mode: GameMode.levelProgression, level: 1);

      // Simula che la palla fosse rimasta attaccata a una piattaforma laterale fuori asse
      // e abbia raggiunto 23.6m prima della morte (es. raggiunta dall'onda di inchiostro)
      final oldPad = ObstacleBlock(
        type: BlockType.matchaPad,
        position: Vector2(120, -1062.0),
        size: Vector2(80, 16),
      );
      game.player.stickToPlatform(oldPad);
      game.player.position.setValues(145.0, -1062.0);
      game.player.velocity.setValues(380.0, 620.0);
      game.player.acceleration.setValues(50.0, 1280.0);
      game.maxMetersReached = 23.6;
      game.metersNotifier.value = 23.6;

      game.triggerGameOver(victory: false);
      expect(game.player.isDead, isTrue);

      // Attiva la Seconda Chance
      game.reviveWithShield();

      final rescuePad = game.player.stuckPlatform;
      expect(rescuePad, isNotNull);
      expect(rescuePad, isNot(equals(oldPad)));

      // 1. Coordinata X centrata/clamped nei margini sicuri della piattaforma
      expect(
        game.player.position.x,
        greaterThanOrEqualTo(rescuePad!.left + PlayerCore.radius),
      );
      expect(
        game.player.position.x,
        lessThanOrEqualTo(rescuePad.right - PlayerCore.radius),
      );
      expect(game.player.position.x, equals(0.0));

      // 2. Coordinata Y posta esattamente sulla superficie superiore di collisione (platform.top - radius)
      expect(game.player.bottomContactY, closeTo(rescuePad.top, 0.0001));
      expect(
        game.player.position.y,
        closeTo(rescuePad.top - PlayerCore.radius, 0.0001),
      );

      // 3. Componenti vettoriali di velocità e accelerazione azzerate
      expect(game.player.velocity, equals(Vector2.zero()));
      expect(game.player.acceleration, equals(Vector2.zero()));

      // 4. Freeze/invulnerabilità temporaneo (0.5s) attivo
      expect(game.player.isRespawnFrozen, isTrue);
      expect(
        game.player.respawnFreezeTimer,
        equals(PlayerCore.defaultRespawnFreezeDuration),
      );
      expect(game.player.shieldTimer, greaterThan(0.0));

      // Durante il freeze, un tentativo di lancio viene ignorato per evitare inerzie spurie
      game.player.launch(Vector2(200, -500), silent: true);
      expect(game.player.velocity, equals(Vector2.zero()));

      // 5. Coerenza metrica altezza: nessuna deriva di decimi di metro dopo il respawn
      for (int i = 0; i < 4; i++) {
        game.update(0.025);
      }
      expect(game.maxMetersReached, equals(23.6));
      expect(game.metersNotifier.value, equals(23.6));
      expect(DailySeedEngine.formatMeters(game.metersNotifier.value), equals('23.6'));

      // Dopo 0.5s totali il freeze termina e il lancio torna attivo
      for (int i = 0; i < 20; i++) {
        game.update(0.025);
      }
      expect(game.player.isRespawnFrozen, isFalse);
      game.player.launch(Vector2(100, -450), silent: true);
      expect(game.player.velocity.y, lessThan(0.0));
    });
  });

  group('Point 4: Anti-Exploit Clock Rollback & Monotonic Timer Tests', () {
    test('SecureTimeVault encrypts/authenticates payload and TrustedTimeService detects clock rollback', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      const futureTimestampMs = 1893456000000; // Anno 2030
      await SecureTimeVault.write(prefs, <String, dynamic>{
        'lastUnixMs': futureTimestampMs,
        'maxUnixMs': futureTimestampMs,
        'netVerified': false,
        'tampered': false,
      });

      final record = await SecureTimeVault.read(prefs);
      expect(record, isNotNull);
      expect(record!['lastUnixMs'], equals(futureTimestampMs));

      // Verifica che la manomissione del token crittografico venga rilevata (MAC invalido -> null)
      expect(SecureTimeVault.verifyAndDecrypt('invalid.token'), isNull);

      // L'inizializzazione con orologio locale precedente all'ultimo timestamp salvato
      // deve rilevare il rollback dell'orologio e bloccare i livelli giornalieri
      await TrustedTimeService.instance.init(
        prefs: prefs,
        attemptNetworkSync: false,
      );

      expect(TrustedTimeService.instance.isClockTampered, isTrue);
      final remaining = TrustedTimeService.instance.getRemainingDailyTime();
      expect(remaining.inSeconds, greaterThan(0));
      expect(
        TrustedTimeService.instance.getFormattedRemainingDailyTime(),
        contains(':'),
      );

      // Ripristina stato pulito per gli altri test tramite sync server simulato
      await TrustedTimeService.instance.syncWithServer(
        customFetcher: () async => DateTime.now().toUtc(),
      );
      expect(TrustedTimeService.instance.isClockTampered, isFalse);
    });
  });

  group('Point 5 & 6: In-Game Pause System & Object Pooling Tests', () {
    test('Pause freezes game loop and physics (timeScale = 0) and enables audio ducking', () async {
      final storage = StorageService();
      final audio = AudioHapticsService()..soundEnabled = false;
      final monetization = MonetizationService();
      final game = InkSlingGame(
        storage: storage,
        audioHaptics: audio,
        monetization: monetization,
      );

      game.onGameResize(Vector2(400, 800));
      await game.onLoad();
      game.startRun(mode: GameMode.levelProgression, level: 1);

      game.update(0.2);
      final timeBeforePause = game.runTimeSeconds;
      expect(timeBeforePause, closeTo(0.2, 0.01));

      game.pauseGame();
      expect(game.isPaused, isTrue);
      expect(game.timeScale, equals(0.0));
      expect(audio.isPaused, isTrue);

      // Durante la pausa il tempo di gioco non avanza
      game.update(1.0);
      expect(game.runTimeSeconds, equals(timeBeforePause));

      game.resumeGame();
      expect(game.isPaused, isFalse);
      expect(game.timeScale, equals(1.0));
      expect(audio.isPaused, isFalse);
    });

    test('Object Pool handles particle bursts on jump without adding transient components to world', () async {
      final storage = StorageService();
      final audio = AudioHapticsService()..soundEnabled = false;
      final monetization = MonetizationService();
      final game = InkSlingGame(
        storage: storage,
        audioHaptics: audio,
        monetization: monetization,
      );

      game.onGameResize(Vector2(400, 800));
      await game.onLoad();
      game.startRun(mode: GameMode.levelProgression, level: 1);

      // Aspetta fine freeze iniziale
      game.update(0.6);

      final worldChildrenBeforeJump = game.world.children.length;
      game.player.launch(Vector2(120, -500), silent: true);
      final worldChildrenAfterJump = game.world.children.length;

      // Nessun nuovo componente viene istanziato o aggiunto al world durante il salto!
      expect(worldChildrenAfterJump, equals(worldChildrenBeforeJump));

      // Verifica FramePerformanceMonitor fallback sotto i 60 FPS
      final perf = FramePerformanceMonitor();
      expect(perf.isLowQualityMode, isFalse);
      for (int i = 0; i < 30; i++) {
        perf.recordFrame(0.033); // ~30 FPS
      }
      expect(perf.isLowQualityMode, isTrue);
      for (int i = 0; i < 130; i++) {
        perf.recordFrame(0.014); // ~70 FPS
      }
      expect(perf.isLowQualityMode, isFalse);
    });

    test('Camera viewfinder tracks the ball upward in both Menu Demo background and active Levels', () async {
      final storage = StorageService();
      final audio = AudioHapticsService()..soundEnabled = false;
      final monetization = MonetizationService();
      final game = InkSlingGame(
        storage: storage,
        audioHaptics: audio,
        monetization: monetization,
      );

      game.onGameResize(Vector2(400, 800));
      await game.onLoad();

      // Verifica stato caricamento e contatore animazione menù
      expect(game.isGameLoadedNotifier.value, isTrue);
      final initialEpoch = game.menuEntryEpochNotifier.value;

      // 1. In Menu Demo la telecamera deve seguire la palla verso l'alto
      expect(game.isMenuDemo, isTrue);
      final initialMenuCamY = game.camera.viewfinder.position.y;
      game.player.position.setValues(0.0, -900.0);
      for (int i = 0; i < 20; i++) {
        game.update(0.016);
      }
      expect(
        game.camera.viewfinder.position.y,
        lessThan(initialMenuCamY - 100.0),
      );

      // 2. Nei Livelli (startRun) la telecamera si resetta e segue il giocatore durante la scalata
      game.startRun(mode: GameMode.levelProgression, level: 1);
      expect(game.isPlaying, isTrue);
      expect(game.isMenuDemo, isFalse);
      final initialLevelCamY = game.camera.viewfinder.position.y;
      expect(initialLevelCamY, closeTo(-180.0, 1.0));

      game.player.position.setValues(0.0, -1200.0);
      for (int i = 0; i < 25; i++) {
        game.update(0.016);
      }
      expect(
        game.camera.viewfinder.position.y,
        lessThan(initialLevelCamY - 200.0),
      );

      // 3. Ritorno al menù incrementa menuEntryEpochNotifier per riattivare l'animazione di assemblaggio
      game.returnToMainMenu();
      expect(game.menuEntryEpochNotifier.value, greaterThan(initialEpoch));
    });

    test('Unified Volume toggle, Infinite Tower (+1 obstacle every 50m), and Zero-Reset Data Persistence work as expected', () async {
      SharedPreferences.setMockInitialValues({
        'current_tower_level': 18,
        'all_time_best_meters': 95.4,
        'infinite_tower_best_meters': 142.0,
        'player_leaderboard_name': 'MasterClimber',
        'selected_ball_skin_id': 'dragon_ember',
      });

      final storage = StorageService();
      await storage.init(attemptNetworkSync: false);

      // 1. Verifica caricamento immediato dei dati giocatore senza alcun reset
      expect(storage.currentTowerLevel, equals(18));
      expect(storage.allTimeBestMeters, equals(95.4));
      expect(storage.infiniteBestMeters, equals(142.0));
      expect(storage.playerName, equals('MasterClimber'));
      expect(storage.selectedBallSkinId, equals('dragon_ember'));

      // Giocare un livello precedente dalla Matrice (es. Livello 3 su 18 sbloccati) NON resetta currentTowerLevel!
      await storage.recordRunResult(
        mode: GameMode.levelProgression,
        playedLevel: 3,
        meters: 50.0,
        isVictory: true,
        consumeOfficialAttempt: false,
        bounces: 22,
      );
      expect(storage.currentTowerLevel, equals(18));

      final audio = AudioHapticsService()..soundEnabled = true;
      final monetization = MonetizationService();
      final game = InkSlingGame(
        storage: storage,
        audioHaptics: audio,
        monetization: monetization,
      );

      game.onGameResize(Vector2(400, 800));
      await game.onLoad();

      // 2. Volume singolo unificato (toggleVolume sincronizza sound, master e musica)
      expect(game.soundNotifier.value, isTrue);
      await game.toggleVolume();
      expect(game.soundNotifier.value, isFalse);
      expect(game.masterAudioNotifier.value, isFalse);
      expect(game.musicNotifier.value, isFalse);
      expect(storage.soundEnabled, isFalse);

      // 3. Modalità Torre Infinita (+1 nuovo ostacolo ogni 50m e streaming infinito)
      expect(DailySeedEngine.getInfiniteObstacleTier(10.0), equals(1));
      expect(DailySeedEngine.getInfiniteObstacleTier(55.0), equals(2));
      expect(DailySeedEngine.getInfiniteObstacleTier(105.0), equals(3));
      expect(DailySeedEngine.getInfiniteObstacleTier(160.0), equals(4));
      expect(DailySeedEngine.getInfiniteObstacleTier(210.0), equals(5));
      expect(DailySeedEngine.getInfiniteObstacleTier(260.0), equals(6));

      game.startRun(mode: GameMode.infiniteTower);
      expect(game.activeMode, equals(GameMode.infiniteTower));
      expect(game.isPlaying, isTrue);

      // Simula salita a 180m: il generatore deve estendere automaticamente la torre oltre i 220m iniziali
      game.player.stuckPlatform = null;
      game.player.position.setValues(0.0, -180.0 * DailySeedEngine.metersToPixels);
      game.player.prevPosition.setFrom(game.player.position);
      game.update(0.016);
      expect(game.maxMetersReached, closeTo(180.0, 1.0));

      await game.triggerGameOver(victory: false);
      expect(storage.infiniteBestMeters, closeTo(180.0, 1.0));
      expect(storage.currentTowerLevel, equals(18));
    });
  });
}

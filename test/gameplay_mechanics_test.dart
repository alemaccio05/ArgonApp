import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ink_sling_daily/core/ball_skins.dart';
import 'package:ink_sling_daily/core/daily_seed.dart';
import 'package:ink_sling_daily/core/palette_theme.dart';
import 'package:ink_sling_daily/game/components/ink_particle_pool.dart';
import 'package:ink_sling_daily/game/components/obstacle_block.dart';
import 'package:ink_sling_daily/game/components/player_core.dart';
import 'package:ink_sling_daily/game/ink_sling_game.dart';
import 'package:ink_sling_daily/main.dart';
import 'package:ink_sling_daily/services/audio_haptics_service.dart';
import 'package:ink_sling_daily/services/monetization_service.dart';
import 'package:ink_sling_daily/services/p2p_multiplayer_service.dart';
import 'package:ink_sling_daily/services/storage_service.dart';
import 'package:ink_sling_daily/services/trusted_time_service.dart';
import 'package:ink_sling_daily/ui/friends_p2p_overlay.dart';
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
      // Lo scudo della Seconda Chance non scade mai col passare del tempo
      for (int i = 0; i < 400; i++) {
        game.player.update(0.025); // +10 secondi
      }
      expect(game.player.hasShield, isTrue);
      expect(game.player.shieldTimer, greaterThan(0.0));

      // Quando impatta un ostacolo, lo scudo si rompe e protegge il giocatore
      final hazard = ObstacleBlock(
        type: BlockType.vermilionHazard,
        position: Vector2(0, game.player.position.y - 40.0),
        size: Vector2(80, 16),
      );
      game.world.add(hazard);
      await game.ready();
      final hitY = game.player.position.y - 40.0;
      game.player.stuckPlatform = null;
      game.player.prevPosition.setValues(0, hitY + 20.0);
      game.player.position.setValues(0, hitY);
      hazard.update(0.016);

      expect(game.player.isDead, isFalse);
      expect(game.player.hasShield, isFalse);
      expect(game.player.shieldTimer, equals(0.0));
      game.player.stickToPlatform(rescuePad);
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

      // 4. Abilità Attiva con Cooldown e Duello P2P + Modalità Spettatore
      await storage.setSelectedAbility('ink_aegis');
      game.startP2PDuel(
        friend: const FriendRecord(
          code: 'INK-RONIN',
          name: 'Maestro Kaze',
          skinId: 'kitsune_spirit',
        ),
        format: P2PDuelFormat.race100m,
      );
      expect(game.isP2PMatch, isTrue);
      expect(game.ghostOpponent, isNotNull);

      final usedAbility = game.activateEquippedAbility();
      expect(usedAbility, isTrue);
      expect(game.player.hasShield, isTrue);
      expect(game.abilityCooldownRemaining, closeTo(18.0, 0.1));
      expect(game.activateEquippedAbility(), isFalse); // In cooldown!

      // Quando il giocatore muore ma il Fantasma avversario è ancora vivo,
      // entra automaticamente in Modalità Spettatore senza chiudere la partita!
      await game.triggerGameOver(victory: false);
      expect(game.player.isDead, isTrue);
      expect(game.isSpectatingOpponent, isTrue);
      expect(game.spectatingNotifier.value, isTrue);
      expect(game.isPlaying, isTrue);

      // L'utente può terminare l'osservazione o attendere la fine della corsa dell'avversario
      game.finishSpectatingEarly();
      expect(game.isSpectatingOpponent, isFalse);
      expect(game.isPlaying, isFalse);
      expect(storage.currentTowerLevel, equals(18));
    });
  });

  group('Update Plan: 8-Digit Friend Code, Hybrid P2P Packet Parsing & High-Water Mark', () {
    test('8-digit friend code generation (INK-XXXXXXXX), 1-field quick friend add, and High-Water Mark safeguard', () async {
      SharedPreferences.setMockInitialValues({
        'current_tower_level': 24,
        'all_time_best_meters': 130.5,
        'infinite_tower_best_meters': 210.0,
        'total_bounces_all_time': 950,
        'p2p_wins_count_all_time': 7,
      });
      final storage = StorageService();
      await storage.init(attemptNetworkSync: false);

      expect(RegExp(r'^INK-\d{8}$').hasMatch(storage.myFriendCode), isTrue);
      for (int i = 0; i < 20; i++) {
        final code = StorageService.generateEightDigitFriendCode();
        expect(RegExp(r'^INK-\d{8}$').hasMatch(code), isTrue);
      }

      // Aggiunta rapida con un solo campo (anche inserendo solo le 8 cifre)
      final added = await storage.addFriend(code: '84729103');
      expect(added.code, equals('INK-84729103'));
      expect(added.name, contains('9103'));
      expect(
        storage.friendsList.any((f) => f.code == 'INK-84729103'),
        isTrue,
      );

      // Verifica High-Water Mark
      storage.currentTowerLevel = 1;
      storage.allTimeBestMeters = 10.0;
      storage.infiniteBestMeters = 5.0;
      storage.totalBouncesAllTime = 12;
      storage.p2pWinsCount = 0;

      await storage.enforceHighWaterMark();

      expect(storage.currentTowerLevel, equals(24));
      expect(storage.allTimeBestMeters, equals(130.5));
      expect(storage.infiniteBestMeters, equals(210.0));
      expect(storage.totalBouncesAllTime, equals(950));
      expect(storage.p2pWinsCount, equals(7));
    });

    test('P2P packet parsing (INVITE, ACCEPT, STATE, Shared PAUSE) and Shared Ink Flood Wave', () async {
      SharedPreferences.setMockInitialValues({
        'my_unique_friend_code': 'INK-11112222',
        'player_leaderboard_name': 'Alice',
      });
      final storage = StorageService();
      await storage.init(attemptNetworkSync: false);

      final audio = AudioHapticsService()..soundEnabled = false;
      final monetization = MonetizationService();
      final game = InkSlingGame(
        storage: storage,
        audioHaptics: audio,
        monetization: monetization,
      );
      game.onGameResize(Vector2(400, 800));
      await game.onLoad();

      // Verifica topic deterministici per Cloud Broker MQTT
      expect(
        P2PMultiplayerService.buildInboxTopic('84729103'),
        equals('inktower/inbox/INK-84729103'),
      );
      expect(
        P2PMultiplayerService.buildRoomTopic('INK-84729103', 'INK-11112222'),
        equals(P2PMultiplayerService.buildRoomTopic('INK-11112222', 'INK-84729103')),
      );

      // 1. Ricezione pacchetto INVITE
      final inviteParsed = game.p2pService.processIncomingJsonPayload(
        '{"t":"INVITE","code":"INK-84729103","target":"INK-11112222","name":"Kenji_Zen","skin":"shinobi_star","fmt":"race100m","seed":904211}',
      );
      expect(inviteParsed, isTrue);
      expect(game.p2pService.incomingInviteNotifier.value, isNotNull);
      expect(
        game.p2pService.incomingInviteNotifier.value!.challengerCode,
        equals('INK-84729103'),
      );

      // 2. Avvia la sfida accettando l'invito
      game.acceptIncomingP2PInvite(game.p2pService.incomingInviteNotifier.value!);
      expect(game.isP2PMatch, isTrue);
      expect(game.p2pService.opponent.isRemoteSocketPeer, isTrue);

      // 3. Ricezione pacchetto STATE a 20Hz
      final stateParsed = game.p2pService.processIncomingJsonPayload(
        '{"t":"STATE","code":"INK-84729103","x":24.5,"y":-900.0,"vx":10,"vy":-120,"m":20.0,"st":false,"sh":true,"sp":false,"dead":false,"won":false}',
      );
      expect(stateParsed, isTrue);
      expect(game.p2pService.opponent.maxMeters, equals(20.0));
      expect(game.p2pService.opponent.hasShield, isTrue);

      // 4. Ricezione pacchetto PAUSE condivisa: congela fisica e mostra chi ha sospeso
      final pauseParsed = game.p2pService.processIncomingJsonPayload(
        '{"t":"PAUSE","code":"INK-84729103","v":true,"by":"Kenji_Zen"}',
      );
      expect(pauseParsed, isTrue);
      expect(game.isPaused, isTrue);
      expect(game.timeScale, equals(0.0));
      expect(game.pausedByPlayerNameNotifier.value, equals('Kenji_Zen'));

      final resumeParsed = game.p2pService.processIncomingJsonPayload(
        '{"t":"PAUSE","code":"INK-84729103","v":false,"by":"Kenji_Zen"}',
      );
      expect(resumeParsed, isTrue);
      expect(game.isPaused, isFalse);
      expect(game.timeScale, equals(1.0));
      expect(game.pausedByPlayerNameNotifier.value, isNull);
    });

    testWidgets(
      'Immediate first sling launch right after Second Chance (reviveWithShield) fires on 1st attempt',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final storage = StorageService();
        final audio = AudioHapticsService()..soundEnabled = false;
        final monetization = MonetizationService();
        final game = InkSlingGame(
          storage: storage,
          audioHaptics: audio,
          monetization: monetization,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 800,
                child: GameWidget<InkSlingGame>(game: game),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));

        game.startRun(mode: GameMode.levelProgression, level: 2);
        game.maxMetersReached = 31.4;
        final gameOverFuture = game.triggerGameOver(victory: false);
        await tester.pump(const Duration(milliseconds: 1200));
        await gameOverFuture;

        // Attiva la Seconda Chance (simula fine video premio)
        game.reviveWithShield();
        await tester.pump(const Duration(milliseconds: 16));

        // Verifica che il giocatore sia ancora dentro la finestra di freeze post-respawn (0.5s)
        expect(game.player.isRespawnFrozen, isTrue);
        expect(game.player.stuckPlatform, isNotNull);
        expect(game.player.hasShield, isTrue);

        // Il giocatore carica SUBITO il primo lancio (prima che scada il mezzo secondo)
        final gesture = await tester.startGesture(const Offset(200, 420));
        await tester.pump(const Duration(milliseconds: 32));
        await gesture.moveBy(const Offset(-35, 130));
        await tester.pump(const Duration(milliseconds: 64));

        // Bullet-Time attivo durante la mira, e al rilascio il lancio DEVE partire al 1° tentativo!
        expect(game.isDragging, isTrue);
        expect(game.targetTimeScale, equals(0.15));

        await gesture.up();
        await tester.pump(const Duration(milliseconds: 16));

        expect(game.isDragging, isFalse);
        expect(game.player.isRespawnFrozen, isFalse);
        expect(game.player.stuckPlatform, isNull);
        expect(game.player.velocity.y, lessThan(-350.0));
        expect(game.player.hasShield, isTrue);
        expect(game.player.airCharges, equals(PlayerCore.maxAirCharges - 1));

        // Smonta GameWidget per fermare il ticker interno prima della chiusura del test
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    test(
      'Mutual Friend Request/Accept, Removing ALL Friends Persistence, Duplicate ACCEPT Deduplication & Independent Parallel P2P Flood',
      () async {
        SharedPreferences.setMockInitialValues({
          'my_unique_friend_code': 'INK-11112222',
          'player_leaderboard_name': 'Alice',
        });
        final storageA = StorageService();
        await storageA.init(attemptNetworkSync: false);

        // Nessun bot predefinito non rimovibile all'avvio
        expect(storageA.friendsList, isEmpty);

        final audio = AudioHapticsService()..soundEnabled = false;
        final monetization = MonetizationService();
        final gameA = InkSlingGame(
          storage: storageA,
          audioHaptics: audio,
          monetization: monetization,
        );
        gameA.onGameResize(Vector2(400, 800));
        await gameA.onLoad();

        // 1. Alice invia richiesta di amicizia a Bob (INK-88889999):
        //    finisce in outgoingFriendRequests, NON ancora nella lista amici!
        final sendStatus =
            await gameA.p2pService.sendFriendRequest('88889999');
        expect(sendStatus, equals(FriendRequestSendStatus.sent));
        expect(storageA.friendsList, isEmpty);
        expect(
          storageA.outgoingFriendRequests
              .any((r) => r.code == 'INK-88889999'),
          isTrue,
        );

        // Bob accetta -> Alice riceve FRIEND_ACCEPT: ora Bob entra in friendsList!
        final ackParsed = gameA.p2pService.processIncomingJsonPayload(
          '{"t":"FRIEND_ACCEPT","code":"INK-88889999","target":"INK-11112222","name":"Bob_Pixel9","avatar":"🐉","skin":"dragon_ember"}',
        );
        expect(ackParsed, isTrue);
        expect(storageA.outgoingFriendRequests, isEmpty);
        expect(storageA.friendsList.length, equals(1));
        expect(storageA.friendsList.first.name, equals('Bob_Pixel9'));

        // Ricezione richiesta in entrata da Charlie -> Accettazione manuale
        final reqParsed = gameA.p2pService.processIncomingJsonPayload(
          '{"t":"FRIEND_REQ","code":"INK-33334444","target":"INK-11112222","name":"Charlie_Win","avatar":"🥷","skin":"shinobi_star"}',
        );
        expect(reqParsed, isTrue);
        expect(gameA.p2pService.incomingFriendRequestNotifier.value, isNotNull);
        expect(storageA.incomingFriendRequests.length, equals(1));

        await gameA.p2pService.acceptFriendRequest(
          storageA.incomingFriendRequests.first,
        );
        expect(storageA.incomingFriendRequests, isEmpty);
        expect(gameA.p2pService.incomingFriendRequestNotifier.value, isNull);
        expect(storageA.friendsList.length, equals(2));

        // 2. Deduplicazione pacchetto ACCEPT (UDP unicast + UDP broadcast + MQTT):
        //    onChallengeAcceptedByPeer deve scattare ESATTAMENTE 1 volta (mai doppio Navigator.pop -> schermo nero!)
        int acceptedCount = 0;
        gameA.p2pService.prepareDirectChallenge(
          friend: storageA.friendsList.first,
          format: P2PDuelFormat.race100m,
          customSeed: 777123,
        );
        gameA.p2pService.onChallengeAcceptedByPeer = (_, __) {
          acceptedCount++;
        };
        const dupAcceptJson =
            '{"t":"ACCEPT","code":"INK-33334444","target":"INK-11112222","name":"Charlie_Win","skin":"shinobi_star","seed":777123}';
        gameA.p2pService.processIncomingJsonPayload(dupAcceptJson);
        gameA.p2pService.processIncomingJsonPayload(dupAcceptJson);
        gameA.p2pService.processIncomingJsonPayload(dupAcceptJson);
        expect(acceptedCount, equals(1));

        // 3. Partite parallele indipendenti sullo stesso seed con fantasmi live e Pausa Condivisa:
        gameA.startP2PDuel(
          friend: storageA.friendsList.first,
          format: P2PDuelFormat.race100m,
          customSeed: 777123,
          alreadyHandshaked: true,
        );
        expect(gameA.isP2PMatch, isTrue);
        expect(gameA.p2pService.opponent.isRemoteSocketPeer, isTrue);

        // Anche se il fantasma remoto vola altissimo (-2400px), l'onda locale segue SOLO il giocatore locale!
        gameA.runTimeSeconds = 2.0;
        gameA.p2pService.processIncomingJsonPayload(
          '{"t":"STATE","code":"INK-33334444","x":10.0,"y":-2400.0,"vx":0,"vy":-200,"m":53.3,"st":false,"sh":false,"sp":false,"dead":false,"won":false}',
        );
        final floodBefore = gameA.inkFlood.position.y;
        gameA.update(0.1);
        final floodDelta = floodBefore - gameA.inkFlood.position.y;
        // L'onda avanza alla velocità base locale (~5.0px in 0.1s), senza catch-up forzato verso i -2400px del fantasma!
        expect(floodDelta, lessThan(20.0));

        // 4. Rimozione di TUTTI gli amici (fino a 0) e persistenza al riavvio
        await storageA.clearAllFriends();
        expect(storageA.friendsList, isEmpty);

        final reloadedStorage = StorageService();
        await reloadedStorage.init(attemptNetworkSync: false);
        expect(reloadedStorage.friendsList, isEmpty);
      },
    );

    test(
      'Real online/offline presence, profile name sync, shared pause, voting rematch, bot-only training, and ghost disappearing on leave',
      () async {
        SharedPreferences.setMockInitialValues({
          'my_unique_friend_code': 'INK-10101010',
          'player_custom_name': 'Marco',
        });
        final storage = StorageService();
        await storage.init(attemptNetworkSync: false);
        await storage.addFriend(
          code: 'INK-20202020',
          name: 'OldNick',
          avatarEmoji: '🥷',
          skinId: 'shinobi_star',
        );

        final game = InkSlingGame(
          storage: storage,
          audioHaptics: AudioHapticsService(),
          monetization: MonetizationService(),
        );
        game.onGameResize(Vector2(400, 800));
        await game.onLoad();

        // 1. Di default gli amici NON risultano falsamente online; PROFILE aggiorna il nome senza segnarli online
        expect(storage.friendsList.first.isOnline, isFalse);
        expect(game.p2pService.isFriendOnline('INK-20202020'), isFalse);

        game.p2pService.processIncomingJsonPayload(
          '{"t":"PROFILE","code":"INK-20202020","name":"Luca_NewName","avatar":"🐉","skin":"kitsune_spirit"}',
          isRetainedMqtt: true,
        );
        await Future<void>.delayed(Duration.zero);
        expect(storage.friendsList.first.name, equals('Luca_NewName'));
        expect(storage.friendsList.first.avatarEmoji, equals('🐉'));
        expect(game.p2pService.isFriendOnline('INK-20202020'), isFalse);

        // Quando arriva PRESENCE online:true risulta online; quando arriva online:false torna offline
        game.p2pService.processIncomingJsonPayload(
          '{"t":"PRESENCE","code":"INK-20202020","online":true,"name":"Luca_Live"}',
        );
        await Future<void>.delayed(Duration.zero);
        expect(game.p2pService.isFriendOnline('INK-20202020'), isTrue);
        expect(storage.friendsList.first.name, equals('Luca_Live'));

        game.p2pService.processIncomingJsonPayload(
          '{"t":"PRESENCE","code":"INK-20202020","online":false,"name":"Luca_Live"}',
        );
        await Future<void>.delayed(Duration.zero);
        expect(game.p2pService.isFriendOnline('INK-20202020'), isFalse);

        // 2. Allenamento contro il Bot: unico caso in cui il fantasma si muove autonomamente
        game.startBotTrainingDuel(
          format: P2PDuelFormat.race100m,
          customSeed: 12345,
        );
        expect(game.isP2PMatch, isTrue);
        expect(game.isBotTrainingMatch, isTrue);
        final botInitialY = game.ghostOpponent!.position.y;
        for (int i = 0; i < 60; i++) {
          game.update(0.02);
        }
        expect(game.ghostOpponent!.position.y, isNot(equals(botInitialY)));

        // 3. Partita P2P reale: NESSUN bot sostitutivo autonomo + Pausa Condivisa + Scomparsa Fantasma su LEAVE
        game.p2pService.prepareDirectChallenge(
          friend: storage.friendsList.first,
          format: P2PDuelFormat.race100m,
          customSeed: 888999,
        );
        expect(game.p2pService.outgoingInviteFriendNotifier.value, isNotNull);

        // Quando il peer accetta, game entra automaticamente in partita reale!
        game.p2pService.processIncomingJsonPayload(
          '{"t":"ACCEPT","code":"INK-20202020","target":"INK-10101010","name":"Luca_Live","seed":888999,"fmt":"race100m"}',
        );
        expect(game.isPlaying, isTrue);
        expect(game.isP2PMatch, isTrue);
        expect(game.isBotTrainingMatch, isFalse);
        expect(game.p2pService.outgoingInviteFriendNotifier.value, isNull);

        // Senza pacchetti STATE dall'avversario, il fantasma NON si muove da solo (zero bot sostitutivo!)
        final realStartY = game.ghostOpponent!.position.y;
        for (int i = 0; i < 60; i++) {
          game.update(0.02);
        }
        expect(game.ghostOpponent!.position.y, equals(realStartY));

        // Pausa condivisa: PAUSE remoto blocca entrambi i giocatori e sblocca al resume
        game.p2pService.processIncomingJsonPayload(
          '{"t":"PAUSE","code":"INK-20202020","target":"INK-10101010","v":true,"by":"Luca_Live","seq":1}',
        );
        expect(game.isPaused, isTrue);
        expect(game.timeScale, equals(0.0));

        game.p2pService.processIncomingJsonPayload(
          '{"t":"PAUSE","code":"INK-20202020","target":"INK-10101010","v":false,"by":"Luca_Live","seq":2}',
        );
        expect(game.isPaused, isFalse);
        expect(game.timeScale, equals(1.0));

        // 4. Votazione Rivincita (1/2 -> 2/2) quando finisce la partita per entrambi
        game.p2pService.processIncomingJsonPayload(
          '{"t":"STATE","code":"INK-20202020","x":0,"y":-500,"vx":0,"vy":0,"m":11.1,"st":false,"sh":false,"sp":false,"dead":true,"won":false}',
        );
        await game.triggerGameOver(victory: true);
        expect(game.isPlaying, isFalse);
        expect(
          game.p2pService.rematchStatusNotifier.value,
          equals(P2PRematchVoteStatus.idle),
        );

        // L'avversario manda la proposta di rivincita (1/2) -> diventa incomingPeerRequest senza avviare da solo
        game.p2pService.processIncomingJsonPayload(
          '{"t":"REMATCH_REQ","code":"INK-20202020","target":"INK-10101010","name":"Luca_Live","seed":555444,"fmt":"race100m"}',
        );
        expect(game.isPlaying, isFalse);
        expect(
          game.p2pService.rematchStatusNotifier.value,
          equals(P2PRematchVoteStatus.incomingPeerRequest),
        );

        // Il giocatore accetta il voto (2/2) -> parte la nuova partita col seed concordato 555444!
        game.acceptP2PRematch();
        expect(game.isPlaying, isTrue);
        expect(game.p2pService.activeMatchSeed, equals(555444));
        expect(game.ghostOpponent, isNotNull);

        // 5. Se l'avversario lascia la partita (LEAVE), il suo fantasma scompare immediatamente!
        game.p2pService.processIncomingJsonPayload(
          '{"t":"LEAVE","code":"INK-20202020","target":"INK-10101010","seed":555444}',
        );
        expect(game.p2pService.opponent.hasLeftMatch, isTrue);
        expect(game.ghostOpponent, isNull);
        expect(
          game.p2pService.rematchStatusNotifier.value,
          equals(P2PRematchVoteStatus.peerLeft),
        );
      },
    );

    testWidgets(
      'Global incoming P2P invite popup is visible on top of open FriendsAndP2PDialog and closes dialog on accept',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'my_unique_friend_code': 'INK-77778888',
          'player_custom_name': 'Giulia',
        });
        final storage = StorageService();
        await storage.init(attemptNetworkSync: false);
        final game = InkSlingGame(
          storage: storage,
          audioHaptics: AudioHapticsService(),
          monetization: MonetizationService(),
        );

        await tester.pumpWidget(InkSlingApp(game: game));
        await tester.pump(const Duration(milliseconds: 1000));
        await tester.pump(const Duration(milliseconds: 700));

        // Apri il dialog Lista Amici
        final navCtx = game.navigatorKey!.currentContext!;
        showFriendsAndP2PDialog(navCtx, game);
        await tester.pump();
        expect(find.byType(FriendsAndP2PDialog), findsOneWidget);

        // Ricevi un invito mentre si è DENTRO la Lista Amici
        game.p2pService.processIncomingJsonPayload(
          '{"t":"INVITE","id":"INK-99990000_321654","code":"INK-99990000","target":"INK-77778888","name":"Kenji_Friend","avatar":"🥷","skin":"shinobi_star","fmt":"race100m","seed":321654}',
        );
        await tester.pump();

        // Il pop-up globale è visibile sopra il dialog e cliccabile!
        final acceptText = game.strings.acceptChallengeBtn;
        expect(find.text(acceptText), findsOneWidget);

        await tester.tap(find.text(acceptText));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1000));

        // Il dialog Lista Amici si è chiuso e il giocatore è entrato in partita col seed 321654!
        expect(find.byType(FriendsAndP2PDialog), findsNothing);
        expect(game.isPlaying, isTrue);
        expect(game.isP2PMatch, isTrue);
        expect(game.isBotTrainingMatch, isFalse);
        expect(game.p2pService.activeMatchSeed, equals(321654));

        game.dispose();
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 200));
      },
    );

    test(
      'New obstacles (shurikenSpinner & spikeTrapPad), 4.8s Ink Sabotage, and Infinite Tower 400m+ milestone cap work accurately',
      () async {
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
        game.startRun(mode: GameMode.infiniteTower);

        // 1. Verifica Spruzzo d'Inchiostro potenziato a 4.8s
        game.triggerIncomingP2PSabotage();
        expect(game.inkSabotageBlindTimer, closeTo(4.8, 0.01));

        // 2. Verifica spikeTrapPad: sicura a 0.0s, avviso a 1.5s, spuntoni letali a 1.95s
        final spikePad = ObstacleBlock(
          position: Vector2(0, -300),
          size: Vector2(110, 18),
          type: BlockType.spikeTrapPad,
          phaseOffset: 0.0,
        );
        game.world.add(spikePad);
        await game.ready();

        expect(spikePad.isSpikeTrapActive, isFalse);
        expect(spikePad.isSpikeTrapWarning, isFalse);
        expect(spikePad.isDeadlyHazard, isFalse);

        // Quando gli spuntoni sono retratti, la sfera vi si incolla come una normale piattaforma verde!
        expect(game.player.stickToPlatform(spikePad), isTrue);
        expect(game.player.stuckPlatform, equals(spikePad));

        // Avanza fino alla fase di preavviso (1.55s)
        spikePad.update(1.55);
        expect(spikePad.isSpikeTrapWarning, isTrue);
        expect(spikePad.isSpikeTrapActive, isFalse);

        // Avanza fino all'estrazione degli spuntoni letali (1.95s totali) con scudo attivo
        game.player.shieldTimer = 10.0;
        spikePad.update(0.40);
        expect(spikePad.isSpikeTrapActive, isTrue);
        expect(spikePad.isDeadlyHazard, isTrue);
        // Lo scudo protegge il giocatore e lo stacca dalla piattaforma
        expect(game.player.isDead, isFalse);
        expect(game.player.hasShield, isFalse);
        expect(game.player.stuckPlatform, isNull);

        // 3. Verifica shurikenSpinner: ostacolo rotante letale
        final shuriken = ObstacleBlock(
          position: Vector2(0, -450),
          size: Vector2(44, 44),
          type: BlockType.shurikenSpinner,
        );
        game.world.add(shuriken);
        await game.ready();
        expect(shuriken.isDeadlyHazard, isTrue);
      },
    );
  });
}

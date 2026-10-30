import 'package:flutter_test/flutter_test.dart';
import 'package:ink_sling_daily/core/app_strings.dart';
import 'package:ink_sling_daily/core/ball_skins.dart';
import 'package:ink_sling_daily/core/daily_seed.dart';
import 'package:ink_sling_daily/core/palette_theme.dart';
import 'package:ink_sling_daily/core/profile_icons.dart';
import 'package:ink_sling_daily/services/storage_service.dart';

void main() {
  test('DailySeedEngine generates deterministic seeds and valid receipt', () {
    final seed = DailySeedEngine.getTodaySeed();
    expect(seed, greaterThan(20250000));

    // Il Livello 3 deve generare sempre lo stesso identico seed per ogni giocatore
    final level3SeedA = DailySeedEngine.getLevelSeed(3);
    final level3SeedB = DailySeedEngine.getLevelSeed(3);
    final level4Seed = DailySeedEngine.getLevelSeed(4);
    expect(level3SeedA, equals(level3SeedB));
    expect(level3SeedA, isNot(equals(level4Seed)));

    final receipt = DailySeedEngine.buildShareReceipt(
      meters: 84.6,
      isVictory: false,
      bounces: 18,
      seconds: 29.4,
      attemptNumber: 1,
    );

    expect(receipt, contains('INK TOWER'));
    expect(receipt, contains('🟩🟩🟩🟩🟥'));
    expect(receipt, contains('84.6m'));
    expect(receipt, contains("Can you climb today's tower?"));
  });

  test('Level goal height grows by +10m every 10 levels starting from 50m', () {
    expect(DailySeedEngine.getLevelGoalMeters(1), equals(50.0));
    expect(DailySeedEngine.getLevelGoalMeters(10), equals(50.0));
    expect(DailySeedEngine.getLevelGoalMeters(11), equals(60.0));
    expect(DailySeedEngine.getLevelGoalMeters(20), equals(60.0));
    expect(DailySeedEngine.getLevelGoalMeters(21), equals(70.0));
    expect(DailySeedEngine.getLevelGoalMeters(30), equals(70.0));
  });

  test('Daily and Global Leaderboards sort by meters/level/percent/bounces and use realistic bounce counts', () {
    expect(DailySeedEngine.getWeeklySeed(), greaterThan(2025000));

    // Un'altezza di 81m su una torre da 90m (Liv. 42) richiede almeno 50+ rimbalzi realistici (mai 11!)
    final bouncesAt90m = DailySeedEngine.computeRealisticRivalBounces(
      metersClimbed: 81.0,
      difficultyLevel: 42,
      rivalIndex: 0,
    );
    expect(bouncesAt90m, greaterThanOrEqualTo(50));

    final daily = DailySeedEngine.getDailyLeaderboard(
      playerName: 'Tester',
      playerBestMetersToday: 92.5,
      playerBouncesToday: 44,
      completedToday: false,
    );
    expect(daily.any((e) => e.isCurrentUser && e.name == 'Tester' && e.bounces == 44), isTrue);
    for (int i = 0; i < daily.length - 1; i++) {
      final a = daily[i];
      final b = daily[i + 1];
      final validOrder = a.bestMeters > b.bestMeters ||
          (a.bestMeters == b.bestMeters && a.bounces <= b.bounces);
      expect(validOrder, isTrue);
    }

    // Quando il giocatore supera i bot della classifica (es. Livello 15 con 10 partite giocate),
    // conquista stabilmente il 1° posto (#1) senza subire rubber-banding sleale
    final globalWon = DailySeedEngine.getGlobalLeaderboard(
      playerName: 'Tester',
      playerLevel: 15,
      playerBestMeters: 10.0,
      playerBounces: 6,
      totalLevelsPlayed: 10,
    );
    expect(globalWon.first.isCurrentUser, isTrue);
    expect(globalWon.first.rank, equals(1));

    // In 10 partite giocate, l'incremento dei bot è compreso tra 1 e 3 livelli
    final globalStart = DailySeedEngine.getGlobalLeaderboard(
      playerName: 'Tester',
      playerLevel: 1,
      playerBestMeters: 0.0,
      totalLevelsPlayed: 0,
    );
    final topBotStart = globalStart.firstWhere((e) => !e.isCurrentUser);
    final topBotAfter10 = globalWon.firstWhere((e) => !e.isCurrentUser && e.name == topBotStart.name);
    final diff = topBotAfter10.level - topBotStart.level;
    expect(diff, greaterThanOrEqualTo(1));
    expect(diff, lessThanOrEqualTo(3));

    // Se il giocatore fa molti tentativi fallendo sullo stesso livello (es. Livello 1 o 3 con 150 tentativi),
    // i bot NON devono scappare via aumentando il divario!
    final globalManyFailedAttempts = DailySeedEngine.getGlobalLeaderboard(
      playerName: 'Tester',
      playerLevel: 1,
      playerBestMeters: 20.0,
      totalLevelsPlayed: 150,
    );
    final topBotAfter150Fails = globalManyFailedAttempts
        .firstWhere((e) => !e.isCurrentUser && e.name == topBotStart.name);
    expect(topBotAfter150Fails.level, equals(topBotStart.level));

    for (int i = 0; i < globalWon.length - 1; i++) {
      final a = globalWon[i];
      final b = globalWon[i + 1];
      final validOrder = a.level > b.level ||
          (a.level == b.level && a.progressPercent > b.progressPercent) ||
          (a.level == b.level &&
              a.progressPercent == b.progressPercent &&
              a.bounces <= b.bounces);
      expect(validOrder, isTrue);
    }
  });

  test('Multi-language support works across all 6 popular languages with clean tab labels', () {
    for (final lang in AppLanguage.values) {
      final s = AppStrings(lang);
      expect(s.subtitleClimbStick, isNotEmpty);
      expect(s.modeLevelsTab.contains('(1, 2, 3'), isFalse);
      expect(s.modeDailyTab(657).contains('#657'), isFalse);
      expect(s.leaderboardDailyBtn(3), contains('#3'));
      expect(s.leaderboardLevelsBtn(2), contains('#2'));
      expect(s.hudInfiniteBadge.contains('♾️'), isFalse);
      final infSub = s.motivatingSubtitle(
        meters: 42.0,
        targetMeters: 50.0,
        isVictory: false,
        isLevelMode: false,
        nextLevel: 2,
        isInfiniteMode: true,
        bestInfiniteMeters: 80.0,
      );
      expect(infSub.toLowerCase().contains('vetta'), isFalse);
    }
  });

  test('RisographPalette lookup and lerp work smoothly', () {
    final p = RisographPalette.fromId('washi_ivory');
    expect(p.name, equals('Sabbia'));
    expect(p.isDark, isFalse);

    final mid = RisographPalette.lerp(
      RisographPalette.washiIvory,
      RisographPalette.sumiCharcoal,
      0.5,
    );
    expect(mid.paperBg, isNotNull);
  });

  test('Daily leaderboard allows climbing by optimizing bounces upon completing 100m', () {
    // 1a scalata: completata con 60 rimbalzi -> piazzamento iniziale (dietro ai top bot a 100m)
    final run1 = DailySeedEngine.getDailyLeaderboard(
      playerName: 'Player1',
      playerBestMetersToday: 100.0,
      playerBouncesToday: 60,
      completedToday: true,
    );
    final rank1 = run1.firstWhere((e) => e.isCurrentUser).rank;
    expect(rank1, greaterThanOrEqualTo(2)); // Almeno 1 bot ha fatto meno di 60 rimbalzi

    // 2a scalata (usando un'altra vita): completata con 46 rimbalzi -> scala posizioni
    final run2 = DailySeedEngine.getDailyLeaderboard(
      playerName: 'Player1',
      playerBestMetersToday: 100.0,
      playerBouncesToday: 46,
      completedToday: true,
    );
    final rank2 = run2.firstWhere((e) => e.isCurrentUser).rank;
    expect(rank2, lessThan(rank1)); // Ha scalato la classifica!

    // 3a scalata perfetta: completata con 32 rimbalzi -> conquista il 1° posto (#1)
    final run3 = DailySeedEngine.getDailyLeaderboard(
      playerName: 'Player1',
      playerBestMetersToday: 100.0,
      playerBouncesToday: 32,
      completedToday: true,
    );
    final rank3 = run3.firstWhere((e) => e.isCurrentUser).rank;
    expect(rank3, equals(1)); // Primo posto conquistato con meno rimbalzi!
  });

  test('ProfileIconsCatalog has 12 unlockable icons with valid criteria', () {
    expect(ProfileIconsCatalog.allIcons.length, equals(12));

    final storage = StorageService();
    storage.currentTowerLevel = 15;
    storage.dailyTop3Count = 3;
    storage.dailyFirstPlaceCount = 1;
    storage.totalBouncesAllTime = 600;

    final defaultIcon = ProfileIconsCatalog.getById('ink_drop');
    expect(defaultIcon.isUnlocked(storage), isTrue);

    final lvl15Icon = ProfileIconsCatalog.getById('bamboo_guard');
    expect(lvl15Icon.isUnlocked(storage), isTrue);

    final lvl30Icon = ProfileIconsCatalog.getById('dragon_spirit');
    expect(lvl30Icon.isUnlocked(storage), isFalse);

    final top3Icon = ProfileIconsCatalog.getById('elite_silver');
    expect(top3Icon.isUnlocked(storage), isTrue);

    final firstPlaceIcon = ProfileIconsCatalog.getById('gold_crown');
    expect(firstPlaceIcon.isUnlocked(storage), isTrue);

    const s = AppStrings(AppLanguage.it);
    final title = ProfileIconsCatalog.getPlayerHonorTitle(storage, s);
    expect(title, contains('Campione del Giorno'));
  });

  test('BallSkinsCatalog has 10 unlockable skins with valid progression criteria', () {
    expect(BallSkinsCatalog.allSkins.length, equals(10));

    final storage = StorageService();
    storage.currentTowerLevel = 15;
    storage.dailyTop3Count = 3;
    storage.dailyFirstPlaceCount = 1;
    storage.totalBouncesAllTime = 800;

    // 1. Classic Ink (default) è sempre sbloccata
    final classic = BallSkinsCatalog.getById('classic_ink');
    expect(classic.isUnlocked(storage), isTrue);

    // 2. Matcha Zen (livello 3) sbloccata
    final matcha = BallSkinsCatalog.getById('matcha_zen');
    expect(matcha.isUnlocked(storage), isTrue);

    // 3. Origami (livello 15) sbloccata
    final origami = BallSkinsCatalog.getById('paper_origami');
    expect(origami.isUnlocked(storage), isTrue);

    // 4. Drago (livello 25) ancora bloccata
    final dragon = BallSkinsCatalog.getById('dragon_ember');
    expect(dragon.isUnlocked(storage), isFalse);

    // 5. Daily Silver (3x Top 3) sbloccata
    final silver = BallSkinsCatalog.getById('daily_silver');
    expect(silver.isUnlocked(storage), isTrue);

    // 6. Daily Gold (1x 1° Posto) sbloccata
    final gold = BallSkinsCatalog.getById('daily_gold');
    expect(gold.isUnlocked(storage), isTrue);

    // 7. Thunder Spark (750 rimbalzi) sbloccata
    final thunder = BallSkinsCatalog.getById('thunder_spark');
    expect(thunder.isUnlocked(storage), isTrue);
  });

  test('Default language is English across AppStrings and StorageService', () {
    expect(AppLanguage.fromCode(null), equals(AppLanguage.en));
    expect(AppLanguage.fromCode(''), equals(AppLanguage.en));
    expect(AppLanguage.fromCode('unknown'), equals(AppLanguage.en));

    final storage = StorageService();
    expect(storage.selectedLanguage, equals(AppLanguage.en));
    expect(storage.playerName, equals('Climber'));
  });
}
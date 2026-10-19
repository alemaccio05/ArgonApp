import 'package:flutter_test/flutter_test.dart';
import 'package:ink_sling_daily/core/app_strings.dart';
import 'package:ink_sling_daily/core/daily_seed.dart';
import 'package:ink_sling_daily/core/palette_theme.dart';

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
    expect(receipt, contains('Riesci a scalare la torre di oggi?'));
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

    final globalLow = DailySeedEngine.getGlobalLeaderboard(
      playerName: 'Tester',
      playerLevel: 1,
      playerBestMeters: 5.0,
      playerBounces: 8,
    );
    final lowestRivalAtStart = globalLow
        .where((e) => !e.isCurrentUser)
        .reduce((a, b) => a.level <= b.level ? a : b);

    // Quando il giocatore supera il rivale, il rivale sale di 1 livello
    final globalOvertake = DailySeedEngine.getGlobalLeaderboard(
      playerName: 'Tester',
      playerLevel: lowestRivalAtStart.level + 1,
      playerBestMeters: 10.0,
      playerBounces: 8,
    );
    final sameRivalAfter = globalOvertake.firstWhere(
      (e) => !e.isCurrentUser && e.name == lowestRivalAtStart.name,
    );
    expect(sameRivalAfter.level, equals(lowestRivalAtStart.level + 1));

    for (int i = 0; i < globalOvertake.length - 1; i++) {
      final a = globalOvertake[i];
      final b = globalOvertake[i + 1];
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
}

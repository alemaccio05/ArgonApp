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

  test('Daily and Global Leaderboards include current user and sort properly', () {
    final daily = DailySeedEngine.getDailyLeaderboard(
      playerName: 'Tester',
      playerBestMetersToday: 92.5,
      completedToday: false,
    );
    expect(daily.any((e) => e.isCurrentUser && e.name == 'Tester'), isTrue);

    final global = DailySeedEngine.getGlobalLeaderboard(
      playerName: 'Tester',
      playerLevel: 10,
      playerBestMeters: 45.0,
    );
    expect(global.any((e) => e.isCurrentUser && e.level == 10), isTrue);
  });

  test('Multi-language support works across all 6 popular languages', () {
    for (final lang in AppLanguage.values) {
      final s = AppStrings(lang);
      expect(s.subtitleClimbStick, isNotEmpty);
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

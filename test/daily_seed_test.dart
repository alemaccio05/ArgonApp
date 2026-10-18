import 'package:flutter_test/flutter_test.dart';
import 'package:ink_sling_daily/core/daily_seed.dart';
import 'package:ink_sling_daily/core/palette_theme.dart';

void main() {
  test('DailySeedEngine generates deterministic seed and valid receipt', () {
    final seed = DailySeedEngine.getTodaySeed();
    expect(seed, greaterThan(20250000));

    final receipt = DailySeedEngine.buildShareReceipt(
      meters: 84.6,
      isVictory: false,
      bounces: 18,
      seconds: 29.4,
      attemptNumber: 1,
    );

    expect(receipt, contains('DAILY SLING'));
    expect(receipt, contains('🟩🟩🟩🟩🟥'));
    expect(receipt, contains('84.6m'));
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

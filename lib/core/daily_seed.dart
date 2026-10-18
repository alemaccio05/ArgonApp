/// Gestisce il Seed Globale Giornaliero (uguale per tutti i giocatori nel mondo)
/// e la generazione del riepilogo condivisibile in stile Wordle.
class DailySeedEngine {
  static const double worldWidth = 400.0;
  static const double metersToPixels = 45.0; // 1 metro = 45px
  static const double goalMeters = 100.0;
  static const int maxOfficialAttemptsPerDay = 3;

  /// Seed intero basato sulla data UTC corrente (formato YYYYMMDD)
  static int getTodaySeed() {
    final now = DateTime.now().toUtc();
    return now.year * 10000 + now.month * 100 + now.day;
  }

  /// Numero progressivo della sfida giornaliera (es. Sfida #291)
  static int getIssueNumber() {
    final epoch = DateTime.utc(2025, 1, 1);
    return DateTime.now().toUtc().difference(epoch).inDays + 1;
  }

  /// Data formattata (es. "18/10/2026")
  static String getFormattedDate() {
    final now = DateTime.now();
    final d = now.day.toString().padLeft(2, '0');
    final m = now.month.toString().padLeft(2, '0');
    return '$d/$m/${now.year}';
  }

  /// Calcola un percentile stimato deterministico in base al metro raggiunto
  static int estimateTopPercentile(double meters, bool isVictory) {
    if (isVictory || meters >= 100.0) return 1;
    if (meters >= 90.0) return 3;
    if (meters >= 80.0) return 7;
    if (meters >= 70.0) return 14;
    if (meters >= 55.0) return 28;
    if (meters >= 40.0) return 45;
    if (meters >= 25.0) return 68;
    return 85;
  }

  /// Costruisce il testo condivisibile per TikTok / WhatsApp / X
  static String buildShareReceipt({
    required double meters,
    required bool isVictory,
    required int bounces,
    required double seconds,
    required int attemptNumber,
  }) {
    final issue = getIssueNumber();
    final topPct = estimateTopPercentile(meters, isVictory);
    final grid = StringBuffer();

    // 5 blocchi da 20 metri ciascuno (stile Wordle)
    for (int sector = 1; sector <= 5; sector++) {
      final top = sector * 20.0;
      if (meters >= top) {
        grid.write('🟩');
      } else if (meters >= top - 20.0) {
        grid.write(isVictory ? '🏆' : '🟥');
      } else {
        grid.write('⬜');
      }
    }

    final statusText = isVictory
        ? '🏆 100.0m COMPLETATA!'
        : '${meters.toStringAsFixed(1)}m / 100m (Top $topPct%)';

    return 'DAILY SLING #$issue 🎯\n'
        '$grid $statusText\n'
        '⚡ Sponde: $bounces | ⏱️ ${seconds.toStringAsFixed(1)}s | Tentativo #$attemptNumber\n'
        'Riesci a scalare la torre di oggi?';
  }
}

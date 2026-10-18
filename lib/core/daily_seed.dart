import 'dart:math';
import 'app_strings.dart';

enum GameMode { levelProgression, dailyTower }

class LeaderboardEntry {
  final int rank;
  final String name;
  final int level;
  final double bestMeters;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.level,
    required this.bestMeters,
    this.isCurrentUser = false,
  });
}

/// Gestisce sia il Seed Deterministico per i Livelli Infiniti (Livello 1, 2, 3... uguali per tutti)
/// sia il Seed Globale Giornaliero, oltre alle Classifiche (Livelli e Giornaliera) e alla condivisione.
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

  /// Seed 100% deterministico basato sul numero del livello (1, 2, 3, ... infinito).
  /// Garantisce che il Livello N sia identico per qualsiasi giocatore su qualsiasi dispositivo.
  static int getLevelSeed(int level) {
    final safeLevel = level < 1 ? 1 : level;
    int hash = safeLevel * 73856093;
    hash ^= (safeLevel * 19349663) << 7;
    hash ^= 0x5A17C39D;
    return hash & 0x7FFFFFFF;
  }

  /// Altezza traguardo del livello: parte da 50m e cresce di +10m ogni 10 livelli superati!
  /// Liv. 1-10: 50m | Liv. 11-20: 60m | Liv. 21-30: 70m | Liv. 31-40: 80m...
  static double getLevelGoalMeters(int level) {
    final safeLevel = level < 1 ? 1 : level;
    final tier = (safeLevel - 1) ~/ 10;
    return (50.0 + tier * 10.0).clamp(50.0, 300.0);
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

  /// Calcola un percentile stimato deterministico in base alla percentuale di completamento
  static int estimateTopPercentile(
    double meters,
    bool isVictory, {
    double targetMeters = goalMeters,
  }) {
    final pct = (meters / targetMeters) * 100.0;
    if (isVictory || pct >= 100.0) return 1;
    if (pct >= 90.0) return 3;
    if (pct >= 80.0) return 7;
    if (pct >= 70.0) return 14;
    if (pct >= 55.0) return 28;
    if (pct >= 40.0) return 45;
    if (pct >= 25.0) return 68;
    return 85;
  }

  /// Calcola un grado arcade (S+, S, A, B, C) per rendere il risultato più gratificante
  static String calculateRunGrade({
    required double meters,
    required double targetMeters,
    required bool isVictory,
    required double seconds,
  }) {
    if (isVictory) {
      if (seconds <= targetMeters * 0.32) return 'S+';
      if (seconds <= targetMeters * 0.45) return 'S';
      return 'A+';
    }
    final ratio = (meters / targetMeters).clamp(0.0, 1.0);
    if (ratio >= 0.85) return 'A';
    if (ratio >= 0.65) return 'B';
    if (ratio >= 0.40) return 'C';
    return 'D';
  }

  /// Genera la classifica globale dei livelli combinando i migliori scalatori
  /// con il record attuale del giocatore.
  static List<LeaderboardEntry> getGlobalLeaderboard({
    required String playerName,
    required int playerLevel,
    required double playerBestMeters,
  }) {
    final rivals = <Map<String, dynamic>>[
      {'name': 'KuroInk_99', 'level': 42, 'meters': 185.0},
      {'name': 'MarcoSling', 'level': 36, 'meters': 164.2},
      {'name': 'Yuki_Riso', 'level': 29, 'meters': 141.0},
      {'name': 'Alex Climber', 'level': 24, 'meters': 123.5},
      {'name': 'Sora_Stick', 'level': 19, 'meters': 107.8},
      {'name': 'Vale_04', 'level': 15, 'meters': 88.0},
      {'name': 'LeoBounce', 'level': 12, 'meters': 82.1},
      {'name': 'Mika_Zen', 'level': 9, 'meters': 71.5},
      {'name': 'Giulia_Up', 'level': 7, 'meters': 64.0},
      {'name': 'Nico_Jump', 'level': 5, 'meters': 58.0},
      {'name': 'Toma_Ink', 'level': 4, 'meters': 52.0},
      {'name': 'Samu_01', 'level': 3, 'meters': 47.4},
      {'name': 'Eli_Sling', 'level': 2, 'meters': 39.0},
      {'name': 'Rookie_Fox', 'level': 1, 'meters': 24.5},
    ];

    final all = <LeaderboardEntry>[
      for (final r in rivals)
        LeaderboardEntry(
          rank: 0,
          name: r['name'] as String,
          level: r['level'] as int,
          bestMeters: r['meters'] as double,
        ),
      LeaderboardEntry(
        rank: 0,
        name: playerName.trim().isEmpty ? 'Scalatore' : playerName.trim(),
        level: playerLevel,
        bestMeters: playerBestMeters,
        isCurrentUser: true,
      ),
    ];

    all.sort((a, b) {
      final lvlCmp = b.level.compareTo(a.level);
      if (lvlCmp != 0) return lvlCmp;
      return b.bestMeters.compareTo(a.bestMeters);
    });

    return [
      for (int i = 0; i < all.length; i++)
        LeaderboardEntry(
          rank: i + 1,
          name: all[i].name,
          level: all[i].level,
          bestMeters: all[i].bestMeters,
          isCurrentUser: all[i].isCurrentUser,
        ),
    ];
  }

  /// Genera la classifica giornaliera dedicata esclusivamente alla "Torre di Oggi" (100m),
  /// basata sul seed della data odierna.
  static List<LeaderboardEntry> getDailyLeaderboard({
    required String playerName,
    required double playerBestMetersToday,
    required bool completedToday,
  }) {
    final rng = Random(getTodaySeed() ^ 0x3F8A1);
    final names = [
      'KuroInk_99',
      'Yuki_Riso',
      'MarcoSling',
      'Sora_Stick',
      'Elena_Climbs',
      'Vale_04',
      'LeoBounce',
      'Mika_Zen',
      'Toma_Ink',
      'Giulia_Up',
      'Nico_Jump',
      'Samu_01',
    ];

    final all = <LeaderboardEntry>[];
    for (int i = 0; i < names.length; i++) {
      final completed = i < 3;
      final meters = completed
          ? 100.0
          : double.parse(
              (96.0 - i * 6.8 - rng.nextDouble() * 3.5).clamp(18.0, 98.5).toStringAsFixed(1),
            );
      all.add(
        LeaderboardEntry(
          rank: 0,
          name: names[i],
          level: completed ? 1 : 0,
          bestMeters: meters,
        ),
      );
    }

    all.add(
      LeaderboardEntry(
        rank: 0,
        name: playerName.trim().isEmpty ? 'Scalatore' : playerName.trim(),
        level: completedToday ? 1 : 0,
        bestMeters: completedToday ? 100.0 : playerBestMetersToday,
        isCurrentUser: true,
      ),
    );

    all.sort((a, b) => b.bestMeters.compareTo(a.bestMeters));

    return [
      for (int i = 0; i < all.length; i++)
        LeaderboardEntry(
          rank: i + 1,
          name: all[i].name,
          level: all[i].level,
          bestMeters: all[i].bestMeters,
          isCurrentUser: all[i].isCurrentUser,
        ),
    ];
  }

  /// Costruisce il testo condivisibile per TikTok / WhatsApp / X.
  /// Nota: Il messaggio finale di sfida compare SOLO qui quando il giocatore condivide il risultato!
  static String buildShareReceipt({
    required double meters,
    double targetMeters = goalMeters,
    required bool isVictory,
    required int bounces,
    required double seconds,
    required int attemptNumber,
    GameMode mode = GameMode.dailyTower,
    int level = 1,
    AppLanguage lang = AppLanguage.it,
  }) {
    final strings = AppStrings(lang);
    final issue = getIssueNumber();
    final topPct = estimateTopPercentile(
      meters,
      isVictory,
      targetMeters: targetMeters,
    );
    final grid = StringBuffer();
    final sectorSize = targetMeters / 5.0;

    // 5 blocchi proporzionali (stile Wordle)
    for (int sector = 1; sector <= 5; sector++) {
      final top = sector * sectorSize;
      if (meters >= top) {
        grid.write('🟩');
      } else if (meters >= top - sectorSize) {
        grid.write(isVictory ? '🏆' : '🟥');
      } else {
        grid.write('⬜');
      }
    }

    final header = mode == GameMode.levelProgression
        ? 'INK TOWER • ${strings.levelShort} $level 🎯'
        : 'INK TOWER • #$issue 🎯';

    final statusText = isVictory
        ? '🏆 ${targetMeters.toStringAsFixed(0)}m!'
        : '${meters.toStringAsFixed(1)}m / ${targetMeters.toStringAsFixed(0)}m (Top $topPct%)';

    return '$header\n'
        '$grid $statusText\n'
        '⚡ ${strings.bouncesLabel}: $bounces | ⏱️ ${seconds.toStringAsFixed(1)}s | #$attemptNumber\n'
        '${strings.shareChallengeFooter}';
  }
}

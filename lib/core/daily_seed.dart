import 'dart:math';
import 'app_strings.dart';

enum GameMode { levelProgression, dailyTower }

class LeaderboardEntry {
  final int rank;
  final String name;
  final int level;
  final double bestMeters;
  final int progressPercent;
  final int bounces;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.level,
    required this.bestMeters,
    this.progressPercent = 0,
    this.bounces = 0,
    this.isCurrentUser = false,
  });
}

/// Gestisce sia il Seed Deterministico per i Livelli Infiniti (Livello 1, 2, 3... uguali per tutti)
/// sia il Seed Globale Giornaliero, oltre alle Classifiche (Livelli e Giornaliera 24h) e alla condivisione.
class DailySeedEngine {
  static const double worldWidth = 400.0;
  static const double metersToPixels = 45.0; // 1 metro = 45px
  static const double goalMeters = 100.0;
  static const int maxOfficialAttemptsPerDay = 3;

  /// Pool ampio di sfidanti per la rotazione giornaliera (24h) della Torre di Oggi
  static const List<String> _dailyChallengerPool = [
    'Alex_V',
    'Matteo_98',
    'Sofia_Climb',
    'Lukas_K',
    'Emma_Sling',
    'Diego_R',
    'Chloe_Up',
    'Noah_Zen',
    'Liam_77',
    'Giulia_M',
    'Hugo_Paris',
    'Mila_T',
    'Leo_Jump',
    'Zoe_Berlin',
    'Gabriel_BR',
    'Ren_Tokyo',
    'Clara_ES',
    'Samu_04',
    'Nina_Peak',
    'Oscar_W',
    'Aria_Sky',
    'Pietro_X',
    'Eva_Moon',
    'Toma_88',
    'Klara_S',
    'Nico_Drop',
    'Maya_Lin',
    'Victor_H',
    'Sara_Vibe',
    'Dario_G',
    'Hana_K',
    'Max_Vert',
    'Iris_Blue',
    'Enzo_99',
    'Lola_Run',
    'Felix_A',
    'Alice_W',
    'Bruno_M',
    'Nora_J',
    'Elias_P',
    'Camilla_R',
    'David_S',
    'Elena_V',
    'Marco_T',
    'Yuki_N',
    'Sora_H',
    'Kuro_7',
    'Vale_11',
  ];

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

  /// Data formattata (es. "19/10/2026")
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

  /// Seed deterministico che ruota ogni 7 giorni (settimanale) per rinnovare gli sfidanti della Scalata Livelli
  static int getWeeklySeed() {
    final epoch = DateTime.utc(2025, 1, 1);
    final daysSinceEpoch = DateTime.now().toUtc().difference(epoch).inDays;
    final weekIndex = daysSinceEpoch ~/ 7;
    return 2025000 + weekIndex;
  }

  /// Calcola un numero di rimbalzi fisicamente realistico e leggermente meno efficiente del giocatore:
  /// - In media una torre ha piattaforme ogni ~4.2m + rimbalzi sulle pareti laterali e riposizionamenti.
  /// - Per scalare `metersClimbed` metri, uno sfidante impiega circa 0.56–0.76 rimbalzi per metro
  ///   (es. ~32-38 rimbalzi per 50m, ~55-68 rimbalzi per 90m), aumentando con la difficoltà del livello.
  static int computeRealisticRivalBounces({
    required double metersClimbed,
    required int difficultyLevel,
    required int rivalIndex,
  }) {
    if (metersClimbed <= 0.0) return 0;
    final levelExtra = (difficultyLevel.clamp(1, 50) - 1) * 0.0045;
    final clumsiness = (rivalIndex % 5) * 0.028;
    final bouncesPerMeter = 0.56 + levelExtra + clumsiness;
    return max(5, (metersClimbed * bouncesPerMeter).round() + 3);
  }

  /// Genera la classifica della progressione livelli.
  /// - Gli sfidanti cambiano automaticamente ogni 7 giorni (`getWeeklySeed()`).
  /// - I livelli iniziali degli sfidanti sono accessibili (Liv. 1..14) e i loro rimbalzi sono
  ///   proporzionati ai metri scalati e un po' più alti del normale, così il giocatore può superarli con soddisfazione.
  /// - Valuta con priorità: 1) Livello -> 2) Percentuale -> 3) Minor numero di rimbalzi.
  /// - Il livello di uno sfidante aumenta SOLO quando il giocatore riesce a superarlo.
  static List<LeaderboardEntry> getGlobalLeaderboard({
    required String playerName,
    required int playerLevel,
    required double playerBestMeters,
    int playerBounces = 0,
  }) {
    final playerGoal = getLevelGoalMeters(playerLevel);
    final playerPct =
        ((playerBestMeters / playerGoal) * 100.0).round().clamp(0, 100);
    final effectivePlayerBounces = playerBounces > 0
        ? playerBounces
        : (playerBestMeters > 0
            ? max(4, (playerBestMeters * 0.48).round())
            : 0);

    // Seleziona 12 sfidanti che ruotano ogni 7 giorni
    final weekSeed = getWeeklySeed();
    final rng = Random(weekSeed ^ 0x4F2A8D);
    final indices = List<int>.generate(_dailyChallengerPool.length, (i) => i);
    for (int i = indices.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final tmp = indices[i];
      indices[i] = indices[j];
      indices[j] = tmp;
    }

    // Livelli base accessibili (dal Liv. 12 giù fino al Liv. 1) con percentuali moderate
    // per permettere al giocatore di scalare la classifica con facilità e gratificazione!
    const baseLevels = [12, 10, 9, 7, 6, 5, 4, 3, 3, 2, 1, 1];
    const basePcts = [74, 68, 64, 60, 56, 52, 48, 44, 38, 34, 28, 22];
    const maxBoosts = [999, 3, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1];

    bool isOvertaken(int rLevel, int rPct, int rBounces) {
      if (playerLevel != rLevel) return playerLevel > rLevel;
      if (playerPct != rPct) return playerPct > rPct;
      if (playerPct == 0 || effectivePlayerBounces == 0) return false;
      return effectivePlayerBounces < rBounces;
    }

    final all = <LeaderboardEntry>[];
    for (int i = 0; i < 12; i++) {
      final rName = _dailyChallengerPool[indices[i]];
      int rLevel = baseLevels[i];
      int rPct = (basePcts[i] + (rng.nextInt(7) - 3)).clamp(18, 82);
      final maxBoost = maxBoosts[i];

      double rGoal = getLevelGoalMeters(rLevel);
      double rMeters =
          double.parse(((rPct / 100.0) * rGoal).toStringAsFixed(1));
      int rBounces = computeRealisticRivalBounces(
        metersClimbed: rMeters,
        difficultyLevel: rLevel,
        rivalIndex: i,
      );

      int boostsUsed = 0;
      while (boostsUsed < maxBoost && isOvertaken(rLevel, rPct, rBounces)) {
        rLevel += 1;
        boostsUsed += 1;
        // Sul nuovo livello lo sfidante si ferma a una percentuale bassa/media (22%..52%)
        // così il giocatore può risuperarlo facilmente!
        rPct = 22 + ((i * 9 + boostsUsed * 13 + weekSeed) % 31);
        rGoal = getLevelGoalMeters(rLevel);
        rMeters = double.parse(((rPct / 100.0) * rGoal).toStringAsFixed(1));
        rBounces = computeRealisticRivalBounces(
          metersClimbed: rMeters,
          difficultyLevel: rLevel,
          rivalIndex: i + boostsUsed,
        );
      }

      all.add(
        LeaderboardEntry(
          rank: 0,
          name: rName,
          level: rLevel,
          bestMeters: rMeters,
          progressPercent: rPct,
          bounces: rBounces,
        ),
      );
    }

    all.add(
      LeaderboardEntry(
        rank: 0,
        name: playerName.trim().isEmpty ? 'Scalatore' : playerName.trim(),
        level: playerLevel,
        bestMeters: playerBestMeters,
        progressPercent: playerPct,
        bounces: effectivePlayerBounces,
        isCurrentUser: true,
      ),
    );

    // Ordine rigoroso: 1) Livello (decrescente) -> 2) Percentuale (decrescente) -> 3) Rimbalzi (crescente)
    all.sort((a, b) {
      final lvlCmp = b.level.compareTo(a.level);
      if (lvlCmp != 0) return lvlCmp;

      final pctCmp = b.progressPercent.compareTo(a.progressPercent);
      if (pctCmp != 0) return pctCmp;

      if (a.bounces == 0 && b.bounces > 0) return 1;
      if (b.bounces == 0 && a.bounces > 0) return -1;
      final bncCmp = a.bounces.compareTo(b.bounces);
      if (bncCmp != 0) return bncCmp;

      return b.bestMeters.compareTo(a.bestMeters);
    });

    return [
      for (int i = 0; i < all.length; i++)
        LeaderboardEntry(
          rank: i + 1,
          name: all[i].name,
          level: all[i].level,
          bestMeters: all[i].bestMeters,
          progressPercent: all[i].progressPercent,
          bounces: all[i].bounces,
          isCurrentUser: all[i].isCurrentUser,
        ),
    ];
  }

  /// Genera la classifica giornaliera (durata 24 ore) dedicata alla "Torre di Oggi" (100m):
  /// - Ogni 24 ore seleziona sfidanti differenti basati sul seed della data odierna.
  /// - Le altezze raggiunte dagli sfidanti (16m..78m) e i loro rimbalzi sono coerenti con la difficoltà
  ///   della Torre di Oggi (100m), permettendo al giocatore di scalare la classifica e puntare al 1° posto!
  static List<LeaderboardEntry> getDailyLeaderboard({
    required String playerName,
    required double playerBestMetersToday,
    required bool completedToday,
    int playerBouncesToday = 0,
  }) {
    final seed = getTodaySeed();
    final rng = Random(seed ^ 0x7A3B91);

    // Seleziona 12 sfidanti diversi ogni 24 ore mescolando il pool con il seed del giorno
    final indices = List<int>.generate(_dailyChallengerPool.length, (i) => i);
    for (int i = indices.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final tmp = indices[i];
      indices[i] = indices[j];
      indices[j] = tmp;
    }
    final dailyNames = [
      for (int i = 0; i < 12; i++) _dailyChallengerPool[indices[i]],
    ];

    final all = <LeaderboardEntry>[];
    for (int i = 0; i < dailyNames.length; i++) {
      // Nella Torre di Oggi (100m a difficoltà crescente) gli sfidanti si fermano
      // ad altezze battibili (tra ~16m e ~78m), con rimbalzi realistici (es. ~48-55 rimbalzi per 75m).
      final meters = double.parse(
        (76.5 - i * 5.2 - rng.nextDouble() * 3.2)
            .clamp(14.5, 79.5)
            .toStringAsFixed(1),
      );
      final pct = meters.round().clamp(0, 100);
      final effectiveDifficultyAtHeight = (1 + (meters / 15.0).floor()).clamp(1, 7);
      final bounces = computeRealisticRivalBounces(
        metersClimbed: meters,
        difficultyLevel: effectiveDifficultyAtHeight,
        rivalIndex: i + 2,
      );

      all.add(
        LeaderboardEntry(
          rank: 0,
          name: dailyNames[i],
          level: 0,
          bestMeters: meters,
          progressPercent: pct,
          bounces: bounces,
        ),
      );
    }

    final effectiveMeters = completedToday ? 100.0 : playerBestMetersToday;
    final effectivePct = effectiveMeters.round().clamp(0, 100);
    final effectiveBounces = playerBouncesToday > 0
        ? playerBouncesToday
        : (effectiveMeters > 0
            ? max(4, (effectiveMeters * 0.48).round())
            : 0);

    all.add(
      LeaderboardEntry(
        rank: 0,
        name: playerName.trim().isEmpty ? 'Scalatore' : playerName.trim(),
        level: completedToday ? 1 : 0,
        bestMeters: effectiveMeters,
        progressPercent: effectivePct,
        bounces: effectiveBounces,
        isCurrentUser: true,
      ),
    );

    // Ordine Giornaliero: 1) Metri (decrescente) -> 2) Minor numero di rimbalzi (crescente)
    all.sort((a, b) {
      final mCmp = b.bestMeters.compareTo(a.bestMeters);
      if (mCmp != 0) return mCmp;

      if (a.bounces == 0 && b.bounces > 0) return 1;
      if (b.bounces == 0 && a.bounces > 0) return -1;
      return a.bounces.compareTo(b.bounces);
    });

    return [
      for (int i = 0; i < all.length; i++)
        LeaderboardEntry(
          rank: i + 1,
          name: all[i].name,
          level: all[i].level,
          bestMeters: all[i].bestMeters,
          progressPercent: all[i].progressPercent,
          bounces: all[i].bounces,
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
        : 'INK TOWER • ${getFormattedDate()} 🎯';

    final statusText = isVictory
        ? '🏆 ${targetMeters.toStringAsFixed(0)}m!'
        : '${meters.toStringAsFixed(1)}m / ${targetMeters.toStringAsFixed(0)}m (Top $topPct%)';

    return '$header\n'
        '$grid $statusText\n'
        '⚡ ${strings.bouncesLabel}: $bounces | ⏱️ ${seconds.toStringAsFixed(1)}s | #$attemptNumber\n'
        '${strings.shareChallengeFooter}';
  }
}

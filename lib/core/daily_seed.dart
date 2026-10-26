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
  final String avatarEmoji;

  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.level,
    required this.bestMeters,
    this.progressPercent = 0,
    this.bounces = 0,
    this.isCurrentUser = false,
    this.avatarEmoji = '💧',
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
  /// - I bot avanzano al proprio ritmo naturale in base alle partite giocate dal giocatore (`totalLevelsPlayed` vinti o persi):
  ///   ogni 4-8 partite un bot può avanzare di 1 livello (circa 1-3 livelli ogni 10 partite).
  /// - Non esiste più alcun rubber-banding sleale: se il giocatore supera il bot in vetta, CONQUISTA IL 1° POSTO (#1)!
  /// - Valuta con priorità: 1) Livello -> 2) Percentuale -> 3) Minor numero di rimbalzi.
  static List<LeaderboardEntry> getGlobalLeaderboard({
    required String playerName,
    required int playerLevel,
    required double playerBestMeters,
    int playerBounces = 0,
    int totalLevelsPlayed = 0,
    String playerAvatarEmoji = '💧',
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

    // Livelli base accessibili degli sfidanti all'inizio (dal Liv. 12 giù fino al Liv. 1)
    const baseLevels = [12, 10, 9, 7, 6, 5, 4, 3, 3, 2, 1, 1];
    const basePcts = [74, 68, 64, 60, 56, 52, 48, 44, 38, 34, 28, 22];

    final all = <LeaderboardEntry>[];
    for (int i = 0; i < 12; i++) {
      final rName = _dailyChallengerPool[indices[i]];

      // Cadenza naturale di ogni bot: avanza di 1 livello ogni 4..8 partite giocate dal giocatore (sia vinte che perse).
      // In un blocco di 1-10 partite, i bot incrementano di poco (es. 1 livello, massimo 2-3).
      final botCadence = 4 + ((i * 3 + weekSeed) % 5); // tra 4 e 8 partite per livello
      final levelIncrement = (totalLevelsPlayed / botCadence).floor();
      final rLevel = baseLevels[i] + levelIncrement;

      // La percentuale varia morbidamente con le partite giocate
      final pctVariation = ((totalLevelsPlayed * (i + 3) + i * 11 + weekSeed) % 21) - 10;
      final rPct = (basePcts[i] + pctVariation).clamp(15, 88);

      final rGoal = getLevelGoalMeters(rLevel);
      final rMeters =
          double.parse(((rPct / 100.0) * rGoal).toStringAsFixed(1));
      final rBounces = computeRealisticRivalBounces(
        metersClimbed: rMeters,
        difficultyLevel: rLevel,
        rivalIndex: i + levelIncrement,
      );

      const botAvatars = ['⚪', '🍃', '🥷', '🎋', '🕊️', '🐉', '⚡', '🖌️', '💧', '🥈', '🥉', '👑'];
      all.add(
        LeaderboardEntry(
          rank: 0,
          name: rName,
          level: rLevel,
          bestMeters: rMeters,
          progressPercent: rPct,
          bounces: rBounces,
          avatarEmoji: botAvatars[i % botAvatars.length],
        ),
      );
    }

    all.add(
      LeaderboardEntry(
        rank: 0,
        name: playerName.trim().isEmpty ? 'Climber' : playerName.trim(),
        level: playerLevel,
        bestMeters: playerBestMeters,
        progressPercent: playerPct,
        bounces: effectivePlayerBounces,
        isCurrentUser: true,
        avatarEmoji: playerAvatarEmoji,
      ),
    );

    // Ordine rigoroso: 1) Livello (decrescente) -> 2) Percentuale (decrescente) -> 3) Minor numero di rimbalzi (crescente)
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
          avatarEmoji: all[i].avatarEmoji,
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
    String playerAvatarEmoji = '💧',
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
      // Nella Torre di Oggi (100m a difficoltà crescente):
      // - I primi 2 sfidanti della giornata hanno completato la scalata (100m) con un ottimo numero di rimbalzi:
      //   Rival 0: ~39-44 rimbalzi (punteggio di vertice)
      //   Rival 1: ~48-53 rimbalzi (ottimo punteggio)
      // - Gli altri sfidanti si posizionano ad altezze realistiche tra 16m e 92m.
      // In questo modo il giocatore può completare la torre e poi usare i tentativi restanti
      // per ottimizzare i rimbalzi e scalare la vetta della classifica (#1)!
      double meters;
      int bounces;
      if (i == 0) {
        meters = 100.0;
        bounces = 39 + rng.nextInt(6);
      } else if (i == 1) {
        meters = 100.0;
        bounces = 48 + rng.nextInt(6);
      } else {
        meters = double.parse(
          (92.0 - (i - 2) * 6.5 - rng.nextDouble() * 3.8)
              .clamp(15.0, 93.5)
              .toStringAsFixed(1),
        );
        final effectiveDifficultyAtHeight =
            (1 + (meters / 15.0).floor()).clamp(1, 7);
        bounces = computeRealisticRivalBounces(
          metersClimbed: meters,
          difficultyLevel: effectiveDifficultyAtHeight,
          rivalIndex: i + 2,
        );
      }
      final pct = meters.round().clamp(0, 100);

      const botAvatars = ['⚪', '🍃', '🥷', '🎋', '🕊️', '🐉', '⚡', '🖌️', '💧', '🥈', '🥉', '👑'];
      all.add(
        LeaderboardEntry(
          rank: 0,
          name: dailyNames[i],
          level: meters >= 100.0 ? 1 : 0,
          bestMeters: meters,
          progressPercent: pct,
          bounces: bounces,
          avatarEmoji: botAvatars[i % botAvatars.length],
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
        name: playerName.trim().isEmpty ? 'Climber' : playerName.trim(),
        level: completedToday ? 1 : 0,
        bestMeters: effectiveMeters,
        progressPercent: effectivePct,
        bounces: effectiveBounces,
        isCurrentUser: true,
        avatarEmoji: playerAvatarEmoji,
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
          avatarEmoji: all[i].avatarEmoji,
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
    AppLanguage lang = AppLanguage.en,
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

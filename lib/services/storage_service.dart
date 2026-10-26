import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_strings.dart';
import '../core/daily_seed.dart';

/// Gestisce il salvataggio locale veloce di:
/// - Progressione infinita dei livelli (Livello 1, 2, 3...), record metri e rimbalzi sul livello attuale
/// - Nome giocatore per la Classifica
/// - Lingua selezionata (rilevata automaticamente dal dispositivo al primo avvio)
/// - Stato Audio ON/OFF
/// - Record giornaliero (metri e rimbalzi) sul seed di oggi (24h)
/// - Tentativi ("Vite") rimasti oggi
/// - Streak di giorni consecutivi giocati
/// - Palette Risograph selezionata
class StorageService {
  static const _keyLastPlayedSeed = 'last_played_seed';
  static const _keyBestMetersToday = 'best_meters_today';
  static const _keyBestBouncesToday = 'best_bounces_today';
  static const _keyCompletedToday = 'completed_today';
  static const _keyOfficialAttemptsLeft = 'official_attempts_left';
  static const _keyCurrentStreak = 'current_streak';
  static const _keyAllTimeBestMeters = 'all_time_best_meters';
  static const _keyPaletteId = 'selected_palette_id';
  static const _keyProUnlocked = 'pro_edition_unlocked';
  static const _keyCurrentTowerLevel = 'current_tower_level';
  static const _keyTotalLevelsPlayed = 'total_levels_played';
  static const _keyBestMetersCurrentLevel = 'best_meters_current_level';
  static const _keyBestBouncesCurrentLevel = 'best_bounces_current_level';
  static const _keyPlayerName = 'player_leaderboard_name';
  static const _keyLanguageCode = 'selected_language_code';
  static const _keySoundEnabled = 'sound_effects_enabled';

  // Statistiche Profilo Giocatore
  static const _keyTotalBouncesAllTime = 'total_bounces_all_time';
  static const _keyLevelFirstPlaceCount = 'level_first_place_count';
  static const _keyDailyFirstPlaceCount = 'daily_first_place_count';
  static const _keyDailyTop3Count = 'daily_top3_count';
  static const _keyTotalDailyTowersCompleted = 'total_daily_towers_completed';
  static const _keyTotalMetersClimbed = 'total_meters_climbed_all_time';
  static const _keyTotalRunsPlayed = 'total_runs_played_all_time';
  static const _keySelectedProfileIcon = 'selected_profile_icon_id';
  static const _keySelectedBallSkin = 'selected_ball_skin_id';
  static const _keyBestDailyRankAchievedToday = 'best_daily_rank_achieved_today';
  static const _keyLastRankAwardedSeed = 'last_rank_awarded_seed';
  static const _keyAwardedLevelFirstPlaces = 'awarded_level_first_places';

  SharedPreferences? _prefs;

  double bestMetersToday = 0.0;
  int bestBouncesToday = 0;
  bool completedToday = false;
  int officialAttemptsLeft = DailySeedEngine.maxOfficialAttemptsPerDay;
  int currentStreak = 1;
  double allTimeBestMeters = 0.0;
  String selectedPaletteId = 'washi_ivory';
  bool proUnlocked = false;

  // Progressione Livelli Infiniti & Classifica
  int currentTowerLevel = 1;
  int totalLevelsPlayed = 0;
  double bestMetersCurrentLevel = 0.0;
  int bestBouncesCurrentLevel = 0;
  String playerName = 'Climber';

  // Profilo Giocatore, Icone & Skin Sfera Sbloccabili
  int totalBouncesAllTime = 0;
  int levelFirstPlaceCount = 0;
  int dailyFirstPlaceCount = 0;
  int dailyTop3Count = 0;
  int totalDailyTowersCompleted = 0;
  double totalMetersClimbed = 0.0;
  int totalRunsPlayed = 0;
  String selectedProfileIconId = 'ink_drop';
  String selectedBallSkinId = 'classic_ink';
  int bestDailyRankAchievedToday = 999;
  int lastRankAwardedSeed = 0;
  List<String> awardedLevelFirstPlaces = [];

  // Lingua & Audio
  AppLanguage selectedLanguage = AppLanguage.en;
  bool soundEnabled = true;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final todaySeed = DailySeedEngine.getTodaySeed();
      final lastSeed = _prefs?.getInt(_keyLastPlayedSeed) ?? 0;

      selectedPaletteId = _prefs?.getString(_keyPaletteId) ?? 'washi_ivory';
      allTimeBestMeters = _prefs?.getDouble(_keyAllTimeBestMeters) ?? 0.0;
      proUnlocked = _prefs?.getBool(_keyProUnlocked) ?? false;
      currentStreak = _prefs?.getInt(_keyCurrentStreak) ?? 1;

      currentTowerLevel = _prefs?.getInt(_keyCurrentTowerLevel) ?? 1;
      totalLevelsPlayed = _prefs?.getInt(_keyTotalLevelsPlayed) ?? 0;
      bestMetersCurrentLevel =
          _prefs?.getDouble(_keyBestMetersCurrentLevel) ?? 0.0;
      bestBouncesCurrentLevel =
          _prefs?.getInt(_keyBestBouncesCurrentLevel) ?? 0;
      playerName = _prefs?.getString(_keyPlayerName) ?? 'Climber';

      final savedLang = _prefs?.getString(_keyLanguageCode);
      selectedLanguage = AppLanguage.fromCode(savedLang);
      soundEnabled = _prefs?.getBool(_keySoundEnabled) ?? true;

      // Caricamento Statistiche Profilo Giocatore
      totalBouncesAllTime = _prefs?.getInt(_keyTotalBouncesAllTime) ??
          (totalLevelsPlayed * 24);
      levelFirstPlaceCount = _prefs?.getInt(_keyLevelFirstPlaceCount) ??
          (currentTowerLevel > 14 ? currentTowerLevel - 13 : 0);
      dailyFirstPlaceCount =
          _prefs?.getInt(_keyDailyFirstPlaceCount) ?? (completedToday ? 1 : 0);
      dailyTop3Count =
          _prefs?.getInt(_keyDailyTop3Count) ?? (completedToday ? 1 : 0);
      totalDailyTowersCompleted = _prefs?.getInt(_keyTotalDailyTowersCompleted) ??
          (completedToday ? 1 : 0);
      totalMetersClimbed = _prefs?.getDouble(_keyTotalMetersClimbed) ??
          (allTimeBestMeters + totalLevelsPlayed * 35.0);
      totalRunsPlayed =
          _prefs?.getInt(_keyTotalRunsPlayed) ?? totalLevelsPlayed;
      selectedProfileIconId =
          _prefs?.getString(_keySelectedProfileIcon) ?? 'ink_drop';
      selectedBallSkinId =
          _prefs?.getString(_keySelectedBallSkin) ?? 'classic_ink';
      bestDailyRankAchievedToday =
          _prefs?.getInt(_keyBestDailyRankAchievedToday) ?? 999;
      lastRankAwardedSeed = _prefs?.getInt(_keyLastRankAwardedSeed) ?? 0;
      awardedLevelFirstPlaces =
          _prefs?.getStringList(_keyAwardedLevelFirstPlaces) ?? [];

      // Protezione anti-rollback data (ignora orologio spostato indietro nel tempo)
      if (lastSeed == 0 || todaySeed > lastSeed) {
        // Nuovo giorno (24h)! Controlliamo se era ieri per incrementare la Streak
        final yesterday = DateTime.now().toUtc().subtract(const Duration(days: 1));
        final yesterdaySeed =
            yesterday.year * 10000 + yesterday.month * 100 + yesterday.day;

        if (lastSeed == yesterdaySeed) {
          currentStreak += 1;
        } else if (lastSeed != 0) {
          currentStreak = 1;
        }

        bestMetersToday = 0.0;
        bestBouncesToday = 0;
        completedToday = false;
        officialAttemptsLeft = DailySeedEngine.maxOfficialAttemptsPerDay;
        bestDailyRankAchievedToday = 999;

        await _prefs?.setInt(_keyLastPlayedSeed, todaySeed);
        await _prefs?.setDouble(_keyBestMetersToday, 0.0);
        await _prefs?.setInt(_keyBestBouncesToday, 0);
        await _prefs?.setBool(_keyCompletedToday, false);
        await _prefs?.setInt(
            _keyOfficialAttemptsLeft, DailySeedEngine.maxOfficialAttemptsPerDay);
        await _prefs?.setInt(_keyCurrentStreak, currentStreak);
        await _prefs?.setInt(_keyBestDailyRankAchievedToday, 999);
      } else {
        // Stesso giorno o orologio spostato indietro nel tempo: mantiene i dati senza reset
        bestMetersToday = _prefs?.getDouble(_keyBestMetersToday) ?? 0.0;
        bestBouncesToday = _prefs?.getInt(_keyBestBouncesToday) ?? 0;
        completedToday = _prefs?.getBool(_keyCompletedToday) ?? false;
        officialAttemptsLeft = _prefs?.getInt(_keyOfficialAttemptsLeft) ??
            DailySeedEngine.maxOfficialAttemptsPerDay;
      }

      // Migration per reimpostare 3 vite pulite per testare la Torre di Oggi
      final hasAppliedLivesFix = _prefs?.getBool('lives_fix_v2') ?? false;
      if (!hasAppliedLivesFix) {
        officialAttemptsLeft = DailySeedEngine.maxOfficialAttemptsPerDay;
        await _prefs?.setInt(_keyOfficialAttemptsLeft, officialAttemptsLeft);
        await _prefs?.setBool('lives_fix_v2', true);
      }
    } catch (_) {
      // Fallback sicuro se SharedPreferences fallisce o ritarda
    }
  }

  /// Registra il risultato di una scalata (inclusi i rimbalzi) e restituisce true se è un nuovo record
  Future<bool> recordRunResult({
    required GameMode mode,
    required int playedLevel,
    required double meters,
    required bool isVictory,
    required bool consumeOfficialAttempt,
    int bounces = 0,
    bool isOfficialAttempt = true,
  }) async {
    bool isNewRecord = false;
    final safeBounces = bounces < 1 ? 1 : bounces;

    // Aggiornamento statistiche complessive del profilo
    totalBouncesAllTime += safeBounces;
    await _prefs?.setInt(_keyTotalBouncesAllTime, totalBouncesAllTime);

    totalMetersClimbed += meters;
    await _prefs?.setDouble(_keyTotalMetersClimbed, totalMetersClimbed);

    totalRunsPlayed += 1;
    await _prefs?.setInt(_keyTotalRunsPlayed, totalRunsPlayed);

    if (meters > allTimeBestMeters) {
      allTimeBestMeters = meters;
      await _prefs?.setDouble(_keyAllTimeBestMeters, allTimeBestMeters);
    }

    if (mode == GameMode.levelProgression) {
      totalLevelsPlayed += 1;
      await _prefs?.setInt(_keyTotalLevelsPlayed, totalLevelsPlayed);

      if (playedLevel == currentTowerLevel) {
        if (isVictory) {
          currentTowerLevel += 1;
          bestMetersCurrentLevel = 0.0;
          bestBouncesCurrentLevel = safeBounces;
          isNewRecord = true;
          await _prefs?.setInt(_keyCurrentTowerLevel, currentTowerLevel);
          await _prefs?.setDouble(_keyBestMetersCurrentLevel, 0.0);
          await _prefs?.setInt(
            _keyBestBouncesCurrentLevel,
            bestBouncesCurrentLevel,
          );
        } else {
          final isHigherMeters = meters > bestMetersCurrentLevel + 0.05;
          final isSameMetersFewerBounces =
              (meters - bestMetersCurrentLevel).abs() <= 0.05 &&
              meters > 0 &&
              (bestBouncesCurrentLevel == 0 ||
                  safeBounces < bestBouncesCurrentLevel);

          if (isHigherMeters || isSameMetersFewerBounces) {
            bestMetersCurrentLevel = meters;
            bestBouncesCurrentLevel = safeBounces;
            isNewRecord = true;
            await _prefs?.setDouble(
              _keyBestMetersCurrentLevel,
              bestMetersCurrentLevel,
            );
            await _prefs?.setInt(
              _keyBestBouncesCurrentLevel,
              bestBouncesCurrentLevel,
            );
          }
        }
      }

      final globalLeaderboard = DailySeedEngine.getGlobalLeaderboard(
        playerName: playerName,
        playerLevel: currentTowerLevel,
        playerBestMeters: bestMetersCurrentLevel,
        playerBounces: bestBouncesCurrentLevel,
        totalLevelsPlayed: totalLevelsPlayed,
      );
      final currentRank =
          globalLeaderboard.firstWhere((e) => e.isCurrentUser).rank;
      if (currentRank == 1) {
        final levelKey = '$currentTowerLevel';
        if (!awardedLevelFirstPlaces.contains(levelKey)) {
          awardedLevelFirstPlaces.add(levelKey);
          levelFirstPlaceCount = awardedLevelFirstPlaces.length;
          await _prefs?.setStringList(
              _keyAwardedLevelFirstPlaces, awardedLevelFirstPlaces);
          await _prefs?.setInt(
              _keyLevelFirstPlaceCount, levelFirstPlaceCount);
        }
      }

      return isNewRecord;
    }

    // Modalità Torre del Giorno (24h)
    if (consumeOfficialAttempt && officialAttemptsLeft > 0) {
      officialAttemptsLeft -= 1;
      await _prefs?.setInt(_keyOfficialAttemptsLeft, officialAttemptsLeft);
    }

    // Se la scalata era un allenamento libero (0 vite e nessun video visto),
    // non sovrascrive i record ufficiali né la classifica
    if (!isOfficialAttempt) {
      return false;
    }

    final effectiveMeters = isVictory ? DailySeedEngine.goalMeters : meters;
    final isHigherDaily = effectiveMeters > bestMetersToday + 0.05;
    final isSameDailyFewerBounces =
        (effectiveMeters - bestMetersToday).abs() <= 0.05 &&
        effectiveMeters > 0 &&
        (bestBouncesToday == 0 || safeBounces < bestBouncesToday);

    if (isHigherDaily || isSameDailyFewerBounces) {
      bestMetersToday = effectiveMeters;
      bestBouncesToday = safeBounces;
      isNewRecord = true;
      await _prefs?.setDouble(_keyBestMetersToday, bestMetersToday);
      await _prefs?.setInt(_keyBestBouncesToday, bestBouncesToday);
    }

    if (isVictory && !completedToday) {
      completedToday = true;
      await _prefs?.setBool(_keyCompletedToday, true);
    }

    if (isVictory) {
      totalDailyTowersCompleted += 1;
      await _prefs?.setInt(
          _keyTotalDailyTowersCompleted, totalDailyTowersCompleted);
    }

    final dailyLeaderboard = DailySeedEngine.getDailyLeaderboard(
      playerName: playerName,
      playerBestMetersToday: bestMetersToday,
      completedToday: completedToday,
      playerBouncesToday: bestBouncesToday,
    );
    final currentDailyRank =
        dailyLeaderboard.firstWhere((e) => e.isCurrentUser).rank;
    final todaySeed = DailySeedEngine.getTodaySeed();
    if (lastRankAwardedSeed != todaySeed) {
      lastRankAwardedSeed = todaySeed;
      bestDailyRankAchievedToday = currentDailyRank;
      if (currentDailyRank <= 3) {
        dailyTop3Count += 1;
        await _prefs?.setInt(_keyDailyTop3Count, dailyTop3Count);
      }
      if (currentDailyRank == 1) {
        dailyFirstPlaceCount += 1;
        await _prefs?.setInt(_keyDailyFirstPlaceCount, dailyFirstPlaceCount);
      }
      await _prefs?.setInt(_keyLastRankAwardedSeed, lastRankAwardedSeed);
      await _prefs?.setInt(
          _keyBestDailyRankAchievedToday, bestDailyRankAchievedToday);
    } else {
      if (currentDailyRank < bestDailyRankAchievedToday) {
        if (bestDailyRankAchievedToday > 3 && currentDailyRank <= 3) {
          dailyTop3Count += 1;
          await _prefs?.setInt(_keyDailyTop3Count, dailyTop3Count);
        }
        if (bestDailyRankAchievedToday > 1 && currentDailyRank == 1) {
          dailyFirstPlaceCount += 1;
          await _prefs?.setInt(_keyDailyFirstPlaceCount, dailyFirstPlaceCount);
        }
        bestDailyRankAchievedToday = currentDailyRank;
        await _prefs?.setInt(
            _keyBestDailyRankAchievedToday, bestDailyRankAchievedToday);
      }
    }

    return isNewRecord;
  }

  Future<void> setSelectedProfileIcon(String iconId) async {
    selectedProfileIconId = iconId;
    await _prefs?.setString(_keySelectedProfileIcon, selectedProfileIconId);
  }

  Future<void> setSelectedBallSkin(String skinId) async {
    selectedBallSkinId = skinId;
    await _prefs?.setString(_keySelectedBallSkin, selectedBallSkinId);
  }

  /// Aggiunge 1 vita extra oggi (es. dopo Rewarded Ad)
  Future<void> grantExtraOfficialAttempt() async {
    officialAttemptsLeft += 1;
    await _prefs?.setInt(_keyOfficialAttemptsLeft, officialAttemptsLeft);
  }

  Future<void> setPlayerName(String name) async {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return;
    playerName = cleaned;
    await _prefs?.setString(_keyPlayerName, playerName);
  }

  Future<void> setLanguage(AppLanguage lang) async {
    selectedLanguage = lang;
    await _prefs?.setString(_keyLanguageCode, lang.code);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    soundEnabled = enabled;
    await _prefs?.setBool(_keySoundEnabled, enabled);
  }

  Future<void> setPalette(String paletteId) async {
    selectedPaletteId = paletteId;
    await _prefs?.setString(_keyPaletteId, paletteId);
  }

  Future<void> unlockProEdition() async {
    proUnlocked = true;
    await _prefs?.setBool(_keyProUnlocked, true);
  }
}

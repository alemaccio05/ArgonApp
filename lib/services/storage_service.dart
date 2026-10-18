import 'package:shared_preferences/shared_preferences.dart';
import '../core/daily_seed.dart';

/// Gestisce il salvataggio locale veloce di:
/// - Record giornaliero sul seed di oggi
/// - Tentativi ufficiali ("Timbri") rimasti oggi
/// - Streak di giorni consecutivi giocati
/// - Palette Risograph selezionata
class StorageService {
  static const _keyLastPlayedSeed = 'last_played_seed';
  static const _keyBestMetersToday = 'best_meters_today';
  static const _keyCompletedToday = 'completed_today';
  static const _keyOfficialAttemptsLeft = 'official_attempts_left';
  static const _keyCurrentStreak = 'current_streak';
  static const _keyAllTimeBestMeters = 'all_time_best_meters';
  static const _keyPaletteId = 'selected_palette_id';
  static const _keyProUnlocked = 'pro_edition_unlocked';

  SharedPreferences? _prefs;

  double bestMetersToday = 0.0;
  bool completedToday = false;
  int officialAttemptsLeft = DailySeedEngine.maxOfficialAttemptsPerDay;
  int currentStreak = 1;
  double allTimeBestMeters = 0.0;
  String selectedPaletteId = 'washi_ivory';
  bool proUnlocked = false;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final todaySeed = DailySeedEngine.getTodaySeed();
    final lastSeed = _prefs?.getInt(_keyLastPlayedSeed) ?? 0;

    selectedPaletteId = _prefs?.getString(_keyPaletteId) ?? 'washi_ivory';
    allTimeBestMeters = _prefs?.getDouble(_keyAllTimeBestMeters) ?? 0.0;
    proUnlocked = _prefs?.getBool(_keyProUnlocked) ?? false;
    currentStreak = _prefs?.getInt(_keyCurrentStreak) ?? 1;

    if (lastSeed != todaySeed) {
      // Nuovo giorno! Controlliamo se era ieri per incrementare la Streak
      final yesterday = DateTime.now().toUtc().subtract(const Duration(days: 1));
      final yesterdaySeed =
          yesterday.year * 10000 + yesterday.month * 100 + yesterday.day;

      if (lastSeed == yesterdaySeed) {
        currentStreak += 1;
      } else if (lastSeed != 0) {
        currentStreak = 1;
      }

      bestMetersToday = 0.0;
      completedToday = false;
      officialAttemptsLeft = DailySeedEngine.maxOfficialAttemptsPerDay;

      await _prefs?.setInt(_keyLastPlayedSeed, todaySeed);
      await _prefs?.setDouble(_keyBestMetersToday, 0.0);
      await _prefs?.setBool(_keyCompletedToday, false);
      await _prefs?.setInt(
          _keyOfficialAttemptsLeft, DailySeedEngine.maxOfficialAttemptsPerDay);
      await _prefs?.setInt(_keyCurrentStreak, currentStreak);
    } else {
      bestMetersToday = _prefs?.getDouble(_keyBestMetersToday) ?? 0.0;
      completedToday = _prefs?.getBool(_keyCompletedToday) ?? false;
      officialAttemptsLeft = _prefs?.getInt(_keyOfficialAttemptsLeft) ??
          DailySeedEngine.maxOfficialAttemptsPerDay;
    }
  }

  /// Registra il risultato di una scalata e restituisce true se è un nuovo record giornaliero
  Future<bool> recordRunResult({
    required double meters,
    required bool isVictory,
    required bool consumeOfficialAttempt,
  }) async {
    bool isNewDailyRecord = false;

    if (consumeOfficialAttempt && officialAttemptsLeft > 0) {
      officialAttemptsLeft -= 1;
      await _prefs?.setInt(_keyOfficialAttemptsLeft, officialAttemptsLeft);
    }

    if (meters > bestMetersToday) {
      bestMetersToday = meters;
      isNewDailyRecord = true;
      await _prefs?.setDouble(_keyBestMetersToday, bestMetersToday);
    }

    if (meters > allTimeBestMeters) {
      allTimeBestMeters = meters;
      await _prefs?.setDouble(_keyAllTimeBestMeters, allTimeBestMeters);
    }

    if (isVictory && !completedToday) {
      completedToday = true;
      await _prefs?.setBool(_keyCompletedToday, true);
    }

    return isNewDailyRecord;
  }

  /// Aggiunge 1 tentativo ufficiale extra (es. dopo Rewarded Ad)
  Future<void> grantExtraOfficialAttempt() async {
    officialAttemptsLeft += 1;
    await _prefs?.setInt(_keyOfficialAttemptsLeft, officialAttemptsLeft);
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

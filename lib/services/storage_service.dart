import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_strings.dart';
import '../core/daily_seed.dart';

/// Gestisce il salvataggio locale veloce di:
/// - Progressione infinita dei livelli (Livello 1, 2, 3...) e record sul livello attuale
/// - Nome giocatore per la Classifica
/// - Lingua selezionata (rilevata automaticamente dal dispositivo al primo avvio)
/// - Stato Audio ON/OFF
/// - Record giornaliero sul seed di oggi
/// - Tentativi ("Vite") rimasti oggi
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
  static const _keyCurrentTowerLevel = 'current_tower_level';
  static const _keyBestMetersCurrentLevel = 'best_meters_current_level';
  static const _keyPlayerName = 'player_leaderboard_name';
  static const _keyLanguageCode = 'selected_language_code';
  static const _keySoundEnabled = 'sound_effects_enabled';

  SharedPreferences? _prefs;

  double bestMetersToday = 0.0;
  bool completedToday = false;
  int officialAttemptsLeft = DailySeedEngine.maxOfficialAttemptsPerDay;
  int currentStreak = 1;
  double allTimeBestMeters = 0.0;
  String selectedPaletteId = 'washi_ivory';
  bool proUnlocked = false;

  // Progressione Livelli Infiniti & Classifica
  int currentTowerLevel = 1;
  double bestMetersCurrentLevel = 0.0;
  String playerName = 'Scalatore';

  // Lingua & Audio
  AppLanguage selectedLanguage = AppLanguage.it;
  bool soundEnabled = true;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final todaySeed = DailySeedEngine.getTodaySeed();
    final lastSeed = _prefs?.getInt(_keyLastPlayedSeed) ?? 0;

    selectedPaletteId = _prefs?.getString(_keyPaletteId) ?? 'washi_ivory';
    allTimeBestMeters = _prefs?.getDouble(_keyAllTimeBestMeters) ?? 0.0;
    proUnlocked = _prefs?.getBool(_keyProUnlocked) ?? false;
    currentStreak = _prefs?.getInt(_keyCurrentStreak) ?? 1;

    currentTowerLevel = _prefs?.getInt(_keyCurrentTowerLevel) ?? 1;
    bestMetersCurrentLevel =
        _prefs?.getDouble(_keyBestMetersCurrentLevel) ?? 0.0;
    playerName = _prefs?.getString(_keyPlayerName) ?? 'Scalatore';

    final savedLang = _prefs?.getString(_keyLanguageCode);
    selectedLanguage = AppLanguage.fromCode(savedLang);
    soundEnabled = _prefs?.getBool(_keySoundEnabled) ?? true;

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

  /// Registra il risultato di una scalata e restituisce true se è un nuovo record
  Future<bool> recordRunResult({
    required GameMode mode,
    required int playedLevel,
    required double meters,
    required bool isVictory,
    required bool consumeOfficialAttempt,
  }) async {
    bool isNewRecord = false;

    if (meters > allTimeBestMeters) {
      allTimeBestMeters = meters;
      await _prefs?.setDouble(_keyAllTimeBestMeters, allTimeBestMeters);
    }

    if (mode == GameMode.levelProgression) {
      if (playedLevel == currentTowerLevel) {
        if (isVictory) {
          currentTowerLevel += 1;
          bestMetersCurrentLevel = 0.0;
          isNewRecord = true;
          await _prefs?.setInt(_keyCurrentTowerLevel, currentTowerLevel);
          await _prefs?.setDouble(_keyBestMetersCurrentLevel, 0.0);
        } else if (meters > bestMetersCurrentLevel) {
          bestMetersCurrentLevel = meters;
          isNewRecord = true;
          await _prefs?.setDouble(
            _keyBestMetersCurrentLevel,
            bestMetersCurrentLevel,
          );
        }
      }
      return isNewRecord;
    }

    // Modalità Torre del Giorno
    if (consumeOfficialAttempt && officialAttemptsLeft > 0) {
      officialAttemptsLeft -= 1;
      await _prefs?.setInt(_keyOfficialAttemptsLeft, officialAttemptsLeft);
    }

    if (meters > bestMetersToday) {
      bestMetersToday = meters;
      isNewRecord = true;
      await _prefs?.setDouble(_keyBestMetersToday, bestMetersToday);
    }

    if (isVictory && !completedToday) {
      completedToday = true;
      await _prefs?.setBool(_keyCompletedToday, true);
    }

    return isNewRecord;
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

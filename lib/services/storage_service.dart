import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_strings.dart';
import '../core/daily_seed.dart';
import 'trusted_time_service.dart';

/// Rappresenta un amico salvato nella Sezione Amici (abbinato una sola volta tramite Codice Amico)
/// per lanciare sfide P2P con 1 tap senza dover ricreare stanze manualmente.
class FriendRecord {
  final String code;
  final String name;
  final String avatarEmoji;
  final String skinId;
  final int winsAgainst;
  final int lossesAgainst;
  final bool isOnline;

  const FriendRecord({
    required this.code,
    required this.name,
    this.avatarEmoji = '🥷',
    this.skinId = 'shinobi_star',
    this.winsAgainst = 0,
    this.lossesAgainst = 0,
    this.isOnline = false,
  });

  FriendRecord copyWith({
    String? name,
    String? avatarEmoji,
    String? skinId,
    int? winsAgainst,
    int? lossesAgainst,
    bool? isOnline,
  }) {
    return FriendRecord(
      code: code,
      name: name ?? this.name,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      skinId: skinId ?? this.skinId,
      winsAgainst: winsAgainst ?? this.winsAgainst,
      lossesAgainst: lossesAgainst ?? this.lossesAgainst,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'avatarEmoji': avatarEmoji,
        'skinId': skinId,
        'winsAgainst': winsAgainst,
        'lossesAgainst': lossesAgainst,
        'isOnline': false,
      };

  factory FriendRecord.fromJson(Map<String, dynamic> json) {
    return FriendRecord(
      code: (json['code'] as String?) ?? 'INK-10000000',
      name: (json['name'] as String?) ?? 'Rival',
      avatarEmoji: (json['avatarEmoji'] as String?) ?? '🥷',
      skinId: (json['skinId'] as String?) ?? 'shinobi_star',
      winsAgainst: (json['winsAgainst'] as int?) ?? 0,
      lossesAgainst: (json['lossesAgainst'] as int?) ?? 0,
      isOnline: false,
    );
  }
}

/// Rappresenta una richiesta di amicizia inviata o ricevuta (con conferma reciproca obbligatoria).
class FriendRequestRecord {
  final String code;
  final String name;
  final String avatarEmoji;
  final String skinId;
  final int timestampMs;

  const FriendRequestRecord({
    required this.code,
    required this.name,
    this.avatarEmoji = '🥷',
    this.skinId = 'shinobi_star',
    this.timestampMs = 0,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'avatarEmoji': avatarEmoji,
        'skinId': skinId,
        'timestampMs': timestampMs,
      };

  factory FriendRequestRecord.fromJson(Map<String, dynamic> json) {
    return FriendRequestRecord(
      code: (json['code'] as String?) ?? 'INK-10000000',
      name: (json['name'] as String?) ?? 'Climber',
      avatarEmoji: (json['avatarEmoji'] as String?) ?? '🥷',
      skinId: (json['skinId'] as String?) ?? 'shinobi_star',
      timestampMs: (json['timestampMs'] as int?) ?? 0,
    );
  }
}

/// Gestisce il salvataggio locale veloce e resiliente (con protezione High-Water Mark
/// e snapshot di backup automatico per impedire qualsiasi perdita o reset dei progressi):
/// - Progressione infinita dei livelli (Livello 1, 2, 3...), record metri e rimbalzi
/// - Record Modalità Torre Infinita (metri massimi e rimbalzi)
/// - Nome giocatore per la Classifica
/// - Lingua selezionata
/// - Stato Volume Audio singolo unificato ON/OFF
/// - Record giornaliero (metri e rimbalzi) sul seed di oggi (24h) validato tramite TrustedTimeService
/// - Tentativi ("Vite") rimasti oggi e Streak di giorni consecutivi
/// - Palette Risograph selezionata, Icone Profilo e Skin Sfera
class StorageService {
  static const _keyLastPlayedSeed = 'last_played_seed';
  static const _keyBestMetersToday = 'best_meters_today';
  static const _keyBestBouncesToday = 'best_bounces_today';
  static const _keyCompletedToday = 'completed_today';
  static const _keyOfficialAttemptsLeft = 'official_attempts_left';
  static const _keyCurrentStreak = 'current_streak';
  static const _keyAllTimeBestMeters = 'all_time_best_meters';
  static const _keyInfiniteBestMeters = 'infinite_tower_best_meters';
  static const _keyInfiniteBestBounces = 'infinite_tower_best_bounces';
  static const _keyPaletteId = 'selected_palette_id';
  static const _keyProUnlocked = 'pro_edition_unlocked';
  static const _keyCurrentTowerLevel = 'current_tower_level';
  static const _keyTotalLevelsPlayed = 'total_levels_played';
  static const _keyBestMetersCurrentLevel = 'best_meters_current_level';
  static const _keyBestBouncesCurrentLevel = 'best_bounces_current_level';
  static const _keyPlayerName = 'player_leaderboard_name';
  static const _keyLanguageCode = 'selected_language_code';
  static const _keySoundEnabled = 'sound_effects_enabled';
  static const _keyMusicEnabled = 'ambient_music_enabled';
  static const _keyMasterAudioEnabled = 'master_audio_enabled';

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
  static const _keyProgressBackupSnapshot = 'ink_progress_backup_snapshot_v1';
  static const _keySelectedAbility = 'selected_climb_ability_id';
  static const _keyP2PWinsCount = 'p2p_wins_count_all_time';
  static const _keyP2PMatchesPlayed = 'p2p_matches_played_all_time';
  static const _keyMyFriendCode = 'my_unique_friend_code';
  static const _keyFriendsListJson = 'saved_friends_list_json_v1';
  static const _keyIncomingFriendReqsJson = 'incoming_friend_requests_json_v1';
  static const _keyOutgoingFriendReqsJson = 'outgoing_friend_requests_json_v1';

  SharedPreferences? _prefs;

  double bestMetersToday = 0.0;
  int bestBouncesToday = 0;
  bool completedToday = false;
  int officialAttemptsLeft = DailySeedEngine.maxOfficialAttemptsPerDay;
  int currentStreak = 1;
  double allTimeBestMeters = 0.0;
  double infiniteBestMeters = 0.0;
  int infiniteBestBounces = 0;
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
  String selectedAbilityId = 'zen_anchor';
  int p2pWinsCount = 0;
  int p2pMatchesPlayed = 0;
  String myFriendCode = 'INK-48291037';
  List<FriendRecord> friendsList = <FriendRecord>[];
  List<FriendRequestRecord> incomingFriendRequests = <FriendRequestRecord>[];
  List<FriendRequestRecord> outgoingFriendRequests = <FriendRequestRecord>[];

  /// Callback invocato automaticamente quando il giocatore modifica nome, icona o skin
  void Function()? onProfileChanged;

  /// Genera un Codice Amico univoco a 8 cifre nel formato `INK-XXXXXXXX` (10000000..99999999)
  static String generateEightDigitFriendCode([Random? rng]) {
    final r = rng ?? Random();
    final numPart = 10000000 + r.nextInt(90000000);
    return 'INK-$numPart';
  }

  /// Normalizza un codice amico inserito (es. `84729103` -> `INK-84729103`)
  static String normalizeFriendCode(String rawCode) {
    final cleaned = rawCode.trim().toUpperCase();
    if (cleaned.isEmpty) return 'INK-55218490';
    final digitsOnly = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length == 8) {
      return 'INK-$digitsOnly';
    }
    if (cleaned.startsWith('INK-')) {
      return cleaned;
    }
    return 'INK-$cleaned';
  }

  // Lingua & Volume Audio Unificato
  AppLanguage selectedLanguage = AppLanguage.en;
  bool masterAudioEnabled = true;
  bool soundEnabled = true;
  bool musicEnabled = true;

  bool get isDailyLockedByTamper => TrustedTimeService.instance.isClockTampered;

  Future<void> init({
    bool attemptNetworkSync = true,
    DateTime? debugDeviceUtc,
  }) async {
    try {
      _prefs = await SharedPreferences.getInstance();

      // 1. PRIMA DI QUALSIASI OPERAZIONE DI RETE, carica immediatamente tutti i progressi
      //    locali da SharedPreferences + eventuale snapshot di backup per prevenire qualsiasi reset!
      final backup = _readBackupSnapshot();

      selectedPaletteId = _prefs?.getString(_keyPaletteId) ??
          (backup['paletteId'] as String?) ??
          'washi_ivory';
      allTimeBestMeters = max(
        _prefs?.getDouble(_keyAllTimeBestMeters) ?? 0.0,
        (backup['allTimeBestMeters'] as num?)?.toDouble() ?? 0.0,
      );
      infiniteBestMeters = max(
        _prefs?.getDouble(_keyInfiniteBestMeters) ?? 0.0,
        (backup['infiniteBestMeters'] as num?)?.toDouble() ?? 0.0,
      );
      infiniteBestBounces = _prefs?.getInt(_keyInfiniteBestBounces) ??
          (backup['infiniteBestBounces'] as int?) ??
          0;
      proUnlocked = (_prefs?.getBool(_keyProUnlocked) ?? false) ||
          ((backup['proUnlocked'] as bool?) ?? false);
      currentStreak = max(
        _prefs?.getInt(_keyCurrentStreak) ?? 1,
        (backup['currentStreak'] as int?) ?? 1,
      );

      currentTowerLevel = max(
        1,
        max(
          _prefs?.getInt(_keyCurrentTowerLevel) ?? 1,
          (backup['currentTowerLevel'] as int?) ?? 1,
        ),
      );
      totalLevelsPlayed = max(
        _prefs?.getInt(_keyTotalLevelsPlayed) ?? 0,
        (backup['totalLevelsPlayed'] as int?) ?? 0,
      );
      bestMetersCurrentLevel =
          _prefs?.getDouble(_keyBestMetersCurrentLevel) ?? 0.0;
      bestBouncesCurrentLevel =
          _prefs?.getInt(_keyBestBouncesCurrentLevel) ?? 0;
      playerName = _prefs?.getString(_keyPlayerName) ??
          (backup['playerName'] as String?) ??
          'Climber';

      final savedLang = _prefs?.getString(_keyLanguageCode) ??
          (backup['languageCode'] as String?);
      selectedLanguage = AppLanguage.fromCode(savedLang);

      // Volume singolo unificato
      final savedVolume = _prefs?.getBool(_keySoundEnabled) ??
          _prefs?.getBool(_keyMasterAudioEnabled) ??
          true;
      masterAudioEnabled = savedVolume;
      soundEnabled = savedVolume;
      musicEnabled = savedVolume;

      // Caricamento Statistiche Profilo Giocatore (con High-Water Mark)
      totalBouncesAllTime = max(
        _prefs?.getInt(_keyTotalBouncesAllTime) ?? (totalLevelsPlayed * 24),
        (backup['totalBouncesAllTime'] as int?) ?? 0,
      );
      levelFirstPlaceCount = max(
        _prefs?.getInt(_keyLevelFirstPlaceCount) ??
            (currentTowerLevel > 14 ? currentTowerLevel - 13 : 0),
        (backup['levelFirstPlaceCount'] as int?) ?? 0,
      );
      dailyFirstPlaceCount = max(
        _prefs?.getInt(_keyDailyFirstPlaceCount) ?? 0,
        (backup['dailyFirstPlaceCount'] as int?) ?? 0,
      );
      dailyTop3Count = max(
        _prefs?.getInt(_keyDailyTop3Count) ?? 0,
        (backup['dailyTop3Count'] as int?) ?? 0,
      );
      totalDailyTowersCompleted = max(
        _prefs?.getInt(_keyTotalDailyTowersCompleted) ?? 0,
        (backup['totalDailyTowersCompleted'] as int?) ?? 0,
      );
      totalMetersClimbed = max(
        _prefs?.getDouble(_keyTotalMetersClimbed) ??
            (allTimeBestMeters + totalLevelsPlayed * 35.0),
        (backup['totalMetersClimbed'] as num?)?.toDouble() ?? 0.0,
      );
      totalRunsPlayed = max(
        _prefs?.getInt(_keyTotalRunsPlayed) ?? totalLevelsPlayed,
        (backup['totalRunsPlayed'] as int?) ?? 0,
      );
      selectedProfileIconId = _prefs?.getString(_keySelectedProfileIcon) ??
          (backup['selectedProfileIconId'] as String?) ??
          'ink_drop';
      selectedBallSkinId = _prefs?.getString(_keySelectedBallSkin) ??
          (backup['selectedBallSkinId'] as String?) ??
          'classic_ink';
      bestDailyRankAchievedToday =
          _prefs?.getInt(_keyBestDailyRankAchievedToday) ?? 999;
      lastRankAwardedSeed = _prefs?.getInt(_keyLastRankAwardedSeed) ?? 0;
      awardedLevelFirstPlaces =
          _prefs?.getStringList(_keyAwardedLevelFirstPlaces) ?? [];
      selectedAbilityId = _prefs?.getString(_keySelectedAbility) ??
          (backup['selectedAbilityId'] as String?) ??
          'zen_anchor';
      p2pWinsCount = max(
        _prefs?.getInt(_keyP2PWinsCount) ?? 0,
        (backup['p2pWinsCount'] as int?) ?? 0,
      );
      p2pMatchesPlayed = max(
        _prefs?.getInt(_keyP2PMatchesPlayed) ?? 0,
        (backup['p2pMatchesPlayed'] as int?) ?? 0,
      );
      final savedCode = _prefs?.getString(_keyMyFriendCode) ??
          (backup['myFriendCode'] as String?);
      if (savedCode != null && RegExp(r'^INK-\d{8}$').hasMatch(savedCode)) {
        myFriendCode = savedCode;
      } else {
        myFriendCode = generateEightDigitFriendCode();
        await _prefs?.setString(_keyMyFriendCode, myFriendCode);
      }
      _loadFriendsList(backup);
      _loadFriendRequests(backup);

      // Carica subito i dati giornalieri esistenti prima della verifica oraria
      bestMetersToday = _prefs?.getDouble(_keyBestMetersToday) ?? 0.0;
      bestBouncesToday = _prefs?.getInt(_keyBestBouncesToday) ?? 0;
      completedToday = _prefs?.getBool(_keyCompletedToday) ?? false;
      officialAttemptsLeft = _prefs?.getInt(_keyOfficialAttemptsLeft) ??
          DailySeedEngine.maxOfficialAttemptsPerDay;

      // 2. Inizializza TrustedTimeService (lettura locale immediata + sync di rete non bloccante)
      await TrustedTimeService.instance.init(
        prefs: _prefs,
        attemptNetworkSync: attemptNetworkSync,
        debugDeviceUtc: debugDeviceUtc,
      );

      final todaySeed = DailySeedEngine.getTodaySeed();
      final lastSeed = _prefs?.getInt(_keyLastPlayedSeed) ?? 0;

      // Protezione anti-rollback / anti-exploit data tramite TrustedTimeService:
      // Se l'orologio è stato manomesso (currentTime < lastRecordedTime), NON resetta le vite!
      if (!isDailyLockedByTamper && (lastSeed == 0 || todaySeed > lastSeed)) {
        final yesterday = TrustedTimeService.instance
            .nowUtc()
            .subtract(const Duration(days: 1));
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
          _keyOfficialAttemptsLeft,
          DailySeedEngine.maxOfficialAttemptsPerDay,
        );
        await _prefs?.setInt(_keyCurrentStreak, currentStreak);
        await _prefs?.setInt(_keyBestDailyRankAchievedToday, 999);
      }

      // Migration una-tantum per le 3 vite
      final hasAppliedLivesFix = _prefs?.getBool('lives_fix_v2') ?? false;
      if (!hasAppliedLivesFix && !isDailyLockedByTamper) {
        officialAttemptsLeft = DailySeedEngine.maxOfficialAttemptsPerDay;
        await _prefs?.setInt(_keyOfficialAttemptsLeft, officialAttemptsLeft);
        await _prefs?.setBool('lives_fix_v2', true);
      }

      await _saveBackupSnapshot();
    } catch (_) {
      // Fallback sicuro se SharedPreferences non è disponibile
    }
  }

  Map<String, dynamic> _readBackupSnapshot() {
    try {
      final raw = _prefs?.getString(_keyProgressBackupSnapshot);
      if (raw == null || raw.isEmpty) return const <String, dynamic>{};
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return const <String, dynamic>{};
  }

  /// Salvaguardia High-Water Mark: garantisce che livelli e record su disco non vengano mai retrocessi
  Future<void> enforceHighWaterMark() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
    } catch (_) {}
    final backup = _readBackupSnapshot();
    final diskLevel = max(
      _prefs?.getInt(_keyCurrentTowerLevel) ?? 1,
      (backup['currentTowerLevel'] as int?) ?? 1,
    );
    if (diskLevel > currentTowerLevel) {
      currentTowerLevel = diskLevel;
    } else if (currentTowerLevel > diskLevel) {
      await _prefs?.setInt(_keyCurrentTowerLevel, currentTowerLevel);
    }

    final diskBestMeters = max(
      _prefs?.getDouble(_keyAllTimeBestMeters) ?? 0.0,
      (backup['allTimeBestMeters'] as num?)?.toDouble() ?? 0.0,
    );
    if (diskBestMeters > allTimeBestMeters) {
      allTimeBestMeters = diskBestMeters;
    } else if (allTimeBestMeters > diskBestMeters) {
      await _prefs?.setDouble(_keyAllTimeBestMeters, allTimeBestMeters);
    }

    final diskInfMeters = max(
      _prefs?.getDouble(_keyInfiniteBestMeters) ?? 0.0,
      (backup['infiniteBestMeters'] as num?)?.toDouble() ?? 0.0,
    );
    if (diskInfMeters > infiniteBestMeters) {
      infiniteBestMeters = diskInfMeters;
    } else if (infiniteBestMeters > diskInfMeters) {
      await _prefs?.setDouble(_keyInfiniteBestMeters, infiniteBestMeters);
    }

    final diskBounces = max(
      _prefs?.getInt(_keyTotalBouncesAllTime) ?? 0,
      (backup['totalBouncesAllTime'] as int?) ?? 0,
    );
    if (diskBounces > totalBouncesAllTime) {
      totalBouncesAllTime = diskBounces;
    } else if (totalBouncesAllTime > diskBounces) {
      await _prefs?.setInt(_keyTotalBouncesAllTime, totalBouncesAllTime);
    }

    final diskP2PWins = max(
      _prefs?.getInt(_keyP2PWinsCount) ?? 0,
      (backup['p2pWinsCount'] as int?) ?? 0,
    );
    if (diskP2PWins > p2pWinsCount) {
      p2pWinsCount = diskP2PWins;
    } else if (p2pWinsCount > diskP2PWins) {
      await _prefs?.setInt(_keyP2PWinsCount, p2pWinsCount);
    }
  }

  Future<void> _saveBackupSnapshot() async {
    try {
      if (_prefs == null) return;
      await enforceHighWaterMark();

      final snapshot = <String, dynamic>{
        'currentTowerLevel': currentTowerLevel,
        'allTimeBestMeters': allTimeBestMeters,
        'infiniteBestMeters': infiniteBestMeters,
        'infiniteBestBounces': infiniteBestBounces,
        'totalLevelsPlayed': totalLevelsPlayed,
        'totalBouncesAllTime': totalBouncesAllTime,
        'totalMetersClimbed': totalMetersClimbed,
        'totalRunsPlayed': totalRunsPlayed,
        'levelFirstPlaceCount': levelFirstPlaceCount,
        'dailyFirstPlaceCount': dailyFirstPlaceCount,
        'dailyTop3Count': dailyTop3Count,
        'totalDailyTowersCompleted': totalDailyTowersCompleted,
        'currentStreak': currentStreak,
        'playerName': playerName,
        'paletteId': selectedPaletteId,
        'languageCode': selectedLanguage.code,
        'selectedProfileIconId': selectedProfileIconId,
        'selectedBallSkinId': selectedBallSkinId,
        'selectedAbilityId': selectedAbilityId,
        'p2pWinsCount': p2pWinsCount,
        'p2pMatchesPlayed': p2pMatchesPlayed,
        'myFriendCode': myFriendCode,
        'friendsList': friendsList.map((f) => f.toJson()).toList(),
        'incomingFriendRequests':
            incomingFriendRequests.map((r) => r.toJson()).toList(),
        'outgoingFriendRequests':
            outgoingFriendRequests.map((r) => r.toJson()).toList(),
        'proUnlocked': proUnlocked,
      };
      await _prefs?.setString(_keyProgressBackupSnapshot, jsonEncode(snapshot));
    } catch (_) {}
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
    try {
      _prefs ??= await SharedPreferences.getInstance();
    } catch (_) {}

    // Sincronizza High-Water Mark da disco prima di aggiornare per evitare qualsiasi regressione
    final diskLevel = _prefs?.getInt(_keyCurrentTowerLevel) ?? 1;
    if (diskLevel > currentTowerLevel) {
      currentTowerLevel = diskLevel;
    }

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

    // 1. MODALITÀ TORRE INFINITA
    if (mode == GameMode.infiniteTower) {
      final isHigherInf = meters > infiniteBestMeters + 0.05;
      final isSameInfFewerBounces =
          (meters - infiniteBestMeters).abs() <= 0.05 &&
          meters > 0 &&
          (infiniteBestBounces == 0 || safeBounces < infiniteBestBounces);

      if (isHigherInf || isSameInfFewerBounces) {
        infiniteBestMeters = meters;
        infiniteBestBounces = safeBounces;
        isNewRecord = true;
        await _prefs?.setDouble(_keyInfiniteBestMeters, infiniteBestMeters);
        await _prefs?.setInt(_keyInfiniteBestBounces, infiniteBestBounces);
      }
      await _saveBackupSnapshot();
      return isNewRecord;
    }

    // 2. MODALITÀ LIVELLI PROGRESSIVI
    if (mode == GameMode.levelProgression) {
      // Incrementa solo quando un livello viene effettivamente superato, così i tentativi falliti non fanno mai avanzare i bot!
      if (isVictory) {
        totalLevelsPlayed += 1;
        await _prefs?.setInt(_keyTotalLevelsPlayed, totalLevelsPlayed);
      }

      if (playedLevel >= currentTowerLevel) {
        if (isVictory) {
          currentTowerLevel = max(currentTowerLevel + 1, playedLevel + 1);
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
            _keyAwardedLevelFirstPlaces,
            awardedLevelFirstPlaces,
          );
          await _prefs?.setInt(
            _keyLevelFirstPlaceCount,
            levelFirstPlaceCount,
          );
        }
      }

      await _saveBackupSnapshot();
      return isNewRecord;
    }

    // 3. MODALITÀ TORRE DEL GIORNO (24h): se l'orologio è manomesso, blocca salvataggi/sblocchi giornalieri
    if (!TrustedTimeService.instance.verifyRuntimeIntegrity()) {
      return false;
    }

    if (consumeOfficialAttempt && officialAttemptsLeft > 0) {
      officialAttemptsLeft -= 1;
      await _prefs?.setInt(_keyOfficialAttemptsLeft, officialAttemptsLeft);
    }

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
        _keyTotalDailyTowersCompleted,
        totalDailyTowersCompleted,
      );
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
        _keyBestDailyRankAchievedToday,
        bestDailyRankAchievedToday,
      );
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
          _keyBestDailyRankAchievedToday,
          bestDailyRankAchievedToday,
        );
      }
    }

    await _saveBackupSnapshot();
    return isNewRecord;
  }

  Future<void> setSelectedProfileIcon(String iconId) async {
    selectedProfileIconId = iconId;
    await _prefs?.setString(_keySelectedProfileIcon, selectedProfileIconId);
    await _saveBackupSnapshot();
    onProfileChanged?.call();
  }

  Future<void> setSelectedBallSkin(String skinId) async {
    selectedBallSkinId = skinId;
    await _prefs?.setString(_keySelectedBallSkin, selectedBallSkinId);
    await _saveBackupSnapshot();
    onProfileChanged?.call();
  }

  /// Aggiunge 1 vita extra oggi (es. dopo Rewarded Ad)
  Future<void> grantExtraOfficialAttempt() async {
    if (!TrustedTimeService.instance.verifyRuntimeIntegrity()) return;
    officialAttemptsLeft += 1;
    await _prefs?.setInt(_keyOfficialAttemptsLeft, officialAttemptsLeft);
  }

  Future<void> setPlayerName(String name) async {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return;
    playerName = cleaned;
    await _prefs?.setString(_keyPlayerName, playerName);
    await _saveBackupSnapshot();
    onProfileChanged?.call();
  }

  Future<void> setLanguage(AppLanguage lang) async {
    selectedLanguage = lang;
    await _prefs?.setString(_keyLanguageCode, lang.code);
    await _saveBackupSnapshot();
  }

  /// Imposta il Volume Audio Singolo unificato (senza separazione tra SFX e musica ambientale)
  Future<void> setUnifiedVolumeEnabled(bool enabled) async {
    masterAudioEnabled = enabled;
    soundEnabled = enabled;
    musicEnabled = enabled;
    await _prefs?.setBool(_keyMasterAudioEnabled, enabled);
    await _prefs?.setBool(_keySoundEnabled, enabled);
    await _prefs?.setBool(_keyMusicEnabled, enabled);
  }

  Future<void> setSoundEnabled(bool enabled) => setUnifiedVolumeEnabled(enabled);

  Future<void> setMusicEnabled(bool enabled) => setUnifiedVolumeEnabled(enabled);

  Future<void> setMasterAudioEnabled(bool enabled) =>
      setUnifiedVolumeEnabled(enabled);

  Future<void> setPalette(String paletteId) async {
    selectedPaletteId = paletteId;
    await _prefs?.setString(_keyPaletteId, paletteId);
    await _saveBackupSnapshot();
  }

  Future<void> unlockProEdition() async {
    proUnlocked = true;
    await _prefs?.setBool(_keyProUnlocked, true);
    await _saveBackupSnapshot();
  }

  void _loadFriendsList(Map<String, dynamic> backup) {
    try {
      final raw = _prefs?.getString(_keyFriendsListJson);
      List<dynamic>? decoded;
      if (raw != null && raw.isNotEmpty) {
        decoded = jsonDecode(raw) as List<dynamic>?;
      } else if (backup['friendsList'] is List<dynamic>) {
        decoded = backup['friendsList'] as List<dynamic>;
      }
      if (decoded != null) {
        friendsList = decoded
            .whereType<Map<String, dynamic>>()
            .map(FriendRecord.fromJson)
            .toList();
      }
    } catch (_) {}
  }

  void _loadFriendRequests(Map<String, dynamic> backup) {
    try {
      final rawIn = _prefs?.getString(_keyIncomingFriendReqsJson);
      List<dynamic>? decodedIn;
      if (rawIn != null && rawIn.isNotEmpty) {
        decodedIn = jsonDecode(rawIn) as List<dynamic>?;
      } else if (backup['incomingFriendRequests'] is List<dynamic>) {
        decodedIn = backup['incomingFriendRequests'] as List<dynamic>;
      }
      if (decodedIn != null) {
        incomingFriendRequests = decodedIn
            .whereType<Map<String, dynamic>>()
            .map(FriendRequestRecord.fromJson)
            .toList();
      }

      final rawOut = _prefs?.getString(_keyOutgoingFriendReqsJson);
      List<dynamic>? decodedOut;
      if (rawOut != null && rawOut.isNotEmpty) {
        decodedOut = jsonDecode(rawOut) as List<dynamic>?;
      } else if (backup['outgoingFriendRequests'] is List<dynamic>) {
        decodedOut = backup['outgoingFriendRequests'] as List<dynamic>;
      }
      if (decodedOut != null) {
        outgoingFriendRequests = decodedOut
            .whereType<Map<String, dynamic>>()
            .map(FriendRequestRecord.fromJson)
            .toList();
      }
    } catch (_) {}
  }

  Future<void> _saveFriendsList() async {
    try {
      final encoded = jsonEncode(friendsList.map((f) => f.toJson()).toList());
      await _prefs?.setString(_keyFriendsListJson, encoded);
      await _saveBackupSnapshot();
    } catch (_) {}
  }

  Future<void> _saveFriendRequests() async {
    try {
      final encIn =
          jsonEncode(incomingFriendRequests.map((r) => r.toJson()).toList());
      final encOut =
          jsonEncode(outgoingFriendRequests.map((r) => r.toJson()).toList());
      await _prefs?.setString(_keyIncomingFriendReqsJson, encIn);
      await _prefs?.setString(_keyOutgoingFriendReqsJson, encOut);
      await _saveBackupSnapshot();
    } catch (_) {}
  }

  Future<void> setSelectedAbility(String abilityId) async {
    selectedAbilityId = abilityId;
    await _prefs?.setString(_keySelectedAbility, selectedAbilityId);
    await _saveBackupSnapshot();
  }

  Future<FriendRecord> addFriend({
    required String code,
    String name = '',
    String avatarEmoji = '🥷',
    String skinId = 'shinobi_star',
    bool isOnline = false,
  }) async {
    final cleanCode = normalizeFriendCode(code);
    final existingIdx =
        friendsList.indexWhere((f) => f.code.toUpperCase() == cleanCode);
    final shortSuffix = cleanCode.length >= 4
        ? cleanCode.substring(cleanCode.length - 4)
        : cleanCode;
    final cleanName = name.trim().isEmpty
        ? (existingIdx >= 0 ? friendsList[existingIdx].name : 'Climber #$shortSuffix')
        : name.trim();
    final effectiveAvatar = avatarEmoji.trim().isEmpty
        ? (existingIdx >= 0 ? friendsList[existingIdx].avatarEmoji : '🥷')
        : avatarEmoji.trim();
    final effectiveSkin = skinId.trim().isEmpty
        ? (existingIdx >= 0 ? friendsList[existingIdx].skinId : 'shinobi_star')
        : skinId.trim();
    final record = FriendRecord(
      code: cleanCode,
      name: cleanName,
      avatarEmoji: effectiveAvatar,
      skinId: effectiveSkin,
      isOnline: isOnline,
    );
    if (existingIdx >= 0) {
      friendsList[existingIdx] = friendsList[existingIdx].copyWith(
        name: cleanName,
        avatarEmoji: effectiveAvatar,
        skinId: effectiveSkin,
        isOnline: isOnline,
      );
      await _saveFriendsList();
      return friendsList[existingIdx];
    } else {
      friendsList.insert(0, record);
      await _saveFriendsList();
      return record;
    }
  }

  /// Sincronizza in modo non distruttivo nome, avatar, skin e stato online di un amico già in lista
  Future<bool> syncFriendProfile({
    required String code,
    String? name,
    String? avatarEmoji,
    String? skinId,
    bool? isOnline,
  }) async {
    final cleanCode = normalizeFriendCode(code);
    bool changedAny = false;

    final idx =
        friendsList.indexWhere((f) => f.code.toUpperCase() == cleanCode);
    if (idx >= 0) {
      final old = friendsList[idx];
      final newName =
          (name != null && name.trim().isNotEmpty) ? name.trim() : old.name;
      final newAvatar = (avatarEmoji != null && avatarEmoji.trim().isNotEmpty)
          ? avatarEmoji.trim()
          : old.avatarEmoji;
      final newSkin =
          (skinId != null && skinId.trim().isNotEmpty) ? skinId.trim() : old.skinId;
      final newOnline = isOnline ?? old.isOnline;

      final persistentDiff = newName != old.name ||
          newAvatar != old.avatarEmoji ||
          newSkin != old.skinId;
      final runtimeDiff = persistentDiff || newOnline != old.isOnline;

      if (runtimeDiff) {
        friendsList[idx] = old.copyWith(
          name: newName,
          avatarEmoji: newAvatar,
          skinId: newSkin,
          isOnline: newOnline,
        );
        changedAny = true;
        if (persistentDiff) {
          await _saveFriendsList();
        }
      }
    }

    final reqIdx = incomingFriendRequests
        .indexWhere((r) => r.code.toUpperCase() == cleanCode);
    if (reqIdx >= 0) {
      final oldReq = incomingFriendRequests[reqIdx];
      final newName =
          (name != null && name.trim().isNotEmpty) ? name.trim() : oldReq.name;
      final newAvatar = (avatarEmoji != null && avatarEmoji.trim().isNotEmpty)
          ? avatarEmoji.trim()
          : oldReq.avatarEmoji;
      final newSkin = (skinId != null && skinId.trim().isNotEmpty)
          ? skinId.trim()
          : oldReq.skinId;
      if (newName != oldReq.name ||
          newAvatar != oldReq.avatarEmoji ||
          newSkin != oldReq.skinId) {
        incomingFriendRequests[reqIdx] = FriendRequestRecord(
          code: oldReq.code,
          name: newName,
          avatarEmoji: newAvatar,
          skinId: newSkin,
          timestampMs: oldReq.timestampMs,
        );
        changedAny = true;
        await _saveFriendRequests();
      }
    }

    return changedAny;
  }

  Future<void> removeFriend(String code) async {
    friendsList.removeWhere((f) => f.code.toUpperCase() == code.toUpperCase());
    await _saveFriendsList();
  }

  Future<void> clearAllFriends() async {
    friendsList.clear();
    await _saveFriendsList();
  }

  bool isAlreadyFriend(String code) {
    final norm = normalizeFriendCode(code);
    return friendsList.any((f) => f.code.toUpperCase() == norm);
  }

  Future<FriendRequestRecord> addIncomingFriendRequest({
    required String code,
    String name = '',
    String avatarEmoji = '🥷',
    String skinId = 'shinobi_star',
  }) async {
    final cleanCode = normalizeFriendCode(code);
    final shortSuffix = cleanCode.length >= 4
        ? cleanCode.substring(cleanCode.length - 4)
        : cleanCode;
    final cleanName =
        name.trim().isEmpty ? 'Climber #$shortSuffix' : name.trim();
    final record = FriendRequestRecord(
      code: cleanCode,
      name: cleanName,
      avatarEmoji: avatarEmoji,
      skinId: skinId,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
    );
    final idx = incomingFriendRequests
        .indexWhere((r) => r.code.toUpperCase() == cleanCode);
    if (idx >= 0) {
      incomingFriendRequests[idx] = record;
    } else {
      incomingFriendRequests.insert(0, record);
    }
    await _saveFriendRequests();
    return record;
  }

  Future<void> removeIncomingFriendRequest(String code) async {
    final cleanCode = normalizeFriendCode(code);
    incomingFriendRequests
        .removeWhere((r) => r.code.toUpperCase() == cleanCode);
    await _saveFriendRequests();
  }

  Future<FriendRequestRecord> addOutgoingFriendRequest({
    required String code,
    String name = '',
  }) async {
    final cleanCode = normalizeFriendCode(code);
    final shortSuffix = cleanCode.length >= 4
        ? cleanCode.substring(cleanCode.length - 4)
        : cleanCode;
    final cleanName =
        name.trim().isEmpty ? 'Climber #$shortSuffix' : name.trim();
    final record = FriendRequestRecord(
      code: cleanCode,
      name: cleanName,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
    );
    final idx = outgoingFriendRequests
        .indexWhere((r) => r.code.toUpperCase() == cleanCode);
    if (idx >= 0) {
      outgoingFriendRequests[idx] = record;
    } else {
      outgoingFriendRequests.insert(0, record);
    }
    await _saveFriendRequests();
    return record;
  }

  Future<void> removeOutgoingFriendRequest(String code) async {
    final cleanCode = normalizeFriendCode(code);
    outgoingFriendRequests
        .removeWhere((r) => r.code.toUpperCase() == cleanCode);
    await _saveFriendRequests();
  }

  Future<void> recordP2PDuelResult({
    required String friendCode,
    required bool isWin,
    required double meters,
    required int bounces,
  }) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
    } catch (_) {}

    p2pMatchesPlayed += 1;
    await _prefs?.setInt(_keyP2PMatchesPlayed, p2pMatchesPlayed);

    if (isWin) {
      p2pWinsCount += 1;
      await _prefs?.setInt(_keyP2PWinsCount, p2pWinsCount);
    }

    totalBouncesAllTime += max(1, bounces);
    await _prefs?.setInt(_keyTotalBouncesAllTime, totalBouncesAllTime);

    totalMetersClimbed += meters;
    await _prefs?.setDouble(_keyTotalMetersClimbed, totalMetersClimbed);

    totalRunsPlayed += 1;
    await _prefs?.setInt(_keyTotalRunsPlayed, totalRunsPlayed);

    if (meters > allTimeBestMeters) {
      allTimeBestMeters = meters;
      await _prefs?.setDouble(_keyAllTimeBestMeters, allTimeBestMeters);
    }

    final idx = friendsList.indexWhere(
      (f) => f.code.toUpperCase() == friendCode.toUpperCase(),
    );
    if (idx >= 0) {
      final f = friendsList[idx];
      friendsList[idx] = f.copyWith(
        winsAgainst: isWin ? f.winsAgainst + 1 : f.winsAgainst,
        lossesAgainst: isWin ? f.lossesAgainst : f.lossesAgainst + 1,
      );
    }
    await _saveFriendsList();
  }

  // ignore: unused_element
  Future<void> _syncProHelper() async {
    proUnlocked = true;
    await _prefs?.setBool(_keyProUnlocked, true);
    await _saveBackupSnapshot();
  }
}

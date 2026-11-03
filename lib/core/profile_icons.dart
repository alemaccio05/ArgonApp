import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'app_strings.dart';

/// Rappresenta una singola icona/avatar profilo sbloccabile del giocatore.
class ProfileIconItem {
  final String id;
  final String emoji;
  final IconData iconData;
  final String Function(AppStrings s) getName;
  final String Function(AppStrings s) getRequirement;
  final bool Function(StorageService storage) isUnlocked;
  final String Function(StorageService storage, AppStrings s) getProgress;

  const ProfileIconItem({
    required this.id,
    required this.emoji,
    required this.iconData,
    required this.getName,
    required this.getRequirement,
    required this.isUnlocked,
    required this.getProgress,
  });
}

class ProfileIconsCatalog {
  static final List<ProfileIconItem> allIcons = [
    // 1. Icone Base sbloccate dall'inizio
    ProfileIconItem(
      id: 'ink_drop',
      emoji: '💧',
      iconData: Icons.water_drop_rounded,
      getName: (s) => s.iconInkDropName,
      getRequirement: (s) => s.iconDefaultReq,
      isUnlocked: (_) => true,
      getProgress: (_, s) => s.unlockedLabel,
    ),
    ProfileIconItem(
      id: 'spirit_orb',
      emoji: '⚪',
      iconData: Icons.circle,
      getName: (s) => s.iconSpiritOrbName,
      getRequirement: (s) => s.iconDefaultReq,
      isUnlocked: (_) => true,
      getProgress: (_, s) => s.unlockedLabel,
    ),
    ProfileIconItem(
      id: 'zen_brush',
      emoji: '🖌️',
      iconData: Icons.brush_rounded,
      getName: (s) => s.iconZenBrushName,
      getRequirement: (s) => s.iconDefaultReq,
      isUnlocked: (_) => true,
      getProgress: (_, s) => s.unlockedLabel,
    ),

    // 2. Icone Sbloccabili con la Progressione dei Livelli
    ProfileIconItem(
      id: 'matcha_leaf',
      emoji: '🍃',
      iconData: Icons.eco_rounded,
      getName: (s) => s.iconMatchaLeafName,
      getRequirement: (s) => s.iconReachLevelReq(5),
      isUnlocked: (st) => st.currentTowerLevel >= 5,
      getProgress: (st, s) =>
          st.currentTowerLevel >= 5 ? s.unlockedLabel : '${st.currentTowerLevel}/5',
    ),
    ProfileIconItem(
      id: 'shinobi_seal',
      emoji: '🥷',
      iconData: Icons.security_rounded,
      getName: (s) => s.iconShinobiSealName,
      getRequirement: (s) => s.iconReachLevelReq(10),
      isUnlocked: (st) => st.currentTowerLevel >= 10,
      getProgress: (st, s) =>
          st.currentTowerLevel >= 10 ? s.unlockedLabel : '${st.currentTowerLevel}/10',
    ),
    ProfileIconItem(
      id: 'bamboo_guard',
      emoji: '🎋',
      iconData: Icons.park_rounded,
      getName: (s) => s.iconBambooGuardName,
      getRequirement: (s) => s.iconReachLevelReq(15),
      isUnlocked: (st) => st.currentTowerLevel >= 15,
      getProgress: (st, s) =>
          st.currentTowerLevel >= 15 ? s.unlockedLabel : '${st.currentTowerLevel}/15',
    ),
    ProfileIconItem(
      id: 'origami_crane',
      emoji: '🕊️',
      iconData: Icons.flight_takeoff_rounded,
      getName: (s) => s.iconPaperCraneName,
      getRequirement: (s) => s.iconReachLevelReq(20),
      isUnlocked: (st) => st.currentTowerLevel >= 20,
      getProgress: (st, s) =>
          st.currentTowerLevel >= 20 ? s.unlockedLabel : '${st.currentTowerLevel}/20',
    ),
    ProfileIconItem(
      id: 'dragon_spirit',
      emoji: '🐉',
      iconData: Icons.local_fire_department_rounded,
      getName: (s) => s.iconDragonSpiritName,
      getRequirement: (s) => s.iconReachLevelReq(30),
      isUnlocked: (st) => st.currentTowerLevel >= 30,
      getProgress: (st, s) =>
          st.currentTowerLevel >= 30 ? s.unlockedLabel : '${st.currentTowerLevel}/30',
    ),

    // 3. Icone Esclusive Giornaliere (Top 3 e 1° Posto)
    ProfileIconItem(
      id: 'daily_podium',
      emoji: '🥉',
      iconData: Icons.military_tech_rounded,
      getName: (s) => s.iconDailyPodiumName,
      getRequirement: (s) => s.iconTop3Req(1),
      isUnlocked: (st) => st.dailyTop3Count >= 1,
      getProgress: (st, s) =>
          st.dailyTop3Count >= 1 ? s.unlockedLabel : '${st.dailyTop3Count}/1',
    ),
    ProfileIconItem(
      id: 'elite_silver',
      emoji: '🥈',
      iconData: Icons.shield_rounded,
      getName: (s) => s.iconEliteSilverName,
      getRequirement: (s) => s.iconTop3Req(3),
      isUnlocked: (st) => st.dailyTop3Count >= 3,
      getProgress: (st, s) =>
          st.dailyTop3Count >= 3 ? s.unlockedLabel : '${st.dailyTop3Count}/3',
    ),
    ProfileIconItem(
      id: 'gold_crown',
      emoji: '👑',
      iconData: Icons.workspace_premium_rounded,
      getName: (s) => s.iconGoldCrownName,
      getRequirement: (s) => s.iconDailyFirstReq(1),
      isUnlocked: (st) => st.dailyFirstPlaceCount >= 1,
      getProgress: (st, s) => st.dailyFirstPlaceCount >= 1
          ? s.unlockedLabel
          : '${st.dailyFirstPlaceCount}/1',
    ),

    // 4. Icona Speciale per Rimbalzi Totali
    ProfileIconItem(
      id: 'bounce_master',
      emoji: '⚡',
      iconData: Icons.bolt_rounded,
      getName: (s) => s.iconBounceMasterName,
      getRequirement: (s) => s.iconBouncesReq(500),
      isUnlocked: (st) => st.totalBouncesAllTime >= 500,
      getProgress: (st, s) => st.totalBouncesAllTime >= 500
          ? s.unlockedLabel
          : '${st.totalBouncesAllTime}/500',
    ),

    // 5. Icone Hardcore & Multiplayer P2P
    ProfileIconItem(
      id: 'oni_mask',
      emoji: '👹',
      iconData: Icons.whatshot_rounded,
      getName: (s) => s.iconOniMaskName,
      getRequirement: (s) => s.iconReachLevelReq(50),
      isUnlocked: (st) => st.currentTowerLevel >= 50,
      getProgress: (st, s) => st.currentTowerLevel >= 50
          ? s.unlockedLabel
          : '${st.currentTowerLevel}/50',
    ),
    ProfileIconItem(
      id: 'kitsune_fox',
      emoji: '🦊',
      iconData: Icons.auto_awesome_rounded,
      getName: (s) => s.iconKitsuneFoxName,
      getRequirement: (s) => s.skinInfiniteMetersReq(150),
      isUnlocked: (st) => st.infiniteBestMeters >= 150.0,
      getProgress: (st, s) => st.infiniteBestMeters >= 150.0
          ? s.unlockedLabel
          : '${st.infiniteBestMeters.toInt()}/150m',
    ),
    ProfileIconItem(
      id: 'duel_champion',
      emoji: '⚔️',
      iconData: Icons.sports_kabaddi_rounded,
      getName: (s) => s.iconDuelChampionName,
      getRequirement: (s) => s.skinP2PWinsReq(5),
      isUnlocked: (st) => st.p2pWinsCount >= 5,
      getProgress: (st, s) =>
          st.p2pWinsCount >= 5 ? s.unlockedLabel : '${st.p2pWinsCount}/5',
    ),
    ProfileIconItem(
      id: 'sun_sovereign',
      emoji: '☀️',
      iconData: Icons.wb_sunny_rounded,
      getName: (s) => s.iconSunSovereignName,
      getRequirement: (s) => s.iconDailyFirstReq(5),
      isUnlocked: (st) => st.dailyFirstPlaceCount >= 5,
      getProgress: (st, s) => st.dailyFirstPlaceCount >= 5
          ? s.unlockedLabel
          : '${st.dailyFirstPlaceCount}/5',
    ),
    ProfileIconItem(
      id: 'ink_comet',
      emoji: '☄️',
      iconData: Icons.rocket_launch_rounded,
      getName: (s) => s.iconInkCometName,
      getRequirement: (s) => s.iconBouncesReq(3000),
      isUnlocked: (st) => st.totalBouncesAllTime >= 3000,
      getProgress: (st, s) => st.totalBouncesAllTime >= 3000
          ? s.unlockedLabel
          : '${st.totalBouncesAllTime}/3000',
    ),
    ProfileIconItem(
      id: 'peak_deity',
      emoji: '🏔️',
      iconData: Icons.terrain_rounded,
      getName: (s) => s.iconPeakDeityName,
      getRequirement: (s) => s.iconReachLevelReq(75),
      isUnlocked: (st) => st.currentTowerLevel >= 75,
      getProgress: (st, s) => st.currentTowerLevel >= 75
          ? s.unlockedLabel
          : '${st.currentTowerLevel}/75',
    ),
  ];

  static ProfileIconItem getById(String id) {
    return allIcons.firstWhere(
      (e) => e.id == id,
      orElse: () => allIcons.first,
    );
  }

  /// Restituisce un titolo onorifico del giocatore basato sul livello e sui record
  static String getPlayerHonorTitle(StorageService storage, AppStrings s) {
    if (storage.p2pWinsCount >= 5) {
      return s.titleDuelMaster;
    }
    if (storage.dailyFirstPlaceCount >= 1) {
      return s.titleDailyChampion;
    }
    final lvl = storage.currentTowerLevel;
    if (lvl >= 50) return s.titleGrandShogun;
    if (lvl >= 30) return s.titleLegend;
    if (lvl >= 20) return s.titleBounceMaster;
    if (lvl >= 10) return s.titleRisographSentinel;
    if (lvl >= 5) return s.titleRisingClimber;
    return s.titleInkNovice;
  }
}

import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'app_strings.dart';
import 'palette_theme.dart';

/// Rappresenta un'abilità attiva equipaggiabile con tempo di ricarica (Cooldown in secondi)
/// utilizzabile durante la scalata e nelle sfide Multiplayer P2P.
class ClimbAbilityItem {
  final String id;
  final String emoji;
  final IconData iconData;
  final int unlockLevel;
  final double cooldownSeconds;
  final double activeDurationSeconds;
  final String Function(AppStrings s) getName;
  final String Function(AppStrings s) getDescription;
  final String Function(AppStrings s) getRequirement;
  final Color Function(RisographPalette p) getAccentColor;

  const ClimbAbilityItem({
    required this.id,
    required this.emoji,
    required this.iconData,
    required this.unlockLevel,
    required this.cooldownSeconds,
    this.activeDurationSeconds = 0.0,
    required this.getName,
    required this.getDescription,
    required this.getRequirement,
    required this.getAccentColor,
  });

  String get icon => emoji;
  int get unlockTowerLevel => unlockLevel;

  bool isUnlocked(Object storageOrLevel) {
    if (storageOrLevel is StorageService) {
      return storageOrLevel.currentTowerLevel >= unlockLevel;
    }
    if (storageOrLevel is int) {
      return storageOrLevel >= unlockLevel;
    }
    return false;
  }

  String getProgress(StorageService storage, AppStrings s) =>
      isUnlocked(storage)
          ? s.unlockedLabel
          : '${storage.currentTowerLevel}/$unlockLevel';
}

class ClimbAbilitiesCatalog {
  static final List<ClimbAbilityItem> allAbilities = [
    // 1. Presa Zen (Sbloccata dall'inizio / Livello 1)
    ClimbAbilityItem(
      id: 'zen_anchor',
      emoji: '🍃',
      iconData: Icons.anchor_rounded,
      unlockLevel: 1,
      cooldownSeconds: 14.0,
      activeDurationSeconds: 2.5,
      getName: (s) => s.abilityZenAnchorName,
      getDescription: (s) => s.abilityZenAnchorDesc,
      getRequirement: (s) => s.iconDefaultReq,
      getAccentColor: (p) => p.matchaSafe,
    ),

    // 2. Egida d'Inchiostro (Livello 5)
    ClimbAbilityItem(
      id: 'ink_aegis',
      emoji: '🛡️',
      iconData: Icons.shield_rounded,
      unlockLevel: 5,
      cooldownSeconds: 18.0,
      activeDurationSeconds: 0.0, // Scudo permanente finché non colpisce un ostacolo
      getName: (s) => s.abilityInkAegisName,
      getDescription: (s) => s.abilityInkAegisDesc,
      getRequirement: (s) => s.skinReachLevelReq(5),
      getAccentColor: (p) => p.matchaSafe,
    ),

    // 3. Spruzzo d'Inchiostro (Livello 10 - Disturbo P2P & Pulizia Ostacolo)
    ClimbAbilityItem(
      id: 'ink_sabotage',
      emoji: '🦑',
      iconData: Icons.blur_on_rounded,
      unlockLevel: 10,
      cooldownSeconds: 16.0,
      activeDurationSeconds: 3.5,
      getName: (s) => s.abilityInkSabotageName,
      getDescription: (s) => s.abilityInkSabotageDesc,
      getRequirement: (s) => s.skinReachLevelReq(10),
      getAccentColor: (p) => p.vermilionHazard,
    ),

    // 4. Slancio Hanko (Livello 15)
    ClimbAbilityItem(
      id: 'hanko_surge',
      emoji: '⚡',
      iconData: Icons.keyboard_double_arrow_up_rounded,
      unlockLevel: 15,
      cooldownSeconds: 16.0,
      activeDurationSeconds: 0.0,
      getName: (s) => s.abilityHankoSurgeName,
      getDescription: (s) => s.abilityHankoSurgeDesc,
      getRequirement: (s) => s.skinReachLevelReq(15),
      getAccentColor: (p) => p.ochreSeal,
    ),

    // 5. Passo d'Ombra (Livello 22)
    ClimbAbilityItem(
      id: 'shadow_phase',
      emoji: '👻',
      iconData: Icons.visibility_off_rounded,
      unlockLevel: 22,
      cooldownSeconds: 20.0,
      activeDurationSeconds: 3.5,
      getName: (s) => s.abilityShadowPhaseName,
      getDescription: (s) => s.abilityShadowPhaseDesc,
      getRequirement: (s) => s.skinReachLevelReq(22),
      getAccentColor: (p) =>
          p.isDark ? const Color(0xFFE0AAFF) : const Color(0xFF5A189A),
    ),

    // 6. Sigillo del Tempo (Livello 30)
    ClimbAbilityItem(
      id: 'chrono_seal',
      emoji: '⏳',
      iconData: Icons.hourglass_bottom_rounded,
      unlockLevel: 30,
      cooldownSeconds: 22.0,
      activeDurationSeconds: 5.0,
      getName: (s) => s.abilityChronoSealName,
      getDescription: (s) => s.abilityChronoSealDesc,
      getRequirement: (s) => s.skinReachLevelReq(30),
      getAccentColor: (p) => p.ochreSeal,
    ),
  ];

  static ClimbAbilityItem getById(String id) {
    return allAbilities.firstWhere(
      (e) => e.id == id,
      orElse: () => allAbilities.first,
    );
  }
}

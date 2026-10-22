import 'package:flutter/material.dart';

/// Definisce una palette morbida e rilassante ad alto contrasto.
/// Supporta l'interpolazione fluida [lerp] per transizioni rilassanti tra i temi.
class RisographPalette {
  final String id;
  final String name;
  final String subtitle;
  final Color paperBg;
  final Color paperCard;
  final Color paperGrid;
  final Color inkPrimary;
  final Color inkSecondary;
  final Color playerFill;
  final Color playerStroke;
  final Color matchaSafe;
  final Color vermilionHazard;
  final Color ochreSeal;
  final Color inkFloodTop;
  final Color inkFloodBottom;
  final Color shadowColor;
  final bool isDark;

  const RisographPalette({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.paperBg,
    required this.paperCard,
    required this.paperGrid,
    required this.inkPrimary,
    required this.inkSecondary,
    required this.playerFill,
    required this.playerStroke,
    required this.matchaSafe,
    required this.vermilionHazard,
    required this.ochreSeal,
    required this.inkFloodTop,
    required this.inkFloodBottom,
    required this.shadowColor,
    this.isDark = false,
  });

  /// Colore ad altissimo contrasto per testo o icone su pulsanti/badge [ochreSeal]
  Color get onOchreSeal => const Color(0xFF141517);

  /// Colore ad altissimo contrasto per testo o icone su pulsanti/badge [matchaSafe]
  Color get onMatchaSafe => isDark ? const Color(0xFF141517) : const Color(0xFFFFFFFF);

  /// Colore ad altissimo contrasto per testo o icone su pulsanti [playerFill]
  Color get onPlayerFill => isDark ? const Color(0xFF141517) : paperCard;

  /// Colore ad altissimo contrasto per testo o icone su sfondi [vermilionHazard]
  Color get onVermilionHazard => const Color(0xFFFFFFFF);

  /// Interpola dolcemente tutti i colori tra due palette per una transizione fluida
  static RisographPalette lerp(
    RisographPalette a,
    RisographPalette b,
    double t,
  ) {
    final clamped = t.clamp(0.0, 1.0);
    return RisographPalette(
      id: clamped < 0.5 ? a.id : b.id,
      name: clamped < 0.5 ? a.name : b.name,
      subtitle: clamped < 0.5 ? a.subtitle : b.subtitle,
      paperBg: Color.lerp(a.paperBg, b.paperBg, clamped)!,
      paperCard: Color.lerp(a.paperCard, b.paperCard, clamped)!,
      paperGrid: Color.lerp(a.paperGrid, b.paperGrid, clamped)!,
      inkPrimary: Color.lerp(a.inkPrimary, b.inkPrimary, clamped)!,
      inkSecondary: Color.lerp(a.inkSecondary, b.inkSecondary, clamped)!,
      playerFill: Color.lerp(a.playerFill, b.playerFill, clamped)!,
      playerStroke: Color.lerp(a.playerStroke, b.playerStroke, clamped)!,
      matchaSafe: Color.lerp(a.matchaSafe, b.matchaSafe, clamped)!,
      vermilionHazard:
          Color.lerp(a.vermilionHazard, b.vermilionHazard, clamped)!,
      ochreSeal: Color.lerp(a.ochreSeal, b.ochreSeal, clamped)!,
      inkFloodTop: Color.lerp(a.inkFloodTop, b.inkFloodTop, clamped)!,
      inkFloodBottom:
          Color.lerp(a.inkFloodBottom, b.inkFloodBottom, clamped)!,
      shadowColor: Color.lerp(a.shadowColor, b.shadowColor, clamped)!,
      isDark: clamped < 0.5 ? a.isDark : b.isDark,
    );
  }

  /// 1. TEMA SABBIA (Default Diurno caldo e riposante)
  static const washiIvory = RisographPalette(
    id: 'washi_ivory',
    name: 'Sabbia',
    subtitle: 'Chiaro & Rilassante',
    paperBg: Color(0xFFF4EFE6),
    paperCard: Color(0xFFFAF7F2),
    paperGrid: Color(0xFFE2D9C8),
    inkPrimary: Color(0xFF1E1E24),
    inkSecondary: Color(0xFF6B665E),
    playerFill: Color(0xFF1D3557),
    playerStroke: Color(0xFF11161B),
    matchaSafe: Color(0xFF2A9D8F),
    vermilionHazard: Color(0xFFD62828),
    ochreSeal: Color(0xFFE76F51),
    inkFloodTop: Color(0xFF2B2D42),
    inkFloodBottom: Color(0xFF14151F),
    shadowColor: Color(0x261E1E24),
    isDark: false,
  );

  /// 2. TEMA NOTTE (Antracite caldo per la sera, zero neon)
  static const sumiCharcoal = RisographPalette(
    id: 'sumi_charcoal',
    name: 'Notte',
    subtitle: 'Scuro & Morbido',
    paperBg: Color(0xFF232426),
    paperCard: Color(0xFF2C2E30),
    paperGrid: Color(0xFF35373A),
    inkPrimary: Color(0xFFF4EFE6),
    inkSecondary: Color(0xFFA5A096),
    playerFill: Color(0xFFF4F1DE),
    playerStroke: Color(0xFFE07A5F),
    matchaSafe: Color(0xFF81B29A),
    vermilionHazard: Color(0xFFE05A47),
    ochreSeal: Color(0xFFF2CC8F),
    inkFloodTop: Color(0xFF141517),
    inkFloodBottom: Color(0xFF0B0C0E),
    shadowColor: Color(0x45000000),
    isDark: true,
  );

  /// 3. TEMA SALVIA (Verde botanico rilassante)
  static const kyotoMatcha = RisographPalette(
    id: 'kyoto_matcha',
    name: 'Salvia',
    subtitle: 'Verde & Naturale',
    paperBg: Color(0xFFE9F0E6),
    paperCard: Color(0xFFF4F8F2),
    paperGrid: Color(0xFFD0DDD0),
    inkPrimary: Color(0xFF1B2E25),
    inkSecondary: Color(0xFF43584E),
    playerFill: Color(0xFF2D6A4F),
    playerStroke: Color(0xFF1B2E25),
    matchaSafe: Color(0xFF52B788),
    vermilionHazard: Color(0xFFBC4749),
    ochreSeal: Color(0xFFDDA15E),
    inkFloodTop: Color(0xFF1B2E25),
    inkFloodBottom: Color(0xFF0F1A15),
    shadowColor: Color(0x241B2E25),
    isDark: false,
  );

  static const List<RisographPalette> all = [
    washiIvory,
    sumiCharcoal,
    kyotoMatcha,
  ];

  static RisographPalette fromId(String id) {
    return all.firstWhere((p) => p.id == id, orElse: () => washiIvory);
  }
}

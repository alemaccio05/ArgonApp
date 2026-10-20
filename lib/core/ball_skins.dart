import 'dart:math';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'app_strings.dart';
import 'palette_theme.dart';

/// Rappresenta una skin sbloccabile ed equipaggiabile per la palla elastica del giocatore.
class BallSkinItem {
  final String id;
  final String emoji;
  final String Function(AppStrings s) getName;
  final String Function(AppStrings s) getDescription;
  final String Function(AppStrings s) getRequirement;
  final bool Function(StorageService storage) isUnlocked;
  final String Function(StorageService storage, AppStrings s) getProgress;
  final Color Function(RisographPalette p) getCoreColor;
  final Color Function(RisographPalette p) getStrokeColor;
  final Color Function(RisographPalette p) getTrailColor;
  final void Function(
    Canvas canvas,
    double radius,
    RisographPalette p,
    double rotation,
  ) renderCustomSkin;

  const BallSkinItem({
    required this.id,
    required this.emoji,
    required this.getName,
    required this.getDescription,
    required this.getRequirement,
    required this.isUnlocked,
    required this.getProgress,
    required this.getCoreColor,
    required this.getStrokeColor,
    required this.getTrailColor,
    required this.renderCustomSkin,
  });
}

class BallSkinsCatalog {
  static final List<BallSkinItem> allSkins = [
    // 1. Sfera Inchiostro Classica (Default)
    BallSkinItem(
      id: 'classic_ink',
      emoji: '⚫',
      getName: (s) => s.skinClassicInkName,
      getDescription: (s) => s.skinClassicInkDesc,
      getRequirement: (s) => s.iconDefaultReq,
      isUnlocked: (_) => true,
      getProgress: (_, s) => s.unlockedLabel,
      getCoreColor: (p) => p.playerFill,
      getStrokeColor: (p) => p.playerStroke,
      getTrailColor: (p) => p.playerFill,
      renderCustomSkin: (canvas, radius, p, rot) {
        // Riflesso concentrico d'inchiostro tradizionale
        canvas.drawCircle(
          Offset.zero,
          radius * 0.45,
          Paint()
            ..color = p.paperCard.withAlpha((0.20 * 255).round())
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      },
    ),

    // 2. Sfera Matcha Zen (Livello 3)
    BallSkinItem(
      id: 'matcha_zen',
      emoji: '🍵',
      getName: (s) => s.skinMatchaZenName,
      getDescription: (s) => s.skinMatchaZenDesc,
      getRequirement: (s) => s.skinReachLevelReq(3),
      isUnlocked: (st) => st.currentTowerLevel >= 3,
      getProgress: (st, s) =>
          st.currentTowerLevel >= 3 ? s.unlockedLabel : '${st.currentTowerLevel}/3',
      getCoreColor: (p) => p.matchaSafe,
      getStrokeColor: (p) => p.inkPrimary,
      getTrailColor: (p) => p.matchaSafe,
      renderCustomSkin: (canvas, radius, p, rot) {
        // Disegno di una foglia matcha zen al centro
        final leafPaint = Paint()
          ..color = p.paperCard.withAlpha((0.85 * 255).round())
          ..style = PaintingStyle.fill;
        final path = Path();
        path.moveTo(0, -radius * 0.55);
        path.quadraticBezierTo(
          radius * 0.45,
          0,
          0,
          radius * 0.55,
        );
        path.quadraticBezierTo(
          -radius * 0.45,
          0,
          0,
          -radius * 0.55,
        );
        canvas.drawPath(path, leafPaint);
      },
    ),

    // 3. Sfera Stella Shinobi (Livello 8)
    BallSkinItem(
      id: 'shinobi_star',
      emoji: '🥷',
      getName: (s) => s.skinShinobiStarName,
      getDescription: (s) => s.skinShinobiStarDesc,
      getRequirement: (s) => s.skinReachLevelReq(8),
      isUnlocked: (st) => st.currentTowerLevel >= 8,
      getProgress: (st, s) =>
          st.currentTowerLevel >= 8 ? s.unlockedLabel : '${st.currentTowerLevel}/8',
      getCoreColor: (p) => p.inkPrimary,
      getStrokeColor: (p) => p.paperCard,
      getTrailColor: (p) => p.inkPrimary,
      renderCustomSkin: (canvas, radius, p, rot) {
        // Shuriken rotante a 4 punte
        final starPaint = Paint()
          ..color = p.paperCard.withAlpha((0.90 * 255).round())
          ..style = PaintingStyle.fill;
        canvas.save();
        canvas.rotate(rot * 2.0);
        final path = Path();
        for (int i = 0; i < 4; i++) {
          final ang = i * pi / 2;
          final xOuter = cos(ang) * (radius * 0.65);
          final yOuter = sin(ang) * (radius * 0.65);
          final xInner = cos(ang + pi / 4) * (radius * 0.22);
          final yInner = sin(ang + pi / 4) * (radius * 0.22);
          if (i == 0) {
            path.moveTo(xOuter, yOuter);
          } else {
            path.lineTo(xOuter, yOuter);
          }
          path.lineTo(xInner, yInner);
        }
        path.close();
        canvas.drawPath(path, starPaint);
        canvas.drawCircle(
          Offset.zero,
          radius * 0.15,
          Paint()..color = p.inkPrimary,
        );
        canvas.restore();
      },
    ),

    // 4. Sfera Papiro Origami (Livello 15)
    BallSkinItem(
      id: 'paper_origami',
      emoji: '🕊️',
      getName: (s) => s.skinPaperOrigamiName,
      getDescription: (s) => s.skinPaperOrigamiDesc,
      getRequirement: (s) => s.skinReachLevelReq(15),
      isUnlocked: (st) => st.currentTowerLevel >= 15,
      getProgress: (st, s) => st.currentTowerLevel >= 15
          ? s.unlockedLabel
          : '${st.currentTowerLevel}/15',
      getCoreColor: (p) => p.paperCard,
      getStrokeColor: (p) => p.inkPrimary,
      getTrailColor: (p) => p.paperGrid,
      renderCustomSkin: (canvas, radius, p, rot) {
        // Linee di piega geometriche stile origami
        final linePaint = Paint()
          ..color = p.inkPrimary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3;
        canvas.drawLine(
          Offset(-radius * 0.6, -radius * 0.2),
          Offset(radius * 0.6, radius * 0.2),
          linePaint,
        );
        canvas.drawLine(
          Offset(0, -radius * 0.65),
          Offset(radius * 0.35, radius * 0.45),
          linePaint,
        );
        canvas.drawLine(
          Offset(-radius * 0.4, radius * 0.3),
          Offset(radius * 0.5, -radius * 0.3),
          linePaint,
        );
      },
    ),

    // 5. Sfera Drago di Fuoco (Livello 25)
    BallSkinItem(
      id: 'dragon_ember',
      emoji: '🐉',
      getName: (s) => s.skinDragonEmberName,
      getDescription: (s) => s.skinDragonEmberDesc,
      getRequirement: (s) => s.skinReachLevelReq(25),
      isUnlocked: (st) => st.currentTowerLevel >= 25,
      getProgress: (st, s) => st.currentTowerLevel >= 25
          ? s.unlockedLabel
          : '${st.currentTowerLevel}/25',
      getCoreColor: (p) => p.vermilionHazard,
      getStrokeColor: (p) => p.inkPrimary,
      getTrailColor: (p) => p.vermilionHazard,
      renderCustomSkin: (canvas, radius, p, rot) {
        // Nucleo fiammeggiante con vortice solare
        canvas.drawCircle(
          Offset.zero,
          radius * 0.52,
          Paint()..color = p.ochreSeal,
        );
        canvas.drawCircle(
          Offset.zero,
          radius * 0.28,
          Paint()..color = p.paperCard,
        );
      },
    ),

    // 6. Sfera Cosmo Celeste (Livello 35)
    BallSkinItem(
      id: 'celestial_void',
      emoji: '🌌',
      getName: (s) => s.skinCelestialVoidName,
      getDescription: (s) => s.skinCelestialVoidDesc,
      getRequirement: (s) => s.skinReachLevelReq(35),
      isUnlocked: (st) => st.currentTowerLevel >= 35,
      getProgress: (st, s) => st.currentTowerLevel >= 35
          ? s.unlockedLabel
          : '${st.currentTowerLevel}/35',
      getCoreColor: (p) => p.inkPrimary,
      getStrokeColor: (p) => p.ochreSeal,
      getTrailColor: (p) => p.ochreSeal,
      renderCustomSkin: (canvas, radius, p, rot) {
        // Mezzaluna e costellazioni
        canvas.save();
        canvas.rotate(rot);
        final moonPath = Path();
        moonPath.addArc(
          Rect.fromCircle(center: Offset.zero, radius: radius * 0.55),
          -pi / 2,
          pi,
        );
        moonPath.arcTo(
          Rect.fromCircle(
            center: Offset(radius * 0.22, 0),
            radius: radius * 0.42,
          ),
          pi / 2,
          -pi,
          false,
        );
        moonPath.close();
        canvas.drawPath(
          moonPath,
          Paint()..color = p.ochreSeal,
        );
        canvas.restore();
      },
    ),

    // 7. Sfera Podio di Bronzo (Top 3 Giornaliera x1)
    BallSkinItem(
      id: 'daily_bronze',
      emoji: '🥉',
      getName: (s) => s.skinDailyBronzeName,
      getDescription: (s) => s.skinDailyBronzeDesc,
      getRequirement: (s) => s.skinTop3Req(1),
      isUnlocked: (st) => st.dailyTop3Count >= 1,
      getProgress: (st, s) =>
          st.dailyTop3Count >= 1 ? s.unlockedLabel : '${st.dailyTop3Count}/1',
      getCoreColor: (p) => const Color(0xFFC47B45),
      getStrokeColor: (p) => p.inkPrimary,
      getTrailColor: (p) => const Color(0xFFC47B45),
      renderCustomSkin: (canvas, radius, p, rot) {
        // Sigillo romboidale di bronzo
        final path = Path();
        path.moveTo(0, -radius * 0.55);
        path.lineTo(radius * 0.55, 0);
        path.lineTo(0, radius * 0.55);
        path.lineTo(-radius * 0.55, 0);
        path.close();
        canvas.drawPath(
          path,
          Paint()
            ..color = p.paperCard.withAlpha((0.75 * 255).round())
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
      },
    ),

    // 8. Sfera Prisma d'Argento (Top 3 Giornaliera x3)
    BallSkinItem(
      id: 'daily_silver',
      emoji: '🥈',
      getName: (s) => s.skinDailySilverName,
      getDescription: (s) => s.skinDailySilverDesc,
      getRequirement: (s) => s.skinTop3Req(3),
      isUnlocked: (st) => st.dailyTop3Count >= 3,
      getProgress: (st, s) =>
          st.dailyTop3Count >= 3 ? s.unlockedLabel : '${st.dailyTop3Count}/3',
      getCoreColor: (p) => const Color(0xFFBDC7D0),
      getStrokeColor: (p) => p.inkPrimary,
      getTrailColor: (p) => const Color(0xFFBDC7D0),
      renderCustomSkin: (canvas, radius, p, rot) {
        // Doppia armatura circolare d'argento
        canvas.drawCircle(
          Offset.zero,
          radius * 0.60,
          Paint()
            ..color = p.paperCard
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
        canvas.drawCircle(
          Offset.zero,
          radius * 0.32,
          Paint()..color = p.inkPrimary,
        );
      },
    ),

    // 9. Sfera Aureo del Campione (1° Posto Giornaliero x1)
    BallSkinItem(
      id: 'daily_gold',
      emoji: '👑',
      getName: (s) => s.skinDailyGoldName,
      getDescription: (s) => s.skinDailyGoldDesc,
      getRequirement: (s) => s.skinDailyFirstReq(1),
      isUnlocked: (st) => st.dailyFirstPlaceCount >= 1,
      getProgress: (st, s) => st.dailyFirstPlaceCount >= 1
          ? s.unlockedLabel
          : '${st.dailyFirstPlaceCount}/1',
      getCoreColor: (p) => p.ochreSeal,
      getStrokeColor: (p) => p.inkPrimary,
      getTrailColor: (p) => p.ochreSeal,
      renderCustomSkin: (canvas, radius, p, rot) {
        // Corona reale del campione a 3 punte
        final crownPath = Path();
        final r = radius * 0.58;
        crownPath.moveTo(-r, r * 0.4);
        crownPath.lineTo(-r, -r * 0.4);
        crownPath.lineTo(-r * 0.45, 0);
        crownPath.lineTo(0, -r * 0.7);
        crownPath.lineTo(r * 0.45, 0);
        crownPath.lineTo(r, -r * 0.4);
        crownPath.lineTo(r, r * 0.4);
        crownPath.close();

        canvas.drawPath(
          crownPath,
          Paint()..color = p.paperCard,
        );
        canvas.drawPath(
          crownPath,
          Paint()
            ..color = p.inkPrimary
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.3,
        );
      },
    ),

    // 10. Sfera Fulmine del Tuono (750 rimbalzi totali)
    BallSkinItem(
      id: 'thunder_spark',
      emoji: '⚡',
      getName: (s) => s.skinThunderSparkName,
      getDescription: (s) => s.skinThunderSparkDesc,
      getRequirement: (s) => s.skinBouncesReq(750),
      isUnlocked: (st) => st.totalBouncesAllTime >= 750,
      getProgress: (st, s) => st.totalBouncesAllTime >= 750
          ? s.unlockedLabel
          : '${st.totalBouncesAllTime}/750',
      getCoreColor: (p) => const Color(0xFFF7C844),
      getStrokeColor: (p) => p.inkPrimary,
      getTrailColor: (p) => const Color(0xFFF7C844),
      renderCustomSkin: (canvas, radius, p, rot) {
        // Saetta a zig-zag dinamica
        final boltPath = Path();
        final r = radius * 0.65;
        boltPath.moveTo(r * 0.15, -r);
        boltPath.lineTo(-r * 0.45, r * 0.05);
        boltPath.lineTo(0, r * 0.05);
        boltPath.lineTo(-r * 0.15, r);
        boltPath.lineTo(r * 0.45, -r * 0.05);
        boltPath.lineTo(0, -r * 0.05);
        boltPath.close();

        canvas.drawPath(
          boltPath,
          Paint()..color = p.inkPrimary,
        );
      },
    ),
  ];

  static BallSkinItem getById(String id) {
    return allSkins.firstWhere(
      (e) => e.id == id,
      orElse: () => allSkins.first,
    );
  }
}

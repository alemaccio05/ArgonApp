import 'dart:math';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'app_strings.dart';
import 'palette_theme.dart';

/// Rappresenta una skin sbloccabile ed equipaggiabile per la palla elastica del giocatore.
/// Tutte le skin sono calibrate per garantire un contrasto netto e leggibile
/// su ciascuno dei 3 temi Risograph (Sabbia, Notte, Salvia), sia contro lo sfondo
/// della torre sia sopra le piattaforme verdi adesive.
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
  static const Color _inkDark = Color(0xFF161920);
  static const Color _warmIvory = Color(0xFFFFFDF8);

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
      getCoreColor: (p) =>
          p.id == 'kyoto_matcha' ? const Color(0xFF183A2C) : p.playerFill,
      getStrokeColor: (p) =>
          p.isDark ? const Color(0xFFE07A5F) : p.playerStroke,
      getTrailColor: (p) =>
          p.id == 'kyoto_matcha' ? const Color(0xFF183A2C) : p.playerFill,
      renderCustomSkin: (canvas, radius, p, rot) {
        // Doppio anello concentrico ad alto contrasto stile timbro d'inchiostro
        final innerRingColor = p.isDark
            ? _inkDark.withAlpha((0.55 * 255).round())
            : _warmIvory.withAlpha((0.55 * 255).round());
        canvas.drawCircle(
          Offset.zero,
          radius * 0.52,
          Paint()
            ..color = innerRingColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
        canvas.drawCircle(
          Offset.zero,
          radius * 0.22,
          Paint()
            ..color = p.isDark ? const Color(0xFFE07A5F) : p.ochreSeal
            ..style = PaintingStyle.fill,
        );
      },
    ),

    // 2. Sfera Matcha Zen (Livello 3)
    // Calibrata con giada imperiale profonda + bordo avorio/inchiostro per staccare
    // nettamente sia sul tema Salvia sia sulle piattaforme verdi matchaSafe.
    BallSkinItem(
      id: 'matcha_zen',
      emoji: '🍵',
      getName: (s) => s.skinMatchaZenName,
      getDescription: (s) => s.skinMatchaZenDesc,
      getRequirement: (s) => s.skinReachLevelReq(3),
      isUnlocked: (st) => st.currentTowerLevel >= 3,
      getProgress: (st, s) => st.currentTowerLevel >= 3
          ? s.unlockedLabel
          : '${st.currentTowerLevel}/3',
      getCoreColor: (p) =>
          p.isDark ? const Color(0xFF2B7A5A) : const Color(0xFF195E43),
      getStrokeColor: (p) =>
          p.isDark ? const Color(0xFFF4F1DE) : const Color(0xFF12231B),
      getTrailColor: (p) =>
          p.isDark ? const Color(0xFF52B788) : const Color(0xFF195E43),
      renderCustomSkin: (canvas, radius, p, rot) {
        // Aureola interna chiara per separare la sfera dalle piattaforme verdi
        canvas.drawCircle(
          Offset.zero,
          radius * 0.80,
          Paint()
            ..color = _warmIvory.withAlpha((0.40 * 255).round())
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );

        // Foglia Matcha Zen in avorio luminoso con nervatura centrale scura
        final path = Path()
          ..moveTo(0, -radius * 0.58)
          ..quadraticBezierTo(radius * 0.48, 0, 0, radius * 0.58)
          ..quadraticBezierTo(-radius * 0.48, 0, 0, -radius * 0.58);

        canvas.drawPath(
          path,
          Paint()
            ..color = _warmIvory
            ..style = PaintingStyle.fill,
        );
        canvas.drawPath(
          path,
          Paint()
            ..color = _inkDark
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
        canvas.drawLine(
          Offset(0, -radius * 0.42),
          Offset(0, radius * 0.42),
          Paint()
            ..color = const Color(0xFF195E43)
            ..strokeWidth = 1.3,
        );
      },
    ),

    // 3. Sfera Stella Shinobi (Livello 8)
    // Nucleo ossidiana scuro costante su tutti i temi così lo shuriken d'acciaio
    // e il contorno avorio/cremisi risultano sempre nitidissimi anche sul tema Notte.
    BallSkinItem(
      id: 'shinobi_star',
      emoji: '🥷',
      getName: (s) => s.skinShinobiStarName,
      getDescription: (s) => s.skinShinobiStarDesc,
      getRequirement: (s) => s.skinReachLevelReq(8),
      isUnlocked: (st) => st.currentTowerLevel >= 8,
      getProgress: (st, s) => st.currentTowerLevel >= 8
          ? s.unlockedLabel
          : '${st.currentTowerLevel}/8',
      getCoreColor: (_) => const Color(0xFF1C212B),
      getStrokeColor: (p) =>
          p.isDark ? const Color(0xFFF4EFE6) : const Color(0xFF11141A),
      getTrailColor: (p) =>
          p.isDark ? const Color(0xFFE07A5F) : const Color(0xFF2B3344),
      renderCustomSkin: (canvas, radius, p, rot) {
        // Anello perimetrale cremisi shinobi
        canvas.drawCircle(
          Offset.zero,
          radius * 0.78,
          Paint()
            ..color = p.vermilionHazard.withAlpha((0.75 * 255).round())
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.3,
        );

        // Shuriken rotante a 4 punte in acciaio chiaro ad altissimo contrasto
        canvas.save();
        canvas.rotate(rot * 2.0);
        final path = Path();
        for (int i = 0; i < 4; i++) {
          final ang = i * pi / 2;
          final xOuter = cos(ang) * (radius * 0.68);
          final yOuter = sin(ang) * (radius * 0.68);
          final xInner = cos(ang + pi / 4) * (radius * 0.24);
          final yInner = sin(ang + pi / 4) * (radius * 0.24);
          if (i == 0) {
            path.moveTo(xOuter, yOuter);
          } else {
            path.lineTo(xOuter, yOuter);
          }
          path.lineTo(xInner, yInner);
        }
        path.close();
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFFF4F1EA)
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          Offset.zero,
          radius * 0.17,
          Paint()..color = p.vermilionHazard,
        );
        canvas.restore();
      },
    ),

    // 4. Sfera Papiro Origami (Livello 15)
    // Carta Washi calda sfaccettata: non usa mai p.paperCard (che su Notte è grigio scuro
    // e sugli altri temi coincide con le card UI), ma un avorio pergamena con sfaccettature
    // geometriche bicolori e bordatura marcata.
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
      getCoreColor: (p) =>
          p.isDark ? const Color(0xFFF5EFE2) : const Color(0xFFFFFBF0),
      getStrokeColor: (p) =>
          p.isDark ? const Color(0xFFF2CC8F) : const Color(0xFF1B1E24),
      getTrailColor: (p) =>
          p.isDark ? const Color(0xFFF2CC8F) : const Color(0xFFD98A4E),
      renderCustomSkin: (canvas, radius, p, rot) {
        // Facce ombreggiate dell'origami per staccare dallo sfondo chiaro di Sabbia/Salvia
        final shadeFacet = Path()
          ..moveTo(0, -radius * 0.82)
          ..lineTo(radius * 0.78, radius * 0.18)
          ..lineTo(0, radius * 0.82)
          ..close();
        canvas.drawPath(
          shadeFacet,
          Paint()
            ..color = const Color(0xFFE4D2B4)
            ..style = PaintingStyle.fill,
        );

        final accentFacet = Path()
          ..moveTo(-radius * 0.76, -radius * 0.15)
          ..lineTo(0, -radius * 0.82)
          ..lineTo(0, radius * 0.25)
          ..close();
        canvas.drawPath(
          accentFacet,
          Paint()
            ..color = const Color(0xFFE76F51).withAlpha((0.42 * 255).round())
            ..style = PaintingStyle.fill,
        );

        // Linee di piega geometriche nette in inchiostro scuro
        final linePaint = Paint()
          ..color = _inkDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.45;
        canvas.drawLine(
          Offset(-radius * 0.65, -radius * 0.2),
          Offset(radius * 0.65, radius * 0.2),
          linePaint,
        );
        canvas.drawLine(
          Offset(0, -radius * 0.72),
          Offset(radius * 0.35, radius * 0.52),
          linePaint,
        );
        canvas.drawLine(
          Offset(-radius * 0.45, radius * 0.35),
          Offset(radius * 0.52, -radius * 0.32),
          linePaint,
        );
      },
    ),

    // 5. Sfera Drago di Fuoco (Livello 25)
    // Nucleo incandescente oro/avorio costante (mai grigio scuro in modalità Notte)
    // e corona esterna ad alto contrasto per distinguerla subito dagli ostacoli rossi.
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
      getCoreColor: (_) => const Color(0xFFC92A2A),
      getStrokeColor: (p) =>
          p.isDark ? const Color(0xFFFFD166) : const Color(0xFF161920),
      getTrailColor: (_) => const Color(0xFFF77F00),
      renderCustomSkin: (canvas, radius, p, rot) {
        // Nucleo fiammeggiante ambra-oro con cuore incandescente avorio
        canvas.drawCircle(
          Offset.zero,
          radius * 0.56,
          Paint()..color = const Color(0xFFFF9F1C),
        );
        canvas.drawCircle(
          Offset.zero,
          radius * 0.30,
          Paint()..color = const Color(0xFFFFF3B0),
        );
        canvas.drawCircle(
          Offset.zero,
          radius * 0.56,
          Paint()
            ..color = _inkDark.withAlpha((0.45 * 255).round())
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1,
        );
      },
    ),

    // 6. Sfera Cosmo Celeste (Livello 35)
    // Blu notte cosmico profondo su tutti i temi così la mezzaluna dorata e le stelle
    // risaltano sempre (evitando il crema-su-crema nel tema Notte).
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
      getCoreColor: (_) => const Color(0xFF181E38),
      getStrokeColor: (p) =>
          p.isDark ? const Color(0xFFF6C967) : const Color(0xFF111528),
      getTrailColor: (_) => const Color(0xFFF6C967),
      renderCustomSkin: (canvas, radius, p, rot) {
        // Anello celeste dorato interno
        canvas.drawCircle(
          Offset.zero,
          radius * 0.80,
          Paint()
            ..color = const Color(0xFFF6C967).withAlpha((0.45 * 255).round())
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1,
        );

        // Mezzaluna dorata e stelle brillanti
        canvas.save();
        canvas.rotate(rot);
        final moonPath = Path()
          ..addArc(
            Rect.fromCircle(center: Offset.zero, radius: radius * 0.56),
            -pi / 2,
            pi,
          )
          ..arcTo(
            Rect.fromCircle(
              center: Offset(radius * 0.22, 0),
              radius: radius * 0.42,
            ),
            pi / 2,
            -pi,
            false,
          )
          ..close();
        canvas.drawPath(
          moonPath,
          Paint()..color = const Color(0xFFF6C967),
        );
        canvas.drawCircle(
          Offset(-radius * 0.32, -radius * 0.18),
          radius * 0.10,
          Paint()..color = _warmIvory,
        );
        canvas.drawCircle(
          Offset(-radius * 0.18, radius * 0.28),
          radius * 0.08,
          Paint()..color = _warmIvory,
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
      getCoreColor: (_) => const Color(0xFFC4743D),
      getStrokeColor: (p) =>
          p.isDark ? const Color(0xFFF8E5CE) : const Color(0xFF1E1610),
      getTrailColor: (_) => const Color(0xFFC4743D),
      renderCustomSkin: (canvas, radius, p, rot) {
        // Sigillo romboidale di bronzo con riempimento champagne e incisione scura
        final path = Path()
          ..moveTo(0, -radius * 0.56)
          ..lineTo(radius * 0.56, 0)
          ..lineTo(0, radius * 0.56)
          ..lineTo(-radius * 0.56, 0)
          ..close();
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFFFFF4E2).withAlpha((0.35 * 255).round())
            ..style = PaintingStyle.fill,
        );
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFFFFF4E2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );
        canvas.drawCircle(
          Offset.zero,
          radius * 0.18,
          Paint()..color = const Color(0xFF2B180A),
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
      getCoreColor: (p) =>
          p.isDark ? const Color(0xFFBCCAD6) : const Color(0xFFA9BCCB),
      getStrokeColor: (p) =>
          p.isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1A222C),
      getTrailColor: (_) => const Color(0xFF94A8B8),
      renderCustomSkin: (canvas, radius, p, rot) {
        // Doppia armatura circolare d'argento con nucleo acciaio scuro ad alto contrasto
        canvas.drawCircle(
          Offset.zero,
          radius * 0.62,
          Paint()
            ..color = const Color(0xFFF8FAFC)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
        canvas.drawCircle(
          Offset.zero,
          radius * 0.44,
          Paint()
            ..color = const Color(0xFF1E293B)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.3,
        );
        canvas.drawCircle(
          Offset.zero,
          radius * 0.28,
          Paint()..color = const Color(0xFF1E293B),
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
      getCoreColor: (_) => const Color(0xFFE8A317),
      getStrokeColor: (p) =>
          p.isDark ? const Color(0xFFFFF6D6) : const Color(0xFF1E1910),
      getTrailColor: (_) => const Color(0xFFE8A317),
      renderCustomSkin: (canvas, radius, p, rot) {
        // Corona reale del campione a 3 punte in avorio puro con bordo inchiostro scuro
        final crownPath = Path();
        final r = radius * 0.58;
        crownPath.moveTo(-r, r * 0.42);
        crownPath.lineTo(-r, -r * 0.42);
        crownPath.lineTo(-r * 0.45, 0);
        crownPath.lineTo(0, -r * 0.72);
        crownPath.lineTo(r * 0.45, 0);
        crownPath.lineTo(r, -r * 0.42);
        crownPath.lineTo(r, r * 0.42);
        crownPath.close();

        canvas.drawPath(
          crownPath,
          Paint()..color = _warmIvory,
        );
        canvas.drawPath(
          crownPath,
          Paint()
            ..color = _inkDark
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
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
      getCoreColor: (_) => const Color(0xFFF5B82E),
      getStrokeColor: (p) =>
          p.isDark ? const Color(0xFFFFF5C0) : const Color(0xFF181A20),
      getTrailColor: (_) => const Color(0xFFF5B82E),
      renderCustomSkin: (canvas, radius, p, rot) {
        // Saetta a zig-zag in antracite tempesta bordata di bianco (sempre visibile anche su Notte)
        final boltPath = Path();
        final r = radius * 0.66;
        boltPath.moveTo(r * 0.16, -r);
        boltPath.lineTo(-r * 0.46, r * 0.05);
        boltPath.lineTo(0, r * 0.05);
        boltPath.lineTo(-r * 0.16, r);
        boltPath.lineTo(r * 0.46, -r * 0.05);
        boltPath.lineTo(0, -r * 0.05);
        boltPath.close();

        canvas.drawPath(
          boltPath,
          Paint()..color = _inkDark,
        );
        canvas.drawPath(
          boltPath,
          Paint()
            ..color = _warmIvory
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
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

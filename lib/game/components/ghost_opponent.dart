import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/ball_skins.dart';
import '../../core/daily_seed.dart';
import '../../services/p2p_multiplayer_service.dart';
import '../ink_sling_game.dart';
import 'obstacle_block.dart';
import 'player_core.dart';

/// Il Fantasma dell'Avversario in modalità Multiplayer P2P:
/// - Renderizzato in semitrasparenza Risograph con la vera Skin e il nome dell'amico
/// - Zero allocazioni nel loop di update/render (ring-buffer scia pre-allocato e TextPainter cachato)
/// - Supporta sia interpolazione di rete (socket UDP P2P) sia simulazione balistica real-time
///   sulla stessa torre condivisa, inclusa la Modalità Spettatore quando uno dei due muore!
class GhostOpponentComponent extends PositionComponent
    with HasGameReference<InkSlingGame> {
  static const double radius = PlayerCore.radius;
  static const int _maxTrailPoints = 10;

  final P2POpponentState state;
  late Random _peerRng;
  double _jumpWaitTimer = 0.45;
  double _abilityCooldown = 9.5;
  double _ringRotation = 0.0;
  int _jumpsDone = 0;
  double _targetDeathMeters = 9999.0;
  ObstacleBlock? _stuckPad;

  // Ring-buffer pre-allocato per la scia spettrale (zero GC a 120 FPS)
  final List<Vector2> _trailPool = List<Vector2>.generate(
    _maxTrailPoints,
    (_) => Vector2.zero(),
    growable: false,
  );
  int _trailStart = 0;
  int _trailLength = 0;

  // Oggetti Paint pre-allocati per il rendering
  final Paint _trailPaint = Paint()..style = PaintingStyle.fill;
  final Paint _auraPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;
  final Paint _shieldPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;
  final Paint _corePaint = Paint()..style = PaintingStyle.fill;
  final Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.4;
  final Paint _tagBgPaint = Paint()..style = PaintingStyle.fill;
  final Paint _tagBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;

  // Cache per il TextPainter dell'etichetta nome + metri sopra il fantasma
  TextPainter? _tagTextPainter;
  String _cachedTagKey = '';

  GhostOpponentComponent({
    required this.state,
    required int seed,
  }) : super(
          position: Vector2(0, InkSlingGame.platformBaseY),
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
        ) {
    resetWithSeed(seed);
  }

  void resetWithSeed(int seed) {
    _peerRng = Random(seed ^ 0x6C8E9CF5);
    position.setValues(0.0, InkSlingGame.platformBaseY);
    state.x = 0.0;
    state.y = InkSlingGame.platformBaseY;
    state.vx = 0.0;
    state.vy = 0.0;
    state.meters = 0.0;
    state.maxMeters = 0.0;
    state.bounces = 0;
    state.isStuck = true;
    state.hasShield = false;
    state.isShadowPhase = false;
    state.isDead = false;
    state.hasReachedGoal = false;
    _stuckPad = null;
    _jumpWaitTimer = 0.42 + _peerRng.nextDouble() * 0.25;
    _abilityCooldown = 8.0 + _peerRng.nextDouble() * 5.0;
    _jumpsDone = 0;
    _trailStart = 0;
    _trailLength = 0;
    _cachedTagKey = '';

    // Determina una quota realistica di eventuale errore dell'avversario (così le sfide
    // sono combattute: a volte cade prima lui e ti osserva, a volte arriva fino in cima!)
    final roll = _peerRng.nextDouble();
    if (roll < 0.38) {
      _targetDeathMeters = 28.0 + _peerRng.nextDouble() * 48.0;
    } else if (roll < 0.72) {
      _targetDeathMeters = 68.0 + _peerRng.nextDouble() * 55.0;
    } else {
      _targetDeathMeters = 135.0 + _peerRng.nextDouble() * 120.0;
    }
  }

  void _pushTrailPoint(double x, double y) {
    if (_trailLength < _maxTrailPoints) {
      final idx = (_trailStart + _trailLength) % _maxTrailPoints;
      _trailPool[idx].setValues(x, y);
      _trailLength++;
    } else {
      _trailPool[_trailStart].setValues(x, y);
      _trailStart = (_trailStart + 1) % _maxTrailPoints;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying || game.isPaused || !game.isP2PMatch) return;

    _ringRotation += dt * 2.2;
    if (state.isDead || state.hasReachedGoal) return;

    // 1. Se connesso a un secondo dispositivo reale via Socket UDP, interpola fluidamente a 120 FPS
    if (state.isRemoteSocketPeer) {
      final lerpFactor = (dt * 14.0).clamp(0.0, 1.0);
      position.x += (state.targetX - position.x) * lerpFactor;
      position.y += (state.targetY - position.y) * lerpFactor;
      state.x = position.x;
      state.y = position.y;
      _pushTrailPoint(position.x, position.y);
      return;
    }

    // 2. Peer P2P autonomo: fisica balistica reale sulla stessa torre
    _abilityCooldown -= dt;
    if (_abilityCooldown <= 0.0 && state.maxMeters > 12.0) {
      _abilityCooldown = 14.0 + _peerRng.nextDouble() * 6.0;
      final abilityRoll = _peerRng.nextDouble();
      if (abilityRoll < 0.35 && !state.hasShield) {
        state.hasShield = true;
      } else if (abilityRoll < 0.65 && !game.player.isDead) {
        // L'avversario attiva Spruzzo d'Inchiostro in P2P!
        game.triggerIncomingP2PSabotage();
      }
    }

    if (state.isStuck) {
      if (_stuckPad != null && _stuckPad!.parent != null) {
        position.x = _stuckPad!.position.x;
        position.y = _stuckPad!.top - radius;
      }
      _jumpWaitTimer -= dt;
      if (_jumpWaitTimer <= 0.0) {
        _performNextBallisticJump();
      }
      return;
    }

    // Integrazione velocità e gravità
    state.vy += PlayerCore.gravity * dt;
    position.x += state.vx * dt;
    position.y += state.vy * dt;

    final halfWall = game.towerHalfWidth - radius;
    if (position.x < -halfWall) {
      position.x = -halfWall;
      state.vx = state.vx.abs() * 0.72;
      state.bounces++;
    } else if (position.x > halfWall) {
      position.x = halfWall;
      state.vx = -state.vx.abs() * 0.72;
      state.bounces++;
    }

    // Controlla atterraggio sulle piattaforme verdi della torre durante la fase discendente
    if (state.vy > 0.0) {
      final pads = game.solidPadsCache;
      for (int i = 0; i < pads.length; i++) {
        final pad = pads[i];
        if (pad.parent == null || pad == _stuckPad) continue;
        final halfW = pad.size.x / 2 + radius * 0.65;
        if ((position.x - pad.position.x).abs() <= halfW &&
            position.y + radius >= pad.top - 6.0 &&
            position.y - radius <= pad.bottom + 6.0) {
          _stuckPad = pad;
          state.isStuck = true;
          state.vx = 0.0;
          state.vy = 0.0;
          position.setValues(
            pad.clampBallX(position.x, radius),
            pad.top - radius,
          );
          state.bounces++;
          // Pausa di mira realistica dell'avversario
          _jumpWaitTimer = 0.34 + _peerRng.nextDouble() * 0.36;
          break;
        }
      }
    }

    // Se scende troppo o manca una piattaforma, esegue un salto aereo di recupero (ha 3 lanci!)
    if (!state.isStuck && state.vy > 210.0) {
      _performNextBallisticJump();
    }

    state.x = position.x;
    state.y = position.y;
    final currentM = max(
      0.0,
      (InkSlingGame.groundSurfaceY - (position.y + radius)) /
          DailySeedEngine.metersToPixels,
    );
    state.meters = currentM;
    if (currentM > state.maxMeters) {
      state.maxMeters = DailySeedEngine.roundMeters(
        currentM,
        maxGoal: game.activeMode == GameMode.infiniteTower
            ? null
            : game.currentGoalMeters,
      );
      if ((state.maxMeters - game.p2pService.opponentMetersNotifier.value)
              .abs() >=
          0.1) {
        game.p2pService.opponentMetersNotifier.value = state.maxMeters;
      }
    }

    _pushTrailPoint(position.x, position.y);

    // Verifica se l'avversario ha raggiunto il traguardo (in modalità Gara 100m)
    if (game.p2pService.activeDuelFormat == P2PDuelFormat.race100m &&
        state.maxMeters >= game.currentGoalMeters) {
      state.maxMeters = game.currentGoalMeters;
      state.hasReachedGoal = true;
      game.p2pService.opponentMetersNotifier.value = game.currentGoalMeters;
      game.onGhostOpponentFinishedOrDied(reachedGoal: true);
      return;
    }

    // Verifica se l'avversario commette un errore fatale alla quota predeterminata o viene preso dall'onda
    if (state.maxMeters >= _targetDeathMeters ||
        position.y > game.inkFlood.position.y + 12.0) {
      if (state.hasShield) {
        state.hasShield = false;
        _targetDeathMeters += 18.0 + _peerRng.nextDouble() * 22.0;
        game.spawnFloatingStampAt(
          position.x,
          position.y - 20,
          game.strings.floatingShield,
        );
      } else {
        _triggerOpponentDeath();
      }
    }
  }

  void _performNextBallisticJump() {
    _jumpsDone++;
    state.isStuck = false;

    ObstacleBlock? bestPad;
    double bestDy = double.infinity;
    final pads = game.solidPadsCache;
    for (int i = 0; i < pads.length; i++) {
      final pad = pads[i];
      if (pad.parent == null || pad == _stuckPad) continue;
      final dy = position.y - pad.position.y;
      if (dy > 42.0 && dy < 330.0 && dy < bestDy) {
        bestDy = dy;
        bestPad = pad;
      }
    }

    double vx;
    double vy;
    if (bestPad != null) {
      final targetX = bestPad.position.x + (_peerRng.nextDouble() - 0.5) * 18.0;
      final targetTopY = bestPad.top - radius;
      final apexY = targetTopY - 48.0;
      final riseH = max(140.0, position.y - apexY);
      vy = -sqrt(2.0 * PlayerCore.gravity * riseH);
      final tUp = -vy / PlayerCore.gravity;
      final dropH = max(16.0, targetTopY - apexY);
      final tDown = sqrt(2.0 * dropH / PlayerCore.gravity);
      final totalT = max(0.24, tUp + tDown);
      vx = ((targetX - position.x) / totalT).clamp(-390.0, 390.0);
    } else {
      vy = -710.0;
      vx = _jumpsDone.isEven ? 200.0 : -200.0;
    }

    state.vx = vx;
    state.vy = vy;
    state.bounces++;
  }

  void _triggerOpponentDeath() {
    if (state.isDead) return;
    state.isDead = true;
    game.p2pService.opponentDeadNotifier.value = true;
    final skin = BallSkinsCatalog.getById(state.skinId);
    game.spawnInkDeathExplosion(
      position,
      skin.getCoreColor(game.palette),
      game.palette.vermilionHazard,
    );
    game.onGhostOpponentFinishedOrDied(reachedGoal: false);
  }

  void _ensureTagPainterUpdated() {
    final mStr = DailySeedEngine.formatMeters(state.maxMeters);
    final statusSuffix = state.isDead ? ' 💀' : (state.hasShield ? ' 🛡️' : '');
    final key =
        '${game.palette.id}_${state.name}_${mStr}_$statusSuffix';
    if (_cachedTagKey == key && _tagTextPainter != null) return;
    _cachedTagKey = key;

    _tagTextPainter = TextPainter(
      text: TextSpan(
        text: '${state.avatarEmoji} ${state.name} • ${mStr}m$statusSuffix',
        style: TextStyle(
          color: game.palette.inkPrimary,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 210);
  }

  @override
  void render(Canvas canvas) {
    if (!game.isP2PMatch) return;
    final p = game.palette;
    final lowQuality = game.isLowQualityMode;
    final center = Offset(size.x / 2, size.y / 2);
    final skin = BallSkinsCatalog.getById(state.skinId);
    final coreColor = skin.getCoreColor(p);
    final strokeColor = skin.getStrokeColor(p);

    // 1. Se l'avversario è caduto, disegna il sigillo fantasma nel punto di morte
    if (state.isDead) {
      _auraPaint.color = p.vermilionHazard.withAlpha((0.55 * 255).round());
      canvas.drawCircle(center, radius * 0.9, _auraPaint);
      _renderFloatingNameTag(canvas, center);
      return;
    }

    // 2. Scia eterea dal ring-buffer pre-allocato
    if (_trailLength > 0) {
      final step = lowQuality ? 2 : 1;
      for (int i = 0; i < _trailLength; i += step) {
        final bufIdx = (_trailStart + i) % _maxTrailPoints;
        final pt = _trailPool[bufIdx];
        final dx = pt.x - position.x;
        final dy = pt.y - position.y;
        final t = (i + 1) / _trailLength;
        _trailPaint.color = coreColor.withAlpha((t * 0.18 * 255).round());
        canvas.drawCircle(
          Offset(center.dx + dx, center.dy + dy),
          radius * t * 0.76,
          _trailPaint,
        );
      }
    }

    // 3. Anello spettrale rotante del Fantasma
    _auraPaint.color = coreColor.withAlpha((0.45 * 255).round());
    final auraRect = Rect.fromCircle(center: center, radius: radius + 5.5);
    for (int s = 0; s < 4; s++) {
      canvas.drawArc(
        auraRect,
        _ringRotation + (s * pi / 2),
        pi / 3,
        false,
        _auraPaint,
      );
    }

    if (state.hasShield) {
      _shieldPaint.color = p.matchaSafe.withAlpha((0.70 * 255).round());
      canvas.drawCircle(center, radius + 11.0, _shieldPaint);
    }

    // 4. Corpo semitrasparente del Fantasma (opacità 55% Risograph)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    _corePaint.color = coreColor.withAlpha((0.52 * 255).round());
    canvas.drawCircle(Offset.zero, radius, _corePaint);

    skin.renderCustomSkin(canvas, radius, p, _ringRotation);

    _strokePaint.color = strokeColor.withAlpha((0.68 * 255).round());
    canvas.drawCircle(Offset.zero, radius, _strokePaint);
    canvas.restore();

    // 5. Targhetta nome + metri sopra il Fantasma
    _renderFloatingNameTag(canvas, center);
  }

  void _renderFloatingNameTag(Canvas canvas, Offset center) {
    _ensureTagPainterUpdated();
    final tp = _tagTextPainter;
    if (tp == null) return;

    final padW = tp.width + 12.0;
    final padH = tp.height + 6.0;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - radius - 18.0),
        width: padW,
        height: padH,
      ),
      const Radius.circular(6),
    );

    _tagBgPaint.color = game.palette.paperCard.withAlpha((0.88 * 255).round());
    _tagBorderPaint.color = state.isDead
        ? game.palette.vermilionHazard
        : game.palette.inkPrimary.withAlpha((0.75 * 255).round());

    canvas.drawRRect(rect, _tagBgPaint);
    canvas.drawRRect(rect, _tagBorderPaint);
    tp.paint(
      canvas,
      Offset(
        center.dx - tp.width / 2,
        center.dy - radius - 18.0 - tp.height / 2,
      ),
    );
  }
}

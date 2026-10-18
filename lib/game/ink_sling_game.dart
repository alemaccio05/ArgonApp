import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import '../core/daily_seed.dart';
import '../core/palette_theme.dart';
import '../services/audio_haptics_service.dart';
import '../services/monetization_service.dart';
import '../services/storage_service.dart';
import 'components/floating_label.dart';
import 'components/ink_flood_wave.dart';
import 'components/obstacle_block.dart';
import 'components/player_core.dart';

/// Il motore principale di DAILY SLING 100m.
class InkSlingGame extends FlameGame with DragCallbacks {
  final StorageService storage;
  final AudioHapticsService audioHaptics;
  final MonetizationService monetization;

  late PlayerCore player;
  late InkFloodWave inkFlood;

  // Transizione fluida tra i temi (600ms con curva easeInOutCubic)
  late RisographPalette _fromPalette;
  late RisographPalette _targetPalette;
  late RisographPalette palette;
  double _themeTransitionT = 1.0;

  // Notifiers leggeri per l'HUD e la UI Flutter
  final ValueNotifier<double> metersNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<int> chargesNotifier =
      ValueNotifier<int>(PlayerCore.maxAirCharges);
  final ValueNotifier<int> comboNotifier = ValueNotifier<int>(0);
  final ValueNotifier<RisographPalette> paletteNotifier =
      ValueNotifier<RisographPalette>(RisographPalette.washiIvory);

  // Controllo Bullet-Time e Drag
  double timeScale = 1.0;
  double targetTimeScale = 1.0;
  bool isDragging = false;
  Vector2 dragStart = Vector2.zero();
  Vector2 dragCurrent = Vector2.zero();

  // Stato della sessione e Scatola Nera ("Flight Path")
  bool isPlaying = false;
  bool isVictory = false;
  bool isOfficialRun = true;
  bool reviveUsed = false;
  bool lastRunWasNewDailyRecord = false;
  int currentAttemptNumber = 1;
  double maxMetersReached = 0.0;
  double runTimeSeconds = 0.0;
  int totalBounces = 0;

  double _pathRecordTimer = 0.0;
  final List<Vector2> flightPath = [];
  final List<double> communityHotspotMeters = [];
  final List<Offset> _paperGrainDots = [];

  // Camera Shake & Hit-Stop
  double _shakeTrauma = 0.0;
  double _hitStopTimer = 0.0;
  final Random _fxRng = Random();

  InkSlingGame({
    required this.storage,
    required this.audioHaptics,
    required this.monetization,
  }) {
    palette = RisographPalette.fromId(storage.selectedPaletteId);
    _fromPalette = palette;
    _targetPalette = palette;
    paletteNotifier.value = palette;
  }

  @override
  Color backgroundColor() => palette.paperBg;

  /// Avvia una transizione fluida e rilassante verso il tema successivo
  Future<void> cyclePalette() async {
    final currentIndex =
        RisographPalette.all.indexWhere((p) => p.id == _targetPalette.id);
    final nextPalette =
        RisographPalette.all[(currentIndex + 1) % RisographPalette.all.length];

    _fromPalette = palette;
    _targetPalette = nextPalette;
    _themeTransitionT = 0.0;

    await storage.setPalette(nextPalette.id);
    audioHaptics.onAimTick();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.center;

    final grainRng = Random(1984);
    for (int i = 0; i < 65; i++) {
      _paperGrainDots.add(
        Offset(grainRng.nextDouble(), grainRng.nextDouble()),
      );
    }

    _buildDailyTower();
  }

  /// Costruisce la torre di 100m usando il Seed Globale di oggi (YYYYMMDD)
  /// Garantisce una progressione accessibile e ritmata di piattaforme verdi adesive!
  void _buildDailyTower() {
    world.removeAll(world.children);
    flightPath.clear();
    communityHotspotMeters.clear();

    final dailyRng = Random(DailySeedEngine.getTodaySeed());

    player = PlayerCore(position: Vector2(0, -20));
    inkFlood = InkFloodWave(startY: 320);
    world.add(player);
    world.add(inkFlood);

    double currentMeter = 3.8;
    int stepIndex = 0;

    while (currentMeter < DailySeedEngine.goalMeters - 2.5) {
      final yPos = -currentMeter * DailySeedEngine.metersToPixels;
      final isEarlyGame = currentMeter < 22.0;

      // Garantiamo SEMPRE una piattaforma verde adesiva su ogni gradino principale
      // alternando sinistra, centro e destra per una scalata fluida e intuitiva!
      final sideChoice = stepIndex % 3;
      double padX;
      if (sideChoice == 0) {
        padX = -75.0 + (dailyRng.nextDouble() - 0.5) * 35.0;
      } else if (sideChoice == 1) {
        padX = 75.0 + (dailyRng.nextDouble() - 0.5) * 35.0;
      } else {
        padX = (dailyRng.nextDouble() - 0.5) * 60.0;
      }

      final padWidth = isEarlyGame ? 132.0 : 114.0;
      world.add(
        ObstacleBlock(
          position: Vector2(padX, yPos),
          size: Vector2(padWidth, 18),
          type: BlockType.matchaPad,
        ),
      );

      // Gemma di Boost sopra o di fianco per chi vuole concatenare salti veloci
      if (stepIndex % 2 == 1) {
        final gemX = -padX * 0.7;
        world.add(
          ObstacleBlock(
            position: Vector2(gemX, yPos - 75),
            size: Vector2(28, 28),
            type: BlockType.hankoSeal,
          ),
        );
      }

      // Ostacoli rossi: assenti nei primissimi 8 metri per far capire l'incollaggio,
      // poi introdotti gradualmente senza mai bloccare tutta la larghezza!
      if (currentMeter >= 8.5) {
        final hazardRoll = dailyRng.nextInt(3);
        if (hazardRoll == 0) {
          // Ostacolo rosso sul lato opposto rispetto alla piattaforma verde
          final hazardX = padX < 0 ? 95.0 : -95.0;
          world.add(
            ObstacleBlock(
              position: Vector2(hazardX, yPos - 85),
              size: Vector2(88, 16),
              type: BlockType.vermilionHazard,
              movingSpeed: currentMeter > 30 && dailyRng.nextBool() ? 65.0 : 0.0,
            ),
          );
        } else if (hazardRoll == 1 && currentMeter > 18.0) {
          // Barriera mobile centrale tra due piattaforme verdi
          world.add(
            ObstacleBlock(
              position: Vector2(0, yPos - 95),
              size: Vector2(85, 16),
              type: BlockType.vermilionHazard,
              movingSpeed: 75.0 + dailyRng.nextDouble() * 35.0,
            ),
          );
          if (currentMeter > 30 && communityHotspotMeters.length < 3) {
            communityHotspotMeters.add(currentMeter + 2);
          }
        }
      }

      stepIndex++;
      currentMeter += 3.8 + dailyRng.nextDouble() * 1.2;
    }

    camera.viewfinder.position = Vector2(0, -180);
  }

  void startRun() {
    _buildDailyTower();
    isPlaying = true;
    isVictory = false;
    reviveUsed = false;
    lastRunWasNewDailyRecord = false;
    isOfficialRun = storage.officialAttemptsLeft > 0;
    currentAttemptNumber =
        (DailySeedEngine.maxOfficialAttemptsPerDay -
                storage.officialAttemptsLeft) +
            1;

    maxMetersReached = 0.0;
    runTimeSeconds = 0.0;
    totalBounces = 0;
    metersNotifier.value = 0.0;
    chargesNotifier.value = PlayerCore.maxAirCharges;
    comboNotifier.value = 0;

    overlays.remove('MainMenu');
    overlays.remove('GameOver');
    overlays.add('Hud');
    audioHaptics.onLaunch();
  }

  /// Continua la scalata dal metro dell'impatto con una piattaforma verde di salvataggio e Scudo
  void reviveWithShield() {
    if (reviveUsed) return;
    reviveUsed = true;
    isPlaying = true;

    final reviveY = -maxMetersReached * DailySeedEngine.metersToPixels;
    // Crea una piattaforma verde sicura proprio sotto il giocatore per farlo ripartire incollato!
    final rescuePad = ObstacleBlock(
      position: Vector2(0, reviveY + 20),
      size: Vector2(130, 18),
      type: BlockType.matchaPad,
    );
    world.add(rescuePad);

    player.position = Vector2(0, reviveY);
    player.stickToPlatform(rescuePad);
    player.shieldTimer = 3.0;
    chargesNotifier.value = PlayerCore.maxAirCharges;

    inkFlood.y = player.y + 14.0 * DailySeedEngine.metersToPixels;

    overlays.remove('GameOver');
    overlays.add('Hud');
    audioHaptics.onSealCollected(combo: 1);
  }

  Future<void> triggerGameOver({required bool victory}) async {
    if (!isPlaying) return;
    isPlaying = false;
    isVictory = victory;
    isDragging = false;
    targetTimeScale = 1.0;

    if (victory) {
      maxMetersReached = DailySeedEngine.goalMeters;
      metersNotifier.value = DailySeedEngine.goalMeters;
    }

    triggerHitStop(0.055);
    addCameraTrauma(0.75);
    spawnInkDrops(
      player.position.clone(),
      victory ? palette.ochreSeal : palette.vermilionHazard,
      count: 30,
    );
    audioHaptics.onCrashOrVictory();

    lastRunWasNewDailyRecord = await storage.recordRunResult(
      meters: maxMetersReached,
      isVictory: victory,
      consumeOfficialAttempt: isOfficialRun && !reviveUsed,
    );

    overlays.remove('Hud');
    overlays.add('GameOver');
  }

  void returnToMainMenu() {
    isPlaying = false;
    isDragging = false;
    targetTimeScale = 1.0;
    overlays.remove('Hud');
    overlays.remove('GameOver');
    overlays.add('MainMenu');
  }

  void triggerHitStop(double durationSeconds) {
    _hitStopTimer = durationSeconds;
  }

  void addCameraTrauma(double amount) {
    _shakeTrauma = (_shakeTrauma + amount).clamp(0.0, 1.0);
  }

  void spawnFloatingStamp(Vector2 worldPos, String text) {
    world.add(FloatingStampComponent(position: worldPos, label: text));
  }

  void spawnInkDrops(Vector2 pos, Color color, {int count = 16}) {
    world.add(
      ParticleSystemComponent(
        position: pos,
        particle: Particle.generate(
          count: count,
          lifespan: 0.42,
          generator: (i) {
            final angle = _fxRng.nextDouble() * pi * 2;
            final speed = 55.0 + _fxRng.nextDouble() * 220.0;
            final vel = Vector2(cos(angle), sin(angle)) * speed;
            return AcceleratedParticle(
              speed: vel,
              acceleration: -vel * 1.9,
              child: CircleParticle(
                radius: 2.5 + _fxRng.nextDouble() * 3.0,
                paint: Paint()..color = color,
              ),
            );
          },
        ),
      ),
    );
  }

  // ==========================================================================
  // INPUT ONE-HANDED: VIRTUAL SLINGSHOT + BULLET-TIME
  // ==========================================================================
  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (!isPlaying || player.airCharges <= 0) return;

    isDragging = true;
    dragStart = event.canvasPosition.clone();
    dragCurrent = dragStart.clone();
    targetTimeScale = 0.15;
    audioHaptics.onAimTick();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!isDragging) return;
    final prevAngle = (dragStart - dragCurrent).screenAngle();
    dragCurrent = event.canvasEndPosition.clone();
    final newAngle = (dragStart - dragCurrent).screenAngle();

    if ((newAngle - prevAngle).abs() > 0.30) {
      audioHaptics.onAimTick();
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!isDragging) return;
    isDragging = false;
    targetTimeScale = 1.0;

    final pullVector = dragStart - dragCurrent;
    if (pullVector.length > 10.0 && player.airCharges > 0) {
      final launchVector = pullVector.normalized() *
          (pullVector.length * 6.8).clamp(440.0, 900.0);
      player.launch(launchVector);
    }
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    isDragging = false;
    targetTimeScale = 1.0;
  }

  // ==========================================================================
  // GAME LOOP & TRANSIZIONE FLUIDA DEL TEMA
  // ==========================================================================
  @override
  void update(double dt) {
    // 1. Aggiorna la transizione morbida del tema (anche durante l'hit-stop o nel menu)
    if (_themeTransitionT < 1.0) {
      _themeTransitionT = (_themeTransitionT + dt / 0.60).clamp(0.0, 1.0);
      final curvedT = Curves.easeInOutCubic.transform(_themeTransitionT);
      palette = RisographPalette.lerp(_fromPalette, _targetPalette, curvedT);
      paletteNotifier.value = palette;
    }

    if (_hitStopTimer > 0) {
      _hitStopTimer -= dt;
      return;
    }

    timeScale += (targetTimeScale - timeScale) * (dt * 14.0).clamp(0.0, 1.0);
    final scaledDt = dt * timeScale;

    super.update(scaledDt);

    if (isPlaying) {
      runTimeSeconds += dt;

      final currentMeters =
          (-player.position.y / DailySeedEngine.metersToPixels)
              .clamp(0.0, 100.0);
      if (currentMeters > maxMetersReached) {
        maxMetersReached = currentMeters;
        if ((maxMetersReached - metersNotifier.value).abs() >= 0.1) {
          metersNotifier.value =
              double.parse(maxMetersReached.toStringAsFixed(1));
        }
      }

      _pathRecordTimer += dt;
      if (_pathRecordTimer >= 0.08) {
        _pathRecordTimer = 0.0;
        flightPath.add(player.position.clone());
      }

      if (currentMeters >= DailySeedEngine.goalMeters) {
        triggerGameOver(victory: true);
      }
    }

    // Camera follow verticale + Shake
    final targetCamY = min(player.position.y - 115.0, -180.0);
    final currentCamPos = camera.viewfinder.position;
    final smoothY = currentCamPos.y +
        (targetCamY - currentCamPos.y) * (dt * 7.5).clamp(0.0, 1.0);

    double shakeX = 0.0;
    double shakeY = 0.0;
    if (_shakeTrauma > 0) {
      final shake = _shakeTrauma * _shakeTrauma * 15.0;
      shakeX = (_fxRng.nextDouble() * 2 - 1) * shake;
      shakeY = (_fxRng.nextDouble() * 2 - 1) * shake;
      _shakeTrauma = max(0.0, _shakeTrauma - dt * 2.5);
    }

    camera.viewfinder.position = Vector2(shakeX, smoothY + shakeY);
  }

  @override
  void render(Canvas canvas) {
    _renderPaperBackgroundAndGrid(canvas);
    super.render(canvas);
    _renderMarginsAndMarkers(canvas);

    if (isPlaying && isDragging && player.airCharges > 0) {
      _renderPredictiveTrajectory(canvas);
    }
  }

  void _renderPaperBackgroundAndGrid(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = palette.paperBg,
    );

    final grainPaint = Paint()
      ..color = palette.inkSecondary.withAlpha((0.09 * 255).round());
    for (final dot in _paperGrainDots) {
      canvas.drawCircle(
        Offset(dot.dx * size.x, dot.dy * size.y),
        1.2,
        grainPaint,
      );
    }
  }

  void _renderMarginsAndMarkers(Canvas canvas) {
    final camY = camera.viewfinder.position.y;
    final screenCenter = size / 2;
    final leftX = max(8.0, screenCenter.x - DailySeedEngine.worldWidth / 2);
    final rightX =
        min(size.x - 8.0, screenCenter.x + DailySeedEngine.worldWidth / 2);

    // Righe orizzontali ogni 5m e tacche principali ogni 10m
    for (int m = 0; m <= 100; m += 5) {
      final worldY = -m * DailySeedEngine.metersToPixels;
      final screenY = screenCenter.y + (worldY - camY);
      if (screenY < -40 || screenY > size.y + 40) continue;

      final isMajor = m % 10 == 0;
      final isGoal = m == 100;

      final linePaint = Paint()
        ..color = isGoal
            ? palette.vermilionHazard
            : (isMajor
                ? palette.paperGrid
                : palette.paperGrid.withAlpha((0.45 * 255).round()))
        ..strokeWidth = isGoal ? 2.5 : (isMajor ? 1.4 : 0.8);

      canvas.drawLine(
        Offset(leftX, screenY),
        Offset(rightX, screenY),
        linePaint,
      );

      if (isMajor && m > 0) {
        final tp = TextPainter(
          text: TextSpan(
            text: isGoal ? '🏁 TRAGUARDO 100m' : '${m}m',
            style: TextStyle(
              color: isGoal ? palette.vermilionHazard : palette.inkSecondary,
              fontSize: isGoal ? 13 : 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: rightX - leftX - 16);
        tp.paint(canvas, Offset(leftX + 8, screenY - tp.height - 3));
      }
    }

    // Marcatori "Zona Difficile"
    for (final hotspotM in communityHotspotMeters) {
      final worldY = -hotspotM * DailySeedEngine.metersToPixels;
      final screenY = screenCenter.y + (worldY - camY);
      if (screenY < -30 || screenY > size.y + 30) continue;

      final tp = TextPainter(
        text: TextSpan(
          text: '⚠️ ZONA CRITICA (${hotspotM.toInt()}m)',
          style: TextStyle(
            color: palette.vermilionHazard.withAlpha((0.65 * 255).round()),
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: rightX - leftX - 16);
      tp.paint(canvas, Offset(rightX - tp.width - 8, screenY + 4));
    }

    // Pareti laterali della torre
    final borderPaint = Paint()
      ..color = palette.inkPrimary.withAlpha((0.55 * 255).round())
      ..strokeWidth = 2.5;
    canvas.drawLine(Offset(leftX, 0), Offset(leftX, size.y), borderPaint);
    canvas.drawLine(Offset(rightX, 0), Offset(rightX, size.y), borderPaint);
  }

  void _renderPredictiveTrajectory(Canvas canvas) {
    final pullVector = dragStart - dragCurrent;
    if (pullVector.length <= 10.0) return;

    final launchVel = pullVector.normalized() *
        (pullVector.length * 6.8).clamp(440.0, 900.0);

    final screenCenter = size / 2;
    final camPos = camera.viewfinder.position;
    Vector2 simPos = player.position.clone();
    Vector2 simVel = launchVel.clone();
    const simDt = 0.024;
    const halfWidth = DailySeedEngine.worldWidth / 2 - PlayerCore.radius;

    for (int i = 1; i <= 22; i++) {
      simVel.y += PlayerCore.gravity * simDt;
      simPos += simVel * simDt;

      if (simPos.x < -halfWidth) {
        simPos.x = -halfWidth;
        simVel.x = -simVel.x * 0.72;
      } else if (simPos.x > halfWidth) {
        simPos.x = halfWidth;
        simVel.x = -simVel.x * 0.72;
      }

      final screenPt = Offset(
        screenCenter.x + (simPos.x - camPos.x),
        screenCenter.y + (simPos.y - camPos.y),
      );
      final alpha = (1.0 - i / 23.0) * 0.88;
      final radius = 4.2 - (i * 0.12);

      canvas.drawCircle(
        screenPt,
        radius,
        Paint()..color = palette.playerFill.withAlpha((alpha * 255).round()),
      );
      canvas.drawCircle(
        screenPt,
        radius,
        Paint()
          ..color = palette.playerStroke.withAlpha((alpha * 255).round())
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }
}

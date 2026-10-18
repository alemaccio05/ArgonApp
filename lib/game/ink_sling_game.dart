import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/daily_seed.dart';
import '../core/palette_theme.dart';
import '../services/audio_haptics_service.dart';
import '../services/monetization_service.dart';
import '../services/storage_service.dart';
import 'components/floating_label.dart';
import 'components/ink_flood_wave.dart';
import 'components/obstacle_block.dart';
import 'components/player_core.dart';

/// Il motore principale di INK TOWER: Climb & Stick.
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
  final ValueNotifier<AppLanguage> languageNotifier =
      ValueNotifier<AppLanguage>(AppLanguage.it);
  final ValueNotifier<bool> soundNotifier = ValueNotifier<bool>(true);

  AppStrings get strings => AppStrings(languageNotifier.value);

  // Controllo Bullet-Time e Drag
  double timeScale = 1.0;
  double targetTimeScale = 1.0;
  bool isDragging = false;
  Vector2 dragStart = Vector2.zero();
  Vector2 dragCurrent = Vector2.zero();

  // Modalità di Gioco e Progressione Livelli Infiniti (1, 2, 3...)
  GameMode activeMode = GameMode.levelProgression;
  int currentLevel = 1;
  double currentGoalMeters = 50.0;
  bool leveledUpInLastRun = false;

  // Stato della sessione e Scatola Nera ("Flight Path")
  bool isPlaying = false;
  bool isMenuDemo = true;
  double _demoJumpTimer = 0.35;
  int _demoStepCounter = 0;

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
  final List<ObstacleBlock> _demoPlatforms = [];

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

    languageNotifier.value = storage.selectedLanguage;
    soundNotifier.value = storage.soundEnabled;
    audioHaptics.soundEnabled = storage.soundEnabled;

    currentLevel = storage.currentTowerLevel;
    currentGoalMeters = DailySeedEngine.getLevelGoalMeters(currentLevel);
  }

  @override
  Color backgroundColor() => palette.paperBg;

  /// Metà larghezza interna effettiva della torre: si adatta automaticamente
  /// agli schermi più stretti (es. Pixel 3a) così i rimbalzi fisici della palla
  /// coincidono esattamente al pixel con il bordo interno delle mura in pietra!
  double get towerHalfWidth => size.x > 0
      ? min(DailySeedEngine.worldWidth / 2, (size.x / 2) - 16.0)
      : DailySeedEngine.worldWidth / 2;

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

  /// Imposta una lingua specifica tra le 6 supportate
  Future<void> setLanguage(AppLanguage lang) async {
    languageNotifier.value = lang;
    await storage.setLanguage(lang);
    audioHaptics.onAimTick();
  }

  /// Passa alla lingua successiva tra le 6 più popolari
  Future<void> cycleLanguage() async {
    final all = AppLanguage.values;
    final idx = all.indexOf(languageNotifier.value);
    final next = all[(idx + 1) % all.length];
    await setLanguage(next);
  }

  /// Attiva/Disattiva gli effetti sonori
  Future<void> toggleSound() async {
    final next = !soundNotifier.value;
    soundNotifier.value = next;
    audioHaptics.soundEnabled = next;
    await storage.setSoundEnabled(next);
    if (next) {
      audioHaptics.onAimTick();
    }
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

    _startMenuDemo();
  }

  /// Costruisce un'animazione di sottofondo per il menu principale in cui una palla
  /// scala autonomamente una torre dimostrativa, senza svelare il livello reale!
  void _startMenuDemo() {
    isPlaying = false;
    isMenuDemo = true;
    isDragging = false;
    targetTimeScale = 1.0;
    timeScale = 1.0;
    _demoJumpTimer = 0.35;
    _demoStepCounter = 0;
    _demoPlatforms.clear();

    _buildTowerWithSeed(
      seed: 9021042,
      goalMeters: 140.0,
      difficultyLevel: 2,
      isDemoTower: true,
    );
  }

  /// Costruisce una torre deterministica regolando la difficoltà attraverso i nuovi ostacoli
  /// lungo cicli di 10 livelli (con l'altezza che aumenta di +10m ogni 10 livelli):
  /// - Liv. 1: Barriere rosse fisse e piattaforme verdi ampie
  /// - Liv. 2: Sblocco Respingenti Pinball (`bumperPin`) e prime barriere mobili
  /// - Liv. 3: Sblocco Piattaforme verdi a tempo (`crumblingPad`)
  /// - Liv. 4: Sblocco Piattaforme verdi mobili orizzontali
  /// - Liv. 5: Sblocco Lame a pattuglia verticale (`verticalPatrolHazard`)
  /// - Liv. 6: Sblocco Varchi Laser a impulsi (`pulsingLaserHazard`)
  /// - Liv. 7–10+: Combinazioni via via più dense, veloci e sfidanti di tutti gli ostacoli!
  void _buildTowerWithSeed({
    required int seed,
    required double goalMeters,
    required int difficultyLevel,
    bool isDemoTower = false,
  }) {
    world.removeAll(world.children);
    flightPath.clear();
    communityHotspotMeters.clear();
    _demoPlatforms.clear();

    final rng = Random(seed);

    player = PlayerCore(position: Vector2(0, -20));
    inkFlood = InkFloodWave(startY: 115);
    world.add(player);
    world.add(inkFlood);

    double currentMeter = 3.8;
    int stepIndex = 0;

    final levelFactor = (difficultyLevel - 1).clamp(0, 40);
    final subLevelInTier = (difficultyLevel - 1) % 10; // 0..9 dentro il blocco di 10 livelli
    final hazardStartMeter = max(4.2, 10.0 - levelFactor * 0.35);

    // Probabilità progressiva di piattaforme speciali e densità di ostacoli
    final crumblingChance = difficultyLevel < 3
        ? 0.0
        : (0.16 + levelFactor * 0.018 + subLevelInTier * 0.012).clamp(0.16, 0.48);
    final movingPadChance = difficultyLevel < 4
        ? 0.0
        : (0.15 + levelFactor * 0.016 + subLevelInTier * 0.012).clamp(0.15, 0.42);
    final hazardSpawnChance = (0.58 + levelFactor * 0.025 + subLevelInTier * 0.02)
        .clamp(0.58, 0.92);

    while (currentMeter < goalMeters - 2.5) {
      final yPos = -currentMeter * DailySeedEngine.metersToPixels;
      final isEarlySection = currentMeter < 12.0 && difficultyLevel <= 2;

      // 1. Piattaforma principale su ogni gradino (alternando sinistra, destra, centro)
      final sideChoice = stepIndex % 3;
      double padX;
      if (sideChoice == 0) {
        padX = -75.0 + (rng.nextDouble() - 0.5) * 35.0;
      } else if (sideChoice == 1) {
        padX = 75.0 + (rng.nextDouble() - 0.5) * 35.0;
      } else {
        padX = (rng.nextDouble() - 0.5) * 60.0;
      }

      final basePadWidth = isEarlySection
          ? 130.0
          : max(84.0, 124.0 - levelFactor * 1.15 - subLevelInTier * 1.2);

      // Piattaforme fragili a tempo (dal Liv. 3) e Piattaforme mobili (dal Liv. 4)
      final canBeSpecialPad = !isDemoTower && currentMeter > 11.0 && stepIndex > 1;
      final isCrumblingPad = canBeSpecialPad &&
          difficultyLevel >= 3 &&
          rng.nextDouble() < crumblingChance;
      final isMovingPad = canBeSpecialPad &&
          !isCrumblingPad &&
          difficultyLevel >= 4 &&
          rng.nextDouble() < movingPadChance;

      final pad = ObstacleBlock(
        position: Vector2(padX, yPos),
        size: Vector2(basePadWidth, 18),
        type: isCrumblingPad ? BlockType.crumblingPad : BlockType.matchaPad,
        movingSpeed: isMovingPad
            ? 40.0 + levelFactor * 2.2 + subLevelInTier * 2.0
            : 0.0,
      );
      world.add(pad);
      if (isDemoTower) {
        _demoPlatforms.add(pad);
      }

      // 2. Gemma Scudo o Respingente Elastico (Bumper Pin sbloccato dal Liv. 2)
      if (stepIndex % 2 == 1) {
        final gemX = -padX * 0.7;
        final bumperChance = difficultyLevel < 2
            ? 0.0
            : (0.28 + subLevelInTier * 0.03).clamp(0.28, 0.55);
        final spawnBumperInstead = !isDemoTower &&
            difficultyLevel >= 2 &&
            currentMeter > 10.0 &&
            rng.nextDouble() < bumperChance;
        world.add(
          ObstacleBlock(
            position: Vector2(gemX, yPos - 75),
            size: spawnBumperInstead ? Vector2(32, 32) : Vector2(28, 28),
            type: spawnBumperInstead
                ? BlockType.bumperPin
                : BlockType.hankoSeal,
          ),
        );
      }

      // 3. Ostacoli Letali progressivi in base al livello raggiunto
      if (!isDemoTower &&
          currentMeter >= hazardStartMeter &&
          rng.nextDouble() < hazardSpawnChance) {
        final speedBonus = levelFactor * 3.5 + subLevelInTier * 3.0;

        // Costruiamo il pool di ostacoli sbloccati per il livello corrente:
        // 0 = Barriera laterale (fissa al Liv. 1, anche mobile dal Liv. 2)
        // 1 = Barriera mobile centrale veloce (dal Liv. 2)
        // 2 = Pattuglia Verticale (dal Liv. 5)
        // 3 = Varco Laser a Impulsi (dal Liv. 6)
        final unlockedHazards = <int>[0];
        if (difficultyLevel >= 2 && currentMeter > 12.0) {
          unlockedHazards.add(1);
        }
        if (difficultyLevel >= 5 && currentMeter > 14.0) {
          unlockedHazards.add(2);
        }
        if (difficultyLevel >= 6 && currentMeter > 16.0) {
          unlockedHazards.add(3);
        }

        final hazardType =
            unlockedHazards[rng.nextInt(unlockedHazards.length)];

        if (hazardType == 0) {
          // Barriera rossa sul lato opposto (fissa al Liv. 1, mobile dal Liv. 2+)
          final hazardX = padX < 0 ? 92.0 : -92.0;
          final shouldMove = difficultyLevel >= 2 &&
              (currentMeter > 16.0 || difficultyLevel >= 4) &&
              rng.nextBool();
          world.add(
            ObstacleBlock(
              position: Vector2(hazardX, yPos - 85),
              size: Vector2(86, 16),
              type: BlockType.vermilionHazard,
              movingSpeed: shouldMove ? 60.0 + speedBonus : 0.0,
            ),
          );
        } else if (hazardType == 1) {
          // Barriera mobile veloce centrale
          world.add(
            ObstacleBlock(
              position: Vector2(0, yPos - 95),
              size: Vector2(84, 16),
              type: BlockType.vermilionHazard,
              movingSpeed: 72.0 + speedBonus + rng.nextDouble() * 32.0,
            ),
          );
          if (currentMeter > 25 && communityHotspotMeters.length < 3) {
            communityHotspotMeters.add(currentMeter + 2);
          }
        } else if (hazardType == 2) {
          // Pattuglia Verticale: lama rossa che sale e scende!
          final patrolX = padX < 0 ? 75.0 : -75.0;
          world.add(
            ObstacleBlock(
              position: Vector2(patrolX, yPos - 90),
              size: Vector2(56, 18),
              type: BlockType.verticalPatrolHazard,
              verticalSpeed: 64.0 + speedBonus * 0.75,
            ),
          );
        } else if (hazardType == 3) {
          // Varco Laser a Impulsi: si accende e spegne ritmicamente!
          final laserX = padX > 0 ? -70.0 : 70.0;
          world.add(
            ObstacleBlock(
              position: Vector2(laserX, yPos - 88),
              size: Vector2(148, 16),
              type: BlockType.pulsingLaserHazard,
              phaseOffset: rng.nextDouble() * 2.5,
            ),
          );
          if (communityHotspotMeters.length < 3) {
            communityHotspotMeters.add(currentMeter + 2);
          }
        }
      }

      stepIndex++;
      currentMeter += 3.8 + rng.nextDouble() * 1.25;
    }

    camera.viewfinder.position = Vector2(0, -180);
  }

  void startRun({GameMode? mode, int? level}) {
    if (mode != null) {
      activeMode = mode;
    }
    if (activeMode == GameMode.levelProgression) {
      currentLevel = level ?? storage.currentTowerLevel;
      currentGoalMeters = DailySeedEngine.getLevelGoalMeters(currentLevel);
      _buildTowerWithSeed(
        seed: DailySeedEngine.getLevelSeed(currentLevel),
        goalMeters: currentGoalMeters,
        difficultyLevel: currentLevel,
      );
    } else {
      currentGoalMeters = DailySeedEngine.goalMeters;
      _buildTowerWithSeed(
        seed: DailySeedEngine.getTodaySeed(),
        goalMeters: currentGoalMeters,
        difficultyLevel: 8,
      );
    }

    isMenuDemo = false;
    isPlaying = true;
    isVictory = false;
    reviveUsed = false;
    lastRunWasNewDailyRecord = false;
    leveledUpInLastRun = false;

    if (activeMode == GameMode.dailyTower) {
      isOfficialRun = storage.officialAttemptsLeft > 0;
      currentAttemptNumber =
          (DailySeedEngine.maxOfficialAttemptsPerDay -
                  storage.officialAttemptsLeft) +
              1;
    } else {
      isOfficialRun = true;
      currentAttemptNumber += 1;
    }

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

    inkFlood.y = player.y + 8.0 * DailySeedEngine.metersToPixels;

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
      maxMetersReached = currentGoalMeters;
      metersNotifier.value = currentGoalMeters;
    }

    triggerHitStop(0.055);
    addCameraTrauma(0.75);
    spawnInkDrops(
      player.position.clone(),
      victory ? palette.ochreSeal : palette.vermilionHazard,
      count: 30,
    );
    audioHaptics.onCrashOrVictory(victory: victory);

    final prevMaxLevel = storage.currentTowerLevel;
    lastRunWasNewDailyRecord = await storage.recordRunResult(
      mode: activeMode,
      playedLevel: currentLevel,
      meters: maxMetersReached,
      isVictory: victory,
      consumeOfficialAttempt:
          activeMode == GameMode.dailyTower && isOfficialRun && !reviveUsed,
    );
    leveledUpInLastRun =
        activeMode == GameMode.levelProgression &&
        victory &&
        storage.currentTowerLevel > prevMaxLevel;

    overlays.remove('Hud');
    overlays.add('GameOver');
  }

  void returnToMainMenu() {
    _startMenuDemo();
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
  // GAME LOOP, ANIMAZIONE DEMO MENU & TRANSIZIONE FLUIDA DEL TEMA
  // ==========================================================================
  void _updateMenuDemo(double dt) {
    // Se la palla dimostrativa ha superato i 115 metri, ricomincia dal basso in modo fluido
    if (-player.position.y > 115.0 * DailySeedEngine.metersToPixels) {
      player.stuckPlatform = null;
      player.position = Vector2(0, -20);
      player.velocity.setZero();
      inkFlood.position.y = 140;
      camera.viewfinder.position = Vector2(0, -180);
      _demoStepCounter = 0;
      return;
    }

    if (player.isStuck || player.velocity.y > 180.0) {
      _demoJumpTimer -= dt;
      if (_demoJumpTimer <= 0) {
        _demoJumpTimer = 0.42;
        _demoStepCounter++;

        // Cerca la prossima piattaforma verde sopra la palla per mirare in modo intelligente
        ObstacleBlock? nextPad;
        double bestDist = double.infinity;
        for (final pad in _demoPlatforms) {
          final dy = player.position.y - pad.position.y;
          if (dy > 80 && dy < 320 && dy < bestDist) {
            bestDist = dy;
            nextPad = pad;
          }
        }

        double vx;
        const double vy = -690.0;
        if (nextPad != null) {
          final dx = nextPad.position.x - player.position.x;
          vx = (dx * 2.1).clamp(-340.0, 340.0);
        } else {
          vx = (_demoStepCounter.isEven ? 240.0 : -240.0);
        }

        player.launch(Vector2(vx, vy), silent: true);
      }
    }
  }

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

    if (isMenuDemo) {
      _updateMenuDemo(scaledDt);
    } else if (isPlaying) {
      runTimeSeconds += dt;

      final currentMeters =
          (-player.position.y / DailySeedEngine.metersToPixels)
              .clamp(0.0, currentGoalMeters);
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

      if (currentMeters >= currentGoalMeters) {
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

  /// Disegna lo sfondo interno della Torre:
  /// - Esterno ombreggiato fuori dalle mura
  /// - Texture carta Risograph all'interno del pozzo della torre
  /// - Finestre ad arco gotico/antico ogni 15m con raggi di luce soffusa
  /// - Pavimento in blocchi di pietra alla base (0m)
  void _renderPaperBackgroundAndGrid(Canvas canvas) {
    final camPos = camera.viewfinder.position;
    final camY = camPos.y;
    final screenCenter = size / 2;
    final halfW = towerHalfWidth;
    final leftX = screenCenter.x - halfW - camPos.x;
    final rightX = screenCenter.x + halfW - camPos.x;

    // 1. Sfondo generale carta
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = palette.paperBg,
    );

    // 2. Ombreggiatura esterna fuori dalle mura per far risaltare la sagoma della Torre
    final exteriorPaint = Paint()
      ..color = palette.inkPrimary.withAlpha((0.08 * 255).round());
    if (leftX > 0) {
      canvas.drawRect(Rect.fromLTWH(0, 0, leftX, size.y), exteriorPaint);
    }
    if (rightX < size.x) {
      canvas.drawRect(
        Rect.fromLTWH(rightX, 0, size.x - rightX, size.y),
        exteriorPaint,
      );
    }

    // 3. Finestre ad arco sullo sfondo della Torre ogni 15 metri
    final maxM = isMenuDemo ? 130 : currentGoalMeters.toInt();
    for (int m = 12; m < maxM; m += 15) {
      final worldY = -m * DailySeedEngine.metersToPixels;
      final screenY = screenCenter.y + (worldY - camY);
      if (screenY < -120 || screenY > size.y + 120) continue;

      _drawTowerArchedWindow(
        canvas,
        center: Offset(screenCenter.x - camPos.x, screenY),
        width: 56,
        height: 92,
      );
    }

    // 4. Grana della carta Risograph
    final grainPaint = Paint()
      ..color = palette.inkSecondary.withAlpha((0.09 * 255).round());
    for (final dot in _paperGrainDots) {
      canvas.drawCircle(
        Offset(dot.dx * size.x, dot.dy * size.y),
        1.2,
        grainPaint,
      );
    }

    // 5. Base in pietra della torre a 0m
    final floorScreenY = screenCenter.y + (0.0 - camY) + 14.0;
    if (floorScreenY > -40 && floorScreenY < size.y + 80) {
      canvas.drawRect(
        Rect.fromLTWH(leftX, floorScreenY, rightX - leftX, 24),
        Paint()..color = palette.paperGrid,
      );
      final stoneBorder = Paint()
        ..color = palette.inkPrimary.withAlpha((0.45 * 255).round())
        ..strokeWidth = 1.8;
      canvas.drawLine(
        Offset(leftX, floorScreenY),
        Offset(rightX, floorScreenY),
        stoneBorder,
      );
    }
  }

  void _drawTowerArchedWindow(
    Canvas canvas, {
    required Offset center,
    required double width,
    required double height,
  }) {
    final halfW = width / 2;
    final halfH = height / 2;
    final archRadius = halfW;
    final rectTop = center.dy - halfH + archRadius;
    final rectBottom = center.dy + halfH;

    final path = Path()
      ..moveTo(center.dx - halfW, rectBottom)
      ..lineTo(center.dx - halfW, rectTop)
      ..arcToPoint(
        Offset(center.dx + halfW, rectTop),
        radius: Radius.circular(archRadius),
        clockwise: true,
      )
      ..lineTo(center.dx + halfW, rectBottom)
      ..close();

    // Luce soffusa interna della finestra
    canvas.drawPath(
      path,
      Paint()..color = palette.paperCard.withAlpha((0.55 * 255).round()),
    );

    // Contorno in pietra della finestra
    final framePaint = Paint()
      ..color = palette.paperGrid.withAlpha((0.85 * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawPath(path, framePaint);

    // Inferriata / montanti interni della finestra della torre
    final mullionPaint = Paint()
      ..color = palette.paperGrid.withAlpha((0.65 * 255).round())
      ..strokeWidth = 1.4;
    canvas.drawLine(
      Offset(center.dx, center.dy - halfH),
      Offset(center.dx, rectBottom),
      mullionPaint,
    );
    canvas.drawLine(
      Offset(center.dx - halfW, rectTop + 10),
      Offset(center.dx + halfW, rectTop + 10),
      mullionPaint,
    );
  }

  /// Disegna le Mura Laterali in pietra/mattoni della Torre, le travi ogni 10m
  /// e la Merlatura in cima al traguardo!
  void _renderMarginsAndMarkers(Canvas canvas) {
    final camPos = camera.viewfinder.position;
    final camY = camPos.y;
    final screenCenter = size / 2;
    final halfW = towerHalfWidth;
    final leftX = screenCenter.x - halfW - camPos.x;
    final rightX = screenCenter.x + halfW - camPos.x;

    final maxM = isMenuDemo ? 130 : currentGoalMeters.toInt();
    const wallThickness = 15.0;

    // 1. Mura in pietra/mattoni a sinistra e destra della Torre
    final wallFillPaint = Paint()
      ..color = palette.paperGrid.withAlpha((0.88 * 255).round());
    canvas.drawRect(
      Rect.fromLTWH(leftX - wallThickness, 0, wallThickness, size.y),
      wallFillPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(rightX, 0, wallThickness, size.y),
      wallFillPaint,
    );

    // Giunture dei blocchi di pietra lungo le pareti verticali
    final brickLinePaint = Paint()
      ..color = palette.inkPrimary.withAlpha((0.28 * 255).round())
      ..strokeWidth = 1.2;
    const brickHeight = 28.0;
    final firstWorldY = camY - screenCenter.y - brickHeight;
    final lastWorldY = camY + screenCenter.y + brickHeight;
    final startBrickIdx = (firstWorldY / brickHeight).floor();
    final endBrickIdx = (lastWorldY / brickHeight).ceil();

    for (int b = startBrickIdx; b <= endBrickIdx; b++) {
      final wy = b * brickHeight;
      final sy = screenCenter.y + (wy - camY);
      if (sy < -10 || sy > size.y + 10) continue;

      // Fuga orizzontale del mattone
      canvas.drawLine(
        Offset(leftX - wallThickness, sy),
        Offset(leftX, sy),
        brickLinePaint,
      );
      canvas.drawLine(
        Offset(rightX, sy),
        Offset(rightX + wallThickness, sy),
        brickLinePaint,
      );

      // Fuga verticale alternata
      final vOffset = b.isEven ? wallThickness * 0.45 : wallThickness * 0.65;
      canvas.drawLine(
        Offset(leftX - vOffset, sy),
        Offset(leftX - vOffset, sy + brickHeight),
        brickLinePaint,
      );
      canvas.drawLine(
        Offset(rightX + vOffset, sy),
        Offset(rightX + vOffset, sy + brickHeight),
        brickLinePaint,
      );
    }

    // 2. Righe orizzontali ogni 5m, mensole ogni 10m e Merlatura in cima
    for (int m = 0; m <= maxM; m += 5) {
      final worldY = -m * DailySeedEngine.metersToPixels;
      final screenY = screenCenter.y + (worldY - camY);
      if (screenY < -60 || screenY > size.y + 60) continue;

      final isMajor = m % 10 == 0;
      final isGoal = !isMenuDemo && m == currentGoalMeters.toInt();

      final linePaint = Paint()
        ..color = isGoal
            ? palette.vermilionHazard
            : (isMajor
                ? palette.paperGrid
                : palette.paperGrid.withAlpha((0.45 * 255).round()))
        ..strokeWidth = isGoal ? 2.8 : (isMajor ? 1.5 : 0.8);

      canvas.drawLine(
        Offset(leftX, screenY),
        Offset(rightX, screenY),
        linePaint,
      );

      // Mensole/blocchi sporgenti dalle mura ogni 10m
      if (isMajor && m > 0) {
        final corbelPaint = Paint()
          ..color = palette.inkPrimary.withAlpha((0.35 * 255).round());
        canvas.drawRect(
          Rect.fromLTWH(leftX, screenY - 3, 9, 6),
          corbelPaint,
        );
        canvas.drawRect(
          Rect.fromLTWH(rightX - 9, screenY - 3, 9, 6),
          corbelPaint,
        );
      }

      // MERLATURA DELLA TORRE (Castle Battlements) sulla linea del traguardo!
      if (isGoal) {
        const merlonWidth = 22.0;
        const merlonHeight = 16.0;
        final merlonFill = Paint()
          ..color = palette.vermilionHazard.withAlpha((0.22 * 255).round());
        final merlonStroke = Paint()
          ..color = palette.vermilionHazard
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        for (double x = leftX + 6;
            x < rightX - merlonWidth;
            x += merlonWidth * 1.65) {
          final rect = Rect.fromLTWH(
            x,
            screenY - merlonHeight,
            merlonWidth,
            merlonHeight,
          );
          canvas.drawRect(rect, merlonFill);
          canvas.drawRect(rect, merlonStroke);
        }
      }

      if (isMajor && m > 0 && !isMenuDemo) {
        final tp = TextPainter(
          text: TextSpan(
            text: isGoal ? strings.goalLineMarker(m) : '${m}m',
            style: TextStyle(
              color: isGoal ? palette.vermilionHazard : palette.inkSecondary,
              fontSize: isGoal ? 13 : 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: rightX - leftX - 24);
        tp.paint(
          canvas,
          Offset(
            leftX + 12,
            screenY - tp.height - (isGoal ? 20 : 3),
          ),
        );
      }
    }

    if (!isMenuDemo) {
      // Marcatori "Zona Critica"
      for (final hotspotM in communityHotspotMeters) {
        final worldY = -hotspotM * DailySeedEngine.metersToPixels;
        final screenY = screenCenter.y + (worldY - camY);
        if (screenY < -30 || screenY > size.y + 30) continue;

        final tp = TextPainter(
          text: TextSpan(
            text: strings.dangerZoneMarker(hotspotM.toInt()),
            style: TextStyle(
              color: palette.vermilionHazard.withAlpha((0.65 * 255).round()),
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: rightX - leftX - 16);
        tp.paint(canvas, Offset(rightX - tp.width - 10, screenY + 4));
      }
    }

    // Bordatura interna ed esterna netta delle Mura della Torre
    final borderPaint = Paint()
      ..color = palette.inkPrimary.withAlpha((0.68 * 255).round())
      ..strokeWidth = 2.6;
    canvas.drawLine(Offset(leftX, 0), Offset(leftX, size.y), borderPaint);
    canvas.drawLine(Offset(rightX, 0), Offset(rightX, size.y), borderPaint);
    canvas.drawLine(
      Offset(leftX - wallThickness, 0),
      Offset(leftX - wallThickness, size.y),
      borderPaint,
    );
    canvas.drawLine(
      Offset(rightX + wallThickness, 0),
      Offset(rightX + wallThickness, size.y),
      borderPaint,
    );
  }

  void _renderPredictiveTrajectory(Canvas canvas) {
    final pullVector = dragStart - dragCurrent;
    if (pullVector.length <= 10.0) return;

    final rawLaunchVel = pullVector.normalized() *
        (pullVector.length * 6.8).clamp(440.0, 900.0);
    final launchVel = player.sanitizeLaunchVelocity(rawLaunchVel);

    final screenCenter = size / 2;
    final camPos = camera.viewfinder.position;
    Vector2 simPos = player.position.clone();
    final Vector2 simVel = launchVel.clone();
    const simDt = 0.024;
    final halfWidth = towerHalfWidth - PlayerCore.radius;
    final solidPads = world.children.whereType<ObstacleBlock>().where(
          (b) =>
              b != player.stuckPlatform &&
              (b.type == BlockType.matchaPad ||
                  b.type == BlockType.crumblingPad),
        );

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

      // Ferma i pallini della traiettoria se incontrano una piattaforma solida
      bool hitSolidPlatform = false;
      for (final pad in solidPads) {
        final halfW = pad.size.x / 2;
        final halfH = pad.size.y / 2;
        final cx = simPos.x.clamp(pad.position.x - halfW, pad.position.x + halfW);
        final cy = simPos.y.clamp(pad.position.y - halfH, pad.position.y + halfH);
        final dx = simPos.x - cx;
        final dy = simPos.y - cy;
        if ((dx * dx + dy * dy) <=
            (PlayerCore.radius + 1.0) * (PlayerCore.radius + 1.0)) {
          hitSolidPlatform = true;
          break;
        }
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

      if (hitSolidPlatform) break;
    }
  }
}

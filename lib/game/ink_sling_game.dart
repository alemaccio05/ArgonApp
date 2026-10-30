import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/ball_skins.dart';
import '../core/daily_seed.dart';
import '../core/palette_theme.dart';
import '../services/audio_haptics_service.dart';
import '../services/monetization_service.dart';
import '../services/storage_service.dart';
import '../services/trusted_time_service.dart';
import 'components/ink_flood_wave.dart';
import 'components/ink_particle_pool.dart';
import 'components/obstacle_block.dart';
import 'components/player_core.dart';

/// Macchia d'inchiostro permanente ("Ink Stamp") lasciata ad ogni rimbalzo sul muro
/// o atterraggio su piattaforma mentre si scala la torre.
class InkStamp {
  final double x;
  final double y;
  final double radius;
  final bool isWall;
  final bool isLeftWall;
  final Color color;
  final Offset dropOffset1;
  final Offset dropOffset2;
  final double dropRadius1;
  final double dropRadius2;

  const InkStamp({
    required this.x,
    required this.y,
    required this.radius,
    required this.isWall,
    required this.isLeftWall,
    required this.color,
    required this.dropOffset1,
    required this.dropOffset2,
    required this.dropRadius1,
    required this.dropRadius2,
  });
}

/// Il motore principale di INK TOWER: Climb & Stick.
class InkSlingGame extends FlameGame with DragCallbacks {
  /// Quota Y in cui riposa il centro della sfera a inizio partita (0.0m)
  static const double platformBaseY = 0.0;

  /// Quota Y assoluta della superficie del pavimento in pietra alla base (contatto inferiore palla)
  static const double groundSurfaceY = platformBaseY + PlayerCore.radius;

  final StorageService storage;
  final AudioHapticsService audioHaptics;
  final MonetizationService monetization;

  late PlayerCore player = PlayerCore(position: Vector2(0, platformBaseY));
  late InkFloodWave inkFlood = InkFloodWave(startY: 115);
  final InkParticlePool particlePool = InkParticlePool();
  final FramePerformanceMonitor perfMonitor = FramePerformanceMonitor();

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
      ValueNotifier<AppLanguage>(AppLanguage.en);
  final ValueNotifier<bool> masterSoundNotifier = ValueNotifier<bool>(true);
  ValueNotifier<bool> get masterAudioNotifier => masterSoundNotifier;
  final ValueNotifier<bool> soundNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> musicNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> pauseNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isGameLoadedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> menuEntryEpochNotifier = ValueNotifier<int>(0);

  AppStrings get strings => AppStrings(languageNotifier.value);
  bool get isLowQualityMode => perfMonitor.isLowQualityMode;

  // Controllo Bullet-Time, Pausa e Drag
  double timeScale = 1.0;
  double targetTimeScale = 1.0;
  bool isPaused = false;
  bool isDragging = false;
  final Vector2 dragStart = Vector2.zero();
  final Vector2 dragCurrent = Vector2.zero();

  // Modalità di Gioco e Progressione Livelli Infiniti (1, 2, 3...)
  GameMode activeMode = GameMode.levelProgression;
  int currentLevel = 1;
  double currentGoalMeters = 50.0;
  bool leveledUpInLastRun = false;

  // Stato Generazione Procedurale Torre Infinita (+1 ostacolo ogni 50m)
  Random _infiniteRng = Random(1);
  double _infiniteGeneratedUpToMeter = 0.0;
  int _infiniteStepIndex = 0;
  int _lastInfiniteMilestoneAnnounced = 0;

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
  double _savedReviveMeters = 0.0;
  double runTimeSeconds = 0.0;
  int totalBounces = 0;

  double _pathRecordTimer = 0.0;
  final List<Vector2> flightPath = [];
  final List<double> communityHotspotMeters = [];
  final List<Offset> _paperGrainDots = [];
  final List<ObstacleBlock> _demoPlatforms = [];
  final List<ObstacleBlock> _solidPadsCache = [];
  final List<InkStamp> _inkStamps = [];

  // Cache di TextPainter per evitare chiamate a TextPainter.layout() a 60/120 FPS
  final Map<int, TextPainter> _heightMarkerPainters = {};
  final Map<int, TextPainter> _hotspotMarkerPainters = {};
  String _cachedTextStyleKey = '';

  // Oggetti Paint e Path pre-allocati per il loop di rendering
  final Paint _bgPaint = Paint();
  final Paint _exteriorPaint = Paint();
  final Paint _grainPaint = Paint();
  final Paint _stampFillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _stampRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;
  final Paint _floorFillPaint = Paint();
  final Paint _floorBorderPaint = Paint()..strokeWidth = 1.8;
  final Paint _windowFillPaint = Paint();
  final Paint _windowFramePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2;
  final Paint _windowMullionPaint = Paint()..strokeWidth = 1.4;
  final Path _windowArchPath = Path();
  final Paint _wallFillPaint = Paint();
  final Paint _brickLinePaint = Paint()..strokeWidth = 1.2;
  final Paint _gridLinePaint = Paint();
  final Paint _corbelPaint = Paint();
  final Paint _merlonFillPaint = Paint();
  final Paint _merlonStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;
  final Paint _wallBorderPaint = Paint()..strokeWidth = 2.6;
  final Paint _trajFillPaint = Paint();
  final Paint _trajStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;
  final Vector2 _simPos = Vector2.zero();
  final Vector2 _simVel = Vector2.zero();

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
    masterSoundNotifier.value = storage.masterAudioEnabled;
    soundNotifier.value = storage.soundEnabled;
    musicNotifier.value = storage.musicEnabled;

    audioHaptics.masterEnabled = storage.masterAudioEnabled;
    audioHaptics.soundEnabled = storage.soundEnabled;
    audioHaptics.musicEnabled = storage.musicEnabled;

    currentLevel = storage.currentTowerLevel;
    currentGoalMeters = DailySeedEngine.getLevelGoalMeters(currentLevel);
  }

  @override
  Color backgroundColor() => palette.paperBg;

  /// Metà larghezza interna effettiva della torre: si adatta automaticamente
  /// agli schermi più stretti così i rimbalzi fisici della palla coincidono col bordo interno.
  double get towerHalfWidth => size.x > 0
      ? min(DailySeedEngine.worldWidth / 2, (size.x / 2) - 16.0)
      : DailySeedEngine.worldWidth / 2;

  /// Calcola l'altezza corrente in metri sottraendo sistematicamente il raggio della sfera
  /// (`bottomContactY = position.y + radius`) rispetto alla superficie base (`groundSurfaceY`),
  /// così il contatto palla-pavimento equivale esattamente a `0.0 m`.
  /// Se la palla è ancorata alla piattaforma di recupero Seconda Chance, restituisce la quota
  /// esatta sincronizzata (`heightScore`) senza oscillazioni in virgola mobile.
  double computeCurrentHeightMeters() {
    final stuckPad = player.stuckPlatform;
    if (stuckPad != null && stuckPad.heightScore != null) {
      return DailySeedEngine.roundMeters(
        stuckPad.heightScore!,
        maxGoal: currentGoalMeters,
      );
    }
    if (player.isRespawnFrozen && _savedReviveMeters > 0.0) {
      return _savedReviveMeters;
    }
    final climbPixels = max(0.0, groundSurfaceY - player.bottomContactY);
    final rawMeters = climbPixels / DailySeedEngine.metersToPixels;
    return rawMeters.clamp(0.0, currentGoalMeters);
  }

  /// Avvia una transizione fluida e rilassante verso il tema successivo
  Future<void> cyclePalette() async {
    final currentIndex =
        RisographPalette.all.indexWhere((p) => p.id == _targetPalette.id);
    final nextPalette =
        RisographPalette.all[(currentIndex + 1) % RisographPalette.all.length];
    await selectPaletteById(nextPalette.id);
  }

  /// Seleziona direttamente un tema specifico tramite il suo ID (es. dal Menu di Pausa)
  Future<void> selectPaletteById(String paletteId) async {
    final nextPalette = RisographPalette.fromId(paletteId);
    _fromPalette = palette;
    _targetPalette = nextPalette;
    _themeTransitionT = 0.0;
    _cachedTextStyleKey = '';

    await storage.setPalette(nextPalette.id);
    audioHaptics.onButtonTap();
  }

  /// Imposta una lingua specifica tra le 6 supportate
  Future<void> setLanguage(AppLanguage lang) async {
    languageNotifier.value = lang;
    _cachedTextStyleKey = '';
    await storage.setLanguage(lang);
    audioHaptics.onButtonTap();
  }

  /// Passa alla lingua successiva tra le 6 più popolari
  Future<void> cycleLanguage() async {
    final all = AppLanguage.values;
    final idx = all.indexOf(languageNotifier.value);
    final next = all[(idx + 1) % all.length];
    await setLanguage(next);
  }

  /// Attiva/Disattiva il Volume Singolo unificato (senza separazione tra SFX e musica ambientale)
  Future<void> toggleVolume() async {
    final next = !soundNotifier.value;
    masterSoundNotifier.value = next;
    soundNotifier.value = next;
    musicNotifier.value = next;
    audioHaptics.masterEnabled = next;
    audioHaptics.soundEnabled = next;
    audioHaptics.musicEnabled = next;
    await storage.setUnifiedVolumeEnabled(next);
    if (next) {
      audioHaptics.onButtonTap();
    }
  }

  Future<void> toggleMasterAudio() => toggleVolume();

  Future<void> toggleSound() => toggleVolume();

  Future<void> toggleMusic() => toggleVolume();

  void _addOverlaySafe(String name) {
    try {
      overlays.add(name);
    } catch (_) {}
  }

  void _removeOverlaySafe(String name) {
    try {
      overlays.remove(name);
    } catch (_) {}
  }

  /// Congela il game loop e la fisica, attenua l'audio e apre il Menu di Pausa
  void pauseGame() {
    if (!isPlaying || isPaused) return;
    isPaused = true;
    pauseNotifier.value = true;
    isDragging = false;
    timeScale = 0.0;
    targetTimeScale = 0.0;
    audioHaptics.onPauseDucking(true);
    _addOverlaySafe('Pause');
  }

  /// Riprende il game loop e la fisica e ripristina il volume audio
  void resumeGame() {
    if (!isPaused) return;
    isPaused = false;
    pauseNotifier.value = false;
    timeScale = 1.0;
    targetTimeScale = 1.0;
    audioHaptics.onPauseDucking(false);
    _removeOverlaySafe('Pause');
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
    isGameLoadedNotifier.value = true;
    menuEntryEpochNotifier.value += 1;
  }

  @override
  void onRemove() {
    audioHaptics.dispose();
    metersNotifier.dispose();
    chargesNotifier.dispose();
    comboNotifier.dispose();
    paletteNotifier.dispose();
    languageNotifier.dispose();
    masterSoundNotifier.dispose();
    soundNotifier.dispose();
    musicNotifier.dispose();
    pauseNotifier.dispose();
    isGameLoadedNotifier.dispose();
    menuEntryEpochNotifier.dispose();
    super.onRemove();
  }

  /// Costruisce un'animazione di sottofondo per il menu principale in cui una palla
  /// scala autonomamente una torre dimostrativa, senza svelare il livello reale!
  void _startMenuDemo() {
    isPlaying = false;
    isPaused = false;
    pauseNotifier.value = false;
    isMenuDemo = true;
    isDragging = false;
    targetTimeScale = 1.0;
    timeScale = 1.0;
    _demoJumpTimer = 0.35;
    _demoStepCounter = 0;
    _demoPlatforms.clear();
    audioHaptics.onPauseDucking(false);

    _buildTowerWithSeed(
      seed: 9021042,
      goalMeters: 140.0,
      difficultyLevel: 2,
      isDemoTower: true,
    );

    player.isDead = false;
  }

  void _buildTowerWithSeed({
    required int seed,
    required double goalMeters,
    required int difficultyLevel,
    bool isDemoTower = false,
    bool isDailyTower = false,
    bool isInfiniteTower = false,
  }) {
    world.removeAll(world.children.where((c) => c != particlePool).toList());
    flightPath.clear();
    communityHotspotMeters.clear();
    _demoPlatforms.clear();
    _solidPadsCache.clear();
    _inkStamps.clear();
    particlePool.clearAll();
    _cachedTextStyleKey = '';

    _infiniteRng = Random(seed);
    _infiniteGeneratedUpToMeter = 3.8;
    _infiniteStepIndex = 0;

    // Posiziona la palla esattamente a platformBaseY (0.0m) così all'inizio l'altezza è 0.0m!
    player = PlayerCore(position: Vector2(0, platformBaseY));
    inkFlood = InkFloodWave(startY: 115);
    world.add(player);
    world.add(inkFlood);
    if (particlePool.parent == null) {
      world.add(particlePool);
    }

    final initialMaxMeter = isInfiniteTower ? 220.0 : (goalMeters - 2.5);
    _generateTowerSpan(
      upToMeters: initialMaxMeter,
      difficultyLevel: difficultyLevel,
      isDemoTower: isDemoTower,
      isDailyTower: isDailyTower,
      isInfiniteTower: isInfiniteTower,
    );

    camera.viewfinder.position = Vector2(0, -180);
  }

  /// Genera proceduralmente i segmenti della torre fino a `upToMeters`.
  /// In modalità `isInfiniteTower`, sblocca un nuovo ostacolo ogni 50m scalati:
  /// - 0-50m (Tier 1): Piattaforme Verdi + Sigilli + Blocchi Rossi Statici
  /// - 50-100m (Tier 2): + Respingenti (Bumper) & Blocchi Rossi Mobili Orizzontali
  /// - 100-150m (Tier 3): + Piattaforme Fragili a Tempo (Crumbling Pads)
  /// - 150-200m (Tier 4): + Piattaforme Verdi Mobili
  /// - 200-250m (Tier 5): + Pattuglie Verticali (Vertical Patrol Hazards)
  /// - 250m+ (Tier 6+): + Laser a Impulsi (Pulsing Lasers) e velocità crescente ogni 50m!
  void _generateTowerSpan({
    required double upToMeters,
    required int difficultyLevel,
    bool isDemoTower = false,
    bool isDailyTower = false,
    bool isInfiniteTower = false,
  }) {
    final rng = _infiniteRng;
    double currentMeter = _infiniteGeneratedUpToMeter;
    int stepIndex = _infiniteStepIndex;

    while (currentMeter < upToMeters) {
      final int tier50 = (currentMeter / 50.0).floor(); // 0, 1, 2, 3, 4, 5...
      final int effectiveDifficulty = isInfiniteTower
          ? (1 + tier50).clamp(1, 20)
          : (isDailyTower
              ? (1 + (currentMeter / 15.0).floor()).clamp(1, 7)
              : difficultyLevel);
      final levelFactor = (effectiveDifficulty - 1).clamp(0, 40);
      final subLevelInTier = isInfiniteTower
          ? ((currentMeter % 50.0) / 5.0).floor()
          : (effectiveDifficulty - 1) % 10;
      final hazardStartMeter = max(4.5, 10.0 - levelFactor * 0.35);

      // In Torre Infinita:
      // - Crumbling pads si sbloccano a 100m (tier50 >= 2)
      // - Moving green pads si sbloccano a 150m (tier50 >= 3)
      final canSpawnCrumbling =
          isInfiniteTower ? (tier50 >= 2) : (effectiveDifficulty >= 3);
      final canSpawnMovingPad =
          isInfiniteTower ? (tier50 >= 3) : (effectiveDifficulty >= 4);

      final crumblingChance = !canSpawnCrumbling
          ? 0.0
          : (0.16 + levelFactor * 0.018 + subLevelInTier * 0.012)
              .clamp(0.16, 0.46);
      final movingPadChance = !canSpawnMovingPad
          ? 0.0
          : (0.15 + levelFactor * 0.016 + subLevelInTier * 0.012)
              .clamp(0.15, 0.40);
      final hazardSpawnChance =
          (0.55 + levelFactor * 0.025 + subLevelInTier * 0.02)
              .clamp(0.55, 0.90);

      final yPos = -currentMeter * DailySeedEngine.metersToPixels;
      final isEarlySection = currentMeter < 12.0 && effectiveDifficulty <= 2;

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

      final canBeSpecialPad =
          !isDemoTower && currentMeter > 11.0 && stepIndex > 1;
      final isCrumblingPad = canBeSpecialPad &&
          canSpawnCrumbling &&
          rng.nextDouble() < crumblingChance;
      final isMovingPad = canBeSpecialPad &&
          !isCrumblingPad &&
          canSpawnMovingPad &&
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
      _solidPadsCache.add(pad);
      if (isDemoTower) {
        _demoPlatforms.add(pad);
      }

      if (stepIndex % 2 == 1) {
        final gemX = -padX * 0.7;
        // In Torre Infinita i Respingenti (Bumper) si sbloccano a 50m (tier50 >= 1)
        final canSpawnBumper =
            isInfiniteTower ? (tier50 >= 1) : (effectiveDifficulty >= 2);
        final bumperChance = !canSpawnBumper
            ? 0.0
            : (0.28 + subLevelInTier * 0.03).clamp(0.28, 0.55);
        final spawnBumperInstead = !isDemoTower &&
            canSpawnBumper &&
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

      if (!isDemoTower &&
          currentMeter >= hazardStartMeter &&
          rng.nextDouble() < hazardSpawnChance) {
        final speedBonus = levelFactor * 3.5 + subLevelInTier * 3.0;

        // Sblocco progressivo degli ostacoli ogni 50m nella Torre Infinita:
        // - 0-50m (tier50 == 0): [0] Blocchi Rossi
        // - 50m+ (tier50 >= 1): + [1] Blocchi Rossi Mobili Centrali
        // - 200m+ (tier50 >= 4): + [2] Pattuglie Verticali
        // - 250m+ (tier50 >= 5): + [3] Laser a Impulsi
        final unlockedHazards = <int>[0];
        if (isInfiniteTower) {
          if (tier50 >= 1) unlockedHazards.add(1);
          if (tier50 >= 4) unlockedHazards.add(2);
          if (tier50 >= 5) unlockedHazards.add(3);
        } else {
          if (effectiveDifficulty >= 2 && currentMeter > 12.0) {
            unlockedHazards.add(1);
          }
          if (effectiveDifficulty >= 5 && currentMeter > 14.0) {
            unlockedHazards.add(2);
          }
          if (effectiveDifficulty >= 6 && currentMeter > 16.0) {
            unlockedHazards.add(3);
          }
        }

        final hazardType =
            unlockedHazards[rng.nextInt(unlockedHazards.length)];

        if (hazardType == 0) {
          final hazardX = padX < 0 ? 92.0 : -92.0;
          final shouldMove = isInfiniteTower
              ? (tier50 >= 1 && rng.nextBool())
              : (effectiveDifficulty >= 2 &&
                  (currentMeter > 16.0 || effectiveDifficulty >= 4) &&
                  rng.nextBool());
          world.add(
            ObstacleBlock(
              position: Vector2(hazardX, yPos - 85),
              size: Vector2(86, 16),
              type: BlockType.vermilionHazard,
              movingSpeed: shouldMove ? 60.0 + speedBonus : 0.0,
            ),
          );
        } else if (hazardType == 1) {
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

    _infiniteGeneratedUpToMeter = currentMeter;
    _infiniteStepIndex = stepIndex;
  }

  /// Rimuove i blocchi rimasti molto sotto l'onda di inchiostro nella Torre Infinita
  /// per mantenere la memoria e il numero di componenti costanti anche a migliaia di metri.
  void _prunePassedInfiniteBlocks() {
    final cullThresholdY = inkFlood.y + 48.0 * DailySeedEngine.metersToPixels;
    final toRemove = <ObstacleBlock>[];
    for (final child in world.children) {
      if (child is ObstacleBlock &&
          child != player.stuckPlatform &&
          child.position.y > cullThresholdY) {
        toRemove.add(child);
      }
    }
    for (final b in toRemove) {
      _solidPadsCache.remove(b);
      b.removeFromParent();
    }
  }

  void startRun({GameMode? mode, int? level}) {
    if (mode != null) {
      activeMode = mode;
    }

    // Verifica anti-exploit per la modalità giornaliera
    if (activeMode == GameMode.dailyTower) {
      TrustedTimeService.instance.verifyRuntimeIntegrity();
      if (storage.isDailyLockedByTamper) {
        return;
      }
    }

    isPaused = false;
    pauseNotifier.value = false;
    audioHaptics.onPauseDucking(false);
    _lastInfiniteMilestoneAnnounced = 0;

    if (activeMode == GameMode.levelProgression) {
      currentLevel = level ?? storage.currentTowerLevel;
      currentGoalMeters = DailySeedEngine.getLevelGoalMeters(currentLevel);
      _buildTowerWithSeed(
        seed: DailySeedEngine.getLevelSeed(currentLevel),
        goalMeters: currentGoalMeters,
        difficultyLevel: currentLevel,
      );
    } else if (activeMode == GameMode.infiniteTower) {
      currentGoalMeters = 100000.0;
      final infSeed = DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF;
      _buildTowerWithSeed(
        seed: infSeed,
        goalMeters: currentGoalMeters,
        difficultyLevel: 1,
        isInfiniteTower: true,
      );
    } else {
      currentGoalMeters = DailySeedEngine.goalMeters;
      _buildTowerWithSeed(
        seed: DailySeedEngine.getTodaySeed(),
        goalMeters: currentGoalMeters,
        difficultyLevel: 5,
        isDailyTower: true,
      );
    }

    isMenuDemo = false;
    isPlaying = true;
    isVictory = false;
    reviveUsed = false;
    lastRunWasNewDailyRecord = false;
    leveledUpInLastRun = false;
    targetTimeScale = 1.0;
    timeScale = 1.0;

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

    // Reset deterministico dell'altezza a 0.0m e della posizione iniziale
    maxMetersReached = 0.0;
    _savedReviveMeters = 0.0;
    runTimeSeconds = 0.0;
    totalBounces = 0;
    player.isDead = false;
    player.position.setValues(0.0, platformBaseY);
    player.prevPosition.setValues(0.0, platformBaseY);
    player.velocity.setZero();
    player.acceleration.setZero();
    metersNotifier.value = 0.0;
    chargesNotifier.value = PlayerCore.maxAirCharges;
    comboNotifier.value = 0;

    _removeOverlaySafe('MainMenu');
    _removeOverlaySafe('GameOver');
    _removeOverlaySafe('Pause');
    _addOverlaySafe('Hud');
    audioHaptics.onLaunch();
  }

  /// Funzione isolata e testabile che crea la piattaforma di recupero alla quota esatta
  /// di `targetMeters` e vi ancora deterministicamente la pallina azzerando velocità e accelerazione.
  ObstacleBlock spawnSecondChancePlayer({double? targetMeters}) {
    final exactMeters = DailySeedEngine.roundMeters(
      targetMeters ??
          (_savedReviveMeters > 0.0 ? _savedReviveMeters : maxMetersReached),
      maxGoal: currentGoalMeters,
    );
    _savedReviveMeters = exactMeters;
    maxMetersReached = exactMeters;
    metersNotifier.value = exactMeters;

    // Quota Y in cui deve trovarsi il centro della sfera per corrispondere esattamente a exactMeters
    final reviveBallCenterY =
        platformBaseY - (exactMeters * DailySeedEngine.metersToPixels);

    // 1. Bonifica l'area attorno al punto di rinascita
    final blocksToRemove = <ObstacleBlock>[];
    for (final block in world.children.whereType<ObstacleBlock>()) {
      final minY = min(block.position.y, block.originY);
      final maxY = max(block.position.y, block.originY);

      final isHazardOrBumper = block.type == BlockType.vermilionHazard ||
          block.type == BlockType.verticalPatrolHazard ||
          block.type == BlockType.pulsingLaserHazard ||
          block.type == BlockType.bumperPin;

      final isPlatform = block.type == BlockType.matchaPad ||
          block.type == BlockType.crumblingPad;

      if (isHazardOrBumper) {
        if (maxY >= reviveBallCenterY - 185.0 &&
            minY <= reviveBallCenterY + 115.0) {
          blocksToRemove.add(block);
        }
      } else if (isPlatform) {
        if (maxY >= reviveBallCenterY - 110.0 &&
            minY <= reviveBallCenterY + 90.0) {
          blocksToRemove.add(block);
        }
      }
    }
    for (final b in blocksToRemove) {
      _solidPadsCache.remove(b);
      b.removeFromParent();
    }

    // 2. Crea la piattaforma di salvataggio posizionata in modo che la sua superficie superiore
    //    (`rescuePad.top`) coincida al pixel con `reviveBallCenterY + PlayerCore.radius`!
    const padWidth = 126.0;
    const padHeight = 18.0;
    final padCenterY =
        reviveBallCenterY + PlayerCore.radius + (padHeight / 2.0);

    final rescuePad = ObstacleBlock(
      position: Vector2(0.0, padCenterY),
      size: Vector2(padWidth, padHeight),
      type: BlockType.matchaPad,
      heightScore: exactMeters,
    );
    world.add(rescuePad);
    _solidPadsCache.add(rescuePad);

    // 3. Ancora deterministicamente la pallina alla superficie superiore di rescuePad,
    //    azzerando velocità/accelerazione e attivando il freeze di 0.5s + scudo
    player.respawnOnPlatform(
      rescuePad,
      preferredX: 0.0,
      freezeDuration: PlayerCore.defaultRespawnFreezeDuration,
      shieldDuration: 4.5,
    );
    chargesNotifier.value = PlayerCore.maxAirCharges;

    inkFlood.y = player.y + 9.5 * DailySeedEngine.metersToPixels;
    camera.viewfinder.position = Vector2(0, reviveBallCenterY - 110);

    return rescuePad;
  }

  /// Continua la scalata dal metro dell'impatto usando `spawnSecondChancePlayer`.
  void reviveWithShield() {
    if (reviveUsed) return;
    reviveUsed = true;
    isPlaying = true;
    isPaused = false;
    pauseNotifier.value = false;
    _hitStopTimer = 0.0;
    timeScale = 1.0;
    targetTimeScale = 1.0;
    audioHaptics.onPauseDucking(false);

    spawnSecondChancePlayer();

    _removeOverlaySafe('GameOver');
    _removeOverlaySafe('Pause');
    _addOverlaySafe('Hud');
    audioHaptics.onSealCollected(combo: 1);
  }

  Future<void> triggerGameOver({required bool victory}) async {
    if (!isPlaying) return;
    isPlaying = false;
    isPaused = false;
    pauseNotifier.value = false;
    isVictory = victory;
    isDragging = false;
    targetTimeScale = 1.0;
    timeScale = 1.0;
    audioHaptics.onPauseDucking(false);

    if (victory) {
      maxMetersReached = currentGoalMeters;
      _savedReviveMeters = currentGoalMeters;
      metersNotifier.value = currentGoalMeters;
      triggerHitStop(0.055);
      addCameraTrauma(0.75);
      spawnInkDropsAt(
        player.position.x,
        player.position.y,
        palette.ochreSeal,
        count: 30,
      );
    } else {
      // Memorizza il valore esatto arrotondato al momento dell'impatto per la Seconda Chance
      maxMetersReached = DailySeedEngine.roundMeters(
        maxMetersReached,
        maxGoal: currentGoalMeters,
      );
      _savedReviveMeters = maxMetersReached;
      metersNotifier.value = maxMetersReached;

      player.isDead = true;
      triggerHitStop(0.08);
      addCameraTrauma(0.85);
      final skin = BallSkinsCatalog.getById(storage.selectedBallSkinId);
      spawnInkDeathExplosion(
        player.position,
        skin.getCoreColor(palette),
        palette.vermilionHazard,
      );
    }
    audioHaptics.onCrashOrVictory(victory: victory);

    final prevMaxLevel = storage.currentTowerLevel;
    lastRunWasNewDailyRecord = await storage.recordRunResult(
      mode: activeMode,
      playedLevel: currentLevel,
      meters: maxMetersReached,
      isVictory: victory,
      consumeOfficialAttempt:
          activeMode == GameMode.dailyTower && isOfficialRun && !reviveUsed,
      bounces: totalBounces,
      isOfficialAttempt:
          activeMode == GameMode.dailyTower ? isOfficialRun : true,
    );
    leveledUpInLastRun =
        activeMode == GameMode.levelProgression &&
        victory &&
        storage.currentTowerLevel > prevMaxLevel;

    monetization.recordRunCompleted();

    if (!victory) {
      await Future<void>.delayed(const Duration(milliseconds: 1100));
    }

    if (isMenuDemo) return;

    _removeOverlaySafe('Hud');
    _removeOverlaySafe('Pause');
    _addOverlaySafe('GameOver');
  }

  void returnToMainMenu() {
    _startMenuDemo();
    menuEntryEpochNotifier.value += 1;
    _removeOverlaySafe('Hud');
    _removeOverlaySafe('Pause');
    _removeOverlaySafe('GameOver');
    _addOverlaySafe('MainMenu');
  }

  void triggerHitStop(double durationSeconds) {
    _hitStopTimer = durationSeconds;
  }

  void addCameraTrauma(double amount) {
    _shakeTrauma = (_shakeTrauma + amount).clamp(0.0, 1.0);
  }

  void spawnFloatingStamp(Vector2 worldPos, String text) {
    spawnFloatingStampAt(worldPos.x, worldPos.y, text);
  }

  void spawnFloatingStampAt(double x, double y, String text) {
    particlePool.spawnFloatingStamp(
      x: x,
      y: y,
      label: text,
      baseColor: palette.vermilionHazard,
    );
  }

  /// Aggiunge un'impronta permanente d'inchiostro ("Ink Stamp") sulla parete o sulla carta della torre
  void addInkStamp({
    required Vector2 position,
    required bool isWall,
    bool isLeftWall = false,
    required Color color,
  }) {
    addInkStampAt(
      x: position.x,
      y: position.y,
      isWall: isWall,
      isLeftWall: isLeftWall,
      color: color,
    );
  }

  void addInkStampAt({
    required double x,
    required double y,
    required bool isWall,
    bool isLeftWall = false,
    required Color color,
  }) {
    if (_inkStamps.length >= 180) {
      _inkStamps.removeAt(0);
    }
    final inwardDir = isWall
        ? (isLeftWall ? 1.0 : -1.0)
        : (_fxRng.nextBool() ? 1.0 : -1.0);
    final drop1 = Offset(
      inwardDir * (5.0 + _fxRng.nextDouble() * 8.0),
      (_fxRng.nextDouble() - 0.5) * 14.0,
    );
    final drop2 = Offset(
      inwardDir * (3.0 + _fxRng.nextDouble() * 9.0),
      (_fxRng.nextDouble() - 0.5) * 16.0,
    );
    _inkStamps.add(
      InkStamp(
        x: x,
        y: y,
        radius: isWall
            ? 6.5 + _fxRng.nextDouble() * 2.5
            : 5.5 + _fxRng.nextDouble() * 2.5,
        isWall: isWall,
        isLeftWall: isLeftWall,
        color: color,
        dropOffset1: drop1,
        dropOffset2: drop2,
        dropRadius1: 1.8 + _fxRng.nextDouble() * 1.4,
        dropRadius2: 1.4 + _fxRng.nextDouble() * 1.2,
      ),
    );
  }

  void spawnInkDrops(Vector2 pos, Color color, {int count = 16}) {
    spawnInkDropsAt(pos.x, pos.y, color, count: count);
  }

  void spawnInkDropsAt(double x, double y, Color color, {int count = 16}) {
    particlePool.spawnInkDrops(
      x: x,
      y: y,
      color: color,
      count: count,
      lowQuality: isLowQualityMode,
    );
  }

  void spawnInkDeathExplosion(
    Vector2 pos,
    Color primaryColor,
    Color secondaryColor,
  ) {
    addInkStampAt(
      x: pos.x,
      y: pos.y,
      isWall: false,
      color: primaryColor,
    );
    addInkStampAt(
      x: pos.x + (_fxRng.nextDouble() - 0.5) * 22.0,
      y: pos.y + (_fxRng.nextDouble() - 0.5) * 22.0,
      isWall: false,
      color: secondaryColor,
    );
    addInkStampAt(
      x: pos.x + (_fxRng.nextDouble() - 0.5) * 32.0,
      y: pos.y + (_fxRng.nextDouble() - 0.5) * 32.0,
      isWall: false,
      color: primaryColor.withAlpha((0.65 * 255).round()),
    );

    particlePool.spawnDeathExplosion(
      x: pos.x,
      y: pos.y,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      lowQuality: isLowQualityMode,
    );
  }

  // ==========================================================================
  // INPUT ONE-HANDED: VIRTUAL SLINGSHOT + BULLET-TIME
  // ==========================================================================
  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (!isPlaying || isPaused || player.airCharges <= 0) return;

    isDragging = true;
    dragStart.setFrom(event.canvasPosition);
    dragCurrent.setFrom(dragStart);
    targetTimeScale = 0.15;
    audioHaptics.onAimTick();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!isDragging || isPaused) return;
    final prevDx = dragStart.x - dragCurrent.x;
    final prevDy = dragStart.y - dragCurrent.y;
    final prevAngle = atan2(prevDy, prevDx);

    dragCurrent.setFrom(event.canvasEndPosition);
    final newDx = dragStart.x - dragCurrent.x;
    final newDy = dragStart.y - dragCurrent.y;
    final newAngle = atan2(newDy, newDx);

    if ((newAngle - prevAngle).abs() > 0.30) {
      audioHaptics.onAimTick();
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!isDragging) return;
    isDragging = false;
    if (isPaused) return;
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
    if (!isPaused) {
      targetTimeScale = 1.0;
    }
  }

  // ==========================================================================
  // GAME LOOP, ANIMAZIONE DEMO MENU & TRANSIZIONE FLUIDA DEL TEMA
  // ==========================================================================
  void _updateMenuDemo(double dt) {
    if (-player.position.y > 115.0 * DailySeedEngine.metersToPixels) {
      player.stuckPlatform = null;
      player.position.setValues(0, platformBaseY);
      player.velocity.setZero();
      player.acceleration.setZero();
      inkFlood.position.y = 140;
      camera.viewfinder.position = Vector2(0, -180);
      _demoStepCounter = 0;
      _inkStamps.clear();
      return;
    }

    if (player.isStuck || player.velocity.y > 120.0) {
      _demoJumpTimer -= dt;
      if (_demoJumpTimer <= 0 ||
          (!player.isStuck && player.velocity.y > 120.0)) {
        _demoJumpTimer = 0.36;
        _demoStepCounter++;

        ObstacleBlock? nextPad;
        double bestDy = double.infinity;
        for (final pad in _demoPlatforms) {
          final dy = player.position.y - pad.position.y;
          if (dy > 45.0 && dy < 340.0 && dy < bestDy) {
            bestDy = dy;
            nextPad = pad;
          }
        }

        double vx;
        double vy;
        if (nextPad != null) {
          final targetX = nextPad.position.x;
          final targetTopY =
              nextPad.position.y - (nextPad.size.y / 2 + PlayerCore.radius);
          final apexY = targetTopY - 54.0;
          final riseH = max(145.0, player.position.y - apexY);
          vy = -sqrt(2.0 * PlayerCore.gravity * riseH);
          final tUp = -vy / PlayerCore.gravity;
          final dropH = max(18.0, targetTopY - apexY);
          final tDown = sqrt(2.0 * dropH / PlayerCore.gravity);
          final totalTime = max(0.25, tUp + tDown);
          vx = ((targetX - player.position.x) / totalTime).clamp(-380.0, 380.0);
        } else {
          vy = -720.0;
          vx = (_demoStepCounter.isEven ? 210.0 : -210.0);
        }

        player.airCharges = PlayerCore.maxAirCharges;
        player.launch(Vector2(vx, vy), silent: true);
      }
    }
  }

  @override
  void update(double dt) {
    // 1. Monitoraggio FPS adattivo (attiva fallback grafico se FPS < 60 su POCO/OPPO)
    if (!isPaused) {
      perfMonitor.recordFrame(dt);
    }

    // 2. Aggiorna la transizione morbida del tema (anche durante la Pausa o nel Menu)
    if (_themeTransitionT < 1.0) {
      _themeTransitionT = (_themeTransitionT + dt / 0.60).clamp(0.0, 1.0);
      final curvedT = Curves.easeInOutCubic.transform(_themeTransitionT);
      palette = RisographPalette.lerp(_fromPalette, _targetPalette, curvedT);
      paletteNotifier.value = palette;
      _cachedTextStyleKey = '';
    }

    // 3. Se il gioco è in Pausa, congela completamente fisica, timer ed entità
    if (isPaused) {
      return;
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

      final currentMeters = computeCurrentHeightMeters();
      if (currentMeters > maxMetersReached) {
        maxMetersReached = currentMeters;
        final rounded = DailySeedEngine.roundMeters(
          maxMetersReached,
          maxGoal: currentGoalMeters,
        );
        if ((rounded - metersNotifier.value).abs() >= 0.09) {
          metersNotifier.value = rounded;
        }
      }

      // Gestione Torre Infinita: generazione continua dei segmenti superiori
      // e notifica di sblocco nuovo ostacolo ogni 50m!
      if (activeMode == GameMode.infiniteTower) {
        if (currentMeters + 125.0 > _infiniteGeneratedUpToMeter) {
          _generateTowerSpan(
            upToMeters: _infiniteGeneratedUpToMeter + 160.0,
            difficultyLevel: 1,
            isInfiniteTower: true,
          );
          _prunePassedInfiniteBlocks();
        }
        if (maxMetersReached >= _lastInfiniteMilestoneAnnounced + 50) {
          _lastInfiniteMilestoneAnnounced += 50;
          spawnFloatingStampAt(
            player.position.x,
            player.position.y - 38.0,
            strings.infiniteNewObstacleStamp(_lastInfiniteMilestoneAnnounced),
          );
          audioHaptics.onSealCollected(
            combo: (_lastInfiniteMilestoneAnnounced ~/ 50).clamp(1, 8),
          );
        }
      }

      _pathRecordTimer += dt;
      if (_pathRecordTimer >= 0.08) {
        _pathRecordTimer = 0.0;
        flightPath.add(player.position.clone());
      }

      if (activeMode != GameMode.infiniteTower &&
          currentMeters >= currentGoalMeters) {
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

    if (isPlaying && !isPaused && isDragging && player.airCharges > 0) {
      _renderPredictiveTrajectory(canvas);
    }
  }

  void _ensureTextPaintersCached(double maxWidth) {
    final key =
        '${palette.id}_${languageNotifier.value.code}_${activeMode.name}_${currentGoalMeters.toInt()}_${maxWidth.toInt()}';
    if (_cachedTextStyleKey == key) return;
    _cachedTextStyleKey = key;

    _heightMarkerPainters.clear();
    _hotspotMarkerPainters.clear();

    for (final hotspotM in communityHotspotMeters) {
      final mInt = hotspotM.toInt();
      final tp = TextPainter(
        text: TextSpan(
          text: strings.dangerZoneMarker(mInt),
          style: TextStyle(
            color: palette.vermilionHazard.withAlpha((0.65 * 255).round()),
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: max(40.0, maxWidth));
      _hotspotMarkerPainters[mInt] = tp;
    }
  }

  TextPainter _getOrCreateHeightMarkerPainter(int m, double maxWidth) {
    final existing = _heightMarkerPainters[m];
    if (existing != null) return existing;

    final isInfinite = activeMode == GameMode.infiniteTower;
    final isGoal = !isInfinite && m == currentGoalMeters.toInt();
    final isInfiniteMilestone = isInfinite && m > 0 && m % 50 == 0;

    final text = isGoal
        ? strings.goalLineMarker(m)
        : (isInfiniteMilestone ? strings.infiniteMilestoneMarker(m) : '${m}m');

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: (isGoal || isInfiniteMilestone)
              ? palette.vermilionHazard
              : palette.inkSecondary,
          fontSize: (isGoal || isInfiniteMilestone) ? 12.0 : 10.0,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: max(40.0, maxWidth));

    if (_heightMarkerPainters.length > 64) {
      _heightMarkerPainters.clear();
    }
    _heightMarkerPainters[m] = tp;
    return tp;
  }

  void _renderPaperBackgroundAndGrid(Canvas canvas) {
    final camPos = camera.viewfinder.position;
    final camY = camPos.y;
    final screenCenter = size / 2;
    final halfW = towerHalfWidth;
    final leftX = screenCenter.x - halfW - camPos.x;
    final rightX = screenCenter.x + halfW - camPos.x;
    final lowQuality = isLowQualityMode;

    // 1. Sfondo generale carta
    _bgPaint.color = palette.paperBg;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _bgPaint);

    // 2. Ombreggiatura esterna fuori dalle mura
    _exteriorPaint.color = palette.inkPrimary.withAlpha((0.08 * 255).round());
    if (leftX > 0) {
      canvas.drawRect(Rect.fromLTWH(0, 0, leftX, size.y), _exteriorPaint);
    }
    if (rightX < size.x) {
      canvas.drawRect(
        Rect.fromLTWH(rightX, 0, size.x - rightX, size.y),
        _exteriorPaint,
      );
    }

    // 3. Finestre ad arco sullo sfondo della Torre ogni 15 metri (solo nel range visibile)
    final maxM = isMenuDemo ? 130 : currentGoalMeters.toInt();
    final minVisM = max(
      12,
      ((-(camY + screenCenter.y + 130)) / DailySeedEngine.metersToPixels)
          .floor(),
    );
    final maxVisM = min(
      maxM,
      ((-(camY - screenCenter.y - 130)) / DailySeedEngine.metersToPixels)
          .ceil(),
    );
    int firstWindowM = minVisM - ((minVisM - 12) % 15);
    if (firstWindowM < 12) firstWindowM = 12;

    for (int m = firstWindowM; m <= maxVisM && m < maxM; m += 15) {
      final worldY = -m * DailySeedEngine.metersToPixels;
      final screenY = screenCenter.y + (worldY - camY);
      if (screenY < -120 || screenY > size.y + 120) continue;

      _drawTowerArchedWindow(
        canvas,
        center: Offset(screenCenter.x - camPos.x, screenY),
        width: 56,
        height: 92,
        lowQuality: lowQuality,
      );
    }

    // 4. Grana della carta Risograph (saltata se FPS < 60)
    if (!lowQuality) {
      _grainPaint.color = palette.inkSecondary.withAlpha((0.09 * 255).round());
      for (final dot in _paperGrainDots) {
        canvas.drawCircle(
          Offset(dot.dx * size.x, dot.dy * size.y),
          1.2,
          _grainPaint,
        );
      }
    }

    // 5. Macchie d'Inchiostro Permanenti ("Ink Stamps")
    for (final stamp in _inkStamps) {
      final sy = screenCenter.y + (stamp.y - camY);
      if (sy < -32 || sy > size.y + 32) continue;
      final sx = screenCenter.x + (stamp.x - camPos.x);
      final center = Offset(sx, sy);

      _stampFillPaint.color = stamp.color.withAlpha((0.30 * 255).round());
      _stampRingPaint.color = stamp.color.withAlpha((0.56 * 255).round());

      if (stamp.isWall) {
        final rect = Rect.fromCenter(
          center: center,
          width: stamp.radius * 1.3,
          height: stamp.radius * 2.2,
        );
        canvas.drawOval(rect, _stampFillPaint);
        canvas.drawOval(rect, _stampRingPaint);
      } else {
        canvas.drawCircle(center, stamp.radius, _stampFillPaint);
        canvas.drawCircle(center, stamp.radius, _stampRingPaint);
      }

      if (!lowQuality) {
        canvas.drawCircle(
          center + stamp.dropOffset1,
          stamp.dropRadius1,
          _stampFillPaint,
        );
        canvas.drawCircle(
          center + stamp.dropOffset2,
          stamp.dropRadius2,
          _stampFillPaint,
        );
      }
    }

    // 6. Base in pietra della torre a 0m (esattamente a groundSurfaceY = +14.0)
    final floorScreenY = screenCenter.y + (groundSurfaceY - camY);
    if (floorScreenY > -40 && floorScreenY < size.y + 80) {
      _floorFillPaint.color = palette.paperGrid;
      canvas.drawRect(
        Rect.fromLTWH(leftX, floorScreenY, rightX - leftX, 24),
        _floorFillPaint,
      );
      _floorBorderPaint.color =
          palette.inkPrimary.withAlpha((0.45 * 255).round());
      canvas.drawLine(
        Offset(leftX, floorScreenY),
        Offset(rightX, floorScreenY),
        _floorBorderPaint,
      );
    }
  }

  void _drawTowerArchedWindow(
    Canvas canvas, {
    required Offset center,
    required double width,
    required double height,
    required bool lowQuality,
  }) {
    final halfW = width / 2;
    final halfH = height / 2;
    final archRadius = halfW;
    final rectTop = center.dy - halfH + archRadius;
    final rectBottom = center.dy + halfH;

    _windowArchPath
      ..reset()
      ..moveTo(center.dx - halfW, rectBottom)
      ..lineTo(center.dx - halfW, rectTop)
      ..arcToPoint(
        Offset(center.dx + halfW, rectTop),
        radius: Radius.circular(archRadius),
        clockwise: true,
      )
      ..lineTo(center.dx + halfW, rectBottom)
      ..close();

    _windowFillPaint.color = palette.paperCard.withAlpha((0.55 * 255).round());
    canvas.drawPath(_windowArchPath, _windowFillPaint);

    _windowFramePaint.color = palette.paperGrid.withAlpha((0.85 * 255).round());
    canvas.drawPath(_windowArchPath, _windowFramePaint);

    if (!lowQuality) {
      _windowMullionPaint.color =
          palette.paperGrid.withAlpha((0.65 * 255).round());
      canvas.drawLine(
        Offset(center.dx, center.dy - halfH),
        Offset(center.dx, rectBottom),
        _windowMullionPaint,
      );
      canvas.drawLine(
        Offset(center.dx - halfW, rectTop + 10),
        Offset(center.dx + halfW, rectTop + 10),
        _windowMullionPaint,
      );
    }
  }

  void _renderMarginsAndMarkers(Canvas canvas) {
    final camPos = camera.viewfinder.position;
    final camY = camPos.y;
    final screenCenter = size / 2;
    final halfW = towerHalfWidth;
    final leftX = screenCenter.x - halfW - camPos.x;
    final rightX = screenCenter.x + halfW - camPos.x;

    final maxM = isMenuDemo ? 130 : currentGoalMeters.toInt();
    const wallThickness = 15.0;
    final maxLabelWidth = rightX - leftX - 24;

    if (!isMenuDemo) {
      _ensureTextPaintersCached(maxLabelWidth);
    }

    // 1. Mura in pietra/mattoni a sinistra e destra della Torre
    _wallFillPaint.color = palette.paperGrid.withAlpha((0.88 * 255).round());
    canvas.drawRect(
      Rect.fromLTWH(leftX - wallThickness, 0, wallThickness, size.y),
      _wallFillPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(rightX, 0, wallThickness, size.y),
      _wallFillPaint,
    );

    // Giunture dei blocchi di pietra lungo le pareti verticali
    _brickLinePaint.color = palette.inkPrimary.withAlpha((0.28 * 255).round());
    const brickHeight = 28.0;
    final firstWorldY = camY - screenCenter.y - brickHeight;
    final lastWorldY = camY + screenCenter.y + brickHeight;
    final startBrickIdx = (firstWorldY / brickHeight).floor();
    final endBrickIdx = (lastWorldY / brickHeight).ceil();

    for (int b = startBrickIdx; b <= endBrickIdx; b++) {
      final wy = b * brickHeight;
      final sy = screenCenter.y + (wy - camY);
      if (sy < -10 || sy > size.y + 10) continue;

      canvas.drawLine(
        Offset(leftX - wallThickness, sy),
        Offset(leftX, sy),
        _brickLinePaint,
      );
      canvas.drawLine(
        Offset(rightX, sy),
        Offset(rightX + wallThickness, sy),
        _brickLinePaint,
      );

      final vOffset = b.isEven ? wallThickness * 0.45 : wallThickness * 0.65;
      canvas.drawLine(
        Offset(leftX - vOffset, sy),
        Offset(leftX - vOffset, sy + brickHeight),
        _brickLinePaint,
      );
      canvas.drawLine(
        Offset(rightX + vOffset, sy),
        Offset(rightX + vOffset, sy + brickHeight),
        _brickLinePaint,
      );
    }

    // 2. Righe orizzontali ogni 5m, mensole ogni 10m e Merlatura (solo nel range visibile O(1))
    final minVisM = max(
      0,
      ((-(camY + screenCenter.y + 70)) / DailySeedEngine.metersToPixels)
          .floor(),
    );
    final maxVisM = min(
      maxM,
      ((-(camY - screenCenter.y - 70)) / DailySeedEngine.metersToPixels)
          .ceil(),
    );
    final firstGridM = minVisM - (minVisM % 5);

    for (int m = firstGridM; m <= maxVisM; m += 5) {
      final worldY = -m * DailySeedEngine.metersToPixels;
      final screenY = screenCenter.y + (worldY - camY);
      if (screenY < -60 || screenY > size.y + 60) continue;

      final isMajor = m % 10 == 0;
      final isInfinite = activeMode == GameMode.infiniteTower;
      final isGoal =
          !isMenuDemo && !isInfinite && m == currentGoalMeters.toInt();
      final isInfiniteMilestone =
          !isMenuDemo && isInfinite && m > 0 && m % 50 == 0;

      _gridLinePaint
        ..color = (isGoal || isInfiniteMilestone)
            ? palette.vermilionHazard
            : (isMajor
                ? palette.paperGrid
                : palette.paperGrid.withAlpha((0.45 * 255).round()))
        ..strokeWidth = (isGoal || isInfiniteMilestone)
            ? 2.6
            : (isMajor ? 1.5 : 0.8);

      canvas.drawLine(
        Offset(leftX, screenY),
        Offset(rightX, screenY),
        _gridLinePaint,
      );

      if (isMajor && m > 0) {
        _corbelPaint.color = palette.inkPrimary.withAlpha((0.35 * 255).round());
        canvas.drawRect(
          Rect.fromLTWH(leftX, screenY - 3, 9, 6),
          _corbelPaint,
        );
        canvas.drawRect(
          Rect.fromLTWH(rightX - 9, screenY - 3, 9, 6),
          _corbelPaint,
        );
      }

      if (isGoal) {
        const merlonWidth = 22.0;
        const merlonHeight = 16.0;
        _merlonFillPaint.color =
            palette.vermilionHazard.withAlpha((0.22 * 255).round());
        _merlonStrokePaint.color = palette.vermilionHazard;

        for (double x = leftX + 6;
            x < rightX - merlonWidth;
            x += merlonWidth * 1.65) {
          final rect = Rect.fromLTWH(
            x,
            screenY - merlonHeight,
            merlonWidth,
            merlonHeight,
          );
          canvas.drawRect(rect, _merlonFillPaint);
          canvas.drawRect(rect, _merlonStrokePaint);
        }
      }

      if (isMajor && m > 0 && !isMenuDemo) {
        final tp = _getOrCreateHeightMarkerPainter(m, maxLabelWidth);
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
      for (final hotspotM in communityHotspotMeters) {
        final worldY = -hotspotM * DailySeedEngine.metersToPixels;
        final screenY = screenCenter.y + (worldY - camY);
        if (screenY < -30 || screenY > size.y + 30) continue;

        final tp = _hotspotMarkerPainters[hotspotM.toInt()];
        if (tp != null) {
          tp.paint(canvas, Offset(rightX - tp.width - 10, screenY + 4));
        }
      }
    }

    _wallBorderPaint.color = palette.inkPrimary.withAlpha((0.68 * 255).round());
    canvas.drawLine(Offset(leftX, 0), Offset(leftX, size.y), _wallBorderPaint);
    canvas.drawLine(
      Offset(rightX, 0),
      Offset(rightX, size.y),
      _wallBorderPaint,
    );
    canvas.drawLine(
      Offset(leftX - wallThickness, 0),
      Offset(leftX - wallThickness, size.y),
      _wallBorderPaint,
    );
    canvas.drawLine(
      Offset(rightX + wallThickness, 0),
      Offset(rightX + wallThickness, size.y),
      _wallBorderPaint,
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
    _simPos.setFrom(player.position);
    _simVel.setFrom(launchVel);
    const simDt = 0.024;
    final halfWidth = towerHalfWidth - PlayerCore.radius;
    const hitRadSq = (PlayerCore.radius + 1.0) * (PlayerCore.radius + 1.0);

    for (int i = 1; i <= 22; i++) {
      _simVel.y += PlayerCore.gravity * simDt;
      _simPos.x += _simVel.x * simDt;
      _simPos.y += _simVel.y * simDt;

      if (_simPos.x < -halfWidth) {
        _simPos.x = -halfWidth;
        _simVel.x = -_simVel.x * 0.72;
      } else if (_simPos.x > halfWidth) {
        _simPos.x = halfWidth;
        _simVel.x = -_simVel.x * 0.72;
      }

      bool hitSolidPlatform = false;
      for (int pIdx = 0; pIdx < _solidPadsCache.length; pIdx++) {
        final pad = _solidPadsCache[pIdx];
        if (pad == player.stuckPlatform || pad.parent == null) continue;
        final halfW = pad.size.x / 2;
        final halfH = pad.size.y / 2;
        final cx =
            _simPos.x.clamp(pad.position.x - halfW, pad.position.x + halfW);
        final cy =
            _simPos.y.clamp(pad.position.y - halfH, pad.position.y + halfH);
        final dx = _simPos.x - cx;
        final dy = _simPos.y - cy;
        if ((dx * dx + dy * dy) <= hitRadSq) {
          hitSolidPlatform = true;
          break;
        }
      }

      final screenPt = Offset(
        screenCenter.x + (_simPos.x - camPos.x),
        screenCenter.y + (_simPos.y - camPos.y),
      );
      final alpha = (1.0 - i / 23.0) * 0.88;
      final radius = 4.2 - (i * 0.12);

      _trajFillPaint.color =
          palette.playerFill.withAlpha((alpha * 255).round());
      _trajStrokePaint.color =
          palette.playerStroke.withAlpha((alpha * 255).round());

      canvas.drawCircle(screenPt, radius, _trajFillPaint);
      canvas.drawCircle(screenPt, radius, _trajStrokePaint);

      if (hitSolidPlatform) break;
    }
  }
}

import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Singola particella pre-allocata per l'Object Pool (zero allocazioni a runtime).
class PooledInkParticle {
  bool active = false;
  double x = 0.0;
  double y = 0.0;
  double vx = 0.0;
  double vy = 0.0;
  double ax = 0.0;
  double ay = 0.0;
  double radius = 3.0;
  double life = 0.0;
  double maxLife = 0.42;
  Color color = const Color(0xFF1D3557);
}

/// Singola etichetta flottante pre-allocata nell'Object Pool.
class PooledFloatingStamp {
  bool active = false;
  double x = 0.0;
  double y = 0.0;
  double life = 0.0;
  double maxLife = 0.65;
  String label = '';
  TextPainter? cachedPainter;
  Color lastColor = Colors.transparent;
}

/// Monitora in tempo reale il frame time per attivare il fallback prestazionale
/// (riduzione particelle, disattivazione ombre e shader pesanti) se il framerate
/// scende sotto la soglia dei 60 FPS su dispositivi mid-range/entry-level (es. POCO / OPPO).
class FramePerformanceMonitor {
  static const double targetFrameTime = 1.0 / 60.0; // ~16.67ms
  static const double lowFpsThresholdDt = 1.0 / 52.0; // ~19.2ms (< 52 FPS)
  static const double recoveryThresholdDt = 1.0 / 58.0; // ~17.2ms (> 58 FPS)

  double _emaDt = targetFrameTime;
  int _slowFrameStreak = 0;
  int _fastFrameStreak = 0;
  bool _lowQualityMode = false;

  bool get isLowQualityMode => _lowQualityMode;
  double get currentFps => _emaDt > 0.0001 ? (1.0 / _emaDt).clamp(1.0, 240.0) : 60.0;

  void recordFrame(double rawDt) {
    // Ignora pause o spike di caricamento superiori a 200ms
    if (rawDt <= 0.0 || rawDt > 0.20) return;

    _emaDt = _emaDt * 0.88 + rawDt * 0.12;

    if (_emaDt > lowFpsThresholdDt) {
      _slowFrameStreak++;
      _fastFrameStreak = 0;
      if (_slowFrameStreak >= 14 && !_lowQualityMode) {
        _lowQualityMode = true;
      }
    } else if (_emaDt < recoveryThresholdDt) {
      _fastFrameStreak++;
      _slowFrameStreak = 0;
      if (_fastFrameStreak >= 90 && _lowQualityMode) {
        _lowQualityMode = false;
      }
    }
  }

  void setLowQualityForTest(bool value) {
    _lowQualityMode = value;
  }

  void reset() {
    _emaDt = targetFrameTime;
    _slowFrameStreak = 0;
    _fastFrameStreak = 0;
    _lowQualityMode = false;
  }
}

/// Object Pool pre-allocato per particelle d'inchiostro ed etichette flottanti.
/// Elimina completamente l'istanziazione di `ParticleSystemComponent`, `AcceleratedParticle`,
/// `CircleParticle`, `Vector2` e `Paint` durante il salto (`launch`) e i rimbalzi.
class InkParticlePool extends Component {
  static const int maxParticles = 140;
  static const int maxFloatingStamps = 8;

  late final List<PooledInkParticle> _particles;
  late final List<PooledFloatingStamp> _stamps;
  final Paint _particlePaint = Paint()..style = PaintingStyle.fill;
  final Random _rng = Random(1337);

  int _nextParticleCursor = 0;
  int _nextStampCursor = 0;
  int _activeParticleCount = 0;
  int _activeStampCount = 0;

  InkParticlePool() {
    // Pre-allocazione statica all'avvio: zero allocazioni sul Garbage Collector in partita
    _particles = List<PooledInkParticle>.generate(
      maxParticles,
      (_) => PooledInkParticle(),
      growable: false,
    );
    _stamps = List<PooledFloatingStamp>.generate(
      maxFloatingStamps,
      (_) => PooledFloatingStamp(),
      growable: false,
    );
  }

  int get activeParticleCount => _activeParticleCount;
  int get activeStampCount => _activeStampCount;
  int get poolCapacity => _particles.length;

  /// Azzera istantaneamente tutte le particelle attive senza deallocare la memoria
  void clearAll() {
    for (int i = 0; i < maxParticles; i++) {
      _particles[i].active = false;
    }
    for (int i = 0; i < maxFloatingStamps; i++) {
      _stamps[i].active = false;
    }
    _activeParticleCount = 0;
    _activeStampCount = 0;
  }

  PooledInkParticle _acquireParticle() {
    for (int i = 0; i < maxParticles; i++) {
      final idx = (_nextParticleCursor + i) % maxParticles;
      final p = _particles[idx];
      if (!p.active) {
        _nextParticleCursor = (idx + 1) % maxParticles;
        p.active = true;
        _activeParticleCount++;
        return p;
      }
    }
    // Se il pool è saturo, ricicla lo slot più vecchio in modo deterministico
    final p = _particles[_nextParticleCursor];
    _nextParticleCursor = (_nextParticleCursor + 1) % maxParticles;
    p.active = true;
    return p;
  }

  /// Attiva un'esplosione leggera di gocce d'inchiostro riutilizzando i buffer pre-allocati
  void spawnInkDrops({
    required double x,
    required double y,
    required Color color,
    int count = 12,
    bool lowQuality = false,
  }) {
    final effectiveCount = lowQuality ? max(3, count ~/ 2) : count;
    for (int i = 0; i < effectiveCount; i++) {
      final p = _acquireParticle();
      final angle = _rng.nextDouble() * pi * 2.0;
      final speed = 55.0 + _rng.nextDouble() * 220.0;
      final vx = cos(angle) * speed;
      final vy = sin(angle) * speed;

      p.x = x;
      p.y = y;
      p.vx = vx;
      p.vy = vy;
      p.ax = -vx * 1.9;
      p.ay = -vy * 1.9;
      p.radius = 2.5 + _rng.nextDouble() * 3.0;
      p.life = 0.0;
      p.maxLife = 0.42;
      p.color = color;
    }
  }

  /// Attiva l'esplosione radiale dual-tone alla sconfitta riutilizzando il pool pre-allocato
  void spawnDeathExplosion({
    required double x,
    required double y,
    required Color primaryColor,
    required Color secondaryColor,
    bool lowQuality = false,
  }) {
    final count = lowQuality ? 32 : 65;
    for (int i = 0; i < count; i++) {
      final p = _acquireParticle();
      final angle = _rng.nextDouble() * pi * 2.0;
      final isHeavyBlob = i % 7 == 0;
      final isSecondary = i % 3 == 0;
      final speed = isHeavyBlob
          ? 140.0 + _rng.nextDouble() * 340.0
          : 60.0 + _rng.nextDouble() * 480.0;
      final vx = cos(angle) * speed;
      final vy = sin(angle) * speed;

      p.x = x;
      p.y = y;
      p.vx = vx;
      p.vy = vy;
      p.ax = -vx * 1.5;
      p.ay = -vy * 1.5 + 360.0;
      p.radius = isHeavyBlob
          ? 6.0 + _rng.nextDouble() * 4.5
          : 2.0 + _rng.nextDouble() * 3.5;
      p.life = 0.0;
      p.maxLife = 0.68;
      p.color = isSecondary ? secondaryColor : primaryColor;
    }
  }

  /// Attiva un'etichetta flottante ("+BOOST!", "SCUDO!") dal pool pre-allocato
  void spawnFloatingStamp({
    required double x,
    required double y,
    required String label,
    required Color baseColor,
  }) {
    PooledFloatingStamp? slot;
    for (int i = 0; i < maxFloatingStamps; i++) {
      final idx = (_nextStampCursor + i) % maxFloatingStamps;
      if (!_stamps[idx].active) {
        slot = _stamps[idx];
        _nextStampCursor = (idx + 1) % maxFloatingStamps;
        _activeStampCount++;
        break;
      }
    }
    if (slot == null) {
      slot = _stamps[_nextStampCursor];
      _nextStampCursor = (_nextStampCursor + 1) % maxFloatingStamps;
    }

    slot.active = true;
    slot.x = x;
    slot.y = y;
    slot.life = 0.0;
    slot.maxLife = 0.65;
    if (slot.label != label ||
        slot.lastColor != baseColor ||
        slot.cachedPainter == null) {
      slot.label = label;
      slot.lastColor = baseColor;
      slot.cachedPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: baseColor,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }
  }

  @override
  void update(double dt) {
    if (_activeParticleCount > 0) {
      int alive = 0;
      for (int i = 0; i < maxParticles; i++) {
        final p = _particles[i];
        if (!p.active) continue;
        p.life += dt;
        if (p.life >= p.maxLife) {
          p.active = false;
          continue;
        }
        p.vx += p.ax * dt;
        p.vy += p.ay * dt;
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        alive++;
      }
      _activeParticleCount = alive;
    }

    if (_activeStampCount > 0) {
      int aliveStamps = 0;
      for (int i = 0; i < maxFloatingStamps; i++) {
        final s = _stamps[i];
        if (!s.active) continue;
        s.life += dt;
        if (s.life >= s.maxLife) {
          s.active = false;
          continue;
        }
        s.y -= 48.0 * dt;
        aliveStamps++;
      }
      _activeStampCount = aliveStamps;
    }
  }

  @override
  void render(Canvas canvas) {
    if (_activeParticleCount > 0) {
      for (int i = 0; i < maxParticles; i++) {
        final p = _particles[i];
        if (!p.active) continue;
        final progress = (1.0 - (p.life / p.maxLife)).clamp(0.0, 1.0);
        _particlePaint.color = p.color.withAlpha((progress * 255).round());
        canvas.drawCircle(
          Offset(p.x, p.y),
          p.radius * (0.45 + 0.55 * progress),
          _particlePaint,
        );
      }
    }

    if (_activeStampCount > 0) {
      for (int i = 0; i < maxFloatingStamps; i++) {
        final s = _stamps[i];
        if (!s.active || s.cachedPainter == null) continue;
        final tp = s.cachedPainter!;
        tp.paint(canvas, Offset(s.x - tp.width / 2, s.y - tp.height / 2));
      }
    }
  }
}

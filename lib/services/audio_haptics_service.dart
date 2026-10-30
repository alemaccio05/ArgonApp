import 'package:flutter/services.dart';
import 'sound_synth_stub.dart'
    if (dart.library.io) 'sound_synth_io.dart';

/// Gestisce gli effetti sonori sintetizzati in memoria pre-allocata (44.1kHz PCM/WAV),
/// i controlli Master / SFX / Musica, il ducking durante la Pausa e i feedback aptici.
class AudioHapticsService {
  final NativeSoundSynth _synth = NativeSoundSynth();
  final Stopwatch _clock = Stopwatch()..start();

  int _currentCombo = 0;
  bool _masterEnabled = true;
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _isPaused = false;

  int _lastAimTickMs = -1000;
  int _lastPadStickMs = -1000;
  int _lastWallBounceMs = -1000;
  int _lastBumperMs = -1000;

  AudioHapticsService() {
    _synth.init();
  }

  bool get masterEnabled => _masterEnabled;
  set masterEnabled(bool value) {
    _masterEnabled = value;
    if (!value) {
      _synth.stopAll();
    }
  }

  bool get soundEnabled => _soundEnabled;
  set soundEnabled(bool value) {
    _soundEnabled = value;
    if (!value) {
      _synth.stopAll();
    }
  }

  bool get musicEnabled => _musicEnabled;
  set musicEnabled(bool value) {
    _musicEnabled = value;
    if (_masterEnabled) {
      _synth.setMusicEnabled(value);
    }
  }

  bool get isPaused => _isPaused;
  bool get _canPlaySfx => _masterEnabled && _soundEnabled;

  /// Attenua / silenzia l'audio di gioco durante la Pausa e lo ripristina al Resume
  void onPauseDucking(bool paused) {
    _isPaused = paused;
    _synth.setPaused(paused);
  }

  /// Feedback tattile + sonoro per il tap sui pulsanti UI
  void onButtonTap() {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
    if (_canPlaySfx) {
      _synth.playAimTick();
    }
  }

  /// Calcola il moltiplicatore di pitch pentatonico in base alla combo corrente
  double get currentPitch => 1.0 + (_currentCombo.clamp(0, 12) * 0.06);

  void onAimTick() {
    if (!_canPlaySfx) return;
    final now = _clock.elapsedMilliseconds;
    if (now - _lastAimTickMs < 65) return;
    _lastAimTickMs = now;
    _synth.playAimTick();
  }

  void onLaunch() {
    if (!_canPlaySfx || _isPaused) return;
    _synth.playLaunch();
  }

  void onPadStick({required int combo}) {
    if (!_canPlaySfx || _isPaused) return;
    final now = _clock.elapsedMilliseconds;
    if (now - _lastPadStickMs < 110) return;
    _lastPadStickMs = now;
    _currentCombo = combo;
    _synth.playPadStick(combo);
  }

  void onWallOrPadBounce({required int combo}) {
    if (!_canPlaySfx || _isPaused) return;
    final now = _clock.elapsedMilliseconds;
    if (now - _lastWallBounceMs < 90) return;
    _lastWallBounceMs = now;
    _currentCombo = combo;
    _synth.playWallBounce();
  }

  void onBumperBounce() {
    if (!_canPlaySfx || _isPaused) return;
    final now = _clock.elapsedMilliseconds;
    if (now - _lastBumperMs < 110) return;
    _lastBumperMs = now;
    _synth.playBumper();
  }

  void onSealCollected({required int combo}) {
    if (!_canPlaySfx || _isPaused) return;
    _currentCombo = combo;
    _synth.playSeal(combo);
  }

  void onShieldBreak() {
    if (!_canPlaySfx || _isPaused) return;
    _synth.playShieldBreak();
  }

  void onCrashOrVictory({bool victory = false}) {
    _currentCombo = 0;
    if (!_canPlaySfx || _isPaused) return;
    if (victory) {
      _synth.playVictory();
    } else {
      _synth.playCrash();
    }
  }

  void dispose() {
    _synth.dispose();
  }
}

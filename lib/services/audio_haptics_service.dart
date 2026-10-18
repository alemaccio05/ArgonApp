import 'sound_synth_stub.dart'
    if (dart.library.io) 'sound_synth_io.dart';

/// Gestisce gli effetti sonori sintetizzati in tempo reale (44.1kHz PCM/WAV)
/// per ogni azione di gioco, con silenziamento immediato quando `soundEnabled == false`.
class AudioHapticsService {
  final NativeSoundSynth _synth = NativeSoundSynth();
  int _currentCombo = 0;
  bool _soundEnabled = true;

  int _lastAimTickMs = 0;
  int _lastPadStickMs = 0;
  int _lastWallBounceMs = 0;
  int _lastBumperMs = 0;

  AudioHapticsService() {
    _synth.init();
  }

  bool get soundEnabled => _soundEnabled;

  set soundEnabled(bool value) {
    _soundEnabled = value;
    if (!value) {
      _synth.stopAll();
    }
  }

  /// Calcola il moltiplicatore di pitch pentatonico in base alla combo corrente
  double get currentPitch => 1.0 + (_currentCombo.clamp(0, 12) * 0.06);

  void onAimTick() {
    if (!_soundEnabled) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastAimTickMs < 65) return;
    _lastAimTickMs = now;
    _synth.playAimTick();
  }

  void onLaunch() {
    if (!_soundEnabled) return;
    _synth.playLaunch();
  }

  void onPadStick({required int combo}) {
    if (!_soundEnabled) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastPadStickMs < 110) return;
    _lastPadStickMs = now;
    _currentCombo = combo;
    _synth.playPadStick(combo);
  }

  void onWallOrPadBounce({required int combo}) {
    if (!_soundEnabled) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastWallBounceMs < 90) return;
    _lastWallBounceMs = now;
    _currentCombo = combo;
    _synth.playWallBounce();
  }

  void onBumperBounce() {
    if (!_soundEnabled) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastBumperMs < 110) return;
    _lastBumperMs = now;
    _synth.playBumper();
  }

  void onSealCollected({required int combo}) {
    if (!_soundEnabled) return;
    _currentCombo = combo;
    _synth.playSeal(combo);
  }

  void onShieldBreak() {
    if (!_soundEnabled) return;
    _synth.playShieldBreak();
  }

  void onCrashOrVictory({bool victory = false}) {
    _currentCombo = 0;
    if (!_soundEnabled) return;
    if (victory) {
      _synth.playVictory();
    } else {
      _synth.playCrash();
    }
  }
}

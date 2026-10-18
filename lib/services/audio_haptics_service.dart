import 'package:flutter/services.dart';

/// Gestisce il feedback aptico stratificato ("Tactile Paper & Mechanical Feel")
/// e gli hook per effetti sonori a pitch crescente.
class AudioHapticsService {
  int _currentCombo = 0;

  /// Calcola il moltiplicatore di pitch pentatonico in base alla combo corrente
  double get currentPitch => 1.0 + (_currentCombo.clamp(0, 12) * 0.06);

  void onAimTick() {
    HapticFeedback.selectionClick();
  }

  void onLaunch() {
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
  }

  void onWallOrPadBounce({required int combo}) {
    _currentCombo = combo;
    HapticFeedback.lightImpact();
  }

  void onSealCollected({required int combo}) {
    _currentCombo = combo;
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
  }

  void onCrashOrVictory() {
    _currentCombo = 0;
    HapticFeedback.heavyImpact();
  }
}

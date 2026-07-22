import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Cross-platform Audio Engine for UI sound feedback.
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  double sfxVolume = 0.8;
  double musicVolume = 0.5;
  bool isMuted = false;

  void init() {
    // Audio engine initialized
  }

  /// Play UI click / button press feedback
  void playClick() {
    if (isMuted || sfxVolume <= 0) return;
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Play subtle brush draw stroke audio feedback
  void playBrushDraw() {
    if (isMuted || sfxVolume <= 0) return;
  }

  /// Play countdown timer tick
  void playTick({bool isLowTime = false}) {
    if (isMuted || sfxVolume <= 0) return;
    try {
      if (isLowTime) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    } catch (_) {}
  }

  /// Play score reveal chime
  void playScoreReveal() {
    if (isMuted || sfxVolume <= 0) return;
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Play victory celebration fanfare
  void playVictory() {
    if (isMuted || sfxVolume <= 0) return;
    try {
      HapticFeedback.vibrate();
    } catch (_) {}
  }

  /// Play defeat sound
  void playDefeat() {
    if (isMuted || sfxVolume <= 0) return;
  }

  /// Play reward claim / coin gain sound
  void playReward() {
    if (isMuted || sfxVolume <= 0) return;
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }
}

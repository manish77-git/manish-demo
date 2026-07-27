import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:js_interop';

@JS('DrawBattleAudio')
extension type DrawBattleAudio._(JSObject _) implements JSObject {
  external static void setVolume(double v);
  external static void setMuted(bool m);
  external static void playClick();
  external static void playBrushDraw();
  external static void playErase();
  external static void playFillBucket();
  external static void playTick(bool isLowTime);
  external static void playRoundStart();
  external static void playRoundEnd();
  external static void playCorrectReveal();
  external static void playScoreReveal();
  external static void playVictory();
  external static void playDefeat();
  external static void playPlayerJoin();
  external static void playPlayerLeave();
}

/// Cross-platform Audio Engine for UI sound feedback.
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  double sfxVolume = 0.8;
  bool isMuted = false;

  void init() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      sfxVolume = prefs.getDouble('sfx_volume') ?? 0.8;
      isMuted = prefs.getBool('sfx_muted') ?? false;
      _syncJsSettings();
    } catch (_) {}
  }

  Future<void> savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('sfx_volume', sfxVolume);
      await prefs.setBool('sfx_muted', isMuted);
      _syncJsSettings();
    } catch (_) {}
  }

  void _syncJsSettings() {
    if (!kIsWeb) return;
    try {
      DrawBattleAudio.setVolume(sfxVolume);
      DrawBattleAudio.setMuted(isMuted);
    } catch (_) {}
  }

  // ─── PUBLIC SOUND METHODS ──────────────────────────────

  /// Play UI click / button press feedback
  void playClick() {
    try { HapticFeedback.selectionClick(); } catch (_) {}
    if (isMuted || sfxVolume <= 0 || !kIsWeb) return;
    try {
      _syncJsSettings();
      DrawBattleAudio.playClick();
    } catch (_) {}
  }

  /// Play brush draw stroke audio feedback
  void playBrushDraw() {
    if (isMuted || sfxVolume <= 0 || !kIsWeb) return;
    try {
      _syncJsSettings();
      DrawBattleAudio.playBrushDraw();
    } catch (_) {}
  }

  /// Play erase sound
  void playErase() {
    if (isMuted || sfxVolume <= 0 || !kIsWeb) return;
    try {
      _syncJsSettings();
      DrawBattleAudio.playErase();
    } catch (_) {}
  }

  /// Play fill bucket sound
  void playFillBucket() {
    if (isMuted || sfxVolume <= 0 || !kIsWeb) return;
    try {
      _syncJsSettings();
      DrawBattleAudio.playFillBucket();
    } catch (_) {}
  }

  /// Play countdown timer tick
  void playTick({bool isLowTime = false}) {
    try {
      if (isLowTime) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    } catch (_) {}
    if (isMuted || sfxVolume <= 0 || !kIsWeb) return;
    try {
      _syncJsSettings();
      DrawBattleAudio.playTick(isLowTime);
    } catch (_) {}
  }

  /// Play round start — ascending arpeggio
  void playRoundStart() {
    if (isMuted || sfxVolume <= 0 || !kIsWeb) return;
    try {
      _syncJsSettings();
      DrawBattleAudio.playRoundStart();
    } catch (_) {}
  }

  /// Play round end — descending chime
  void playRoundEnd() {
    if (isMuted || sfxVolume <= 0 || !kIsWeb) return;
    try {
      _syncJsSettings();
      DrawBattleAudio.playRoundEnd();
    } catch (_) {}
  }

  /// Play correct answer reveal
  void playCorrectReveal() {
    if (isMuted || sfxVolume <= 0 || !kIsWeb) return;
    try {
      _syncJsSettings();
      DrawBattleAudio.playCorrectReveal();
    } catch (_) {}
  }

  /// Play score reveal chime
  void playScoreReveal() {
    try { HapticFeedback.mediumImpact(); } catch (_) {}
    if (isMuted || sfxVolume <= 0 || !kIsWeb) return;
    try {
      _syncJsSettings();
      DrawBattleAudio.playScoreReveal();
    } catch (_) {}
  }

  /// Play victory celebration fanfare
  void playVictory() {
    try { HapticFeedback.vibrate(); } catch (_) {}
    if (isMuted || sfxVolume <= 0 || !kIsWeb) return;
    try {
      _syncJsSettings();
      DrawBattleAudio.playVictory();
    } catch (_) {}
  }

  /// Play defeat sound
  void playDefeat() {
    if (isMuted || sfxVolume <= 0 || !kIsWeb) return;
    try {
      _syncJsSettings();
      DrawBattleAudio.playDefeat();
    } catch (_) {}
  }

  /// Play player join sound
  void playPlayerJoin() {
    if (isMuted || sfxVolume <= 0 || !kIsWeb) return;
    try {
      _syncJsSettings();
      DrawBattleAudio.playPlayerJoin();
    } catch (_) {}
  }

  /// Play player leave sound
  void playPlayerLeave() {
    if (isMuted || sfxVolume <= 0 || !kIsWeb) return;
    try {
      _syncJsSettings();
      DrawBattleAudio.playPlayerLeave();
    } catch (_) {}
  }

  /// Play menu navigation whoosh
  void playMenuNav() {
    playClick();
  }

  /// Play reward claim / coin gain sound
  void playReward() {
    playScoreReveal();
  }
}

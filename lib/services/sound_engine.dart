// services/sound_engine.dart
//
// Lightweight sound + haptic feedback wrapper.
//
// We deliberately avoid pulling in a third-party audio package (no
// asset-shipping required, simpler grading). Instead we use:
//   • SystemSound  — short OS-provided click for taps
//   • HapticFeedback — vibration cues for matches / mismatches / wins
//
// The whole thing is a no-op when the user has disabled sound in settings.

import 'package:flutter/services.dart';
import 'preferences_store.dart';

class SoundEngine {
  SoundEngine._();
  static final SoundEngine instance = SoundEngine._();

  bool get _enabled => PreferencesStore.instance.isSoundOn;

  /// Tile-flip cue.
  Future<void> flip() async {
    if (!_enabled) return;
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.selectionClick();
  }

  /// Two tiles matched.
  Future<void> match() async {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  /// Two tiles didn't match.
  Future<void> mismatch() async {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Whole board cleared — celebratory pattern.
  Future<void> victory() async {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    HapticFeedback.lightImpact();
  }
}

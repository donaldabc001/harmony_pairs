// services/preferences_store.dart
//
// Wraps SharedPreferences with a tiny ChangeNotifier-style API.
//
// Responsibilities:
//   • Remember whether dark mode and sound effects are enabled.
//   • Persist best-score entries per stage.
//
// Listeners (typically the root widget) repaint whenever any preference
// changes so theme/sound toggles take effect immediately.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/score_record.dart';

class PreferencesStore extends ChangeNotifier {
  PreferencesStore._();

  /// Singleton — the whole app shares one instance.
  static final PreferencesStore instance = PreferencesStore._();

  static const _keyDarkMode = 'pref_dark_mode';
  static const _keySoundOn  = 'pref_sound_on';

  SharedPreferences? _prefs;
  bool _darkMode = false;
  bool _soundOn = true;

  // ---- bootstrapping -----------------------------------------------------

  /// Loads persisted values from disk. Called once from `main()` before the
  /// first frame so the root widget already knows the chosen theme.
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _darkMode = _prefs?.getBool(_keyDarkMode) ?? false;
    _soundOn  = _prefs?.getBool(_keySoundOn) ?? true;
  }

  // ---- getters -----------------------------------------------------------

  bool get isDarkMode => _darkMode;
  bool get isSoundOn  => _soundOn;

  // ---- toggles -----------------------------------------------------------

  Future<void> toggleDarkMode() async {
    _darkMode = !_darkMode;
    await _prefs?.setBool(_keyDarkMode, _darkMode);
    notifyListeners();
  }

  Future<void> toggleSound() async {
    _soundOn = !_soundOn;
    await _prefs?.setBool(_keySoundOn, _soundOn);
    notifyListeners();
  }

  // ---- best-score persistence -------------------------------------------

  /// Reads the best-score record for [storageKey], or null if none yet.
  ScoreRecord? readBestScore(String storageKey) {
    final raw = _prefs?.getString(storageKey);
    if (raw == null) return null;
    try {
      return ScoreRecord.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Corrupt entry — wipe it so the user starts fresh next round.
      _prefs?.remove(storageKey);
      return null;
    }
  }

  /// Saves [candidate] under [storageKey] only if it beats the existing
  /// record (or there is no existing record). Returns true if a new record
  /// was written.
  Future<bool> submitScore(String storageKey, ScoreRecord candidate) async {
    final current = readBestScore(storageKey);
    if (!candidate.isBetterThan(current)) return false;

    await _prefs?.setString(storageKey, jsonEncode(candidate.toJson()));
    notifyListeners();
    return true;
  }
}

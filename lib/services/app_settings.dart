import 'package:flutter/foundation.dart';

import '../models/scenario.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small key/value backing for preferences, swapped out in tests.
abstract interface class SettingsStore {
  Future<bool?> readBool(String key);

  Future<void> writeBool(String key, bool value);

  Future<int?> readInt(String key);

  Future<void> writeInt(String key, int value);

  Future<String?> readString(String key);

  Future<void> writeString(String key, String value);
}

class SharedPreferencesSettingsStore implements SettingsStore {
  const SharedPreferencesSettingsStore();

  @override
  Future<bool?> readBool(String key) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(key);
  }

  @override
  Future<void> writeBool(String key, bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(key, value);
  }

  @override
  Future<int?> readInt(String key) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(key);
  }

  @override
  Future<void> writeInt(String key, int value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(key, value);
  }

  @override
  Future<String?> readString(String key) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(key);
  }

  @override
  Future<void> writeString(String key, String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, value);
  }
}

class InMemorySettingsStore implements SettingsStore {
  InMemorySettingsStore([Map<String, Object>? values]) : _values = {...?values};

  final Map<String, Object> _values;

  @override
  Future<bool?> readBool(String key) async {
    final value = _values[key];
    return value is bool ? value : null;
  }

  @override
  Future<void> writeBool(String key, bool value) async {
    _values[key] = value;
  }

  @override
  Future<int?> readInt(String key) async {
    final value = _values[key];
    return value is int ? value : null;
  }

  @override
  Future<void> writeInt(String key, int value) async {
    _values[key] = value;
  }

  @override
  Future<String?> readString(String key) async {
    final value = _values[key];
    return value is String ? value : null;
  }

  @override
  Future<void> writeString(String key, String value) async {
    _values[key] = value;
  }
}

/// Preferences that shape how a rehearsal plays, kept on the device.
class AppSettings extends ChangeNotifier {
  AppSettings({SettingsStore? store})
    : _store = store ?? const SharedPreferencesSettingsStore();

  static const _spokenRepliesKey = 'rehearse.spoken_replies';
  static const _onboardingKey = 'rehearse.onboarding_completed';
  static const _difficultyKey = 'rehearse.simulation_difficulty';

  final SettingsStore _store;
  bool _spokenRepliesEnabled = true;
  bool _onboardingCompleted = false;
  SimulationDifficulty _difficulty = SimulationDifficulty.defensive;
  bool _isLoaded = false;

  /// False until the first read finishes. The root waits on this rather than
  /// guessing, so a returning manager never sees a flash of onboarding.
  bool get isLoaded => _isLoaded;

  bool get onboardingCompleted => _onboardingCompleted;

  /// The level last chosen. People settle on one, so it is worth not making
  /// them pick it again every time. Defensive is the realistic middle and
  /// the PRD's default reading of the product.
  SimulationDifficulty get difficulty => _difficulty;

  /// Whether the other person's lines are read aloud. On by default: a
  /// rehearsal you can hear is closer to the conversation you are dreading.
  bool get spokenRepliesEnabled => _spokenRepliesEnabled;

  Future<void> load() async {
    try {
      _spokenRepliesEnabled =
          await _store.readBool(_spokenRepliesKey) ?? _spokenRepliesEnabled;
      _onboardingCompleted =
          await _store.readBool(_onboardingKey) ?? _onboardingCompleted;
      _difficulty = SimulationDifficultyLabel.fromName(
        await _store.readString(_difficultyKey),
      );
    } on Object {
      // Fall back to the defaults rather than blocking startup. Erring
      // toward showing onboarding is the safe way to be wrong.
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setDifficulty(SimulationDifficulty value) async {
    if (_difficulty == value) return;
    _difficulty = value;
    notifyListeners();
    try {
      await _store.writeString(_difficultyKey, value.name);
    } on Object {
      // The choice still applies to this session.
    }
  }

  Future<void> completeOnboarding() async {
    if (_onboardingCompleted) return;
    _onboardingCompleted = true;
    notifyListeners();
    try {
      await _store.writeBool(_onboardingKey, true);
    } on Object {
      // It still applies to this session; the worst case is seeing the
      // intro once more.
    }
  }

  Future<void> setSpokenRepliesEnabled(bool value) async {
    if (_spokenRepliesEnabled == value) return;
    _spokenRepliesEnabled = value;
    notifyListeners();
    try {
      await _store.writeBool(_spokenRepliesKey, value);
    } on Object {
      // The choice still applies to this session.
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small key/value backing for preferences, swapped out in tests.
abstract interface class SettingsStore {
  Future<bool?> readBool(String key);

  Future<void> writeBool(String key, bool value);
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
}

class InMemorySettingsStore implements SettingsStore {
  InMemorySettingsStore([Map<String, bool>? values]) : _values = {...?values};

  final Map<String, bool> _values;

  @override
  Future<bool?> readBool(String key) async => _values[key];

  @override
  Future<void> writeBool(String key, bool value) async {
    _values[key] = value;
  }
}

/// Preferences that shape how a rehearsal plays, kept on the device.
class AppSettings extends ChangeNotifier {
  AppSettings({SettingsStore? store})
    : _store = store ?? const SharedPreferencesSettingsStore();

  static const _spokenRepliesKey = 'rehearse.spoken_replies';

  final SettingsStore _store;
  bool _spokenRepliesEnabled = true;

  /// Whether the other person's lines are read aloud. On by default: a
  /// rehearsal you can hear is closer to the conversation you are dreading.
  bool get spokenRepliesEnabled => _spokenRepliesEnabled;

  Future<void> load() async {
    try {
      final stored = await _store.readBool(_spokenRepliesKey);
      if (stored != null && stored != _spokenRepliesEnabled) {
        _spokenRepliesEnabled = stored;
        notifyListeners();
      }
    } on Object {
      // Fall back to the default rather than blocking startup.
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

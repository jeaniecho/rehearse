import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/practice_record.dart';
import '../models/practice_summary.dart';

/// Where finished rehearsals are kept. Swapped for an in-memory store in
/// tests so nothing touches platform channels.
abstract interface class PracticeHistoryStore {
  Future<List<String>> read();

  Future<void> write(List<String> entries);
}

class SharedPreferencesHistoryStore implements PracticeHistoryStore {
  const SharedPreferencesHistoryStore();

  static const _key = 'rehearse.practice_history';

  @override
  Future<List<String>> read() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_key) ?? const [];
  }

  @override
  Future<void> write(List<String> entries) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_key, entries);
  }
}

class InMemoryHistoryStore implements PracticeHistoryStore {
  InMemoryHistoryStore([List<String>? entries])
    : _entries = List.of(entries ?? const []);

  List<String> _entries;

  @override
  Future<List<String>> read() async => List.of(_entries);

  @override
  Future<void> write(List<String> entries) async {
    _entries = List.of(entries);
  }
}

/// The device-local record of every finished rehearsal, plus the momentum
/// figures the home screen and progress screen read from it.
///
/// Records are held newest-first.
class PracticeHistory extends ChangeNotifier {
  PracticeHistory({PracticeHistoryStore? store, DateTime Function()? now})
    : _store = store ?? const SharedPreferencesHistoryStore(),
      _now = now ?? DateTime.now;

  /// Older entries fall off the end so a long-running install cannot grow
  /// preferences without bound.
  static const maxRecords = 200;

  final PracticeHistoryStore _store;
  final DateTime Function() _now;
  List<PracticeRecord> _records = const [];
  bool _isLoaded = false;

  List<PracticeRecord> get records => List.unmodifiable(_records);

  bool get isLoaded => _isLoaded;

  bool get isEmpty => _records.isEmpty;

  Future<void> load() async {
    List<String> entries;
    try {
      entries = await _store.read();
    } on Object {
      entries = const [];
    }

    _records = _sorted([for (final entry in entries) ?_decode(entry)]);
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> add(PracticeRecord record) async {
    _records = _sorted([record, ..._records]);
    if (_records.length > maxRecords) {
      _records = _records.sublist(0, maxRecords);
    }
    _isLoaded = true;
    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    _records = const [];
    _isLoaded = true;
    notifyListeners();
    await _persist();
  }

  // Momentum figures.

  /// Consecutive days ending today, or ending yesterday when today has no
  /// practice yet — so a streak is not lost before the day is over.
  int get streakDays {
    if (_records.isEmpty) return 0;

    final days = _records.map((record) => _dayOf(record.completedAt)).toSet();
    var cursor = _dayOf(_now());
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(cursor)) return 0;
    }

    var streak = 0;
    while (days.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  bool get practicedToday =>
      _records.any((record) => _dayOf(record.completedAt) == _dayOf(_now()));

  int get sessionsThisWeek {
    final cutoff = _dayOf(_now()).subtract(const Duration(days: 6));
    return _records
        .where((record) => !_dayOf(record.completedAt).isBefore(cutoff))
        .length;
  }

  /// Every dimension is an average over the rehearsals that have one.
  ///
  /// A guided rehearsal has none — see [PracticeRecord] — and neither do the
  /// records written before the rubric gained confidence. Both are left out
  /// rather than counted as a neutral 50, so a week of guided practice
  /// cannot drag an average it never measured.
  int? _averageOf(int? Function(PracticeRecord) dimension) {
    final scored = [for (final record in _records) ?dimension(record)];
    return scored.isEmpty ? null : _average(scored);
  }

  /// Null until something has been scored at all.
  int? get averageScore => _averageOf((record) => record.score);

  int? get averageClarity => _averageOf((record) => record.clarity);

  int? get averageEmpathy => _averageOf((record) => record.empathy);

  int? get averageDirectness => _averageOf((record) => record.directness);

  int? get averageConfidence => _averageOf((record) => record.confidence);

  /// Every dimension there is data for, in report order. Empty while nothing
  /// has been scored.
  Map<PracticeSkill, int> get averageSkills => {
    PracticeSkill.clarity: ?averageClarity,
    PracticeSkill.empathy: ?averageEmpathy,
    PracticeSkill.directness: ?averageDirectness,
    PracticeSkill.confidence: ?averageConfidence,
  };

  /// The skill that has scored lowest across every rehearsal, or null while
  /// the scores are still tied or there is nothing scored to read.
  PracticeSkill? get weakestSkill {
    final averages = averageSkills;
    if (averages.isEmpty) return null;
    final lowest = averages.values.reduce((a, b) => a < b ? a : b);
    if (lowest == averages.values.reduce((a, b) => a > b ? a : b)) return null;
    return averages.entries.firstWhere((entry) => entry.value == lowest).key;
  }

  /// Change in average score between the most recent [window] scored
  /// sessions and the [window] before them. Null until there is something to
  /// compare — guided rehearsals are not in this line at all.
  int? scoreTrend({int window = 3}) {
    final scores = [for (final record in _records) ?record.score];
    if (scores.length < window * 2) return null;
    final recent = _average(scores.take(window));
    final earlier = _average(scores.skip(window).take(window));
    return recent - earlier;
  }

  List<PracticeRecord> recordsFor(String scenarioId) => [
    for (final record in _records)
      if (record.scenarioId == scenarioId) record,
  ];

  int? bestScoreFor(String scenarioId) {
    final scores = [for (final record in recordsFor(scenarioId)) ?record.score];
    return scores.isEmpty ? null : scores.reduce((a, b) => a > b ? a : b);
  }

  Future<void> _persist() async {
    try {
      await _store.write([
        for (final record in _records) jsonEncode(record.toJson()),
      ]);
    } on Object {
      // Losing a history write should never interrupt a practice session.
    }
  }

  static PracticeRecord? _decode(String entry) {
    try {
      return PracticeRecord.tryFromJson(jsonDecode(entry));
    } on FormatException {
      return null;
    }
  }

  static List<PracticeRecord> _sorted(List<PracticeRecord> records) =>
      records..sort((a, b) => b.completedAt.compareTo(a.completedAt));

  static DateTime _dayOf(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static int _average(Iterable<int> values) {
    if (values.isEmpty) return 0;
    return (values.reduce((a, b) => a + b) / values.length).round();
  }
}

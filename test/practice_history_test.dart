import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rehearse/models/practice_record.dart';
import 'package:rehearse/models/practice_response.dart';
import 'package:rehearse/models/practice_summary.dart';
import 'package:rehearse/services/practice_history.dart';

PracticeRecord recordAt(
  DateTime completedAt, {
  String scenarioId = 'missed-deadlines',
  int score = 70,
  int clarity = 70,
  int empathy = 70,
  int directness = 70,
  int confidence = 70,
}) {
  return PracticeRecord(
    scenarioId: scenarioId,
    completedAt: completedAt,
    mode: PracticeMode.freestyle,
    score: score,
    clarity: clarity,
    empathy: empathy,
    directness: directness,
    confidence: confidence,
    usedAi: false,
  );
}

PracticeResponse responseWith({
  required int scoreDelta,
  int clarity = 0,
  int empathy = 0,
  int directness = 0,
  int confidence = 0,
  EvaluationSource source = EvaluationSource.guided,
}) {
  return PracticeResponse(
    text: 'response',
    scoreDelta: scoreDelta,
    feedback: 'feedback',
    clarity: clarity,
    empathy: empathy,
    directness: directness,
    confidence: confidence,
    source: source,
  );
}

void main() {
  final today = DateTime(2026, 9, 3, 10);
  DateTime now() => today;

  group('PracticeSummary', () {
    test('starts neutral and moves with each turn', () {
      final summary = PracticeSummary.fromResponses([
        responseWith(
          scoreDelta: 12,
          clarity: 2,
          empathy: 1,
          directness: 2,
          confidence: 2,
        ),
        responseWith(
          scoreDelta: 10,
          clarity: 1,
          empathy: 2,
          directness: 1,
          confidence: 1,
        ),
      ]);

      expect(summary.score, 72);
      expect(summary.clarity, 74);
      expect(summary.empathy, 74);
      expect(summary.directness, 74);
      expect(summary.usedAi, isFalse);
    });

    test('clamps to the 0-100 range', () {
      final summary = PracticeSummary.fromResponses([
        for (var i = 0; i < 8; i++)
          responseWith(
            scoreDelta: -10,
            clarity: -2,
            empathy: -2,
            directness: -2,
            confidence: -2,
          ),
      ]);

      expect(summary.score, 0);
      expect(summary.clarity, 0);
    });

    test('reports AI scoring when any turn was evaluated remotely', () {
      final summary = PracticeSummary.fromResponses([
        responseWith(scoreDelta: 5),
        responseWith(scoreDelta: 5, source: EvaluationSource.ai),
      ]);

      expect(summary.usedAi, isTrue);
    });
  });

  group('PracticeRecord', () {
    test('round-trips through JSON', () {
      final record = recordAt(DateTime(2026, 8, 30, 9, 15), score: 81);
      final restored = PracticeRecord.tryFromJson(
        jsonDecode(jsonEncode(record.toJson())),
      );

      expect(restored, isNotNull);
      expect(restored!.scenarioId, record.scenarioId);
      expect(restored.completedAt, record.completedAt);
      expect(restored.score, 81);
      expect(restored.mode, PracticeMode.freestyle);
    });

    test('rejects entries without an id or timestamp', () {
      expect(PracticeRecord.tryFromJson({'score': 70}), isNull);
      expect(PracticeRecord.tryFromJson({'scenarioId': 'x'}), isNull);
      expect(PracticeRecord.tryFromJson('not a map'), isNull);
    });

    test('reads a record written before the rubric gained a dimension', () {
      // `courage` was always described as directness, so it maps straight
      // across. Confidence was genuinely not measured and stays absent
      // rather than being invented as a neutral 50.
      final record = PracticeRecord.tryFromJson({
        'scenarioId': 'missed-deadlines',
        'completedAt': '2026-08-01T09:00:00.000',
        'score': 74,
        'clarity': 66,
        'empathy': 82,
        'courage': 58,
        'usedAi': true,
      });

      expect(record, isNotNull);
      expect(record!.directness, 58);
      expect(record.confidence, isNull);
      expect(record.toJson().containsKey('confidence'), isFalse);
    });

    test('a new record round-trips all four dimensions', () {
      final record = recordAt(DateTime(2026, 9, 1), score: 80);
      final restored = PracticeRecord.tryFromJson(
        jsonDecode(jsonEncode(record.toJson())),
      );

      expect(restored!.directness, record.directness);
      expect(restored.confidence, record.confidence);
    });

    test('falls back to neutral scores for missing fields', () {
      final record = PracticeRecord.tryFromJson({
        'scenarioId': 'say-no',
        'completedAt': '2026-09-01T12:00:00.000',
      });

      expect(record, isNotNull);
      expect(record!.score, 50);
      expect(record.mode, PracticeMode.guided);
      expect(record.usedAi, isFalse);
    });
  });

  group('PracticeHistory', () {
    test('loads newest first and survives a corrupt entry', () async {
      final store = InMemoryHistoryStore([
        jsonEncode(recordAt(DateTime(2026, 9, 1), score: 60).toJson()),
        'not json at all',
        jsonEncode(recordAt(DateTime(2026, 9, 3), score: 80).toJson()),
        jsonEncode({'nonsense': true}),
      ]);
      final history = PracticeHistory(store: store, now: now);
      addTearDown(history.dispose);

      await history.load();

      expect(history.isLoaded, isTrue);
      expect(history.records.map((record) => record.score), [80, 60]);
    });

    test('persists an added record and notifies listeners', () async {
      final store = InMemoryHistoryStore();
      final history = PracticeHistory(store: store, now: now);
      addTearDown(history.dispose);
      var notifications = 0;
      history.addListener(() => notifications += 1);

      await history.load();
      await history.add(recordAt(today, score: 77));

      expect(notifications, 2);
      expect(await store.read(), hasLength(1));

      final reloaded = PracticeHistory(store: store, now: now);
      addTearDown(reloaded.dispose);
      await reloaded.load();
      expect(reloaded.records.single.score, 77);
    });

    test('drops the oldest records past the cap', () async {
      final history = PracticeHistory(store: InMemoryHistoryStore(), now: now);
      addTearDown(history.dispose);

      for (var i = 0; i <= PracticeHistory.maxRecords; i++) {
        await history.add(
          recordAt(today.subtract(Duration(days: i)), score: 100 - i),
        );
      }

      expect(history.records, hasLength(PracticeHistory.maxRecords));
      expect(history.records.first.score, 100);
      expect(
        history.records.last.completedAt,
        today.subtract(Duration(days: PracticeHistory.maxRecords - 1)),
      );
    });

    test('counts consecutive days, ignoring more than one a day', () async {
      final history = PracticeHistory(store: InMemoryHistoryStore(), now: now);
      addTearDown(history.dispose);

      await history.add(recordAt(today));
      await history.add(recordAt(today.subtract(const Duration(hours: 3))));
      await history.add(recordAt(today.subtract(const Duration(days: 1))));
      await history.add(recordAt(today.subtract(const Duration(days: 2))));

      expect(history.streakDays, 3);
      expect(history.practicedToday, isTrue);
    });

    test('keeps the streak alive on a day not yet practiced', () async {
      final history = PracticeHistory(store: InMemoryHistoryStore(), now: now);
      addTearDown(history.dispose);

      await history.add(recordAt(today.subtract(const Duration(days: 1))));
      await history.add(recordAt(today.subtract(const Duration(days: 2))));

      expect(history.streakDays, 2);
      expect(history.practicedToday, isFalse);
    });

    test('breaks the streak after a missed day', () async {
      final history = PracticeHistory(store: InMemoryHistoryStore(), now: now);
      addTearDown(history.dispose);

      await history.add(recordAt(today.subtract(const Duration(days: 2))));
      await history.add(recordAt(today.subtract(const Duration(days: 3))));

      expect(history.streakDays, 0);
    });

    test('counts the last seven days as this week', () async {
      final history = PracticeHistory(store: InMemoryHistoryStore(), now: now);
      addTearDown(history.dispose);

      await history.add(recordAt(today));
      await history.add(recordAt(today.subtract(const Duration(days: 6))));
      await history.add(recordAt(today.subtract(const Duration(days: 7))));

      expect(history.sessionsThisWeek, 2);
    });

    test('confidence averages only over rehearsals that measured it', () async {
      final history = PracticeHistory(store: InMemoryHistoryStore(), now: now);
      addTearDown(history.dispose);

      await history.add(
        PracticeRecord(
          scenarioId: 'missed-deadlines',
          completedAt: today,
          mode: PracticeMode.guided,
          score: 70,
          clarity: 70,
          empathy: 70,
          directness: 70,
          usedAi: false,
        ),
      );
      expect(history.averageConfidence, isNull);
      expect(
        history.averageSkills.containsKey(PracticeSkill.confidence),
        isFalse,
      );

      await history.add(
        recordAt(today.subtract(const Duration(days: 1)), confidence: 40),
      );

      expect(history.averageConfidence, 40);
      expect(history.averageSkills[PracticeSkill.confidence], 40);
    });

    test('averages scores and skills across every rehearsal', () async {
      final history = PracticeHistory(store: InMemoryHistoryStore(), now: now);
      addTearDown(history.dispose);

      await history.add(recordAt(today, score: 60, clarity: 40, empathy: 90));
      await history.add(
        recordAt(
          today.subtract(const Duration(days: 1)),
          score: 80,
          clarity: 60,
          empathy: 70,
        ),
      );

      expect(history.averageScore, 70);
      expect(history.averageClarity, 50);
      expect(history.averageEmpathy, 80);
    });

    test(
      'reports a trend only once there are two windows to compare',
      () async {
        final history = PracticeHistory(
          store: InMemoryHistoryStore(),
          now: now,
        );
        addTearDown(history.dispose);

        for (var i = 0; i < 5; i++) {
          await history.add(
            recordAt(today.subtract(Duration(days: i)), score: 50),
          );
        }
        expect(history.scoreTrend(), isNull);

        // Six sessions: the three most recent average 80, the older three 50.
        await history.add(recordAt(today.subtract(const Duration(days: 5))));
        for (var i = 0; i < 3; i++) {
          await history.add(
            recordAt(today.add(Duration(days: i + 1)), score: 80),
          );
        }

        expect(history.scoreTrend(), 30);
      },
    );

    test('tracks reps and the best score per scenario', () async {
      final history = PracticeHistory(store: InMemoryHistoryStore(), now: now);
      addTearDown(history.dispose);

      await history.add(recordAt(today, scenarioId: 'say-no', score: 64));
      await history.add(
        recordAt(
          today.subtract(const Duration(days: 1)),
          scenarioId: 'say-no',
          score: 79,
        ),
      );
      await history.add(
        recordAt(today, scenarioId: 'peer-conflict', score: 55),
      );

      expect(history.recordsFor('say-no'), hasLength(2));
      expect(history.bestScoreFor('say-no'), 79);
      expect(history.bestScoreFor('missed-deadlines'), isNull);
    });

    test('clear empties both memory and storage', () async {
      final store = InMemoryHistoryStore();
      final history = PracticeHistory(store: store, now: now);
      addTearDown(history.dispose);

      await history.add(recordAt(today));
      await history.clear();

      expect(history.isEmpty, isTrue);
      expect(await store.read(), isEmpty);
    });

    test('a failing store leaves the app with an empty history', () async {
      final history = PracticeHistory(store: _BrokenStore(), now: now);
      addTearDown(history.dispose);

      await history.load();
      expect(history.isLoaded, isTrue);
      expect(history.isEmpty, isTrue);

      // A failed write must not surface to the caller mid-practice.
      await history.add(recordAt(today));
      expect(history.records, hasLength(1));
    });
  });
}

class _BrokenStore implements PracticeHistoryStore {
  @override
  Future<List<String>> read() async => throw StateError('unavailable');

  @override
  Future<void> write(List<String> entries) async =>
      throw StateError('unavailable');
}

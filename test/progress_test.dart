import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearse/data/scenarios.dart';
import 'package:rehearse/models/practice_record.dart';
import 'package:rehearse/models/practice_response.dart';
import 'package:rehearse/screens/home_screen.dart';
import 'package:rehearse/screens/progress_screen.dart';
import 'package:rehearse/services/practice_history.dart';
import 'package:rehearse/theme/app_theme.dart';
import 'package:rehearse/widgets/practice_history_scope.dart';

PracticeRecord record({
  required String scenarioId,
  required DateTime completedAt,
  int score = 72,
}) {
  return PracticeRecord(
    scenarioId: scenarioId,
    completedAt: completedAt,
    mode: PracticeMode.freestyle,
    score: score,
    clarity: score,
    empathy: score,
    directness: score,
    confidence: score,
    usedAi: false,
  );
}

void main() {
  // Tracks the real clock: the session list formats relative days against
  // DateTime.now(), so a pinned date makes these pass on one day only.
  final realNow = DateTime.now();
  final today = DateTime(realNow.year, realNow.month, realNow.day, 9);
  DateTime now() => today;

  Future<PracticeHistory> pumpApp(
    WidgetTester tester,
    Widget screen, {
    List<PracticeRecord> records = const [],
  }) async {
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final history = PracticeHistory(store: InMemoryHistoryStore(), now: now);
    addTearDown(history.dispose);
    for (final entry in records) {
      await history.add(entry);
    }

    await tester.pumpWidget(
      PracticeHistoryScope(
        history: history,
        child: MaterialApp(theme: AppTheme.light, home: screen),
      ),
    );
    await tester.pumpAndSettle();
    return history;
  }

  group('home momentum', () {
    testWidgets('sells the format before the first rehearsal', (tester) async {
      await pumpApp(tester, const HomeScreen());

      expect(find.text('Say the hard thing.\nBetter.'), findsOneWidget);
      expect(find.text('Start practicing'), findsOneWidget);
      expect(find.text('START HERE'), findsOneWidget);
      expect(find.textContaining('day streak'), findsNothing);
    });

    testWidgets('reports the real streak once there is history', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const HomeScreen(),
        records: [
          record(scenarioId: 'missed-deadlines', completedAt: today, score: 74),
          record(
            scenarioId: 'missed-deadlines',
            completedAt: today.subtract(const Duration(days: 1)),
            score: 66,
          ),
        ],
      );

      expect(find.text('🔥 2 day streak'), findsOneWidget);
      expect(find.text('One more rep?\nGo again.'), findsOneWidget);
      expect(find.text('2 reps · best 74'), findsOneWidget);
    });

    testWidgets('urges you on when the streak has not been kept today', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const HomeScreen(),
        records: [
          record(
            scenarioId: 'missed-deadlines',
            completedAt: today.subtract(const Duration(days: 1)),
          ),
        ],
      );

      expect(find.text('🔥 1 day streak'), findsOneWidget);
      expect(find.text('Keep the streak.\nOne conversation.'), findsOneWidget);
    });

    testWidgets('opens the progress screen from the header', (tester) async {
      await pumpApp(
        tester,
        const HomeScreen(),
        records: [
          record(scenarioId: 'missed-deadlines', completedAt: today, score: 74),
        ],
      );

      await tester.tap(find.byKey(const Key('open_progress')));
      await tester.pumpAndSettle();

      expect(find.text('Your progress'), findsOneWidget);
      expect(find.text('Session history'), findsOneWidget);
    });
  });

  group('recommendation', () {
    test('opens on the authored first scenario for a new manager', () {
      final history = PracticeHistory(store: InMemoryHistoryStore(), now: now);
      addTearDown(history.dispose);

      expect(HomeScreen.recommendedScenario(history), scenarios.first);
    });

    test('moves on to whatever has been rehearsed least', () async {
      final history = PracticeHistory(store: InMemoryHistoryStore(), now: now);
      addTearDown(history.dispose);

      await history.add(
        record(scenarioId: scenarios.first.id, completedAt: today),
      );

      expect(HomeScreen.recommendedScenario(history), scenarios[1]);
    });
  });

  group('progress screen', () {
    testWidgets('explains itself when nothing has been rehearsed', (
      tester,
    ) async {
      await pumpApp(tester, const ProgressScreen());

      expect(find.text('No rehearsals yet'), findsOneWidget);
      expect(find.byKey(const Key('clear_history')), findsNothing);
    });

    testWidgets('lists every session with its score', (tester) async {
      await pumpApp(
        tester,
        const ProgressScreen(),
        records: [
          record(scenarioId: 'missed-deadlines', completedAt: today, score: 74),
          record(
            scenarioId: 'say-no',
            completedAt: today.subtract(const Duration(days: 1)),
            score: 58,
          ),
        ],
      );

      expect(find.text('2-day streak'), findsOneWidget);
      expect(find.text('2 rehearsals on this device.'), findsOneWidget);
      expect(find.text('The slipping deadline'), findsOneWidget);
      expect(find.text('The impossible request'), findsOneWidget);
      expect(find.text('74'), findsOneWidget);
      expect(find.text('58'), findsOneWidget);
      expect(find.textContaining('Today'), findsOneWidget);
      expect(find.textContaining('Yesterday'), findsOneWidget);
    });

    testWidgets('clearing history asks first, then empties', (tester) async {
      final history = await pumpApp(
        tester,
        const ProgressScreen(),
        records: [record(scenarioId: 'missed-deadlines', completedAt: today)],
      );

      await tester.tap(find.byKey(const Key('clear_history')));
      await tester.pumpAndSettle();
      expect(find.text('Clear your practice history?'), findsOneWidget);

      await tester.tap(find.text('Keep it'));
      await tester.pumpAndSettle();
      expect(history.records, hasLength(1));

      await tester.tap(find.byKey(const Key('clear_history')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_clear_history')));
      await tester.pumpAndSettle();

      expect(history.isEmpty, isTrue);
      expect(find.text('No rehearsals yet'), findsOneWidget);
    });
  });

  group('formatRelativeDay', () {
    test('names the recent days and falls back to a date', () {
      expect(formatRelativeDay(today, now: today), 'Today');
      expect(
        formatRelativeDay(today.subtract(const Duration(days: 1)), now: today),
        'Yesterday',
      );
      expect(
        formatRelativeDay(today.subtract(const Duration(days: 3)), now: today),
        '3 days ago',
      );
      expect(
        formatRelativeDay(today.subtract(const Duration(days: 9)), now: today),
        'Last week',
      );
      expect(formatRelativeDay(DateTime(2026, 1, 4), now: today), '4/1/2026');
    });
  });
}

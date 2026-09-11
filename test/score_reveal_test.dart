import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearse/data/scenarios.dart';
import 'package:rehearse/models/practice_response.dart';
import 'package:rehearse/models/practice_summary.dart';
import 'package:rehearse/screens/results_screen.dart';
import 'package:rehearse/services/haptics.dart';
import 'package:rehearse/services/practice_history.dart';
import 'package:rehearse/theme/app_theme.dart';
import 'package:rehearse/widgets/rehearse_scope.dart';

final _scenario = scenarios.first;

PracticeSummary _summary() => PracticeSummary.fromResponses([
  for (final turn in _scenario.turns)
    PracticeResponse.fromChoice(
      turn.choices.reduce((a, b) => a.scoreDelta >= b.scoreDelta ? a : b),
      turn,
    ),
]);

Future<SilentHaptics> pump(
  WidgetTester tester, {
  bool disableAnimations = false,
}) async {
  final haptics = SilentHaptics();
  final history = PracticeHistory(store: InMemoryHistoryStore());
  addTearDown(history.dispose);

  await tester.pumpWidget(
    RehearseScope(
      history: history,
      child: MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: ResultsScreen(
            scenario: _scenario,
            summary: _summary(),
            haptics: haptics,
          ),
        ),
      ),
    ),
  );
  return haptics;
}

String _shown(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('final_score'))).data!;

void main() {
  testWidgets('the score counts up to the real number', (tester) async {
    await pump(tester);
    final target = _summary().score;

    // The first frame starts from nothing rather than showing the answer.
    expect(int.parse(_shown(tester)), lessThan(target));

    await tester.pumpAndSettle();
    expect(_shown(tester), '$target');
  });

  testWidgets('it never overshoots on the way', (tester) async {
    await pump(tester);
    final target = _summary().score;

    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 80));
      expect(int.parse(_shown(tester)), inInclusiveRange(0, target));
    }
    await tester.pumpAndSettle();
  });

  testWidgets('reduce motion shows the score immediately', (tester) async {
    // Not decoration: a number counting itself up is exactly what that
    // setting is for, so with it on there is nothing to wait through.
    final haptics = await pump(tester, disableAnimations: true);

    expect(_shown(tester), '${_summary().score}');
    expect(haptics.calls, ['impact'], reason: 'the moment still lands');
  });

  testWidgets('the phone taps once, as the number arrives', (tester) async {
    final haptics = await pump(tester);
    expect(haptics.calls, isEmpty, reason: 'not when the screen opens');

    await tester.pumpAndSettle();
    expect(haptics.calls, ['impact']);

    // A rebuild for any other reason must not tap again.
    await tester.pump();
    expect(haptics.calls, ['impact']);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearse/app.dart';
import 'package:rehearse/data/scenarios.dart';
import 'package:rehearse/models/practice_response.dart';
import 'package:rehearse/screens/practice_screen.dart';
import 'package:rehearse/services/coach_service.dart';
import 'package:rehearse/theme/app_theme.dart';

void main() {
  testWidgets('completes the recommended practice and shows coaching', (
    tester,
  ) async {
    await tester.pumpWidget(const RehearseApp());

    expect(find.text('Say the hard thing.\nBetter.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('start_recommended')));
    await tester.pumpAndSettle();

    expect(find.text('Scenario briefing'), findsOneWidget);
    expect(find.text('Jordan Lee'), findsOneWidget);

    await tester.fling(
      find.byType(Scrollable).last,
      const Offset(0, -1000),
      1200,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mode_guided')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('begin_simulation')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('choice_1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('coach_feedback')), findsOneWidget);
    await tester.tap(find.byKey(const Key('continue_practice')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('choice_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continue_practice')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('choice_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continue_practice')));
    await tester.pumpAndSettle();

    expect(find.text('COACHING REPORT'), findsOneWidget);
    expect(find.text('88'), findsOneWidget);
    expect(find.text('You held the line with care.'), findsOneWidget);
  });

  testWidgets('evaluates a typed response with the private demo coach', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PracticeScreen(
          scenario: scenarios.first,
          mode: PracticeMode.freestyle,
          coachService: OfflineCoachService(),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('freeform_response')),
      'I see how much you have taken on. We still need to discuss the missed handoffs and agree on a next step.',
    );
    await tester.tap(find.byKey(const Key('submit_response')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('coach_feedback')), findsOneWidget);
    expect(find.text('OFFLINE COACH'), findsOneWidget);

    await tester.tap(find.byKey(const Key('continue_practice')));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
  });
}

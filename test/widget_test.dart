import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearse/app.dart';

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
}

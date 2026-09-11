import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearse/screens/home_screen.dart';
import 'package:rehearse/screens/progress_screen.dart';
import 'package:rehearse/screens/tabs_screen.dart';
import 'package:rehearse/screens/you_screen.dart';
import 'package:rehearse/services/practice_history.dart';
import 'package:rehearse/theme/app_theme.dart';
import 'package:rehearse/widgets/eyebrow.dart';
import 'package:rehearse/widgets/rehearse_scope.dart';

Future<PracticeHistory> pump(WidgetTester tester, {Widget? home}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final history = PracticeHistory(store: InMemoryHistoryStore());
  addTearDown(history.dispose);

  await tester.pumpWidget(
    RehearseScope(
      history: history,
      child: MaterialApp(
        theme: AppTheme.light,
        home: home ?? const TabsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return history;
}

void main() {
  testWidgets('the bar carries two destinations, not three', (tester) async {
    await pump(tester);

    expect(find.byKey(const Key('tab_practice')), findsOneWidget);
    expect(find.byKey(const Key('tab_progress')), findsOneWidget);
    expect(find.text('You'), findsNothing, reason: 'You left the bar');
  });

  testWidgets('the body runs the full height, behind the capsule', (
    tester,
  ) async {
    await pump(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('WARM-UP'), findsOneWidget);
    // The page is not shortened to make room — the capsule floats over it,
    // so there is no white band behind the bar.
    expect(tester.getSize(find.byType(IndexedStack)).height, 932);
  });

  testWidgets('the reserved inset matches what the capsule measures', (
    tester,
  ) async {
    // The screens underneath cannot see the capsule, so they are handed its
    // height as bottom padding. Nothing but this would notice the constant
    // and the real thing drifting apart, and the symptom would be a row
    // stuck behind the bar with no way to scroll it clear.
    await pump(tester);

    expect(
      tester.getSize(find.byKey(const Key('tabs'))).height,
      TabsScreen.navHeight,
    );
  });

  testWidgets('a list can scroll its last row clear of the capsule', (
    tester,
  ) async {
    await pump(tester);

    final list = find.byType(ListView).first;
    await tester.drag(list, const Offset(0, -4000));
    await tester.pumpAndSettle();

    final capsuleTop = tester.getTopLeft(find.byKey(const Key('tabs'))).dy;
    final listBottom = tester.getBottomLeft(list).dy;
    expect(
      listBottom - capsuleTop,
      greaterThan(0),
      reason: 'the list really does run under the capsule',
    );
    // Scrolled to the end, the last thing in the list sits above the bar.
    final lastRail = find.byType(Eyebrow).last;
    expect(tester.getBottomLeft(lastRail).dy, lessThan(capsuleTop));
  });

  testWidgets('the profile button opens You over the bar', (tester) async {
    await pump(tester);
    expect(find.byType(YouScreen), findsNothing);

    await tester.tap(find.byKey(const Key('open_you')));
    await tester.pumpAndSettle();

    expect(find.byType(YouScreen), findsOneWidget);
    // Pushed onto the root navigator, so it covers the bar rather than
    // sitting inside it.
    expect(find.byKey(const Key('tab_practice')), findsNothing);
  });

  testWidgets('You is reachable from progress too', (tester) async {
    await pump(tester, home: const TabsScreen(initialTab: 1));
    expect(find.byType(ProgressScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('open_you')));
    await tester.pumpAndSettle();

    expect(find.byType(YouScreen), findsOneWidget);
  });

  testWidgets('both pills clear the 44pt minimum target', (tester) async {
    await pump(tester);

    for (final key in ['tab_practice', 'tab_progress']) {
      expect(
        tester.getSize(find.byKey(Key(key))).height,
        greaterThanOrEqualTo(44),
        reason: '$key is too small to hit',
      );
    }
  });
}

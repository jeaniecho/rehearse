import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearse/screens/home_screen.dart';
import 'package:rehearse/screens/progress_screen.dart';
import 'package:rehearse/screens/tabs_screen.dart';
import 'package:rehearse/screens/you_screen.dart';
import 'package:rehearse/services/practice_history.dart';
import 'package:rehearse/theme/app_theme.dart';
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

  testWidgets('the capsule leaves the body its height', (tester) async {
    // The bar is given the whole screen to size itself in, and a `Center`
    // there takes all of it — which rendered an empty app once. The body
    // having room is the assertion that stops it happening twice.
    await pump(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Conversations'), findsOneWidget);
    expect(tester.getSize(find.byType(IndexedStack)).height, greaterThan(700));
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

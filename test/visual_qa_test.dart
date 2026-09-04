import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearse/data/scenarios.dart';
import 'package:rehearse/models/practice_response.dart';
import 'package:rehearse/models/practice_summary.dart';
import 'package:rehearse/screens/brief_screen.dart';
import 'package:rehearse/screens/home_screen.dart';
import 'package:rehearse/models/practice_record.dart';
import 'package:rehearse/screens/practice_screen.dart';
import 'package:rehearse/screens/progress_screen.dart';
import 'package:rehearse/screens/results_screen.dart';
import 'package:rehearse/services/coach_service.dart';
import 'package:rehearse/services/practice_history.dart';
import 'package:rehearse/theme/app_theme.dart';
import 'package:rehearse/widgets/illustration.dart';
import 'package:rehearse/widgets/practice_history_scope.dart';

void main() {
  late PracticeHistory history;

  Future<void> render(
    WidgetTester tester,
    Widget screen,
    String filename,
  ) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      PracticeHistoryScope(
        history: history,
        child: MaterialApp(theme: AppTheme.light, home: screen),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Illustration.precacheAll(tester.element(find.byType(MaterialApp))),
    );
    await tester.pumpAndSettle();
    final element = tester.element(find.byType(Scaffold).first);
    await tester.runAsync(() async {
      final image = await captureImage(element);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('/tmp/$filename').writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('render UI review screens', (tester) async {
    final scenario = scenarios.first;
    history = PracticeHistory(store: InMemoryHistoryStore());
    addTearDown(history.dispose);
    final responses = scenario.turns
        .map((turn) => PracticeResponse.fromChoice(turn.choices.first, turn))
        .toList();

    await render(tester, const HomeScreen(), 'rehearse-home-empty.png');

    for (var day = 0; day < 3; day++) {
      await history.add(
        PracticeRecord(
          scenarioId: scenarios[day % scenarios.length].id,
          completedAt: DateTime.now().subtract(Duration(days: day)),
          mode: PracticeMode.freestyle,
          score: 62 + day * 7,
          clarity: 58 + day * 6,
          empathy: 74,
          directness: 50,
          confidence: 50 + day * 9,
          usedAi: day.isEven,
        ),
      );
    }

    await render(tester, const HomeScreen(), 'rehearse-home-refined.png');
    await render(tester, const ProgressScreen(), 'rehearse-progress.png');
    await render(
      tester,
      BriefScreen(scenario: scenario),
      'rehearse-brief-refined.png',
    );
    await render(
      tester,
      PracticeScreen(
        scenario: scenario,
        mode: PracticeMode.freestyle,
        coachService: OfflineCoachService(),
      ),
      'rehearse-practice-refined.png',
    );
    await render(
      tester,
      ResultsScreen(
        scenario: scenario,
        summary: PracticeSummary.fromResponses(responses),
        mode: PracticeMode.guided,
      ),
      'rehearse-results-refined.png',
    );
  });
}

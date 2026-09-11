import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearse/data/scenarios.dart';
import 'package:rehearse/models/practice_response.dart';
import 'package:rehearse/screens/practice_screen.dart';
import 'package:rehearse/services/coach_service.dart';
import 'package:rehearse/services/speech_output_service.dart';
import 'package:rehearse/theme/app_theme.dart';

/// In guided mode the thing the transcript is scrolling in changes height
/// underneath it: choosing an answer swaps three choice cards for a Continue
/// button, which hands the viewport a couple of hundred points, and the next
/// turn takes them back.
///
/// The room used to chase that with a scroll animation and lurched about a
/// hundred points in the wrong direction on the way. It is a reversed view
/// now — the newest line is the anchor — so these pin the end state: after
/// anything the panel does, the view is still at the newest end, which with
/// `reverse` is the *minimum* extent.
void main() {
  final scenario = scenarios.first;

  Future<void> pumpPractice(WidgetTester tester) async {
    // Short enough that the transcript has somewhere to scroll.
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PracticeScreen(
          scenario: scenario,
          mode: PracticeMode.guided,
          coachService: OfflineCoachService(),
          speechOutputService: _SilentVoice(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  ScrollPosition transcriptOf(WidgetTester tester) =>
      tester.state<ScrollableState>(find.byType(Scrollable).first).position;

  testWidgets('the transcript is at the bottom after a choice', (tester) async {
    await pumpPractice(tester);

    await tester.tap(find.byKey(const Key('choice_0')));
    await tester.pumpAndSettle();

    final transcript = transcriptOf(tester);
    expect(
      transcript.pixels,
      moreOrLessEquals(transcript.minScrollExtent, epsilon: 1),
      reason: 'the answer and its note should be in view',
    );
  });

  testWidgets('and after the next turn arrives', (tester) async {
    await pumpPractice(tester);

    await tester.tap(find.byKey(const Key('choice_0')));
    await tester.pumpAndSettle();
    // The panel grows back from one button to three cards here, which is the
    // same problem in the other direction.
    await tester.tap(find.byKey(const Key('continue_practice')));
    await tester.pumpAndSettle();

    final transcript = transcriptOf(tester);
    expect(
      transcript.pixels,
      moreOrLessEquals(transcript.minScrollExtent, epsilon: 1),
    );
  });
}

/// No device voice in a test, and nothing to wait on.
class _SilentVoice implements SpeechOutputService {
  @override
  Future<bool> initialize({
    required SpeakingStateCallback onSpeakingChanged,
  }) async => false;

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}
}

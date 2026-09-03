import 'package:flutter/material.dart';

import '../models/practice_record.dart';
import '../models/practice_response.dart';
import '../models/practice_summary.dart';
import '../models/scenario.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/practice_history_scope.dart';
import '../widgets/score_display.dart';
import '../widgets/subscription_scope.dart';
import 'practice_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({
    required this.scenario,
    required this.responses,
    this.mode = PracticeMode.guided,
    super.key,
  });

  final Scenario scenario;
  final List<PracticeResponse> responses;
  final PracticeMode mode;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late final PracticeSummary _summary = PracticeSummary.fromResponses(
    widget.responses,
  );
  bool _recorded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _recordOnce();
  }

  /// Reaching the report is what counts as finishing a rehearsal, so the
  /// history entry is written here rather than mid-conversation.
  ///
  /// Recording notifies the history's listeners, so it waits until this
  /// frame is done rather than marking widgets dirty mid-build.
  void _recordOnce() {
    if (_recorded) return;
    final history = PracticeHistoryScope.maybeOf(context);
    if (history == null) return;

    _recorded = true;
    // Only a finished rehearsal spends a free session, so abandoning one
    // costs nothing.
    final subscription = SubscriptionScope.maybeOf(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      history.add(
        PracticeRecord.fromSummary(
          scenarioId: widget.scenario.id,
          completedAt: DateTime.now(),
          mode: widget.mode,
          summary: _summary,
        ),
      );
      subscription?.recordCompletedSession();
    });
  }

  PracticeResponse get _strongest =>
      widget.responses.reduce((a, b) => a.scoreDelta >= b.scoreDelta ? a : b);

  PracticeResponse get _weakest =>
      widget.responses.reduce((a, b) => a.scoreDelta <= b.scoreDelta ? a : b);

  void _retry() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            PracticeScreen(scenario: widget.scenario, mode: widget.mode),
      ),
    );
  }

  void _finish() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const BrandMark(),
        actions: [
          TextButton(
            key: const Key('finish_practice'),
            onPressed: _finish,
            child: const Text('Done'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: PageBody(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
        child: ListView(
          children: [
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'COACHING REPORT',
                style: TextStyle(
                  color: AppColors.coral,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            if (widget.mode == PracticeMode.freestyle) ...[
              const SizedBox(height: 9),
              Center(
                child: MetaPill(
                  icon: _summary.usedAi
                      ? Icons.auto_awesome_rounded
                      : Icons.offline_bolt_rounded,
                  label: _summary.usedAi
                      ? 'Personalized by AI'
                      : 'Private demo scoring',
                  color: AppColors.forest,
                  backgroundColor: AppColors.mint,
                ),
              ),
            ],
            const SizedBox(height: 18),
            ScoreRing(key: const Key('final_score'), score: _summary.score),
            const SizedBox(height: 20),
            Text(
              _summary.headline,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 9),
            Text(
              _summary.summary,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(21),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your conversation balance',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'The three skills that make hard messages land.',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 22),
                    SkillBar(
                      label: 'Clarity',
                      value: _summary.clarity,
                      color: SkillColors.clarity,
                    ),
                    const SizedBox(height: 17),
                    SkillBar(
                      label: 'Empathy',
                      value: _summary.empathy,
                      color: SkillColors.empathy,
                    ),
                    const SizedBox(height: 17),
                    SkillBar(
                      label: 'Courage',
                      value: _summary.courage,
                      color: SkillColors.courage,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _CoachCard(
              icon: Icons.auto_awesome_rounded,
              eyebrow: 'KEEP DOING',
              title: 'A move that worked',
              body: _strongest.feedback,
              color: AppColors.forest,
              background: AppColors.mint,
            ),
            const SizedBox(height: 12),
            _CoachCard(
              icon: Icons.north_east_rounded,
              eyebrow: 'TRY NEXT TIME',
              title: 'Make the message easier to act on',
              body: _weakest.scoreDelta >= 8
                  ? widget.scenario.watchFor
                  : _weakest.feedback,
              color: AppColors.coral,
              background: AppColors.peach,
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('retry_scenario'),
                    onPressed: _retry,
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Try again'),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: FilledButton(
                    onPressed: _finish,
                    child: const Text('Choose another'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Practice complete · ${widget.scenario.durationMinutes} min',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String body;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

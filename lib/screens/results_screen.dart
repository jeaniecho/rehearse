import 'package:flutter/material.dart';

import '../models/coaching_note.dart';
import '../models/practice_record.dart';
import '../models/practice_response.dart';
import '../models/practice_summary.dart';
import '../models/scenario.dart';
import '../theme/app_theme.dart';
import '../widgets/analytics_scope.dart';
import '../widgets/app_shell.dart';
import '../widgets/practice_history_scope.dart';
import '../widgets/score_display.dart';
import '../widgets/subscription_scope.dart';
import 'practice_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({
    required this.scenario,
    required this.summary,
    this.mode = PracticeMode.guided,
    this.difficulty = SimulationDifficulty.defensive,
    this.isRetry = false,
    super.key,
  });

  final Scenario scenario;

  /// Already scored. The report never recomputes it, so what is shown and
  /// what is stored cannot disagree.
  final PracticeSummary summary;
  final PracticeMode mode;
  final SimulationDifficulty difficulty;

  /// Carried through from the rehearsal so the retry funnel stays intact
  /// across a "Try again".
  final bool isRetry;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  PracticeSummary get _summary => widget.summary;
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
    AnalyticsScope.maybeOf(
      context,
    )?.evaluationViewed(widget.scenario, mode: widget.mode, summary: _summary);

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

  void _retry() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => PracticeScreen(
          scenario: widget.scenario,
          mode: widget.mode,
          difficulty: widget.difficulty,
          isRetry: true,
        ),
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
                      'The four skills that make hard messages land.',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 22),
                    SkillBars(values: _summary.skills, spacing: 17),
                  ],
                ),
              ),
            ),
            for (final note in _summary.strengths) ...[
              const SizedBox(height: 12),
              _NoteCard(
                note: note,
                eyebrow: 'KEEP DOING',
                icon: Icons.check_circle_rounded,
                color: AppColors.forest,
                background: AppColors.mint,
              ),
            ],
            for (final note in _summary.improvements) ...[
              const SizedBox(height: 12),
              _NoteCard(
                note: note,
                eyebrow: 'TRY NEXT TIME',
                icon: Icons.north_east_rounded,
                color: AppColors.coral,
                background: AppColors.peach,
              ),
            ],
            if (_summary.strengths.isEmpty &&
                _summary.improvements.isEmpty) ...[
              const SizedBox(height: 12),
              _NoteCard(
                note: CoachingNote(
                  turnIndex: 0,
                  quote: '',
                  comment: widget.scenario.watchFor,
                ),
                eyebrow: 'WATCH FOR',
                icon: Icons.visibility_outlined,
                color: AppColors.coral,
                background: AppColors.peach,
              ),
            ],
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

/// One observation, anchored to what the manager actually said.
///
/// The quote is the whole point: a critique you can match to a moment you
/// remember is the difference between advice and coaching.
class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.eyebrow,
    required this.icon,
    required this.color,
    required this.background,
  });

  final CoachingNote note;
  final String eyebrow;
  final IconData icon;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  eyebrow,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Text(
                'TURN ${note.turnIndex + 1}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          if (note.quote.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Quote(text: note.quote, accent: color),
          ],
          const SizedBox(height: 12),
          Text(
            note.comment,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          if (note.suggestion case final suggestion?) ...[
            const SizedBox(height: 14),
            const Text(
              'STRONGER',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 7),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                suggestion,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// What you said, set off so it reads as a quotation rather than as more
/// coaching prose.
class _Quote extends StatelessWidget {
  const _Quote({required this.text, required this.accent});

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 13),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Text(
        '“$text”',
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 14,
          height: 1.45,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

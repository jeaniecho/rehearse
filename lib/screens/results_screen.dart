import 'package:flutter/material.dart';

import '../models/coaching_note.dart';
import '../models/practice_record.dart';
import '../models/practice_response.dart';
import '../models/practice_summary.dart';
import '../models/session_outcome.dart';
import '../models/scenario.dart';
import '../theme/app_theme.dart';
import '../widgets/analytics_scope.dart';
import '../widgets/app_shell.dart';
import '../widgets/brand_mark.dart';
import '../widgets/eyebrow.dart';
import '../widgets/practice_history_scope.dart';
import '../widgets/score_display.dart';
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
    final focusIsImprovement = _summary.improvements.isNotEmpty;
    final focusNote = focusIsImprovement
        ? _summary.improvements.first
        : _summary.strengths.isNotEmpty
        ? _summary.strengths.first
        : CoachingNote(
            turnIndex: 0,
            quote: '',
            comment: widget.scenario.watchFor,
          );

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
      body: PageWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Eyebrow('COACHING REPORT'),
                const SizedBox(width: 12),
                if (widget.mode == PracticeMode.freestyle)
                  Expanded(
                    child: Text(
                      _summary.usedAi
                          ? 'Personalized by AI'
                          : 'Private demo scoring',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 26),
            _ScoreBlock(summary: _summary),
            const SizedBox(height: 22),
            _CoachBubble(text: _summary.summary),
            const SizedBox(height: 30),
            Text(
              focusIsImprovement ? 'The moment to rehearse' : 'What landed',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 5),
            Text(
              focusIsImprovement
                  ? 'One small rewrite can change how the whole message lands.'
                  : 'Keep this part of your approach intact next time.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _NoteCard(
              key: const Key('focus_note'),
              note: focusNote,
              eyebrow: focusIsImprovement ? 'TRY THIS INSTEAD' : 'KEEP THIS',
              icon: focusIsImprovement
                  ? Icons.replay_rounded
                  : Icons.check_circle_rounded,
              color: focusIsImprovement ? AppColors.coral : AppColors.forest,
              background: focusIsImprovement ? AppColors.peach : AppColors.mint,
              prominent: true,
            ),
            for (final note in _summary.strengths.skip(
              focusIsImprovement ? 0 : 1,
            )) ...[
              const SizedBox(height: 12),
              _NoteCard(
                note: note,
                eyebrow: 'KEEP DOING',
                icon: Icons.check_circle_rounded,
                color: AppColors.forest,
                background: AppColors.mint,
              ),
            ],
            for (final note in _summary.improvements.skip(
              focusIsImprovement ? 1 : 0,
            )) ...[
              const SizedBox(height: 12),
              _NoteCard(
                note: note,
                eyebrow: 'TRY NEXT TIME',
                icon: Icons.north_east_rounded,
                color: AppColors.coral,
                background: AppColors.peach,
              ),
            ],
            const SizedBox(height: 18),
            Card(
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 4,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                title: const Text(
                  'Your skill breakdown',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                subtitle: const Text(
                  'Clarity · empathy · directness · confidence',
                ),
                children: [SkillBars(values: _summary.skills, spacing: 17)],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: PageActionBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              key: const Key('retry_scenario'),
              onPressed: _retry,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Practice this scenario again'),
            ),
            TextButton(
              onPressed: _finish,
              child: const Text('Choose another scenario'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The score, given the whole width and nothing to compete with.
///
/// It used to sit as a ring inside a dark card next to the headline, which
/// made three things fight for the same moment.
class _ScoreBlock extends StatelessWidget {
  const _ScoreBlock({required this.summary});

  final PracticeSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'SCORE',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${summary.score}',
          key: const Key('final_score'),
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 76,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: -3,
          ),
        ),
        const SizedBox(height: 14),
        _OutcomePill(outcome: summary.outcome),
        const SizedBox(height: 16),
        Text(
          summary.headline,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ],
    );
  }
}

/// How the conversation ended (PRD §11), which is not how well it was
/// handled — the two sit next to each other here precisely because they can
/// disagree. A careful manager can still end unresolved.
class _OutcomePill extends StatelessWidget {
  const _OutcomePill({required this.outcome});

  final SessionOutcome outcome;

  /// Every pair measured against the 4.5:1 floor for body text: forest on
  /// mint 6.43, forest on sky 6.08, coral on peach 4.99, muted on subtle
  /// 4.77. Re-measure if the palette moves — see `STATUS.md` §6.
  (Color, Color) get _colors => switch (outcome) {
    SessionOutcome.success => (AppColors.forest, AppColors.mint),
    SessionOutcome.partial => (AppColors.forest, AppColors.sky),
    SessionOutcome.unresolved => (AppColors.muted, AppColors.subtle),
    SessionOutcome.escalated => (AppColors.coral, AppColors.peach),
  };

  @override
  Widget build(BuildContext context) {
    final (ink, tint) = _colors;
    return Column(
      children: [
        Container(
          key: const Key('session_outcome'),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            outcome.label.toUpperCase(),
            style: TextStyle(
              color: ink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          outcome.description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

/// The coach saying it, rather than a paragraph of report prose.
///
/// A voice needs somewhere to come from, so the read of the conversation is
/// spoken by the mark the app is already signed with.
class _CoachBubble extends StatelessWidget {
  const _CoachBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.forest,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(Icons.forum_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(15, 13, 15, 14),
            decoration: BoxDecoration(
              color: AppColors.butter,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: AppColors.butterEdge),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
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
    super.key,
    this.prominent = false,
  });

  final CoachingNote note;
  final String eyebrow;
  final IconData icon;
  final Color color;
  final Color background;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(prominent ? 20 : 17),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(prominent ? 18 : 14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 17),
              const SizedBox(width: 8),
              Expanded(child: Eyebrow.small(eyebrow, color: color)),
              Eyebrow.small(
                'TURN ${note.turnIndex + 1}',
                color: AppColors.muted,
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
            const Eyebrow.small('STRONGER', color: AppColors.ink),
            const SizedBox(height: 7),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              // Serif, like the quote above it: this is a line to say, not
              // a note about one. The card then reads as speech, comment,
              // speech, and the comment stops looking like more of your
              // own words. Lighter than the w600 it replaced — the serif
              // was already carrying the emphasis.
              child: Text(
                suggestion,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontFamily: AppTheme.serifFontFamily,
                  fontFamilyFallback: AppTheme.serifFallback,
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
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
///
/// The serif is what does that now. It used to be italic, which was the
/// only distinction one family offered; serif and italic together would be
/// one emphasis too many. A point larger than the comment beside it
/// because the serif's x-height is smaller — the two should look the same
/// size, not measure the same.
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
          fontFamily: AppTheme.serifFontFamily,
          fontFamilyFallback: AppTheme.serifFallback,
          fontSize: 15,
          height: 1.45,
        ),
      ),
    );
  }
}

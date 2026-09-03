import 'package:flutter/material.dart';

import '../models/scenario.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import 'practice_screen.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({
    required this.scenario,
    required this.responses,
    super.key,
  });

  final Scenario scenario;
  final List<ResponseChoice> responses;

  int get _score {
    final total = responses.fold<int>(50, (sum, item) => sum + item.scoreDelta);
    return total.clamp(0, 100);
  }

  int _dimensionScore(int Function(ResponseChoice) read) {
    final total = responses.fold<int>(50, (sum, item) => sum + read(item) * 8);
    return total.clamp(0, 100);
  }

  String get _headline => switch (_score) {
    >= 82 => 'You held the line with care.',
    >= 68 => 'A solid conversation—with room to sharpen.',
    >= 52 => 'You stayed in it. That’s where growth starts.',
    _ => 'That was hard. Let’s make the next one clearer.',
  };

  String get _summary => switch (_score) {
    >= 82 =>
      'You balanced candor with curiosity and ended on a concrete agreement.',
    >= 68 =>
      'Your intent was clear. A little more specificity would make the outcome easier to act on.',
    >= 52 =>
      'You protected the relationship, but softened key moments where clarity mattered.',
    _ =>
      'You reacted to the pressure instead of naming the issue. A slower opening can change the whole conversation.',
  };

  ResponseChoice get _strongest =>
      responses.reduce((a, b) => a.scoreDelta >= b.scoreDelta ? a : b);

  ResponseChoice get _weakest =>
      responses.reduce((a, b) => a.scoreDelta <= b.scoreDelta ? a : b);

  void _retry(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => PracticeScreen(scenario: scenario),
      ),
    );
  }

  void _finish(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final clarity = _dimensionScore((choice) => choice.clarity);
    final empathy = _dimensionScore((choice) => choice.empathy);
    final courage = _dimensionScore((choice) => choice.courage);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const BrandMark(),
        actions: [
          TextButton(
            key: const Key('finish_practice'),
            onPressed: () => _finish(context),
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
            const SizedBox(height: 18),
            _ScoreRing(score: _score),
            const SizedBox(height: 20),
            Text(
              _headline,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 9),
            Text(
              _summary,
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
                    _SkillBar(
                      label: 'Clarity',
                      value: clarity,
                      color: AppColors.coral,
                    ),
                    const SizedBox(height: 17),
                    _SkillBar(
                      label: 'Empathy',
                      value: empathy,
                      color: AppColors.forest,
                    ),
                    const SizedBox(height: 17),
                    _SkillBar(
                      label: 'Courage',
                      value: courage,
                      color: const Color(0xFF7660A8),
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
                  ? scenario.watchFor
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
                    onPressed: () => _retry(context),
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Try again'),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _finish(context),
                    child: const Text('Choose another'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Practice complete · ${scenario.durationMinutes} min',
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

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 142,
        height: 142,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 11,
                strokeCap: StrokeCap.round,
                color: AppColors.coral,
                backgroundColor: AppColors.border,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$score',
                  key: const Key('final_score'),
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 46,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'CONVERSATION SCORE',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillBar extends StatelessWidget {
  const _SkillBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 8,
            color: color,
            backgroundColor: AppColors.border,
          ),
        ),
      ],
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

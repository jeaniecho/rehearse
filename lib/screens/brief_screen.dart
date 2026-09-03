import 'package:flutter/material.dart';

import '../models/scenario.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import 'practice_screen.dart';

class BriefScreen extends StatelessWidget {
  const BriefScreen({required this.scenario, super.key});

  final Scenario scenario;

  void _begin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PracticeScreen(scenario: scenario),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Scenario briefing',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: PageBody(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: ListView(
          children: [
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                MetaPill(
                  icon: Icons.bolt_rounded,
                  label: scenario.skill,
                  backgroundColor: scenario.tint,
                  color: AppColors.ink,
                ),
                MetaPill(
                  icon: Icons.timer_outlined,
                  label: '${scenario.durationMinutes} minutes',
                ),
                MetaPill(
                  icon: Icons.signal_cellular_alt_rounded,
                  label: scenario.difficulty.label,
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              scenario.title,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 10),
            Text(
              scenario.subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 26),
            _PersonCard(scenario: scenario),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR BRIEF',
                      style: TextStyle(
                        color: AppColors.coral,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _BriefItem(
                      icon: Icons.notes_rounded,
                      label: 'What’s happening',
                      text: scenario.context,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Divider(color: AppColors.border, height: 1),
                    ),
                    _BriefItem(
                      icon: Icons.flag_outlined,
                      label: 'Your goal',
                      text: scenario.goal,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Divider(color: AppColors.border, height: 1),
                    ),
                    _BriefItem(
                      icon: Icons.visibility_outlined,
                      label: 'Watch for',
                      text: scenario.watchFor,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.psychology_alt_outlined,
                    color: AppColors.forest,
                    size: 22,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'There is no perfect script. Choose what you would genuinely say—your coach will unpack the tradeoffs.',
                      style: TextStyle(
                        color: AppColors.forest,
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('begin_simulation'),
              onPressed: () => _begin(context),
              icon: const Icon(Icons.mic_none_rounded),
              label: const Text('Enter the conversation'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.scenario});

  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scenario.tint,
              shape: BoxShape.circle,
            ),
            child: Text(
              scenario.personInitials,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOU’RE MEETING WITH',
                  style: TextStyle(
                    color: Color(0xFFAEC5B7),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  scenario.personName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  scenario.personRole,
                  style: const TextStyle(
                    color: Color(0xFFD9E5DD),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.record_voice_over_outlined,
            color: Color(0xFFAEC5B7),
          ),
        ],
      ),
    );
  }
}

class _BriefItem extends StatelessWidget {
  const _BriefItem({
    required this.icon,
    required this.label,
    required this.text,
  });

  final IconData icon;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 19, color: AppColors.forest),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 5),
              Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

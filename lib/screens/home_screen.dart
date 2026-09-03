import 'package:flutter/material.dart';

import '../data/scenarios.dart';
import '../models/scenario.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import 'brief_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openScenario(BuildContext context, Scenario scenario) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => BriefScreen(scenario: scenario)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageBody(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: ListView(
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const BrandMark(),
                const Spacer(),
                IconButton.filledTonal(
                  tooltip: 'Profile',
                  onPressed: () {},
                  icon: const Icon(Icons.person_outline_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _HeroCard(onStart: () => _openScenario(context, scenarios.first)),
            const SizedBox(height: 14),
            const _MomentumCard(),
            const SizedBox(height: 28),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose your practice',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Short scenarios. Real leadership muscles.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${scenarios.length} scenarios',
                  style: const TextStyle(
                    color: AppColors.forest,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final scenario in scenarios) ...[
              _ScenarioCard(
                scenario: scenario,
                recommended: scenario == scenarios.first,
                onTap: () => _openScenario(context, scenario),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Built for conversations that matter.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -42,
            top: -52,
            child: _DecorativeCircle(size: 170, color: Color(0xFF2C684F)),
          ),
          const Positioned(
            right: 36,
            bottom: -62,
            child: _DecorativeCircle(size: 128, color: Color(0xFFE86D4A)),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'YOUR PRIVATE PRACTICE ROOM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Say the hard thing.\nBetter.',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 36,
                    height: 1.03,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 390),
                  child: const Text(
                    'Practice high-stakes conversations, learn from each choice, and walk in ready.',
                    style: TextStyle(
                      color: Color(0xFFD9E5DD),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const Key('start_recommended'),
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start today’s practice'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.forest,
                    minimumSize: const Size(220, 50),
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

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _MomentumCard extends StatelessWidget {
  const _MomentumCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Expanded(
            child: _ProofPoint(
              icon: Icons.timer_outlined,
              title: '4 min',
              label: 'per practice',
            ),
          ),
          _ProofDivider(),
          Expanded(
            child: _ProofPoint(
              icon: Icons.forum_outlined,
              title: '3 turns',
              label: 'real dialogue',
            ),
          ),
          _ProofDivider(),
          Expanded(
            child: _ProofPoint(
              icon: Icons.lock_outline_rounded,
              title: 'Private',
              label: 'practice room',
            ),
          ),
        ],
      ),
    );
  }
}

class _ProofPoint extends StatelessWidget {
  const _ProofPoint({
    required this.icon,
    required this.title,
    required this.label,
  });

  final IconData icon;
  final String title;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: AppColors.coral),
        const SizedBox(height: 5),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, fontSize: 9),
        ),
      ],
    );
  }
}

class _ProofDivider extends StatelessWidget {
  const _ProofDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 36,
      child: VerticalDivider(color: AppColors.border, width: 1),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.scenario,
    required this.recommended,
    required this.onTap,
  });

  final Scenario scenario;
  final bool recommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        key: Key('scenario_${scenario.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scenario.tint,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(scenario.icon, color: AppColors.ink, size: 25),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (recommended) ...[
                      const Text(
                        'RECOMMENDED',
                        style: TextStyle(
                          color: AppColors.coral,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.9,
                        ),
                      ),
                      const SizedBox(height: 5),
                    ],
                    Text(
                      scenario.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      scenario.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 13),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        MetaPill(
                          icon: Icons.bolt_rounded,
                          label: scenario.skill,
                        ),
                        MetaPill(
                          icon: Icons.timer_outlined,
                          label: '${scenario.durationMinutes} min',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 14),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.muted,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

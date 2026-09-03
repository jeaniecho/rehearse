import 'package:flutter/material.dart';

import '../models/practice_response.dart';
import '../models/scenario.dart';
import '../services/analytics.dart';
import '../widgets/app_settings_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/analytics_scope.dart';
import '../widgets/app_shell.dart';
import '../widgets/subscription_scope.dart';
import 'paywall_screen.dart';
import 'practice_screen.dart';

class BriefScreen extends StatefulWidget {
  const BriefScreen({required this.scenario, super.key});

  final Scenario scenario;

  @override
  State<BriefScreen> createState() => _BriefScreenState();
}

class _BriefScreenState extends State<BriefScreen> {
  PracticeMode _mode = PracticeMode.freestyle;

  Scenario get scenario => widget.scenario;
  bool _viewReported = false;

  /// Falls back to the PRD's realistic middle when nothing is remembered.
  SimulationDifficulty get _difficulty =>
      AppSettingsScope.maybeOf(context)?.difficulty ??
      SimulationDifficulty.defensive;

  void _setDifficulty(SimulationDifficulty value) {
    if (value == _difficulty) return;
    AppSettingsScope.maybeOf(context)?.setDifficulty(value);
    AnalyticsScope.maybeOf(
      context,
    )?.difficultySelected(scenario, difficulty: value);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewReported) return;
    _viewReported = true;
    AnalyticsScope.maybeOf(context)?.scenarioViewed(scenario);
  }

  /// Browsing and reading a briefing is always free; the gate is at the
  /// moment of starting, so nobody hits a paywall before they understand
  /// what they would be practicing (PRD §14).
  Future<void> _begin(BuildContext context) async {
    final subscription = SubscriptionScope.maybeOf(context);
    final analytics = AnalyticsScope.maybeOf(context);

    if (subscription != null && subscription.isPaywalled) {
      final unlocked = await PaywallScreen.show(
        context,
        trigger: PaywallTrigger.sessionLimit,
      );
      if (!unlocked || !context.mounted) return;
    }

    if (!context.mounted) return;
    analytics?.scenarioStarted(scenario, mode: _mode, difficulty: _difficulty);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PracticeScreen(
          scenario: scenario,
          mode: _mode,
          difficulty: _difficulty,
        ),
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
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        safeTop: false,
        safeBottom: false,
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
                  label: scenario.stakes.label,
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
            Text(
              'How do you want to practice?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 5),
            const Text(
              'You can switch styles each time you rehearse.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            _ModeOption(
              key: const Key('mode_freestyle'),
              icon: Icons.mic_rounded,
              title: 'Speak freely',
              description:
                  'Say or type what you would really say and get personal feedback.',
              badge: 'RECOMMENDED',
              selected: _mode == PracticeMode.freestyle,
              onTap: () => setState(() => _mode = PracticeMode.freestyle),
            ),
            const SizedBox(height: 9),
            _ModeOption(
              key: const Key('mode_guided'),
              icon: Icons.format_list_bulleted_rounded,
              title: 'Guided choices',
              description: 'Choose between examples and learn the tradeoffs.',
              selected: _mode == PracticeMode.guided,
              onTap: () => setState(() => _mode = PracticeMode.guided),
            ),
            // Only free-form has a model playing the other person, so only
            // free-form can honour this. Offering it in guided mode would be
            // exactly the cosmetic control PRD §7.2 warns against.
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              alignment: Alignment.topCenter,
              child: _mode == PracticeMode.freestyle
                  ? Padding(
                      padding: const EdgeInsets.only(top: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How hard should ${scenario.personName.split(' ').first} push back?',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'This changes how they answer, not how you are scored.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _DifficultyPicker(
                            selected: _difficulty,
                            onChanged: _setDifficulty,
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
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
            const SizedBox(height: 8),
          ],
        ),
      ),
      bottomNavigationBar: PageActionBar(
        child: FilledButton.icon(
          key: const Key('begin_simulation'),
          onPressed: () => _begin(context),
          icon: Icon(
            _mode == PracticeMode.freestyle
                ? Icons.mic_rounded
                : Icons.play_arrow_rounded,
          ),
          label: Text(
            _mode == PracticeMode.freestyle
                ? 'Start speaking practice'
                : 'Start guided practice',
          ),
        ),
      ),
    );
  }
}

/// Three levels as one compact row — the choice matters, but it should not
/// take as much room as the briefing it sits under.
class _DifficultyPicker extends StatelessWidget {
  const _DifficultyPicker({required this.selected, required this.onChanged});

  final SimulationDifficulty selected;
  final ValueChanged<SimulationDifficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final level in SimulationDifficulty.values) ...[
              if (level != SimulationDifficulty.values.first)
                const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  selected: level == selected,
                  button: true,
                  child: Material(
                    color: level == selected
                        ? AppColors.forest
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      key: Key('difficulty_${level.name}'),
                      onTap: () => onChanged(level),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: level == selected
                                ? AppColors.forest
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          level.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(
                            color: level == selected
                                ? Colors.white
                                : AppColors.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Text(
          selected.description,
          key: const Key('difficulty_description'),
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
    super.key,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.mint : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(19),
        side: BorderSide(
          color: selected ? AppColors.forest : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected ? AppColors.forest : AppColors.canvas,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: selected ? Colors.white : AppColors.ink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            badge!,
                            style: const TextStyle(
                              color: AppColors.coral,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AppColors.forest : AppColors.muted,
              ),
            ],
          ),
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

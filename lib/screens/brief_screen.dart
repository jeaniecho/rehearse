import 'package:flutter/material.dart';

import '../models/practice_response.dart';
import '../models/scenario.dart';
import '../services/analytics.dart';
import '../widgets/app_settings_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/analytics_scope.dart';
import '../widgets/app_shell.dart';
import '../widgets/difficulty_picker.dart';
import '../widgets/eyebrow.dart';
import '../widgets/illustration.dart';
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

    if (subscription != null && subscription.isLocked(scenario)) {
      final unlocked = await PaywallScreen.show(
        context,
        trigger: PaywallTrigger.lockedScenario,
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
    final isLocked =
        SubscriptionScope.maybeOf(context)?.isLocked(scenario) ?? false;

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
      body: PageWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            const SizedBox(height: 12),
            // The same mark the home row carried, so arriving here reads as
            // opening the thing you tapped rather than as a new screen.
            Align(
              alignment: Alignment.centerLeft,
              child: Illustration.scenario(scenario.id),
            ),
            const SizedBox(height: 18),
            Eyebrow(
              '${scenario.skill.toUpperCase()}  ·  ${scenario.durationMinutes} MIN  ·  ${scenario.stakes.label.toUpperCase()}',
            ),
            const SizedBox(height: 14),
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
            const SizedBox(height: 20),
            _PersonCard(scenario: scenario),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  left: BorderSide(color: AppColors.coralBright, width: 4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow.small('YOUR GOAL'),
                  const SizedBox(height: 5),
                  Text(
                    scenario.goal,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Practice setup',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 5),
            const Text(
              'Choose how you want this rehearsal to feel.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ModeOption(
                    key: const Key('mode_freestyle'),
                    icon: Icons.mic_rounded,
                    title: 'Speak freely',
                    description: 'Use your own words',
                    badge: 'Recommended',
                    selected: _mode == PracticeMode.freestyle,
                    onTap: () => setState(() => _mode = PracticeMode.freestyle),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _ModeOption(
                    key: const Key('mode_guided'),
                    icon: Icons.format_list_bulleted_rounded,
                    title: 'Guided',
                    description: 'Compare responses',
                    selected: _mode == PracticeMode.guided,
                    onTap: () => setState(() => _mode = PracticeMode.guided),
                  ),
                ),
              ],
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
                            'Pushback level',
                            style: Theme.of(context).textTheme.titleMedium,
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
                          DifficultyPicker(
                            selected: _difficulty,
                            onChanged: _setDifficulty,
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            const SizedBox(height: 14),
            Card(
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                leading: const Icon(
                  Icons.description_outlined,
                  color: AppColors.forest,
                ),
                title: const Text(
                  'Read the full brief',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                subtitle: const Text('Situation and coaching cue'),
                children: [
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 10),
                  _BriefItem(
                    icon: Icons.notes_rounded,
                    label: 'What’s happening',
                    text: scenario.context,
                  ),
                  const SizedBox(height: 16),
                  _BriefItem(
                    icon: Icons.visibility_outlined,
                    label: 'Watch for',
                    text: scenario.watchFor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      bottomNavigationBar: PageActionBar(
        // The button says where the tap leads. Reading the brief stays free
        // either way, so someone who opens a locked conversation still gets
        // the whole situation before the price comes up — but they are not
        // told "start" and then shown a paywall.
        child: isLocked
            ? FilledButton.icon(
                key: const Key('begin_simulation'),
                onPressed: () => _begin(context),
                icon: const Icon(Icons.lock_open_rounded),
                label: const Text('Unlock with Pro'),
              )
            : FilledButton.icon(
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
    return Semantics(
      button: true,
      selected: selected,
      label: [title, description, ?badge].join('. '),
      child: Material(
        color: selected ? AppColors.mint : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? AppColors.forest : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? AppColors.forest : AppColors.muted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_rounded,
                    size: 17,
                    color: AppColors.forest,
                  ),
              ],
            ),
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              // Was `scenario.tint`, a per-scenario field that all twelve
              // filled in with this same value.
              color: AppColors.subtle,
              shape: BoxShape.circle,
            ),
            child: Text(
              scenario.personInitials,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow.small(
                  'REHEARSING WITH',
                  color: AppColors.onForestMuted,
                ),
                const SizedBox(height: 3),
                Text(
                  scenario.personName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
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
            color: AppColors.onForestMuted,
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
            color: AppColors.surface,
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

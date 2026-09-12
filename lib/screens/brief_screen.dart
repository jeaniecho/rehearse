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
        // No title. A toolbar labelled "Scenario briefing" over a page
        // whose own heading is the scenario was a category name in the one
        // place the app has room to say the actual thing — and a bar with a
        // grey label and a back arrow is the most generic object a screen
        // can open with. The mark and the title carry it.
      ),
      body: PageWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            const SizedBox(height: 8),
            // The same mark the home tile carried, so arriving here reads as
            // opening the thing you tapped rather than as a new screen — at
            // the size that screen gives it, not at 40. This is the page
            // about this conversation; it had the smallest drawing of it
            // anywhere in the app.
            Align(
              alignment: Alignment.centerLeft,
              child: Illustration.scenario(
                scenario.id,
                size: Illustration.spotSize,
              ),
            ),
            const SizedBox(height: 16),
            Eyebrow(
              '${scenario.skill.toUpperCase()}  ·  ${scenario.durationMinutes} MIN  ·  ${scenario.stakes.label.toUpperCase()}',
            ),
            const SizedBox(height: 12),
            Text(
              scenario.title,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              scenario.subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            _PersonCard(scenario: scenario),
            const SizedBox(height: 12),
            // Shown, not folded into a disclosure the reader has to ask for.
            // It was a `Card` wrapping an `ExpansionTile` — a stock
            // component with a leading glyph, a subtitle and a chevron,
            // which is what made this screen read as somebody else's design
            // system — and what it was hiding is the briefing itself, on the
            // screen whose whole job is to deliver it.
            //
            // Two sheets in the app's own note language: the situation on
            // white, what to watch for on peach, which is the tint the
            // coaching report already uses for the thing to be careful
            // about.
            _BriefNote(
              icon: Icons.notes_rounded,
              eyebrow: 'WHAT’S HAPPENING',
              text: scenario.context,
              background: AppColors.surface,
              accent: AppColors.muted,
              bordered: true,
            ),
            const SizedBox(height: 10),
            _BriefNote(
              icon: Icons.visibility_outlined,
              eyebrow: 'WATCH FOR',
              text: scenario.watchFor,
              background: AppColors.peach,
              accent: AppColors.coral,
            ),
            const SizedBox(height: 28),
            const Eyebrow('PRACTICE SETUP', color: AppColors.muted),
            const SizedBox(height: 10),
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
                      padding: const EdgeInsets.only(top: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Eyebrow(
                            'PUSHBACK LEVEL',
                            color: AppColors.muted,
                          ),
                          const SizedBox(height: 6),
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
            padding: const EdgeInsets.fromLTRB(13, 12, 12, 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: selected ? AppColors.forest : AppColors.muted,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: selected ? AppColors.forest : AppColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
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

/// Who you are about to talk to, and what you want out of it.
///
/// The goal used to sit under this in a white box with a coral rule down its
/// left edge and a small-caps label — which is the callout every
/// documentation template ships with, and the app draws nothing else that
/// way. It is one object now: the person, a hairline, the goal. A briefing
/// is those two facts, and they belong on the same piece of paper.
class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.scenario});

  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 16),
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          const SizedBox(height: 15),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.16)),
          const SizedBox(height: 14),
          const Eyebrow.small('YOUR GOAL', color: AppColors.onForestMuted),
          const SizedBox(height: 6),
          Text(
            scenario.goal,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// One block of the briefing, in the note language the coaching report
/// already speaks: a tinted sheet, a small-caps label, and the text.
///
/// It replaces a row of Material glyph-in-a-rounded-square + label + body,
/// which is a list item from a component library rather than anything this
/// app draws.
class _BriefNote extends StatelessWidget {
  const _BriefNote({
    required this.icon,
    required this.eyebrow,
    required this.text,
    required this.background,
    required this.accent,
    this.bordered = false,
  });

  final IconData icon;
  final String eyebrow;
  final String text;
  final Color background;
  final Color accent;

  /// White needs an edge against the page; a tint does not.
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 15),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: bordered ? Border.all(color: AppColors.border) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The glyph rides with the label rather than in a rounded square
          // of its own, which is what the old brief rows had — an icon tile
          // beside every paragraph is a list item from a component library.
          Row(
            children: [
              Icon(icon, size: 13, color: accent),
              const SizedBox(width: 6),
              Eyebrow.small(eyebrow, color: accent),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

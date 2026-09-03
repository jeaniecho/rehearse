import 'package:flutter/material.dart';

import '../models/practice_summary.dart';
import '../models/subscription.dart';
import '../services/analytics.dart';
import '../theme/app_theme.dart';
import '../widgets/analytics_scope.dart';
import '../widgets/app_shell.dart';
import '../widgets/practice_history_scope.dart';
import '../widgets/subscription_scope.dart';

/// The Pro upgrade.
///
/// Deliberately contextual (PRD §14): it appears only once someone has
/// finished their free rehearsals, and it opens by naming the pattern their
/// own history shows rather than a generic pitch.
///
/// Plans and prices come from the RevenueCat offering, never from code, so
/// packaging can be changed and experimented on from the dashboard.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({required this.trigger, super.key});

  /// How this person got here, so a forced paywall and a voluntary one can
  /// be told apart in the funnel.
  final PaywallTrigger trigger;

  /// Shows the paywall as a full-screen page. Resolves true if the person
  /// came away with Pro.
  static Future<bool> show(
    BuildContext context, {
    required PaywallTrigger trigger,
  }) async {
    final unlocked = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (_) => PaywallScreen(trigger: trigger),
      ),
    );
    return unlocked ?? false;
  }

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  String? _selectedPlanId;
  String? _notice;
  bool _viewReported = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewReported) return;
    _viewReported = true;

    final offer = SubscriptionScope.of(context).offer;
    AnalyticsScope.maybeOf(context)?.paywallViewed(
      trigger: widget.trigger,
      offeringId: offer?.id,
      planCount: offer?.plans.length ?? 0,
    );
  }

  void _dismiss() {
    AnalyticsScope.maybeOf(context)?.paywallDismissed(
      trigger: widget.trigger,
      offeringId: SubscriptionScope.of(context).offer?.id,
    );
    Navigator.of(context).pop(false);
  }

  SubscriptionPlan? _planFor(SubscriptionOffer offer) {
    for (final plan in offer.plans) {
      if (plan.id == _selectedPlanId) return plan;
    }
    return offer.recommended;
  }

  Future<void> _buy(SubscriptionPlan plan) async {
    final offeringId = SubscriptionScope.of(context).offer?.id;
    final outcome = await SubscriptionScope.of(context).purchase(plan);
    if (!mounted) return;

    if (outcome == PurchaseOutcome.purchased) {
      AnalyticsScope.maybeOf(context)?.purchaseCompleted(
        packageId: plan.id,
        offeringId: offeringId,
        startedTrial: plan.hasTrial,
      );
    }
    _settle(outcome);
  }

  Future<void> _restore() async {
    final outcome = await SubscriptionScope.of(context).restore();
    if (!mounted) return;

    AnalyticsScope.maybeOf(context)?.restoreCompleted(
      restored: outcome.unlocksPro,
      from: RestoreSource.paywall,
    );
    _settle(outcome);
  }

  void _settle(PurchaseOutcome outcome) {
    if (outcome.unlocksPro) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _notice = outcome.message);
  }

  @override
  Widget build(BuildContext context) {
    final subscription = SubscriptionScope.of(context);
    final offer = subscription.offer;
    final weakest = PracticeHistoryScope.maybeOf(context)?.weakestSkill;
    final hasPlans = offer != null && !offer.isEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('close_paywall'),
          tooltip: 'Close',
          onPressed: subscription.isBusy ? null : _dismiss,
          icon: const Icon(Icons.close_rounded),
        ),
        actions: [
          TextButton(
            key: const Key('restore_purchases'),
            onPressed: subscription.isBusy ? null : _restore,
            child: const Text('Restore'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: PageWidth(
        child: ListView(
          // The action bar carries the bottom inset, but it is only built
          // when there is a plan to buy — so without one the list takes it.
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            hasPlans ? 24 : MediaQuery.paddingOf(context).bottom + 24,
          ),
          children: [
            const SizedBox(height: 4),
            _Header(offer: offer, weakest: weakest),
            const SizedBox(height: 20),
            const _ValueList(),
            const SizedBox(height: 20),
            if (!hasPlans)
              _Unavailable(
                onRetry: subscription.isBusy ? null : subscription.refreshOffer,
              )
            else
              for (final plan in offer.plans) ...[
                _PlanCard(
                  plan: plan,
                  selected: plan.id == _planFor(offer)?.id,
                  onTap: () => setState(() => _selectedPlanId = plan.id),
                ),
                const SizedBox(height: 10),
              ],
            if (_notice case final notice?) ...[
              const SizedBox(height: 6),
              _Notice(text: notice),
            ],
            const SizedBox(height: 14),
            Text(
              'Billed through your app store account. Cancel any time in your '
              'store settings. Your practice history stays on this device '
              'either way.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
      bottomNavigationBar: !hasPlans
          ? null
          : PageActionBar(
              child: FilledButton(
                key: const Key('start_subscription'),
                onPressed: subscription.isBusy
                    ? null
                    : () {
                        final plan = _planFor(offer);
                        if (plan == null) return;
                        _buy(plan);
                      },
                child: subscription.isBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_ctaLabel(offer, _planFor(offer))),
              ),
            ),
    );
  }

  static String _ctaLabel(SubscriptionOffer offer, SubscriptionPlan? plan) {
    if (offer.callToAction case final remote?) return remote;
    if (plan?.hasTrial ?? false) return 'Start my free trial';
    return 'Unlock unlimited practice';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.offer, required this.weakest});

  final SubscriptionOffer? offer;
  final PracticeSkill? weakest;

  @override
  Widget build(BuildContext context) {
    // Dashboard copy wins, then the pattern this person's own rehearsals
    // show, then a generic line.
    final subhead =
        offer?.subhead ??
        weakest?.weaknessDescription ??
        'You have used your free rehearsals. Keep practicing the '
            'conversations you would rather not have.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'REHEARSE PRO',
          style: TextStyle(
            color: AppColors.coral,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          offer?.headline ?? 'Keep going.',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 10),
        Text(
          subhead,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

class _ValueList extends StatelessWidget {
  const _ValueList();

  static const _items = <(IconData, String, String)>[
    (
      Icons.all_inclusive_rounded,
      'Unlimited rehearsals',
      'Practice the same conversation until the wording is yours.',
    ),
    (
      Icons.forum_outlined,
      'Every scenario',
      'The full library, including the high-stakes ones.',
    ),
    (
      Icons.insights_rounded,
      'Your full history',
      'Every score and skill trend, kept on your device.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          children: [
            for (var index = 0; index < _items.length; index++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _items[index].$1,
                      color: AppColors.forest,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _items[index].$2,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _items[index].$3,
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
              if (index != _items.length - 1) const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final SubscriptionPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.mint : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: Key('plan_${plan.id}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.forest : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? AppColors.forest : AppColors.muted,
                  size: 21,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.period.label,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (plan.trialLabel case final trial?) ...[
                        const SizedBox(height: 2),
                        Text(
                          '$trial, then ${plan.priceLabel}',
                          style: const TextStyle(
                            color: AppColors.forest,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ] else if (plan.perMonthLabel case final perMonth?) ...[
                        const SizedBox(height: 2),
                        Text(
                          '$perMonth per month',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  plan.priceLabel,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('offer_unavailable'),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.muted, size: 26),
          const SizedBox(height: 12),
          const Text(
            'Plans aren’t loading right now',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'The store didn’t answer. Nothing has been charged, and you can '
            'try again in a moment.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            key: const Key('retry_offer'),
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('paywall_notice'),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.peach,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.ink,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../data/legal_links.dart';
import '../data/scenarios.dart';
import '../models/practice_summary.dart';
import '../models/subscription.dart';
import '../services/analytics.dart';
import '../services/link_service.dart';
import '../services/subscription.dart';
import '../theme/app_theme.dart';
import '../widgets/analytics_scope.dart';
import '../widgets/app_shell.dart';
import '../widgets/eyebrow.dart';
import '../widgets/illustration.dart';
import '../widgets/practice_history_scope.dart';
import '../widgets/subscription_scope.dart';

/// The Pro upgrade.
///
/// Deliberately contextual (PRD §14): it appears when someone tries to start
/// a conversation the free tier does not include, and it opens by naming the
/// pattern their own history shows rather than a generic pitch.
///
/// Plans and prices come from the RevenueCat offering, never from code, so
/// packaging can be changed and experimented on from the dashboard.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({
    required this.trigger,
    this.links = const DeviceLinkService(),
    super.key,
  });

  /// How this person got here, so a forced paywall and a voluntary one can
  /// be told apart in the funnel.
  final PaywallTrigger trigger;

  /// Opens the published terms and privacy policy.
  final LinkService links;

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

  /// A link that will not open is the person's problem to work around, so
  /// say so rather than leaving a dead tap.
  void _reportLinkFailure() {
    if (!mounted) return;
    setState(
      () => _notice = 'Could not open that page. It is also at jeanie.dev.',
    );
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
            const _Comparison(),
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
            const SizedBox(height: 6),
            // Apple 3.1.2 wants both reachable from the point of purchase for
            // an auto-renewing subscription, so they sit with the price
            // rather than only in the You tab.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegalLink(
                  key: const Key('paywall_terms'),
                  label: 'Terms of Use',
                  url: LegalLinks.terms,
                  onFailed: _reportLinkFailure,
                  links: widget.links,
                ),
                Text(
                  ' · ',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontSize: 11),
                ),
                _LegalLink(
                  key: const Key('paywall_privacy'),
                  label: 'Privacy Policy',
                  url: LegalLinks.privacy,
                  onFailed: _reportLinkFailure,
                  links: widget.links,
                ),
              ],
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
    // Not "unlimited practice" — the free tier already has that, within its
    // two conversations. What Pro sells is the rest of the library.
    return 'Unlock every conversation';
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
        'Open the whole library, and keep practicing the conversations '
            'you would rather not have.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Illustration.proUnlock(),
        const SizedBox(height: 18),
        const Eyebrow('REHEARSE PRO'),
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

/// Free against Pro, side by side.
///
/// Every row here is checked against `Subscription.isLocked`, which is the
/// only gate the app actually has: Pro opens the rest of the library and
/// changes nothing else. Rehearsals, coaching and history are not gated —
/// the free tier repeats its two conversations without limit — so they are
/// ticked in both columns rather than crossed out of the free one.
///
/// That makes for a table with one differing row, which is the honest
/// shape of this product. A cross against something the free tier really
/// does have would be a false claim in a subscription disclosure, and
/// CLAUDE.md's rule about not promising what the app does not do cuts both
/// ways — overselling Pro is the same fault as underselling it.
class _Comparison extends StatelessWidget {
  const _Comparison();

  static const _freeColumn = 66.0;
  static const _proColumn = 84.0;

  /// A null value means "included", drawn as a tick.
  static final _rows = <(String, String?, String?)>[
    (
      'Conversations',
      '${Subscription.freeScenarioIds.length}',
      'All ${scenarios.length}',
    ),
    ('Unlimited rehearsals', null, null),
    ('Coaching on what you actually said', null, null),
    ('Scores, streak and history', null, null),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Stack(
          children: [
            // Behind the Pro column, so it reads as the one being offered
            // without needing a heavier treatment on every cell.
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: _proColumn,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            Column(
              children: [
                const _ComparisonRow(
                  label: '',
                  free: 'Free',
                  pro: 'Pro',
                  isHeader: true,
                ),
                for (final (label, free, pro) in _rows) ...[
                  const Divider(color: AppColors.border, height: 1),
                  _ComparisonRow(label: label, free: free, pro: pro),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.free,
    required this.pro,
    this.isHeader = false,
  });

  final String label;
  final String? free;
  final String? pro;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                height: 1.3,
                fontWeight: isHeader ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: _Comparison._freeColumn,
            child: _cell(free, isHeader: isHeader),
          ),
          SizedBox(
            width: _Comparison._proColumn,
            child: _cell(pro, isHeader: isHeader, emphasis: true),
          ),
        ],
      ),
    );
  }

  Widget _cell(String? value, {required bool isHeader, bool emphasis = false}) {
    if (value == null) {
      return Icon(
        Icons.check_rounded,
        size: 19,
        color: emphasis ? AppColors.forest : AppColors.muted,
      );
    }
    return Text(
      value,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: emphasis ? AppColors.forest : AppColors.muted,
        fontSize: isHeader ? 12 : 13,
        fontWeight: isHeader ? FontWeight.w800 : FontWeight.w700,
        letterSpacing: isHeader ? 0.6 : 0,
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

/// One of the two documents the store requires beside the price.
class _LegalLink extends StatelessWidget {
  const _LegalLink({
    required this.label,
    required this.url,
    required this.onFailed,
    required this.links,
    super.key,
  });

  final String label;
  final Uri url;
  final VoidCallback onFailed;
  final LinkService links;

  @override
  Widget build(BuildContext context) {
    // 11pt type is a 14pt tap target. Padded out to 44 so a finger — and a
    // reviewer checking the links work — can actually hit it.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        if (!await links.open(url)) onFailed();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 11,
            color: AppColors.forest,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.forest,
          ),
        ),
      ),
    );
  }
}

/// Plain types describing what is for sale, so nothing above the
/// subscription client has to import the RevenueCat SDK.
library;

enum SubscriptionPeriod {
  weekly,
  monthly,
  twoMonth,
  threeMonth,
  sixMonth,
  annual,
  lifetime,
  unknown,
}

extension SubscriptionPeriodLabel on SubscriptionPeriod {
  String get label => switch (this) {
    SubscriptionPeriod.weekly => 'Weekly',
    SubscriptionPeriod.monthly => 'Monthly',
    SubscriptionPeriod.twoMonth => 'Every 2 months',
    SubscriptionPeriod.threeMonth => 'Quarterly',
    SubscriptionPeriod.sixMonth => 'Every 6 months',
    SubscriptionPeriod.annual => 'Annual',
    SubscriptionPeriod.lifetime => 'Lifetime',
    SubscriptionPeriod.unknown => 'Subscription',
  };
}

/// One purchasable package, with the store's own localized price strings.
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.period,
    required this.priceLabel,
    this.perMonthLabel,
    this.trialLabel,
  });

  /// The RevenueCat package identifier — what [SubscriptionClient.purchase]
  /// is called with.
  final String id;
  final SubscriptionPeriod period;

  /// Already localized and currency-formatted by the store. Never build a
  /// price string by hand.
  final String priceLabel;
  final String? perMonthLabel;
  final String? trialLabel;

  bool get hasTrial => trialLabel != null;
}

/// A RevenueCat offering: the plans plus any copy the dashboard supplies.
///
/// Copy lives in offering metadata so paywall wording can be changed, and
/// A/B tested, without shipping a build.
class SubscriptionOffer {
  const SubscriptionOffer({
    required this.id,
    required this.plans,
    this.headline,
    this.subhead,
    this.callToAction,
  });

  final String id;
  final List<SubscriptionPlan> plans;
  final String? headline;
  final String? subhead;
  final String? callToAction;

  bool get isEmpty => plans.isEmpty;

  /// The plan to preselect: the best annual-or-longer option if there is
  /// one, otherwise the first.
  SubscriptionPlan? get recommended {
    if (plans.isEmpty) return null;
    for (final plan in plans) {
      if (plan.period == SubscriptionPeriod.annual) return plan;
    }
    return plans.first;
  }
}

/// Why a purchase or restore ended. Cancelling is a normal outcome, not an
/// error, and must never be shown as one.
enum PurchaseOutcome {
  purchased,
  restored,
  cancelled,
  pending,
  alreadyOwned,
  nothingToRestore,
  unavailable,
  failed,
}

extension PurchaseOutcomeMessage on PurchaseOutcome {
  /// What to tell the person, or null when the outcome needs no message.
  String? get message => switch (this) {
    PurchaseOutcome.purchased => null,
    PurchaseOutcome.cancelled => null,
    PurchaseOutcome.restored => 'Your subscription is back. Welcome back.',
    PurchaseOutcome.alreadyOwned => 'You already have Pro on this account.',
    PurchaseOutcome.pending =>
      'Your purchase is pending approval. Pro unlocks as soon as it clears.',
    PurchaseOutcome.nothingToRestore =>
      'No previous purchase found on this account.',
    PurchaseOutcome.unavailable =>
      'The store is unavailable right now. Your free practice is unaffected.',
    PurchaseOutcome.failed =>
      'That didn’t go through. You have not been charged.',
  };

  bool get unlocksPro =>
      this == PurchaseOutcome.purchased ||
      this == PurchaseOutcome.restored ||
      this == PurchaseOutcome.alreadyOwned;
}

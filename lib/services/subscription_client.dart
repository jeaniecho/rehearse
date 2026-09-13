import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../models/subscription.dart';

typedef ProStatusCallback = void Function(bool isPro);

/// The store, behind an interface so the rest of the app never imports the
/// RevenueCat SDK and tests never touch a platform channel.
abstract interface class SubscriptionClient {
  /// Returns false when there is no API key for this platform. The app then
  /// runs unlimited and free rather than blocking — see [Subscription].
  Future<bool> configure({required ProStatusCallback onProChanged});

  Future<SubscriptionOffer?> loadOffer();

  Future<PurchaseOutcome> purchase(String planId);

  Future<PurchaseOutcome> restore();
}

/// Reads the platform's public SDK key from `--dart-define`.
///
/// These are publishable client keys, not secrets — but they are still
/// per-environment configuration, so they stay out of the repository the
/// same way `REHEARSE_COACH_URL` does.
abstract final class RevenueCatKeys {
  static const ios = String.fromEnvironment('REHEARSE_REVENUECAT_IOS_KEY');
  static const android = String.fromEnvironment(
    'REHEARSE_REVENUECAT_ANDROID_KEY',
  );

  /// The entitlement that unlocks Pro. Must match the RevenueCat dashboard.
  static const entitlement = 'pro';

  static String? forPlatform([TargetPlatform? platform]) {
    if (kIsWeb) return null;
    final key = switch (platform ?? defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => ios,
      TargetPlatform.android => android,
      _ => '',
    };
    return key.trim().isEmpty ? null : key.trim();
  }
}

class RevenueCatSubscriptionClient implements SubscriptionClient {
  RevenueCatSubscriptionClient({String? apiKey})
    : _apiKey = apiKey ?? RevenueCatKeys.forPlatform();

  final String? _apiKey;
  ProStatusCallback? _onProChanged;
  bool _configured = false;

  @override
  Future<bool> configure({required ProStatusCallback onProChanged}) async {
    _onProChanged = onProChanged;
    final apiKey = _apiKey;
    if (apiKey == null) return false;

    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
      await Purchases.configure(PurchasesConfiguration(apiKey));

      // Renewals, expiries, and purchases made on another device all arrive
      // here, so entitlement state is never only what we saw at startup.
      Purchases.addCustomerInfoUpdateListener((info) {
        _onProChanged?.call(_isPro(info));
      });

      _configured = true;
    } on Object {
      // A misconfigured key must not take the app down with it.
      return false;
    }

    // Asking who this person is, is a different question from whether the
    // store is wired up, and it fails for a different reason: no network.
    //
    // It used to share the block above, so an aeroplane-mode launch returned
    // false and the whole library fell open — a build with a key in it gave
    // everything away to anyone offline. Configuring succeeded; only this
    // call failed.
    //
    // Offline the SDK answers from its own cache, so someone who has been
    // Pro on this device stays Pro. With no cache to answer from there is no
    // evidence of an entitlement, and the honest reading of that is "not
    // Pro" — which shows the free tier, not the whole library. Restore is on
    // the paywall and on You for the case where that is wrong.
    try {
      _onProChanged?.call(_isPro(await Purchases.getCustomerInfo()));
    } on Object {
      _onProChanged?.call(false);
    }
    return true;
  }

  @override
  Future<SubscriptionOffer?> loadOffer() async {
    if (!_configured) return null;
    try {
      final offering = (await Purchases.getOfferings()).current;
      if (offering == null || offering.availablePackages.isEmpty) return null;
      return _toOffer(offering);
    } on Object {
      return null;
    }
  }

  @override
  Future<PurchaseOutcome> purchase(String planId) async {
    if (!_configured) return PurchaseOutcome.unavailable;

    final Package package;
    try {
      final offering = (await Purchases.getOfferings()).current;
      final match = offering?.availablePackages
          .where((item) => item.identifier == planId)
          .firstOrNull;
      if (match == null) return PurchaseOutcome.unavailable;
      package = match;
    } on Object {
      return PurchaseOutcome.unavailable;
    }

    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      final isPro = _isPro(result.customerInfo);
      _onProChanged?.call(isPro);
      return isPro ? PurchaseOutcome.purchased : PurchaseOutcome.pending;
    } on PlatformException catch (error) {
      return _outcomeFor(error);
    } on Object {
      return PurchaseOutcome.failed;
    }
  }

  @override
  Future<PurchaseOutcome> restore() async {
    if (!_configured) return PurchaseOutcome.unavailable;
    try {
      final info = await Purchases.restorePurchases();
      final isPro = _isPro(info);
      _onProChanged?.call(isPro);
      return isPro
          ? PurchaseOutcome.restored
          : PurchaseOutcome.nothingToRestore;
    } on PlatformException catch (error) {
      return _outcomeFor(error);
    } on Object {
      return PurchaseOutcome.failed;
    }
  }

  static bool _isPro(CustomerInfo info) =>
      info.entitlements.active.containsKey(RevenueCatKeys.entitlement);

  static PurchaseOutcome _outcomeFor(PlatformException error) {
    return switch (PurchasesErrorHelper.getErrorCode(error)) {
      PurchasesErrorCode.purchaseCancelledError => PurchaseOutcome.cancelled,
      PurchasesErrorCode.paymentPendingError => PurchaseOutcome.pending,
      PurchasesErrorCode.productAlreadyPurchasedError ||
      PurchasesErrorCode.receiptAlreadyInUseError =>
        PurchaseOutcome.alreadyOwned,
      PurchasesErrorCode.purchaseNotAllowedError ||
      PurchasesErrorCode.productNotAvailableForPurchaseError ||
      PurchasesErrorCode.storeProblemError ||
      PurchasesErrorCode.networkError ||
      PurchasesErrorCode.offlineConnectionError => PurchaseOutcome.unavailable,
      _ => PurchaseOutcome.failed,
    };
  }

  static SubscriptionOffer _toOffer(Offering offering) {
    String? copy(String key) {
      final value = offering.metadata[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    return SubscriptionOffer(
      id: offering.identifier,
      headline: copy('headline'),
      subhead: copy('subhead'),
      callToAction: copy('cta'),
      plans: [
        for (final package in offering.availablePackages) _toPlan(package),
      ],
    );
  }

  static SubscriptionPlan _toPlan(Package package) {
    final product = package.storeProduct;
    final intro = product.introductoryPrice;
    final period = _periodFor(package.packageType);

    return SubscriptionPlan(
      id: package.identifier,
      period: period,
      priceLabel: product.priceString,
      // Only worth showing where it reframes the price, which is the whole
      // point of an annual plan.
      perMonthLabel: period == SubscriptionPeriod.annual
          ? product.pricePerMonthString
          : null,
      trialLabel: intro != null && intro.price == 0
          ? '${intro.periodNumberOfUnits} ${_unitLabel(intro.periodUnit, intro.periodNumberOfUnits)} free'
          : null,
    );
  }

  static SubscriptionPeriod _periodFor(PackageType type) => switch (type) {
    PackageType.weekly => SubscriptionPeriod.weekly,
    PackageType.monthly => SubscriptionPeriod.monthly,
    PackageType.twoMonth => SubscriptionPeriod.twoMonth,
    PackageType.threeMonth => SubscriptionPeriod.threeMonth,
    PackageType.sixMonth => SubscriptionPeriod.sixMonth,
    PackageType.annual => SubscriptionPeriod.annual,
    PackageType.lifetime => SubscriptionPeriod.lifetime,
    _ => SubscriptionPeriod.unknown,
  };

  static String _unitLabel(PeriodUnit unit, int count) {
    final singular = switch (unit) {
      PeriodUnit.day => 'day',
      PeriodUnit.week => 'week',
      PeriodUnit.month => 'month',
      PeriodUnit.year => 'year',
      PeriodUnit.unknown => 'period',
    };
    return count == 1 ? singular : '${singular}s';
  }
}

/// Used when no API key is configured for this platform, including on web.
/// Reports "not pro" and sells nothing, which keeps every gate open.
class UnconfiguredSubscriptionClient implements SubscriptionClient {
  const UnconfiguredSubscriptionClient();

  @override
  Future<bool> configure({required ProStatusCallback onProChanged}) async =>
      false;

  @override
  Future<SubscriptionOffer?> loadOffer() async => null;

  @override
  Future<PurchaseOutcome> purchase(String planId) async =>
      PurchaseOutcome.unavailable;

  @override
  Future<PurchaseOutcome> restore() async => PurchaseOutcome.unavailable;
}

SubscriptionClient createSubscriptionClient() {
  return RevenueCatKeys.forPlatform() == null
      ? const UnconfiguredSubscriptionClient()
      : RevenueCatSubscriptionClient();
}

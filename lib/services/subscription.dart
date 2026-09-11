import 'package:flutter/foundation.dart';

import '../models/scenario.dart';
import '../models/subscription.dart';
import 'subscription_client.dart';

/// Owns the one question the rest of the app asks: may this person rehearse
/// this conversation?
///
/// The answer depends on the store entitlement and on which scenarios the
/// free tier includes, so both live here rather than being stitched together
/// at each call site.
class Subscription extends ChangeNotifier {
  Subscription({SubscriptionClient? client})
    : _client = client ?? createSubscriptionClient();

  /// The conversations a free account can rehearse, without limit.
  ///
  /// PRD §13 lists "all scenarios" among what Pro unlocks; this is that gate.
  /// It replaced a lifetime count of completed rehearsals, and the reason is
  /// worth keeping: a count has to be stored, and anything stored on the
  /// device is back at zero after a reinstall. A content gate holds no state,
  /// so there is nothing to reset.
  ///
  /// Two warm-up scenarios in different registers — handing work over, and
  /// repairing a peer relationship — so the free tier samples the range of
  /// the library rather than one corner of it.
  static const freeScenarioIds = <String>{'delegation', 'peer-conflict'};

  final SubscriptionClient _client;

  bool _isConfigured = false;
  bool _isPro = false;
  bool _isLoaded = false;
  bool _isBusy = false;
  SubscriptionOffer? _offer;

  /// False when no API key is set for this platform, or the store could not
  /// be reached at startup.
  bool get isConfigured => _isConfigured;

  bool get isPro => _isPro;

  bool get isLoaded => _isLoaded;

  /// True while a purchase or restore is in flight.
  bool get isBusy => _isBusy;

  SubscriptionOffer? get offer => _offer;

  /// Whether to draw the free/locked distinction at all — Pro users and
  /// unconfigured builds have nothing to lock.
  bool get showsLocks => _isConfigured && !_isPro;

  /// The gate.
  ///
  /// An unconfigured build never locks anything: a missing key or an
  /// unreachable store must leave the core experience intact (PRD §26), and
  /// the demo has to run without any of this wired up.
  bool isLocked(Scenario scenario) =>
      showsLocks && !freeScenarioIds.contains(scenario.id);

  /// The free tier is unlimited within the scenarios it includes, so this is
  /// only ever false for a locked one.
  bool canPractice(Scenario scenario) => !isLocked(scenario);

  Future<void> load() async {
    _isConfigured = await _client.configure(onProChanged: _handleProChanged);
    _isLoaded = true;
    notifyListeners();

    if (_isConfigured) await refreshOffer();
  }

  Future<void> refreshOffer() async {
    if (!_isConfigured) return;
    final offer = await _client.loadOffer();
    if (offer == _offer) return;
    _offer = offer;
    notifyListeners();
  }

  Future<PurchaseOutcome> purchase(SubscriptionPlan plan) =>
      _run(() => _client.purchase(plan.id));

  Future<PurchaseOutcome> restore() => _run(_client.restore);

  Future<PurchaseOutcome> _run(
    Future<PurchaseOutcome> Function() action,
  ) async {
    if (_isBusy) return PurchaseOutcome.failed;
    _isBusy = true;
    notifyListeners();

    PurchaseOutcome outcome;
    try {
      outcome = await action();
    } on Object {
      outcome = PurchaseOutcome.failed;
    }

    if (outcome.unlocksPro) _isPro = true;
    _isBusy = false;
    notifyListeners();
    return outcome;
  }

  void _handleProChanged(bool isPro) {
    if (_isPro == isPro) return;
    _isPro = isPro;
    notifyListeners();
  }
}

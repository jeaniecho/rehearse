import 'package:flutter/foundation.dart';

import '../models/subscription.dart';
import 'app_settings.dart';
import 'subscription_client.dart';

/// Owns the one question the rest of the app asks: may this person start
/// another rehearsal?
///
/// The answer depends on the store entitlement and on how many free sessions
/// have been used, so both live here rather than being stitched together at
/// each call site.
class Subscription extends ChangeNotifier {
  Subscription({SubscriptionClient? client, SettingsStore? store})
    : _client = client ?? createSubscriptionClient(),
      _store = store ?? const SharedPreferencesSettingsStore();

  /// Completed rehearsals before Pro is required. PRD §13: a lifetime limit
  /// rather than a weekly one, for a simpler funnel.
  static const freeSessionLimit = 3;

  /// Deliberately not the practice-history key. Clearing your history is a
  /// privacy action and must not hand back free sessions.
  static const _usedKey = 'rehearse.free_sessions_used';

  final SubscriptionClient _client;
  final SettingsStore _store;

  bool _isConfigured = false;
  bool _isPro = false;
  bool _isLoaded = false;
  bool _isBusy = false;
  int _freeSessionsUsed = 0;
  SubscriptionOffer? _offer;

  /// False when no API key is set for this platform, or the store could not
  /// be reached at startup.
  bool get isConfigured => _isConfigured;

  bool get isPro => _isPro;

  bool get isLoaded => _isLoaded;

  /// True while a purchase or restore is in flight.
  bool get isBusy => _isBusy;

  SubscriptionOffer? get offer => _offer;

  int get freeSessionsUsed => _freeSessionsUsed;

  int get freeSessionsRemaining =>
      (freeSessionLimit - _freeSessionsUsed).clamp(0, freeSessionLimit);

  /// Whether the free allowance should be shown at all — Pro users and
  /// unconfigured builds have nothing to count.
  bool get showsFreeAllowance => _isConfigured && !_isPro;

  /// The gate.
  ///
  /// An unconfigured build never blocks: a missing key or an unreachable
  /// store must leave the core experience intact (PRD §26), and the demo has
  /// to run without any of this wired up.
  bool get canStartPractice =>
      _isPro || !_isConfigured || freeSessionsRemaining > 0;

  /// True once the allowance is spent and Pro would unlock more.
  bool get isPaywalled => !canStartPractice;

  Future<void> load() async {
    _freeSessionsUsed = await _readUsed();
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

  /// Called when a rehearsal reaches its coaching report. Only completed
  /// sessions count, so abandoning one costs nothing.
  Future<void> recordCompletedSession() async {
    if (_isPro || !_isConfigured) return;
    if (_freeSessionsUsed >= freeSessionLimit) return;

    _freeSessionsUsed += 1;
    notifyListeners();
    await _writeUsed(_freeSessionsUsed);
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

  Future<int> _readUsed() async {
    try {
      final stored = await _store.readInt(_usedKey);
      return (stored ?? 0).clamp(0, freeSessionLimit);
    } on Object {
      return 0;
    }
  }

  Future<void> _writeUsed(int value) async {
    try {
      await _store.writeInt(_usedKey, value);
    } on Object {
      // The count still holds for this session; losing it errs toward
      // giving someone an extra free rehearsal, which is the safe way to
      // be wrong.
    }
  }
}

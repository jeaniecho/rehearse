import 'package:flutter/services.dart';

/// The taps the phone makes back.
///
/// Behind an interface like speech and links, because it is a platform
/// channel — a widget test that reached one would be testing the channel
/// rather than the screen.
abstract interface class HapticsService {
  /// A moment landing: the score arriving on the report.
  ///
  /// One call, because there is one such moment. Selection feedback on the
  /// pickers was considered and left out — it is the kind of thing that
  /// reads as texture on the first tap and as noise on the twentieth.
  void impact();
}

class DeviceHaptics implements HapticsService {
  const DeviceHaptics();

  @override
  void impact() => HapticFeedback.mediumImpact();
}

/// The counterpart, and also what a device with no haptics amounts to.
/// Nothing in the app may depend on the phone having answered.
class SilentHaptics implements HapticsService {
  SilentHaptics();

  final List<String> calls = [];

  @override
  void impact() => calls.add('impact');
}

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a link outside the app.
///
/// Behind an interface for the same reason as speech and crashes: it touches
/// a platform channel, so a widget test needs something to stand in for it.
abstract interface class LinkService {
  /// Returns false when the device could not open [url] — the caller says so
  /// rather than failing silently.
  Future<bool> open(Uri url);
}

class DeviceLinkService implements LinkService {
  const DeviceLinkService();

  @override
  Future<bool> open(Uri url) async {
    try {
      // The store requires these to be reachable, and a legal document
      // belongs in the browser rather than a webview we would have to
      // maintain.
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  }
}

/// Records what it was asked to open, and opens nothing.
@visibleForTesting
class FakeLinkService implements LinkService {
  FakeLinkService({this.succeeds = true});

  final bool succeeds;
  final List<Uri> opened = [];

  @override
  Future<bool> open(Uri url) async {
    opened.add(url);
    return succeeds;
  }
}

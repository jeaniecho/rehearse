/// Where the published legal documents live.
///
/// Apple 3.1.2 requires both to be reachable from the point of purchase for
/// an auto-renewing subscription, so the paywall links them directly.
///
/// The pages are rendered from `docs/PRIVACY.md` and their own source by
/// `react/src/pages/terms/` in the `jeanie-dev` repository. Change these only
/// alongside the routes there.
abstract final class LegalLinks {
  static final privacy = Uri.parse('https://jeanie.dev/rehearse-privacy');
  static final terms = Uri.parse('https://jeanie.dev/rehearse-terms');
}

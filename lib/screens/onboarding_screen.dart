import 'package:flutter/material.dart';

import '../models/practice_summary.dart';
import '../theme/app_theme.dart';
import '../widgets/analytics_scope.dart';
import '../widgets/app_settings_scope.dart';
import '../widgets/app_shell.dart';
import '../widgets/brand_mark.dart';
import '../widgets/score_display.dart';

/// Three screens, then out of the way.
///
/// The headlines are PRD §18 verbatim, and the supporting lines now say the
/// same things its versions do — selectable resistance and a four-dimension
/// score both exist. They are still worded for this app rather than copied,
/// and `test/onboarding_test.dart` asserts the promises and the product move
/// together in both directions.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  bool _startReported = false;

  static const _pages = <_Page>[
    _Page(
      headline: 'Practice the conversation before it matters.',
      body:
          'Short rehearsals of the workplace conversations most people put '
          'off — with someone on the other side who reacts to what you say.',
      art: _ConversationArt(),
    ),
    _Page(
      headline: 'They won’t always agree with you.',
      body:
          'Choose how hard they push back, then live with it. Every reply '
          'follows from your last one, so a vague message makes the next '
          'turn harder, exactly like it does in the room.',
      art: _PushbackArt(),
    ),
    _Page(
      headline: 'See exactly what to improve.',
      body:
          'A score for clarity, empathy, directness, and confidence, the move '
          'that worked, and the one thing to change next time. Then go again.',
      art: _ReportArt(),
    ),
  ];

  bool get _isLast => _page == _pages.length - 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_startReported) return;
    _startReported = true;
    AnalyticsScope.maybeOf(context)?.onboardingStarted();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      _finish(skipped: false);
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _finish({required bool skipped}) {
    AnalyticsScope.maybeOf(
      context,
    )?.onboardingCompleted(pagesSeen: _page + 1, skipped: skipped);
    AppSettingsScope.of(context).completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageWidth(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.paddingOf(context).top + 4,
                12,
                0,
              ),
              child: Row(
                children: [
                  const BrandMark(),
                  const Spacer(),
                  if (!_isLast)
                    TextButton(
                      key: const Key('skip_onboarding'),
                      onPressed: () => _finish(skipped: true),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.muted,
                      ),
                      child: const Text('Skip'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                key: const Key('onboarding_pages'),
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, index) => _PageView(page: _pages[index]),
              ),
            ),
            _Dots(count: _pages.length, active: _page),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: PageActionBar(
        child: FilledButton(
          key: const Key('onboarding_next'),
          onPressed: _next,
          child: Text(_isLast ? 'Start practicing' : 'Next'),
        ),
      ),
    );
  }
}

class _Page {
  const _Page({required this.headline, required this.body, required this.art});

  final String headline;
  final String body;
  final Widget art;
}

class _PageView extends StatelessWidget {
  const _PageView({required this.page});

  final _Page page;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              page.art,
              const SizedBox(height: 24),
              Text(
                page.headline,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              Text(
                page.body,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Page ${active + 1} of $count',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < count; index++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: index == active ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: index == active ? AppColors.forest : AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
        ],
      ),
    );
  }
}

// The artwork is the product's own UI rather than illustration, so what the
// intro promises is literally what the next screen looks like.

class _ArtFrame extends StatelessWidget {
  const _ArtFrame({required this.child, required this.color});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // A floor rather than a fixed height, so the three pages line up at
    // normal text size and the preview grows instead of clipping at large
    // ones.
    return Container(
      constraints: const BoxConstraints(minHeight: 244),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: child,
    );
  }
}

/// A simplified echo of the practice screen's chat bubbles.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.fromYou});

  final String text;
  final bool fromYou;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: fromYou
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        if (fromYou) const SizedBox(width: 34),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: fromYou ? AppColors.forest : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(fromYou ? 18 : 0),
                topRight: Radius.circular(fromYou ? 0 : 18),
                bottomLeft: const Radius.circular(18),
                bottomRight: const Radius.circular(18),
              ),
              border: fromYou ? null : Border.all(color: AppColors.border),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: fromYou ? Colors.white : AppColors.ink,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ),
        if (!fromYou) const SizedBox(width: 34),
      ],
    );
  }
}

class _ConversationArt extends StatelessWidget {
  const _ConversationArt();

  @override
  Widget build(BuildContext context) {
    return const _ArtFrame(
      color: AppColors.sky,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Bubble(
            text: 'I’m surprised we’re talking about this.',
            fromYou: false,
          ),
          SizedBox(height: 10),
          _Bubble(
            text:
                'I see how much you’ve taken on. We still need to talk '
                'about the two missed handoffs.',
            fromYou: true,
          ),
        ],
      ),
    );
  }
}

class _PushbackArt extends StatelessWidget {
  const _PushbackArt();

  @override
  Widget build(BuildContext context) {
    return const _ArtFrame(
      color: AppColors.peach,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Bubble(
            text:
                'Engineering changes the scope constantly. I can’t commit '
                'to a date when the target keeps moving.',
            fromYou: false,
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.tips_and_updates, size: 17, color: AppColors.ink),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Soften here and the expectation disappears.',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportArt extends StatelessWidget {
  const _ReportArt();

  @override
  Widget build(BuildContext context) {
    return const _ArtFrame(
      color: AppColors.mint,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScoreRing(score: 78, diameter: 96),
          SizedBox(height: 18),
          SkillBars(
            spacing: 10,
            values: {
              PracticeSkill.clarity: 74,
              PracticeSkill.empathy: 86,
              PracticeSkill.directness: 66,
              PracticeSkill.confidence: 71,
            },
          ),
        ],
      ),
    );
  }
}

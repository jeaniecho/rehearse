import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'brand_mark.dart';
import 'practice_history_scope.dart';
import 'profile_button.dart';

/// The bar both tabs wear: the mark, the streak, and the way into You.
///
/// Not an `AppBar`. Home and the progress tab put their content under a
/// header that stays put while the list runs beneath it, and `AppBar` lays
/// its title and actions out on its own margins — which is how the two tabs
/// came to have a mark at two different insets and a streak on only one of
/// them. One widget, one layout, [kToolbarHeightShort] tall on both.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final history = PracticeHistoryScope.maybeOf(context);
    final streak = history?.streakDays ?? 0;

    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      child: SizedBox(
        height: kToolbarHeightShort,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const BrandMark(),
              const Spacer(),
              // The streak is status, not news: it belongs in the bar with
              // the other standing thing rather than on a row of its own
              // above a headline it is not part of.
              if (streak > 0) ...[
                StreakChip(days: streak),
                const SizedBox(width: 8),
              ],
              // Pro is worn on the button itself, so the eyebrow that used
              // to sit here would now say it twice.
              const ProfileButton(),
            ],
          ),
        ),
      ),
    );
  }
}

/// The streak, worn in the header.
///
/// A flame and the number, not "4 day streak" spelled out: the chip shares a
/// row with the logo and the way into You, and at 1.3x text the sentence
/// pushed the row twenty-seven points past the screen. The words are kept
/// for screen readers, which have the room.
///
/// The flame is drawn, not typed. An emoji is somebody else's artwork — it
/// arrives in whatever colour and style the platform ships, orange on a page
/// with no orange in it, and it is the one glyph in the app the palette
/// could not reach. This one is [AppColors.forest], like everything else
/// that means you are doing well.
class StreakChip extends StatelessWidget {
  const StreakChip({required this.days, super.key});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: days == 1 ? '1 day streak' : '$days day streak',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.mint,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_fire_department_rounded,
              size: 15,
              color: AppColors.forest,
            ),
            const SizedBox(width: 3),
            Text(
              '$days',
              style: const TextStyle(
                color: AppColors.forest,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

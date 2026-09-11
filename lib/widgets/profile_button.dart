import 'package:flutter/material.dart';

import '../screens/you_screen.dart';
import '../theme/app_theme.dart';
import 'subscription_scope.dart';

/// The way into You, from the header of whichever tab you are on.
///
/// You stopped being a destination in the bar: it is somewhere you visit —
/// to restore a purchase, change one preference, or erase your history —
/// rather than somewhere you work, and it now opens over the bar like every
/// other pushed screen.
///
/// Pro is worn here rather than announced separately. The header used to
/// carry a `PRO` eyebrow beside the wordmark, which said the same thing
/// twice once this arrived.
class ProfileButton extends StatelessWidget {
  const ProfileButton({super.key});

  static const _size = 38.0;

  @override
  Widget build(BuildContext context) {
    final isPro = SubscriptionScope.maybeOf(context)?.isPro ?? false;

    return Semantics(
      button: true,
      label: isPro ? 'You, Rehearse Pro' : 'You',
      child: Material(
        // Unfilled unless it is carrying the medal. A grey disc at one end
        // of the header outweighed the logo at the other, which is backwards
        // — the way to a settings screen is not the heaviest thing on home.
        color: isPro ? AppColors.mint : Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('open_you'),
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const YouScreen())),
          child: SizedBox(
            // 38 is the chip, not the target — the tap area below is padded
            // out to 44 by the header that places it.
            width: _size,
            height: _size,
            child: Icon(
              isPro ? Icons.workspace_premium_rounded : Icons.person_rounded,
              size: isPro ? 20 : 23,
              color: isPro ? AppColors.forest : AppColors.charcoal,
            ),
          ),
        ),
      ),
    );
  }
}

/// [ProfileButton] as an `AppBar` action, padded to a 44pt target and given
/// the trailing gutter the bar does not supply.
class ProfileAction extends StatelessWidget {
  const ProfileAction({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(3, 3, 14, 3),
      child: ProfileButton(),
    );
  }
}

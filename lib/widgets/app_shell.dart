import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Keeps a phone-shaped column on iPad and the web instead of letting a
/// screen stretch to the edges.
///
/// Safe-area insets and padding deliberately live in each screen instead:
/// wrapping a scrollable in either one shrinks its viewport, so the list
/// gets clipped partway up the screen rather than scrolling off the edge.
class PageWidth extends StatelessWidget {
  const PageWidth({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: child,
      ),
    );
  }
}

class PageActionBar extends StatelessWidget {
  const PageActionBar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: SizedBox(width: double.infinity, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

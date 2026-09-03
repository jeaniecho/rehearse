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

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white : AppColors.forest;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            Icons.forum_rounded,
            color: light ? AppColors.forest : Colors.white,
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        // Flexible so the wordmark shortens rather than overflowing an app
        // bar that also carries actions at a large text scale.
        Flexible(
          child: Text(
            'rehearse',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
        ),
      ],
    );
  }
}

class MetaPill extends StatelessWidget {
  const MetaPill({
    required this.icon,
    required this.label,
    super.key,
    this.color = AppColors.muted,
    this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.canvas,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          // Flexible so a long label or a large text scale shortens the pill
          // instead of overflowing the card it sits in.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

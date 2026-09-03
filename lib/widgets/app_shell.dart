import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PageBody extends StatelessWidget {
  const PageBody({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 32),
    this.safeTop = true,
    this.safeBottom = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool safeTop;
  final bool safeBottom;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: safeTop,
      bottom: safeBottom,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(padding: padding, child: child),
        ),
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
        Text(
          'rehearse',
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
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
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

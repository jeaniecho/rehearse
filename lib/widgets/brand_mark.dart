import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'illustration.dart';

/// The logo lockup: the two bubbles, then the wordmark.
///
/// The mark is the paper illustration rather than a glyph in a tinted
/// square, which is what it was until the rest of the brand became paper.
/// It carries its own colour, so there is no light variant — every place it
/// appears is a white app bar.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Illustration.logo(),
        SizedBox(width: 8),
        // Flexible so the wordmark shortens rather than overflowing an app
        // bar that also carries actions at a large text scale.
        Flexible(
          child: Text(
            'rehearse',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.forest,
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

import 'package:flutter/material.dart';

import 'illustration.dart';

/// The logo: the two bubbles, on their own.
///
/// The mark is the paper illustration rather than a glyph in a tinted
/// square, which is what it was until the rest of the brand became paper.
/// It carries its own colour, so there is no light variant — every place it
/// appears is a white app bar.
///
/// The wordmark used to sit beside it and no longer does. The mark is
/// carrying the name on its own, which is what a mark is for; it also means
/// the header stops competing with the headline under it, and the app bar
/// has one fewer thing to shorten at a large text scale.
///
/// [Illustration] keeps itself out of the semantics tree, so with the word
/// gone the label has to be said here or a screen reader reaches a header
/// with no name in it.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Rehearse',
      container: true,
      child: const Illustration.logo(),
    );
  }
}

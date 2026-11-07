import 'package:flutter/material.dart';

import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_text.dart';

/// A round avatar with one letter: dark with a green letter (the user, a
/// friend in a list) or [filled] green with a dark letter (the friend who
/// paid, reference 52).
class SosAvatar extends StatelessWidget {
  const SosAvatar(this.letter, {super.key, required this.size, this.filled = false});

  final String letter;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? BunoColors.primary : BunoDark.card,
      ),
      child: BunoText(
        letter,
        style: BunoType.h1.copyWith(
          fontSize: size * 0.42,
          height: 1.2,
          color: filled ? BunoDark.on_primary : BunoColors.primary,
        ),
      ),
    );
  }
}

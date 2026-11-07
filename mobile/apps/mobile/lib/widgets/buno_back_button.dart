import 'package:flutter/material.dart';

import '../theme/buno_tokens.dart';
import '../theme/buno_tokens_ext.dart';
import 'buno_icon.dart';
import 'buno_pressable.dart';
import '../l10n/buno_locale.dart';

/// Back button (components.md "Top app bar"): 44pt touch target on the
/// trailing side in RTL, drawn as a 41pt outlined circle like the board.
class BunoBackButton extends StatelessWidget {
  const BunoBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return BunoPressable(
      semanticLabel: tr('رجوع', 'Back'),
      onTap: onPressed ?? () => Navigator.of(context).maybePop(),
      child: SizedBox.square(
        dimension: BunoSize.touchMin,
        child: Center(
          child: Container(
            width: 41,
            height: 41,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: BunoDark.border, width: BunoStroke.hairline),
            ),
            child: const BunoIcon(BunoIcons.back, color: BunoDark.text_primary),
          ),
        ),
      ),
    );
  }
}

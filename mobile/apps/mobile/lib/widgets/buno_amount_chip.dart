import 'package:flutter/widgets.dart';

import '../theme/buno_tokens.dart';
import '../theme/buno_tokens_ext.dart';
import 'buno_pressable.dart';
import 'buno_text.dart';

/// Top-up amount choice (low-balance sheet, /topup): selected = primary
/// border on `primary_soft`.
class BunoAmountChip extends StatelessWidget {
  const BunoAmountChip({super.key, required this.amount, required this.selected, required this.onTap});

  final int amount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BunoPressable(
      onTap: onTap,
      semanticLabel: '$amount',
      child: AnimatedContainer(
        duration: MediaQuery.of(context).disableAnimations ? Duration.zero : BunoMotion.fast,
        height: BunoSize.buttonLg,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? BunoColors.primary_soft : BunoDark.background,
          borderRadius: BorderRadius.circular(BunoRadius.md),
          border: Border.all(
            color: selected ? BunoColors.primary : BunoDark.border,
            width: selected ? BunoStroke.defaultWidth : BunoStroke.hairline,
          ),
        ),
        child: BunoText(
          '$amount',
          style: BunoType.title.copyWith(color: selected ? BunoColors.primary : null),
        ),
      ),
    );
  }
}

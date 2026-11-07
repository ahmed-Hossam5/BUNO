import 'package:flutter/widgets.dart';

import '../theme/buno_tokens.dart';
import '../theme/buno_tokens_ext.dart';
import 'buno_text.dart';

/// Price / info chip used on the station card: pill, `--color-background`
/// fill, 1px `--color-border`, secondary text.
class BunoChip extends StatelessWidget {
  const BunoChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: BunoDark.background,
        borderRadius: BorderRadius.circular(BunoRadius.pill),
        border: Border.all(color: BunoDark.border, width: BunoStroke.hairline),
      ),
      // A Row (not Container.alignment) keeps the chip hugging its label.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BunoText(
            label,
            style: BunoType.caption.copyWith(
              fontWeight: FontWeight.w400,
              height: 1.2,
              color: BunoDark.text_secondary,
            ),
          ),
        ],
      ),
    );
  }
}

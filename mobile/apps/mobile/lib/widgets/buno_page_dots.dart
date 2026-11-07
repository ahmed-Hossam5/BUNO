import 'package:flutter/widgets.dart';

import '../theme/buno_tokens.dart';
import '../theme/buno_tokens_ext.dart';
import '../l10n/buno_locale.dart';

/// Page indicator: the active page is a 26pt Buno-green pill, the others
/// 8pt `--color-border` pills. Laid out in reading order, so page 1 sits on
/// the right in Arabic.
class BunoPageDots extends StatelessWidget {
  const BunoPageDots({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tr('صفحة ${index + 1} من $count', 'Page ${index + 1} of $count'),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            AnimatedContainer(
              duration: BunoMotion.base,
              curve: BunoMotion.easing,
              width: i == index ? 26 : 8,
              height: 6,
              decoration: BoxDecoration(
                color: i == index ? BunoColors.primary : BunoDark.border,
                borderRadius: BorderRadius.circular(BunoRadius.pill),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

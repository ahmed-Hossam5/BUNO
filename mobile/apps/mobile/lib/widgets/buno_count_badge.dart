import 'package:flutter/widgets.dart';

import '../l10n/buno_locale.dart';
import '../theme/buno_tokens.dart';
import '../theme/buno_tokens_ext.dart';
import 'buno_text.dart';

/// "5 جاهز" / "3 فاضي": a count in Sora and its word, on a tint of [color].
class BunoCountBadge extends StatelessWidget {
  const BunoCountBadge({super.key, required this.count, required this.label, required this.color});

  /// Ready units, in green.
  BunoCountBadge.ready(int count, {Key? key}) : this(key: key, count: count, label: tr('جاهز', 'ready'), color: BunoColors.primary);

  /// Empty bays to return to, in blue.
  BunoCountBadge.free(int count, {Key? key}) : this(key: key, count: count, label: tr('فاضي', 'free'), color: BunoColors.info);

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$count $label',
      excludeSemantics: true,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Color.alphaBlend(color.withValues(alpha: 0.10), BunoDark.card),
          borderRadius: BorderRadius.circular(BunoRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BunoText('$count', style: BunoType.bodySm.copyWith(fontWeight: FontWeight.w700, height: 1, color: color)),
            const SizedBox(width: BunoSpace.s1),
            BunoText(label, style: BunoType.caption.copyWith(height: 1, color: BunoDark.text_secondary)),
          ],
        ),
      ),
    );
  }
}

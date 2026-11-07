import 'package:flutter/widgets.dart';

import '../theme/buno_tokens.dart';
import '../theme/buno_tokens_ext.dart';
import 'buno_text.dart';

/// Outlined status pill, e.g. "إيجار شغّال · بونو #07".
class BunoStatusPill extends StatelessWidget {
  const BunoStatusPill(this.label, {super.key, this.color = BunoColors.primary});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BunoRadius.pill),
        border: Border.all(color: color, width: BunoStroke.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BunoText(
            label,
            style: BunoType.caption.copyWith(height: 1.2, color: color),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/widgets.dart';

import '../theme/buno_tokens.dart';
import '../theme/buno_tokens_ext.dart';
import 'buno_pressable.dart';

/// A centred text-only action under a primary button ("هكمّل الساعة
/// التانية", "المحطة مش بتستلم؟"). Keeps the 44pt touch target.
class BunoTextLink extends StatelessWidget {
  const BunoTextLink(this.label, {super.key, required this.onTap, this.color = BunoDark.text_secondary});

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return BunoPressable(
      onTap: onTap,
      semanticLabel: label,
      child: SizedBox(
        height: BunoSize.touchMin,
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: BunoType.bodySm.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

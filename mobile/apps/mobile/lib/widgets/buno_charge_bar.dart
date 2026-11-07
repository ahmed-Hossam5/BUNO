import 'package:flutter/widgets.dart';

import '../theme/buno_tokens.dart';

/// Power-bank charge bar (components.md "Power bank card"): 8pt tall pill.
/// Fills from the start side, so it grows right-to-left in Arabic.
class BunoChargeBar extends StatelessWidget {
  const BunoChargeBar({
    super.key,
    required this.value,
    this.width = 90,
    this.color = BunoColors.secondary,
  });

  /// 0..1
  final double value;
  final double width;
  final Color color;

  static const height = 8.0;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(BunoRadius.pill);
    return Semantics(
      value: '${(value * 100).round()}%',
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: BunoDark.background, borderRadius: radius),
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0, 1),
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, borderRadius: radius),
          ),
        ),
      ),
    );
  }
}

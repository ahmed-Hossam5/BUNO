import 'package:flutter/widgets.dart';

import '../theme/buno_tokens.dart';
import '../theme/buno_tokens_ext.dart';
import 'buno_text.dart';

/// Label / value row (price rows on /station, /confirm, the low-balance
/// sheet): secondary label on the start side, primary value on the end side,
/// with an optional hairline divider below.
class BunoInfoRow extends StatelessWidget {
  const BunoInfoRow(
    this.label,
    this.value, {
    super.key,
    this.divider = false,
    this.verticalPadding = BunoSpace.s3,
  });

  final String label;
  final String value;
  final bool divider;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      decoration: divider
          ? const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: BunoDark.divider, width: BunoStroke.hairline),
              ),
            )
          : null,
      child: Row(
        children: [
          Expanded(
            child: BunoText(
              label,
              maxLines: 2,
              style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary),
            ),
          ),
          const SizedBox(width: BunoSpace.s3),
          BunoText(
            value,
            style: BunoType.bodySm.copyWith(
              color: BunoDark.text_primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

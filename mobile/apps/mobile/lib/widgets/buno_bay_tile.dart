import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../data/mock_rental.dart' show minReadyCharge;
import '../theme/buno_tokens.dart';
import '../theme/buno_tokens_ext.dart';
import 'buno_pressable.dart';
import 'buno_text.dart';
import '../l10n/buno_locale.dart';

/// Bay colour by charge: green ≥50, amber 20–49, red <20, grey when empty.
Color chargeColor(int? charge) => switch (charge) {
  null => BunoDark.border,
  >= 50 => BunoColors.success,
  >= 20 => BunoColors.warning,
  _ => BunoColors.error,
};

/// One station bay drawn as a battery: the cell fills from the bottom to the
/// unit's [charge], coloured by [chargeColor], with the percentage on top and
/// the bay [number] below. A null [charge] is an empty, grey bay; a unit below
/// [minReadyCharge] is dimmed. [onTap] null makes the tile inert; a tap gives
/// light haptic feedback.
class BunoBayTile extends StatelessWidget {
  const BunoBayTile({super.key, required this.number, required this.charge, this.selected = false, this.onTap});

  final int number;

  /// Percent 0..100, or null when the bay is empty.
  final int? charge;
  final bool selected;
  final VoidCallback? onTap;

  static const height = 104.0;

  /// Opacity of a unit below [minReadyCharge].
  static const lowOpacity = 0.55;

  @override
  Widget build(BuildContext context) {
    final c = charge;
    final tap = onTap;
    return BunoPressable(
      onTap: tap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              tap();
            },
      semanticLabel: c == null ? tr('خانة $number فاضية', 'Bay $number empty') : tr('خانة $number، $c%', 'Bay $number, $c%'),
      child: ExcludeSemantics(
        child: Opacity(
          opacity: c != null && c < minReadyCharge ? lowOpacity : 1,
          child: Container(
            height: height,
            padding: const EdgeInsets.fromLTRB(BunoSpace.s3, BunoSpace.s2, BunoSpace.s3, BunoSpace.s2),
            decoration: BoxDecoration(
              color: BunoDark.card,
              borderRadius: BorderRadius.circular(BunoRadius.lg),
              border: Border.all(
                color: selected ? BunoColors.primary : BunoDark.border,
                width: selected ? BunoStroke.defaultWidth : BunoStroke.hairline,
              ),
            ),
            child: Column(
              children: [
                FittedBox(
                  child: BunoText(
                    c == null ? tr('فاضية', 'Empty') : '$c%',
                    style: BunoType.bodySm.copyWith(
                      fontWeight: FontWeight.w600,
                      color: c == null ? BunoDark.text_disabled : BunoDark.text_primary,
                    ),
                  ),
                ),
                const SizedBox(height: BunoSpace.s1),
                Expanded(child: _Cell(charge: c)),
                const SizedBox(height: BunoSpace.s1),
                BunoText('$number', style: BunoType.caption.copyWith(color: BunoDark.text_secondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Battery body with a small cap; fill height = charge.
class _Cell extends StatelessWidget {
  const _Cell({required this.charge});

  final int? charge;

  static const _capHeight = 3.0;

  @override
  Widget build(BuildContext context) {
    final c = charge;
    final colour = chargeColor(c);
    return Column(
      children: [
        FractionallySizedBox(
          widthFactor: 0.4,
          child: Container(
            height: _capHeight,
            decoration: BoxDecoration(
              color: BunoDark.border,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(BunoRadius.xs)),
            ),
          ),
        ),
        Expanded(
          child: FractionallySizedBox(
            widthFactor: 0.62,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: BunoDark.background,
                borderRadius: BorderRadius.circular(BunoRadius.xs),
                border: Border.all(color: BunoDark.border, width: BunoStroke.hairline),
              ),
              alignment: Alignment.bottomCenter,
              child: c == null
                  ? null
                  : FractionallySizedBox(
                      heightFactor: (c / 100).clamp(0.0, 1.0),
                      widthFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colour,
                          borderRadius: BorderRadius.circular(BunoRadius.xs - 2),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

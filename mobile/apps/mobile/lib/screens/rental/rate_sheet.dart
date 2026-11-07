import 'package:flutter/material.dart';

import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_text.dart';
import '../../widgets/buno_text_link.dart';
import '../../l10n/buno_locale.dart';

/// "What went wrong?" sheet (reference 64_rate), shown by /receipt when the
/// trip gets [rating] 3 stars or less. Completes with true once sent.
Future<bool?> showRateSheet(BuildContext context, {required int rating}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: BunoDark.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(BunoRadius.xxl)),
    ),
    builder: (_) => RateSheet(rating: rating),
  );
}

class RateSheet extends StatefulWidget {
  const RateSheet({super.key, required this.rating});

  final int rating;

  static List<String> get reasons => [
    tr('الوحدة شحنها ضعيف', 'Low unit charge'),
    tr('الشحن بطيء', 'Slow charging'),
    tr('الوحدة كانت سخنة', 'The unit was hot'),
    tr('الكابل مش شغال', "The cable didn't work"),
    tr('الخانة ماكانتش بتفتح', "The bay wouldn't open"),
    tr('الإرجاع كان صعب', 'Returning was hard'),
    tr('المحطة بعيدة', 'Station too far'),
    tr('التطبيق بطيء', 'Slow app'),
    tr('حاجة تانية', 'Something else'),
  ];

  @override
  State<RateSheet> createState() => _RateSheetState();
}

class _RateSheetState extends State<RateSheet> {
  final _picked = <String>{};

  void _toggle(String reason) => setState(() => _picked.contains(reason) ? _picked.remove(reason) : _picked.add(reason));

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, BunoSpace.s3, 22, BunoSpace.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: BunoDark.border,
                  borderRadius: BorderRadius.circular(BunoRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: BunoSpace.s5),
            Text(tr('إيه اللي ماعجبكش؟', "What didn't you like?"), style: BunoType.h2),
            BunoText(
              tr('قيّمتها ${widget.rating} من 5. اختار سبب أو أكتر وهنشتغل عليه.', "You rated it ${widget.rating} of 5. Pick one or more reasons and we'll work on it."),
              style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary),
            ),
            const SizedBox(height: BunoSpace.s4),
            Wrap(
              spacing: BunoSpace.s2,
              runSpacing: BunoSpace.s2,
              children: [
                for (final r in RateSheet.reasons)
                  _ReasonChip(label: r, selected: _picked.contains(r), onTap: () => _toggle(r)),
              ],
            ),
            const SizedBox(height: BunoSpace.s5),
            BunoPrimaryButton(
              label: tr('ابعت', 'Send'),
              onPressed: _picked.isEmpty ? null : () => Navigator.of(context).pop(true),
            ),
            BunoTextLink(tr('مش دلوقتي', 'Not now'), onTap: () => Navigator.of(context).pop(false)),
          ],
        ),
      ),
    );
  }
}

class _ReasonChip extends StatelessWidget {
  const _ReasonChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: BunoPressable(
        onTap: onTap,
        semanticLabel: label,
        child: AnimatedContainer(
          duration: MediaQuery.of(context).disableAnimations ? Duration.zero : BunoMotion.fast,
          constraints: const BoxConstraints(minHeight: BunoSize.touchMin),
          padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s4, vertical: BunoSpace.s2),
          decoration: BoxDecoration(
            color: selected ? BunoColors.primary_soft : BunoDark.background,
            borderRadius: BorderRadius.circular(BunoRadius.pill),
            border: Border.all(
              color: selected ? BunoColors.primary : BunoDark.border,
              width: selected ? BunoStroke.defaultWidth : BunoStroke.hairline,
            ),
          ),
          child: Text(
            label,
            style: BunoType.bodySm.copyWith(
              fontWeight: FontWeight.w600,
              color: selected ? BunoColors.primary : BunoDark.text_secondary,
            ),
          ),
        ),
      ),
    );
  }
}

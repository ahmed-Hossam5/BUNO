import 'package:flutter/material.dart';

import '../../data/mock_wrapped.dart';
import '../../l10n/buno_locale.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_text.dart';

/// Home's "your month is ready" banner, shown while
/// [MockWrapped.bannerVisible]. Tapping opens /wrapped; the cross hides it.
class WrappedBanner extends StatelessWidget {
  const WrappedBanner({super.key, required this.onOpen});

  final VoidCallback onOpen;

  static const _ink = BunoDark.on_primary;

  @override
  Widget build(BuildContext context) {
    final title = tr('شهرك مع بونو جاهز', 'Your month with Buno is ready');
    return BunoPressable(
      onTap: onOpen,
      semanticLabel: title,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(BunoSpace.s4, BunoSpace.s3, BunoSpace.s1, BunoSpace.s3),
        decoration: BoxDecoration(
          color: BunoColors.primary,
          borderRadius: BorderRadius.circular(BunoRadius.xl),
        ),
        child: Row(
          children: [
            const BunoLottieIcon(name: 'star', size: BunoSize.iconLg, color: _ink),
            const SizedBox(width: BunoSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BunoText(title, maxLines: 1, style: BunoType.title.copyWith(fontWeight: FontWeight.w700, color: _ink)),
                  BunoText(
                    tr('شوف شحنت قد إيه في [الشهر]', 'See how much you charged in [month]'),
                    maxLines: 1,
                    style: BunoType.caption.copyWith(color: _ink.withValues(alpha: 0.72)),
                  ),
                ],
              ),
            ),
            BunoPressable(
              onTap: MockWrapped.dismiss,
              semanticLabel: tr('اخفي', 'Hide'),
              child: const SizedBox.square(
                dimension: BunoSize.touchMin,
                child: Center(child: BunoIcon(BunoIcons.close, size: BunoSize.iconSm, color: _ink)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

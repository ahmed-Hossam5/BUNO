import 'package:flutter/widgets.dart';

import '../theme/buno_tokens.dart';
import '../theme/buno_tokens_ext.dart';
import 'buno_icon.dart';
import 'buno_lottie_icon.dart';
import 'buno_text.dart';
import '../l10n/buno_locale.dart';

enum BunoStepStatus { done, current, next }

/// One row of a vertical progress list (/unlocking, /verifying): a dot that
/// fills green when done, amber ring (with an optional [lottie]) while
/// current, and a line down to the next row.
class BunoStepRow extends StatelessWidget {
  const BunoStepRow({
    super.key,
    required this.title,
    required this.detail,
    required this.status,
    required this.last,
    this.lottie,
  });

  final String title;
  final String detail;
  final BunoStepStatus status;
  final bool last;
  final String? lottie;

  static const _dot = 32.0;
  static const _gap = 34.0;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.of(context).disableAnimations ? Duration.zero : BunoMotion.base;
    final pending = status == BunoStepStatus.next;
    final lottie = this.lottie;
    return Semantics(
      label: '$title${tr('،', ',')} ${switch (status) {
        BunoStepStatus.done => tr('تم', 'Done'),
        BunoStepStatus.current => tr('جاري', 'In progress'),
        BunoStepStatus.next => tr('لسه', 'Not yet'),
      }}',
      excludeSemantics: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                AnimatedContainer(
                  duration: duration,
                  width: _dot,
                  height: _dot,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: status == BunoStepStatus.done ? BunoColors.primary : null,
                    borderRadius: BorderRadius.circular(BunoRadius.circle),
                    border: Border.all(
                      color: switch (status) {
                        BunoStepStatus.done => BunoColors.primary,
                        BunoStepStatus.current => BunoColors.warning,
                        BunoStepStatus.next => BunoDark.border,
                      },
                      width: BunoStroke.emphasis,
                    ),
                  ),
                  child: switch (status) {
                    BunoStepStatus.done => const BunoIcon(
                        BunoIcons.check,
                        size: BunoSize.iconSm,
                        color: BunoDark.on_primary,
                      ),
                    BunoStepStatus.current when lottie != null => BunoLottieIcon(
                        name: lottie,
                        size: BunoSize.iconSm,
                        color: BunoColors.warning,
                        playKey: '$lottie$title',
                      ),
                    _ => null,
                  },
                ),
                if (!last)
                  Expanded(
                    child: AnimatedContainer(
                      duration: duration,
                      width: BunoStroke.emphasis,
                      constraints: const BoxConstraints(minHeight: BunoSpace.s4),
                      color: status == BunoStepStatus.done ? BunoColors.primary : BunoDark.border,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: BunoSpace.s3),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: last ? 0 : _gap - BunoSpace.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: BunoType.title.copyWith(
                        color: pending ? BunoDark.text_secondary : BunoDark.text_primary,
                      ),
                    ),
                    BunoText(
                      detail,
                      maxLines: 1,
                      style: BunoType.caption.copyWith(
                        color: pending ? BunoDark.text_disabled : BunoDark.text_secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

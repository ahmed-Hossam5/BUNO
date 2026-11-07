import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_text.dart';
import '../auth/auth_scaffold.dart' show showBunoToast;
import 'account_scaffold.dart';
import '../../l10n/buno_locale.dart';

/// Invite a friend (ادعي صاحبك, reference 25): referral code with copy,
/// share on WhatsApp as the primary action (snackbar only for now).
class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  static const code = 'BUNO-MO12';

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  int _copies = 0;

  static const _gift = 96.0;

  Future<void> _copy() async {
    await Clipboard.setData(const ClipboardData(text: ReferralScreen.code));
    if (!mounted) return;
    setState(() => _copies++);
    showBunoToast(context, tr('اتنسخ الكود', 'Code copied'));
  }

  @override
  Widget build(BuildContext context) {
    final headline = BunoType.h2.copyWith(height: 1.3);
    return AccountScaffold(
      title: tr('ادعي صاحبك', 'Invite a friend'),
      button: BunoPrimaryButton(
        label: tr('ابعت على واتساب', 'Send on WhatsApp'),
        leading: const BunoLottieIcon(name: 'share', playKey: true, color: BunoDark.on_primary),
        onPressed: () => showBunoToast(context, tr('بنفتح واتساب عشان تبعت الكود…', 'Opening WhatsApp to send the code…')),
      ),
      children: [
        const SizedBox(height: BunoSpace.s6),
        const Center(child: BunoLottieIcon(name: 'gift', size: _gift, playKey: true, color: BunoColors.primary)),
        const SizedBox(height: BunoSpace.s4),
        BunoText(tr('30 دقيقة ببلاش', '30 free minutes'), textAlign: TextAlign.center, style: headline),
        Text(tr('ليك ولصاحبك', 'For you and your friend'), textAlign: TextAlign.center, style: headline.copyWith(color: BunoColors.primary)),
        const SizedBox(height: BunoSpace.s5),
        Container(
          height: 64,
          padding: const EdgeInsetsDirectional.only(start: BunoSpace.s5, end: BunoSpace.s2),
          decoration: BoxDecoration(
            color: BunoDark.card,
            borderRadius: BorderRadius.circular(BunoRadius.xl),
            border: Border.all(color: BunoDark.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: BunoText(
                    ReferralScreen.code,
                    style: BunoType.h2.copyWith(letterSpacing: 1.5, height: 1.2),
                  ),
                ),
              ),
              BunoPressable(
                onTap: _copy,
                semanticLabel: tr('نسخ', 'Copy'),
                child: Container(
                  height: BunoSize.touchMin,
                  padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s3),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BunoLottieIcon(
                        name: 'copy',
                        size: BunoSize.iconSm,
                        playKey: _copies == 0 ? null : _copies,
                        color: BunoColors.primary,
                      ),
                      const SizedBox(width: BunoSpace.s1),
                      Text(tr('نسخ', 'Copy'), style: BunoType.bodySm.copyWith(fontWeight: FontWeight.w700, color: BunoColors.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: BunoSpace.s3),
        Text(
          tr('لما صاحبك ياخد أول بونو، الاتنين بتاخدوا الهدية.', 'When your friend takes their first Buno, you both get the gift.'),
          textAlign: TextAlign.center,
          style: BunoType.caption.copyWith(color: BunoDark.text_secondary),
        ),
      ],
    );
  }
}

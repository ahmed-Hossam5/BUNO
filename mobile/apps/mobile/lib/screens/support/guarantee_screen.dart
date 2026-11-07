import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../l10n/buno_locale.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_text.dart';
import '../auth/auth_scaffold.dart' show showBunoToast;
import 'support_scaffold.dart';

/// Full-station guarantee (الخانات مليانة؟ علينا, reference 62): the meter
/// stopped when the user reached a full station, what they pay (placeholder),
/// and the nearest station with free bays. From /help.
class GuaranteeScreen extends StatelessWidget {
  const GuaranteeScreen({super.key});

  /// Mock: where the meter stopped.
  static const stoppedAt = '01:12';

  @override
  Widget build(BuildContext context) {
    return SupportScaffold(
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s3, vertical: BunoSpace.s1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(BunoRadius.pill),
          border: Border.all(color: BunoColors.warning),
        ),
        child: Text(tr('المحطة مليانة', 'Station full'), style: BunoType.caption.copyWith(fontWeight: FontWeight.w700, color: BunoColors.warning)),
      ),
      buttons: [
        BunoPrimaryButton(
          label: tr('ودّيني للمحطة البديلة', 'Take me to the other station'),
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.stations),
        ),
        BunoSecondaryButton(
          label: tr('بلّغ إن الخانات مليانة', 'Report the bays are full'),
          labelWeight: FontWeight.w700,
          onPressed: () => showBunoToast(context, tr('وصلنا البلاغ، شكرًا', 'Report received, thanks')),
        ),
      ],
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: BunoColors.primary_soft,
              borderRadius: BorderRadius.circular(BunoRadius.lg),
              boxShadow: const [BunoElevation.glow],
            ),
            child: const BunoLottieIcon(name: 'shield', size: BunoSize.iconLg, color: BunoColors.primary),
          ),
        ),
        const SizedBox(height: BunoSpace.s4),
        Text(tr('الخانات مليانة؟ علينا', 'Bays full? On us'), style: BunoType.h2),
        const SizedBox(height: BunoSpace.s1),
        Text(
          tr(
            'وقفنا العدّاد من اللحظة اللي وصلت فيها. أي دقيقة زيادة لحد ما ترجّعه في محطة تانية مش هتتحسب عليك.',
            "We stopped the meter the moment you arrived. Any extra minute until you return it at another station won't be charged.",
          ),
          style: BunoType.body.copyWith(fontWeight: FontWeight.w600, color: BunoDark.text_secondary),
        ),
        const SizedBox(height: BunoSpace.s5),
        const _MeterCard(),
        const SizedBox(height: BunoSpace.s4),
        const _AlternativeCard(),
      ],
    );
  }
}

class _MeterCard extends StatelessWidget {
  const _MeterCard();

  @override
  Widget build(BuildContext context) {
    final label = BunoType.bodySm.copyWith(fontWeight: FontWeight.w600, color: BunoDark.text_secondary);
    return Container(
      padding: const EdgeInsets.all(BunoSpace.s5),
      decoration: BoxDecoration(
        color: BunoDark.card,
        borderRadius: BorderRadius.circular(BunoRadius.xl),
        border: Border.all(color: BunoColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(tr('العداد وقف عند', 'Meter stopped at'), style: label)),
              BunoText(GuaranteeScreen.stoppedAt, style: BunoType.h3.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: BunoSpace.s3),
          const Divider(height: 1, thickness: 1, color: BunoDark.divider),
          const SizedBox(height: BunoSpace.s3),
          Row(
            children: [
              Expanded(child: Text(tr('اللي هتدفعه', "You'll pay"), style: label)),
              BunoText(tr('ج [السعر]', 'EGP [Price]'), style: BunoType.h3.copyWith(fontWeight: FontWeight.w700, color: BunoColors.primary)),
            ],
          ),
          const SizedBox(height: BunoSpace.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsetsDirectional.only(top: 2),
                child: BunoLottieIcon(name: 'clock', size: BunoSize.iconSm, color: BunoColors.primary),
              ),
              const SizedBox(width: BunoSpace.s2),
              Expanded(
                child: BunoText(
                  tr(
                    'معاك [المدة] ترجّعه في أي محطة تانية بالسعر ده.',
                    'You have [duration] to return it at any other station at this price.',
                  ),
                  style: BunoType.caption.copyWith(fontWeight: FontWeight.w600, color: BunoDark.text_secondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlternativeCard extends StatelessWidget {
  const _AlternativeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BunoSpace.s4),
      decoration: BoxDecoration(
        color: BunoDark.card,
        borderRadius: BorderRadius.circular(BunoRadius.lg),
        border: Border.all(color: BunoDark.border),
      ),
      child: Row(
        children: [
          const BunoLottieIcon(name: 'pin', size: BunoSize.iconMd, color: BunoColors.primary),
          const SizedBox(width: BunoSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('[اسم المكان]', '[Place name]'), style: BunoType.body.copyWith(fontWeight: FontWeight.w700, height: 1.3)),
                BunoText(
                  tr('[المسافة] · [العدد] خانات فاضية', '[Distance] · [N] free bays'),
                  style: BunoType.caption.copyWith(color: BunoDark.text_secondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: BunoSpace.s2),
          Text(tr('أقرب بديل', 'Nearest'), style: BunoType.caption.copyWith(fontWeight: FontWeight.w700, color: BunoColors.primary)),
        ],
      ),
    );
  }
}

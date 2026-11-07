import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/mock_subscription.dart';
import '../../l10n/buno_locale.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_text.dart';
import 'support_scaffold.dart';

/// Emergency rental (إيجار الطوارئ, reference 63): one free hour a term with
/// no balance or deposit. "استخدمها دلوقتي" marks it used ([MockEmergency])
/// and opens /scan. From /help.
class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  static List<String> get conditions => [
        tr('إيميل الجامعة لازم يكون متأكد', 'Your university e-mail must be verified'),
        tr('ساعة واحدة بس، واللي بعدها بيتحسب عادي', 'One hour only; after that it is charged as usual'),
        tr('لازم ترجّعه في 24 ساعة، وإلا بتدفع غرامة عدم الإرجاع', 'Return it within 24 hours, or you pay the non-return fee'),
        tr('مرة واحدة كل ترم لكل حساب', 'Once a term per account'),
      ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: MockEmergency.used,
      builder: (context, used, _) => SupportScaffold(
        buttons: [
          BunoPrimaryButton(
            label: used ? tr('استخدمتها الترم ده', 'Used this term') : tr('استخدمها دلوقتي', 'Use it now'),
            onPressed: used
                ? null
                : () {
                    MockEmergency.used.value = true;
                    Navigator.of(context).pushNamed(AppRoutes.scan);
                  },
          ),
          BunoSecondaryButton(
            label: tr('سيبها لوقت تاني', 'Save it for later'),
            labelWeight: FontWeight.w700,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
        children: [
          const _HeroCard(),
          const SizedBox(height: BunoSpace.s4),
          const _ConditionsCard(),
          const SizedBox(height: BunoSpace.s4),
          _AvailabilityCard(used: used),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BunoSpace.s5),
      decoration: BoxDecoration(
        color: BunoColors.primary,
        borderRadius: BorderRadius.circular(BunoRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BunoLottieIcon(name: 'gift', size: BunoSize.iconLg, color: BunoDark.on_primary),
          const SizedBox(height: BunoSpace.s2),
          Text(tr('إيجار الطوارئ', 'Emergency rental'), style: BunoType.h2.copyWith(color: BunoDark.on_primary)),
          Text(
            tr('ساعة ببلاش، مرة واحدة في الترم، من غير رصيد ومن غير أي تأمين.', 'One free hour, once a term, with no balance and no deposit.'),
            style: BunoType.body.copyWith(fontWeight: FontWeight.w600, color: BunoDark.on_primary),
          ),
        ],
      ),
    );
  }
}

class _ConditionsCard extends StatelessWidget {
  const _ConditionsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BunoSpace.s5),
      decoration: BoxDecoration(
        color: BunoDark.card,
        borderRadius: BorderRadius.circular(BunoRadius.xl),
        border: Border.all(color: BunoDark.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tr('الشروط', 'Conditions'), style: BunoType.body.copyWith(fontWeight: FontWeight.w700, height: 1.3)),
          for (final c in EmergencyScreen.conditions) ...[
            const SizedBox(height: BunoSpace.s3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsetsDirectional.only(top: 1),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: BunoColors.primary_soft),
                  child: const BunoIcon(BunoIcons.check, size: BunoSize.iconSm, color: BunoColors.primary),
                ),
                const SizedBox(width: BunoSpace.s3),
                Expanded(
                  child: BunoText(c, style: BunoType.bodySm.copyWith(fontWeight: FontWeight.w600, color: BunoDark.text_secondary)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({required this.used});

  final bool used;

  @override
  Widget build(BuildContext context) {
    final color = used ? BunoDark.text_secondary : BunoColors.primary;
    return Container(
      padding: const EdgeInsets.all(BunoSpace.s4),
      decoration: BoxDecoration(
        color: BunoDark.card,
        borderRadius: BorderRadius.circular(BunoRadius.lg),
        border: Border.all(color: BunoDark.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('متاح ليك', 'Available to you'), style: BunoType.caption.copyWith(color: BunoDark.text_secondary)),
                Text(
                  used ? tr('ولا مرة', 'None left') : tr('مرة واحدة', 'Once'),
                  style: BunoType.title.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s3, vertical: BunoSpace.s1),
            decoration: BoxDecoration(
              color: used ? BunoDark.elevated : BunoColors.primary_soft,
              borderRadius: BorderRadius.circular(BunoRadius.pill),
            ),
            child: Text(
              used ? tr('استخدمتها', 'Used') : tr('لسه ماستخدمتهاش', 'Not used yet'),
              style: BunoType.caption.copyWith(fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

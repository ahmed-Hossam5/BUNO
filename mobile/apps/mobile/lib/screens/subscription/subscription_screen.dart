import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/mock_subscription.dart';
import '../../l10n/buno_locale.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_charge_bar.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_text.dart';
import '../account/account_scaffold.dart';
import '../auth/auth_scaffold.dart' show showBunoToast;

/// My plan (اشتراكي, reference 60): the active plan, renewal date and price
/// (placeholders), this month's usage, change plan → /plans, and cancelling
/// auto-renew after a confirm dialog. From the wallet's "اشتراكي".
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  Future<void> _confirmCancel(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BunoDark.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BunoRadius.xl)),
        title: Text(tr('تلغي التجديد التلقائي؟', 'Cancel auto-renew?'), style: BunoType.title),
        content: Text(
          tr('باقتك هتفضل شغالة لحد [التاريخ]، وبعدها مش هتتجدد.', 'Your plan stays active until [date], then it won’t renew.'),
          style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(tr('لأ', 'No'), style: BunoType.body.copyWith(color: BunoDark.text_primary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(tr('ألغي', 'Cancel it'), style: BunoType.body.copyWith(fontWeight: FontWeight.w700, color: BunoColors.error)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    MockSubscription.autoRenew.value = false;
    showBunoToast(context, tr('اتلغى التجديد التلقائي', 'Auto-renew cancelled'));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: MockSubscription.autoRenew,
      builder: (context, renews, _) => AccountScaffold(
        title: tr('اشتراكي', 'My plan'),
        button: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BunoSecondaryButton(
              label: tr('غيّر الباقة', 'Change plan'),
              labelWeight: FontWeight.w700,
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.plans),
            ),
            const SizedBox(height: BunoSpace.s3),
            if (renews)
              _DangerButton(label: tr('ألغي التجديد التلقائي', 'Cancel auto-renew'), onTap: () => _confirmCancel(context))
            else
              BunoSecondaryButton(
                label: tr('شغّل التجديد التلقائي تاني', 'Turn auto-renew back on'),
                onPressed: () {
                  MockSubscription.autoRenew.value = true;
                  showBunoToast(context, tr('التجديد التلقائي رجع', 'Auto-renew is back on'));
                },
              ),
          ],
        ),
        children: [
          _PlanCard(renews: renews),
          const SizedBox(height: BunoSpace.s4),
          const _UsageCard(),
          const SizedBox(height: BunoSpace.s4),
          Container(
            padding: const EdgeInsets.all(BunoSpace.s4),
            decoration: BoxDecoration(
              color: BunoDark.card,
              borderRadius: BorderRadius.circular(BunoRadius.lg),
              border: Border.all(color: BunoDark.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsetsDirectional.only(top: 2),
                  child: BunoLottieIcon(name: 'clock', size: BunoSize.iconSm, color: BunoColors.warning),
                ),
                const SizedBox(width: BunoSpace.s2),
                Expanded(
                  child: BunoText(
                    tr(
                      'الحد في الإيجار الواحد ${MockSubscription.maxRentalHours} ساعات. لو عدّيتها، الزيادة بتتحسب بالدقيقة من محفظتك.',
                      'Each rental is capped at ${MockSubscription.maxRentalHours} hours. Past that, the extra is charged per minute from your wallet.',
                    ),
                    style: BunoType.bodySm.copyWith(fontWeight: FontWeight.w600, color: BunoDark.text_secondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.renews});

  final bool renews;

  @override
  Widget build(BuildContext context) {
    final label = BunoType.caption.copyWith(fontWeight: FontWeight.w700, color: BunoDark.on_primary);
    final value = BunoType.title.copyWith(fontWeight: FontWeight.w700, color: BunoDark.on_primary);
    return Container(
      padding: const EdgeInsets.all(BunoSpace.s5),
      decoration: BoxDecoration(
        color: BunoColors.primary,
        borderRadius: BorderRadius.circular(BunoRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('باقتك', 'Your plan'), style: label),
                    Text(MockSubscription.plan.text, style: BunoType.h1.copyWith(color: BunoDark.on_primary, height: 1.3)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s3, vertical: BunoSpace.s1),
                decoration: BoxDecoration(
                  color: BunoDark.on_primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(BunoRadius.pill),
                ),
                child: Text(renews ? tr('شغّال', 'Active') : tr('مش هيتجدد', 'Not renewing'), style: label),
              ),
            ],
          ),
          const SizedBox(height: BunoSpace.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(renews ? tr('بيتجدد في', 'Renews on') : tr('شغّال لحد', 'Active until'), style: label),
                    BunoText(tr('[التاريخ]', '[Date]'), style: value),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(tr('القيمة', 'Price'), style: label),
                  BunoText(tr('EGP [السعر]', 'EGP [Price]'), style: value),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  const _UsageCard();

  @override
  Widget build(BuildContext context) {
    final muted = BunoType.bodySm.copyWith(fontWeight: FontWeight.w600, color: BunoDark.text_secondary);
    final strong = BunoType.bodySm.copyWith(fontWeight: FontWeight.w700);
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
          Row(
            children: [
              Expanded(
                child: Text(tr('استخدامك الشهر ده', 'Your usage this month'), style: BunoType.body.copyWith(fontWeight: FontWeight.w700, height: 1.3)),
              ),
              BunoText(tr('[العدد] يوم فاضل', '[N] days left'), style: BunoType.caption.copyWith(color: BunoDark.text_secondary)),
            ],
          ),
          const SizedBox(height: BunoSpace.s3),
          _UsageRow(
            label: tr('إيجارات', 'Rentals'),
            value: tr('${MockSubscription.rentalsUsed} / [عدد الإيجارات]', '${MockSubscription.rentalsUsed} / [Rentals]'),
            fraction: MockSubscription.rentalsUsed / MockSubscription.rentalsIncluded,
            color: BunoColors.primary,
            labelStyle: muted,
            valueStyle: strong,
          ),
          const SizedBox(height: BunoSpace.s3),
          _UsageRow(
            label: tr('ساعات', 'Hours'),
            value: tr('${MockSubscription.hoursUsed} / [الساعات] س', '${MockSubscription.hoursUsed} / [Hours] h'),
            fraction: MockSubscription.hoursUsed / MockSubscription.hoursIncluded,
            color: BunoColors.secondary,
            labelStyle: muted,
            valueStyle: strong,
          ),
          const SizedBox(height: BunoSpace.s4),
          Row(
            children: [
              Expanded(child: Text(tr('وفّرت الشهر ده', 'Saved this month'), style: muted)),
              BunoText(tr('[المبلغ] جنيه', 'EGP [Amount]'), style: strong.copyWith(color: BunoColors.primary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
    required this.labelStyle,
    required this.valueStyle,
  });

  final String label;
  final String value;
  final double fraction;
  final Color color;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: labelStyle)),
            BunoText(value, style: valueStyle),
          ],
        ),
        const SizedBox(height: BunoSpace.s1),
        LayoutBuilder(
          builder: (context, c) => BunoChargeBar(value: fraction.clamp(0, 1), width: c.maxWidth, color: color),
        ),
      ],
    );
  }
}

/// Outlined red button for the destructive action, sized like
/// [BunoSecondaryButton].
class _DangerButton extends StatelessWidget {
  const _DangerButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BunoPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BunoColors.error, width: BunoStroke.hairline),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, style: BunoType.button.copyWith(fontSize: 14, color: BunoColors.error)),
        ),
      ),
    );
  }
}

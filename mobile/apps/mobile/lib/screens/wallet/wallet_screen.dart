import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/mock_trust.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_bottom_nav.dart';
import '../../widgets/buno_dashed_button.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_tab_header.dart';
import '../../widgets/buno_text.dart';
import '../../widgets/buno_wallet_card.dart';
import '../auth/auth_scaffold.dart' show showBunoToast;
import '../../l10n/buno_locale.dart';

/// Bottom-nav items shared by the tab screens.
List<BunoNavItem> get bunoNavItems => [
  BunoNavItem(icon: BunoIcons.home, label: tr('الرئيسية', 'Home')),
  BunoNavItem(icon: BunoIcons.history, label: tr('رحلاتي', 'Trips')),
  BunoNavItem(icon: BunoIcons.wallet, label: tr('المحفظة', 'Wallet')),
  BunoNavItem(icon: BunoIcons.profile, label: tr('حسابي', 'Profile')),
];

class WalletTransaction {
  const WalletTransaction(this.title, this.subtitle, this.amount, {this.credit = false});

  final String title;
  final String subtitle;
  final String amount;
  final bool credit;
}

/// Wallet — Brand Board page 12. Mock data only; amounts stay as the
/// board's placeholders until real pricing exists.
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  static const _gutter = 24.0;
  static const _navIndex = 2;

  static List<WalletTransaction> get _transactions => [
    WalletTransaction(tr('إيجار بونو', 'Buno rental'), tr('[اسم المكان] · امبارح', '[Place name] · yesterday'), tr('-[السعر]', '-[Price]')),
    WalletTransaction(tr('شحن المحفظة', 'Wallet top-up'), tr('فيزا 4417 · السبت', 'Visa 4417 · Saturday'), tr('+[المبلغ]', '+[Amount]'), credit: true),
    WalletTransaction(tr('إيجار بونو', 'Buno rental'), tr('[اسم المكان] · الخميس', '[Place name] · Thursday'), tr('-[السعر]', '-[Price]')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BunoDark.background,
      bottomNavigationBar: BunoBottomNav(
        items: bunoNavItems,
        currentIndex: _navIndex,
        onSelected: (i) => AppRoutes.goToTab(context, i, _navIndex),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(_gutter, 21, _gutter, 24),
          children: [
            BunoTabHeader(title: tr('المحفظة', 'Wallet')),
            const SizedBox(height: 19.3),
            BunoWalletCard(
              balance: tr('[الرصيد]', '[Balance]'),
              holder: tr('[اسم المستخدم]', '[User name]'),
              idLast4: '4417',
              level: MockTrust.current.name.text,
              onLevelTap: () => Navigator.of(context).pushNamed(AppRoutes.trust),
            ),
            const SizedBox(height: BunoSpace.s5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _QuickAction(
                  label: tr('اشحن', 'Top up'),
                  icon: const BunoIcon(BunoIcons.plus, color: BunoDark.on_primary),
                  primary: true,
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.topup),
                ),
                _QuickAction(
                  label: tr('كود خصم', 'Promo code'),
                  icon: const BunoLottieIcon(name: 'gift', color: BunoDark.text_primary),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.promo),
                ),
                _QuickAction(
                  label: tr('اشتراكي', 'My plan'),
                  icon: const BunoLottieIcon(name: 'star', color: BunoDark.text_primary),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.subscription),
                ),
                _QuickAction(
                  label: tr('الإيصالات', 'Receipts'),
                  icon: const BunoIcon(BunoIcons.receipt, color: BunoDark.text_primary),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.history),
                ),
              ],
            ),
            const SizedBox(height: 19.6),
            BunoSectionTitle(tr('طرق الدفع', 'Payment methods')),
            const SizedBox(height: 10.6),
            _PaymentMethodRow(label: tr('فيزا تنتهي بـ 4417', 'Visa ending in 4417'), primary: true),
            const SizedBox(height: 12),
            BunoDashedButton(
              label: tr('ضيف طريقة دفع', 'Add payment method'),
              onPressed: () => showBunoToast(context, tr('إضافة كارت هتيجي في الخطوة الجاية', 'Adding a card comes in the next step')),
            ),
            const SizedBox(height: 18),
            BunoSectionTitle(tr('آخر العمليات', 'Recent activity')),
            for (final t in _transactions) _TransactionRow(t),
          ],
        ),
      ),
    );
  }
}

/// Square shortcut under the card (reference 19); [primary] = green fill.
class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.label, required this.icon, required this.onTap, this.primary = false});

  final String label;
  final Widget icon;
  final VoidCallback onTap;
  final bool primary;

  static const _tile = 60.0;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: BunoPressable(
        onTap: onTap,
        semanticLabel: label,
        child: Column(
          children: [
            Container(
              width: _tile,
              height: _tile,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: primary ? BunoColors.primary : BunoDark.card,
                borderRadius: BorderRadius.circular(BunoRadius.lg),
                border: primary ? null : Border.all(color: BunoDark.border),
              ),
              child: icon,
            ),
            const SizedBox(height: BunoSpace.s2),
            Text(
              label,
              maxLines: 1,
              style: BunoType.caption.copyWith(
                fontWeight: primary ? FontWeight.w700 : FontWeight.w400,
                color: primary ? BunoDark.text_primary : BunoDark.text_secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodRow extends StatelessWidget {
  const _PaymentMethodRow({required this.label, this.primary = false});

  final String label;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: BunoDark.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BunoDark.border),
      ),
      child: Row(
        children: [
          const BunoIcon(BunoIcons.wallet, color: BunoDark.text_primary),
          const SizedBox(width: 12),
          Expanded(
            child: BunoText(
              label,
              style: BunoType.body.copyWith(fontSize: 13, fontWeight: FontWeight.w500, height: 1.2),
            ),
          ),
          if (primary)
            Text(
              tr('الأساسية', 'Primary'),
              style: BunoType.caption.copyWith(color: BunoColors.secondary),
            ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow(this.t);

  final WalletTransaction t;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66.5,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: BunoDark.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.title, style: BunoType.title.copyWith(fontSize: 16, fontWeight: FontWeight.w700, height: 1.3)),
                BunoText(
                  t.subtitle,
                  style: BunoType.caption.copyWith(fontWeight: FontWeight.w400, height: 1.4, color: BunoDark.text_secondary),
                ),
              ],
            ),
          ),
          Text(
            t.amount,
            style: BunoType.body.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: t.credit ? BunoColors.secondary : BunoDark.text_primary,
            ),
          ),
        ],
      ),
    );
  }
}

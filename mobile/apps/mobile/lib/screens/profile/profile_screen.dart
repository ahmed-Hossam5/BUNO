import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/mock_auth.dart';
import '../../data/mock_trust.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_bottom_nav.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_heart.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_tab_header.dart';
import '../auth/auth_scaffold.dart' show showBunoToast;
import '../wallet/wallet_screen.dart' show bunoNavItems;
import '../../l10n/buno_locale.dart';

/// Profile (حسابي). The Brand Board has no page for it, so it is composed
/// from the design-system components and the Wallet page's patterns:
/// same header, cards (radius 20, 1px border), section titles and nav.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _gutter = 24.0;
  static const _navIndex = 3;

  @override
  Widget build(BuildContext context) {
    void soon(String what) => showBunoToast(context, tr('$what هتكون جاهزة قريب', '$what is coming soon'));
    void open(String route) => Navigator.of(context).pushNamed(route);
    final email = MockAuth.pendingEmail.isEmpty ? 'name@email.com' : MockAuth.pendingEmail;

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
            BunoTabHeader(title: tr('حسابي', 'Profile')),
            const SizedBox(height: 19.3),
            _UserCard(name: tr('[الاسم]', '[Name]'), email: email, onEdit: () => open(AppRoutes.editProfile)),
            const SizedBox(height: 22),
            BunoSectionTitle(tr('الحساب', 'Account')),
            const SizedBox(height: 9),
            _MenuCard(rows: [
              _MenuRow(icon: BunoIcons.creditCard, label: tr('طرق الدفع', 'Payment methods'),
                  onTap: () => AppRoutes.goToTab(context, 2, _navIndex)),
              _MenuRow(icon: BunoIcons.history, label: tr('رحلاتي', 'My trips'), onTap: () => soon(tr('رحلاتي', 'My trips'))),
              _MenuRow(icon: BunoIcons.location, leading: const BunoHeart(on: false), label: tr('المفضلة', 'Favorites'), onTap: () => open(AppRoutes.favorites)),
              _MenuRow(icon: BunoIcons.notifications, lottie: 'bell', label: tr('الإشعارات', 'Notifications'), onTap: () => open(AppRoutes.notifications)),
              _MenuRow(icon: BunoIcons.language, lottie: 'globe', label: tr('اللغة', 'Language'), value: BunoLocale.nameOf(BunoLocale.current.value), onTap: () => open(AppRoutes.settings)),
              _MenuRow(icon: BunoIcons.check, lottie: 'shield', label: tr('مستواك في بونو', 'Your Buno level'), value: MockTrust.current.name.text, onTap: () => open(AppRoutes.trust)),
              _MenuRow(icon: BunoIcons.receipt, lottie: 'star', label: tr('الباقات', 'Plans'), onTap: () => open(AppRoutes.plans)),
              _MenuRow(icon: BunoIcons.plus, lottie: 'gift', label: tr('ادعي صاحبك', 'Invite a friend'), onTap: () => open(AppRoutes.referral)),
              _MenuRow(icon: BunoIcons.edit, lottie: 'settings', label: tr('الإعدادات', 'Settings'), onTap: () => open(AppRoutes.settings)),
            ]),
            const SizedBox(height: 22),
            BunoSectionTitle(tr('المساعدة', 'Help')),
            const SizedBox(height: 9),
            _MenuCard(rows: [
              _MenuRow(icon: BunoIcons.help, lottie: 'help', label: tr('المساعدة والدعم', 'Help and support'), onTap: () => open(AppRoutes.help)),
              _MenuRow(icon: BunoIcons.terms, label: tr('الشروط والأحكام', 'Terms and Conditions'), onTap: () => soon(tr('الشروط', 'Terms'))),
              _MenuRow(icon: BunoIcons.privacy, label: tr('سياسة الخصوصية', 'Privacy Policy'), onTap: () => soon(tr('سياسة الخصوصية', 'Privacy Policy'))),
            ]),
            const SizedBox(height: 16),
            _MenuCard(rows: [
              _MenuRow(
                icon: BunoIcons.logout,
                label: tr('تسجيل الخروج', 'Log out'),
                color: BunoColors.error,
                chevron: false,
                onTap: () => Navigator.of(context)
                    .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.name, required this.email, required this.onEdit});

  final String name;
  final String email;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BunoDark.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BunoDark.border),
      ),
      child: Row(
        children: [
          // Avatar (--size-avatar-lg is 72; 56 keeps the card compact).
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: BunoColors.primary_soft,
              border: Border.all(color: BunoColors.primary, width: 1.5),
            ),
            child: const BunoIcon(BunoIcons.profile, size: BunoSize.iconLg, color: BunoColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: BunoType.title.copyWith(fontWeight: FontWeight.w700, height: 1.3)),
                Text(
                  email,
                  textDirection: TextDirection.ltr,
                  style: BunoType.bodySm.copyWith(fontSize: 14, height: 1.3, color: BunoDark.text_secondary),
                ),
              ],
            ),
          ),
          BunoPressable(
            onTap: onEdit,
            semanticLabel: tr('تعديل', 'Edit'),
            child: Container(
              width: BunoSize.touchMin,
              height: BunoSize.touchMin,
              alignment: Alignment.center,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: BunoDark.elevated),
              child: const BunoLottieIcon(
                name: 'edit',
                size: BunoSize.iconSm,
                playKey: true,
                color: BunoDark.text_primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.rows});

  final List<_MenuRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BunoDark.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BunoDark.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsetsDirectional.only(start: 52),
                child: Divider(height: 1, thickness: 1, color: BunoDark.divider),
              ),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.color = BunoDark.text_primary,
    this.chevron = true,
    this.lottie,
    this.leading,
  });

  final BunoIcons icon;

  /// Animated icon in assets/lottie/ used in place of [icon]; plays once.
  final String? lottie;

  /// Drawn in place of [icon] and [lottie].
  final Widget? leading;
  final String label;
  final String? value;
  final Color color;
  final bool chevron;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = color == BunoDark.text_primary ? BunoDark.text_secondary : color;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (leading != null)
                  leading!
                else if (lottie != null)
                  BunoLottieIcon(name: lottie!, playKey: true, color: iconColor)
                else
                  BunoIcon(icon, color: iconColor),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label, style: BunoType.body.copyWith(fontSize: 16, color: color)),
                ),
                if (value != null) ...[
                  Text(value!, style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary)),
                  const SizedBox(width: 6),
                ],
                // "Forward" in RTL points left, which is the back glyph.
                if (chevron)
                  BunoIcon(
                    Directionality.of(context) == TextDirection.rtl ? BunoIcons.back : BunoIcons.forward,
                    size: BunoSize.iconSm,
                    color: BunoDark.text_disabled,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

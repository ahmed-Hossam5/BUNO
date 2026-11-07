import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/mock_settings.dart';
import '../../data/phone_battery.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_text.dart';
import '../auth/auth_scaffold.dart' show showBunoToast;
import 'account_scaffold.dart';
import '../../l10n/buno_locale.dart';

/// Settings (reference 21). Toggles live in [MockSettings] (memory only);
/// "تقليل الحركة" stops every BunoLottieIcon in the app.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _logout(BuildContext context) =>
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BunoDark.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BunoRadius.xl)),
        title: Text(tr('تمسح حسابك؟', 'Delete your account?'), style: BunoType.title),
        content: Text(
          tr('هتخسر رحلاتك ورصيدك ومش هتقدر ترجّعهم.', "You'll lose your trips and balance and can't get them back."),
          style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(tr('لأ', 'No'), style: BunoType.body.copyWith(color: BunoDark.text_primary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(tr('امسح', 'Delete'), style: BunoType.body.copyWith(fontWeight: FontWeight.w700, color: BunoColors.error)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    showBunoToast(context, tr('اتمسح الحساب', 'Account deleted'));
    _logout(context);
  }

  @override
  Widget build(BuildContext context) {
    return AccountScaffold(
      title: tr('الإعدادات', 'Settings'),
      children: [
        _ToggleRow(lottie: 'bell', label: tr('تذكير قبل الساعة الجاية', 'Remind me before the next hour'), value: MockSettings.hourReminder),
        accountDivider,
        _ToggleRow(lottie: 'battery_low', label: tr('تنبيه لما بطاريتي تقل', 'Alert me when my battery is low'), value: MockSettings.lowBatteryAlert),
        accountDivider,
        _ToggleRow(lottie: 'moon', label: tr('تقليل الحركة', 'Reduce motion'), value: MockSettings.reduceMotion),
        accountDivider,
        // Test rows: in debug and profile builds (profile runs on a phone
        // without the Mac), never in release.
        if (!kReleaseMode) ...[
          _ToggleRow(lottie: 'offline', label: tr('تجربة: من غير نت', 'Test: offline'), value: MockSettings.simulateOffline),
          accountDivider,
          _ToggleRow(lottie: 'calendar', label: tr('تجربة: أسبوع الامتحانات', 'Test: exam week'), value: MockSettings.examMode),
          accountDivider,
          _ToggleRow(lottie: 'star', label: tr('تجربة: ملخص الشهر', 'Test: month wrap-up'), value: MockSettings.wrappedNow),
          accountDivider,
          const _BatteryDebugRow(),
          accountDivider,
          _SettingsRow(
            lottie: 'settings',
            label: tr('دخول كفريق التشغيل', 'Enter as the ops team'),
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.ops),
          ),
          accountDivider,
        ],
        const _LanguageRow(),
        accountDivider,
        _SettingsRow(
          lottie: 'shield',
          label: tr('الخصوصية والشروط', 'Privacy and terms'),
          onTap: () => showBunoToast(context, tr('الخصوصية والشروط هتكون جاهزة قريب', 'Privacy and terms are coming soon')),
        ),
        accountDivider,
        _SettingsRow(
          lottie: 'chat_typing',
          label: tr('كلّمنا على واتساب', 'Message us on WhatsApp'),
          onTap: () => showBunoToast(context, tr('بنفتح واتساب الدعم…', 'Opening support on WhatsApp…')),
        ),
        accountDivider,
        const SizedBox(height: BunoSpace.s7),
        _SettingsRow(icon: BunoIcons.logout, label: tr('خروج', 'Log out'), onTap: () => _logout(context)),
        accountDivider,
        _SettingsRow(
          lottie: 'trash',
          label: tr('حذف الحساب', 'Delete account'),
          color: BunoColors.error,
          onTap: () => _confirmDelete(context),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    this.lottie,
    this.icon,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
    this.color = BunoDark.text_primary,
  });

  /// Animated icon in assets/lottie/; [icon] is used instead when set.
  final String? lottie;
  final BunoIcons? icon;
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color color;

  static const _height = 64.0;

  @override
  Widget build(BuildContext context) {
    final iconColor = color == BunoDark.text_primary ? BunoDark.text_secondary : color;
    return Semantics(
      button: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: _height,
          child: Row(
            children: [
              if (icon != null)
                BunoIcon(icon!, size: BunoSize.iconSm, color: iconColor)
              else
                BunoLottieIcon(name: lottie!, size: BunoSize.iconSm, playKey: true, color: iconColor),
              const SizedBox(width: BunoSpace.s3),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BunoType.body.copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: color),
                ),
              ),
              if (value != null)
                Text(value!, style: BunoType.bodySm.copyWith(fontWeight: FontWeight.w600, color: BunoDark.text_secondary)),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// Debug-only "تجربة: البطارية": pick a fixed phone battery reading
/// ([PhoneBattery.debugOverride]) or the real one.
class _BatteryDebugRow extends StatelessWidget {
  const _BatteryDebugRow();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BatteryDebug>(
      valueListenable: PhoneBattery.debugOverride,
      builder: (context, current, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingsRow(lottie: 'battery_fill', label: tr('تجربة: البطارية', 'Test: battery'), value: current.label),
          Padding(
            padding: const EdgeInsets.only(bottom: BunoSpace.s4),
            child: Wrap(
              spacing: BunoSpace.s2,
              runSpacing: BunoSpace.s2,
              children: [
                for (final option in BatteryDebug.values)
                  _Choice(
                    label: option.label,
                    selected: option == current,
                    onTap: () => PhoneBattery.debugOverride.value = option,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "اللغة" / "Language": Arabic (right-to-left) or English
/// (left-to-right). Switching relays out the whole app at once.
class _LanguageRow extends StatelessWidget {
  const _LanguageRow();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: BunoLocale.current,
      builder: (context, current, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingsRow(lottie: 'globe', label: tr('اللغة', 'Language'), value: BunoLocale.nameOf(current)),
          Padding(
            padding: const EdgeInsets.only(bottom: BunoSpace.s4),
            child: Wrap(
              spacing: BunoSpace.s2,
              runSpacing: BunoSpace.s2,
              children: [
                for (final locale in BunoLocale.supported)
                  _Choice(
                    label: BunoLocale.nameOf(locale),
                    selected: locale == current,
                    onTap: () => BunoLocale.current.value = locale,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One option pill: green when [selected].
class _Choice extends StatelessWidget {
  const _Choice({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: BunoPressable(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: BunoSize.touchMin),
          padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s4),
          decoration: BoxDecoration(
            color: selected ? BunoColors.primary : null,
            borderRadius: BorderRadius.circular(BunoRadius.pill),
            border: Border.all(color: selected ? BunoColors.primary : BunoDark.border),
          ),
          // Hugs the label; centred in the 44pt height.
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: BunoText(
              label,
              style: BunoType.bodySm.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? BunoDark.on_primary : BunoDark.text_secondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.lottie, required this.label, required this.value});

  final String lottie;
  final String label;
  final ValueNotifier<bool> value;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: value,
      builder: (context, on, _) => MergeSemantics(
        child: _SettingsRow(
          lottie: lottie,
          label: label,
          onTap: () => value.value = !on,
          trailing: Switch(
            value: on,
            onChanged: (v) => value.value = v,
            thumbColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? BunoDark.on_primary : BunoDark.text_secondary,
            ),
            trackColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? BunoColors.primary : BunoDark.border,
            ),
            trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
          ),
        ),
      ),
    );
  }
}

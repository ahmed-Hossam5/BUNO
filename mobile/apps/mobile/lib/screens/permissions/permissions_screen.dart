import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/mock_first_run.dart';
import '../../data/user_location.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_logo.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_text_link.dart';
import '../../l10n/buno_locale.dart';

/// /permissions (reference 36_permissions), after sign-up's code check:
/// location, notifications and camera switches with a one-line reason each
/// ([MockPermissions], memory only). Turning location on asks the OS for
/// "while using the app" ([UserLocation.requestAccess]); the others aren't
/// asked of the OS yet. "كمّل" and "بعدين" both go on to /verify-uni.
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  static const _gutter = 22.0;

  @override
  void initState() {
    super.initState();
    // The location switch shows the real permission.
    UserLocation.shared.refresh().then((_) {
      MockPermissions.location.value = UserLocation.shared.access == LocationAccess.granted;
    });
  }

  Future<void> _setLocation(bool on) async {
    if (!on) {
      MockPermissions.location.value = false;
      return;
    }
    MockPermissions.location.value = await UserLocation.shared.requestAccess();
  }

  void _next(BuildContext context) => Navigator.of(context).pushNamed(AppRoutes.verifyUni);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_gutter, 18, _gutter, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                height: BunoSize.touchMin,
                child: Align(alignment: AlignmentDirectional.centerStart, child: BunoLogo(height: 26.9)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: BunoSpace.s5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(tr('إذنين بس', 'Just two permissions'), style: BunoType.h1),
                      const SizedBox(height: BunoSpace.s1),
                      Text(
                        tr('وتقدر تغيّرهم في أي وقت.', 'You can change them any time.'),
                        style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: BunoSpace.s6),
                      _PermissionCard(
                        lottie: 'pin',
                        title: tr('الموقع', 'Location'),
                        reason: tr('عشان نوريك أقرب محطة', 'To show you the nearest station'),
                        value: MockPermissions.location,
                        onChanged: _setLocation,
                      ),
                      const SizedBox(height: BunoSpace.s3),
                      _PermissionCard(
                        lottie: 'bell',
                        title: tr('الإشعارات', 'Notifications'),
                        reason: tr('تذكير قبل الساعة الجاية', 'A reminder before the next hour'),
                        value: MockPermissions.notifications,
                      ),
                      const SizedBox(height: BunoSpace.s3),
                      _PermissionCard(
                        lottie: 'camera',
                        title: tr('الكاميرا', 'Camera'),
                        reason: tr('لمسح الـ QR بس', 'Only for scanning QR codes'),
                        value: MockPermissions.camera,
                      ),
                    ],
                  ),
                ),
              ),
              BunoPrimaryButton(label: tr('كمّل', 'Continue'), onPressed: () => _next(context)),
              const SizedBox(height: BunoSpace.s2),
              BunoTextLink(tr('بعدين', 'Later'), onTap: () => _next(context)),
            ],
          ),
        ),
      ),
    );
  }
}

/// One permission: icon tile, title and reason, switch. Green outline while on.
class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.lottie,
    required this.title,
    required this.reason,
    required this.value,
    this.onChanged,
  });

  final String lottie;
  final String title;
  final String reason;
  final ValueNotifier<bool> value;

  /// Instead of setting [value] directly.
  final ValueChanged<bool>? onChanged;

  void _set(bool on) => onChanged == null ? value.value = on : onChanged!(on);

  static const _tile = 44.0;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.of(context).disableAnimations ? Duration.zero : BunoMotion.base;
    return ValueListenableBuilder<bool>(
      valueListenable: value,
      builder: (context, on, _) => MergeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _set(!on),
          child: AnimatedContainer(
            duration: duration,
            padding: const EdgeInsets.all(BunoSpace.s4),
            decoration: BoxDecoration(
              color: BunoDark.card,
              borderRadius: BorderRadius.circular(BunoRadius.lg),
              border: Border.all(
                color: on ? BunoColors.primary : BunoDark.card,
                width: BunoStroke.defaultWidth,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: duration,
                  width: _tile,
                  height: _tile,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: on ? BunoColors.primary_soft : BunoDark.elevated,
                    borderRadius: BorderRadius.circular(BunoRadius.md),
                  ),
                  child: BunoLottieIcon(
                    name: lottie,
                    size: BunoSize.iconSm,
                    playKey: on,
                    color: on ? BunoColors.primary : BunoDark.text_primary,
                  ),
                ),
                const SizedBox(width: BunoSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: BunoType.title),
                      Text(
                        reason,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BunoType.caption.copyWith(color: BunoDark.text_secondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: BunoSpace.s2),
                Switch(
                  value: on,
                  onChanged: _set,
                  thumbColor: WidgetStateProperty.resolveWith(
                    (s) => s.contains(WidgetState.selected) ? BunoDark.on_primary : BunoDark.text_secondary,
                  ),
                  trackColor: WidgetStateProperty.resolveWith(
                    (s) => s.contains(WidgetState.selected) ? BunoColors.primary : BunoDark.border,
                  ),
                  trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

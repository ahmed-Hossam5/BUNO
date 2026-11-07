import 'package:flutter/widgets.dart';

import '../../data/phone_battery.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_logo.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_pressable.dart';
import '../../l10n/buno_locale.dart';

/// Logo (or, with [onSearch], the search field) on the start side (right
/// in RTL); battery status and profile on the end side (left in RTL).
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key, required this.battery, this.onProfile, this.onSearch});

  /// The phone's live battery reading.
  final BatteryReading battery;
  final VoidCallback? onProfile;

  /// Shows "دوّر على محطة أو مكان" in place of the logo; tapping it opens
  /// the full-screen search (reference 107).
  final VoidCallback? onSearch;

  /// Logo box height that makes the wordmark ink 59pt wide, as in the reference.
  static const _logoHeight = 26.9;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // Pull the SVG's built-in right padding out so the ring's outer edge sits
    // on the content edge, like the search field below it.
    final logoNudge = BunoLogo.inkEndInset * _logoHeight / 120;
    return SizedBox(
      height: BunoSize.touchMin,
      child: Row(
        children: [
          if (onSearch != null)
            Expanded(child: _SearchButton(onTap: onSearch!))
          else ...[
            Transform.translate(
              offset: Offset(rtl ? logoNudge : -logoNudge, 0),
              child: const BunoLogo(height: _logoHeight),
            ),
            const Spacer(),
          ],
          if (onSearch != null) const SizedBox(width: 8),
          _BatteryStatus(reading: battery),
          const SizedBox(width: 8),
          _ProfileButton(onTap: onProfile),
        ],
      ),
    );
  }
}

/// Looks like a search field; opens the search screen.
class _SearchButton extends StatelessWidget {
  const _SearchButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hint = tr('دوّر على محطة أو مكان', 'Search a station or place');
    return BunoPressable(
      onTap: onTap,
      semanticLabel: hint,
      child: Container(
        height: BunoSize.touchMin,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: BunoDark.card,
          borderRadius: BorderRadius.circular(BunoRadius.pill),
          border: Border.all(color: BunoDark.border, width: BunoStroke.hairline),
        ),
        child: Row(
          children: [
            const BunoIcon(BunoIcons.search, size: BunoSize.iconSm, color: BunoDark.text_secondary),
            const SizedBox(width: BunoSpace.s2),
            Expanded(
              child: ExcludeSemantics(
                child: Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return BunoPressable(
      onTap: onTap ?? () {},
      semanticLabel: tr('حسابي', 'Profile'),
      // 44pt touch target around the 40pt visual.
      child: SizedBox.square(
        dimension: BunoSize.touchMin,
        child: Center(
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: BunoDark.card,
              border: Border.all(color: BunoDark.border, width: BunoStroke.hairline),
            ),
            child: const BunoIcon(BunoIcons.profile, color: BunoDark.text_primary),
          ),
        ),
      ),
    );
  }
}

/// Phone battery status pill: live percentage in Sora, warning colour at
/// 20% or less, charging bolt while plugged in, "--%" when unreadable.
class _BatteryStatus extends StatelessWidget {
  const _BatteryStatus({required this.reading});

  final BatteryReading reading;

  @override
  Widget build(BuildContext context) {
    final percent = reading.percent;
    final low = percent != null && percent <= 20 && !reading.charging;
    final color = percent == null
        ? BunoDark.text_secondary
        : low
            ? BunoColors.warning
            : BunoColors.secondary;
    final icon = reading.charging
        ? BunoIcons.charging
        : percent == null
            ? BunoIcons.battery
            : percent <= 20
                ? BunoIcons.batteryLow
                : percent >= 80
                    ? BunoIcons.batteryFull
                    : BunoIcons.battery;
    final semantics = percent == null
        ? tr('شحن موبايلك مش معروف', "Your phone's charge is unknown")
        : reading.charging
            ? tr('شحن موبايلك $percent%، بيشحن', "Your phone's charge is $percent%, charging")
            : tr('شحن موبايلك $percent%', "Your phone's charge is $percent%");
    return Semantics(
      label: semantics,
      liveRegion: true,
      excludeSemantics: true,
      child: Container(
        height: 32,
        padding: const EdgeInsetsDirectional.only(start: 10, end: 12),
        decoration: BoxDecoration(
          color: BunoDark.card,
          borderRadius: BorderRadius.circular(BunoRadius.pill),
          border: Border.all(color: BunoDark.border, width: BunoStroke.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon == BunoIcons.batteryLow)
              BunoLottieIcon(
                name: 'battery_low',
                size: BunoSize.iconSm,
                loop: true,
                color: color,
              )
            else
              BunoIcon(icon, size: BunoSize.iconSm, color: color),
            const SizedBox(width: 4),
            Text(
              percent == null ? '--%' : '$percent%',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontFamily: BunoFonts.sora,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                height: 1,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

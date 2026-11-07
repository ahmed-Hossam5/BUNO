import 'package:flutter/widgets.dart';

import '../theme/buno_tokens.dart';
import '../theme/buno_tokens_ext.dart';
import 'buno_bay_tile.dart' show chargeColor;
import '../l10n/buno_locale.dart';

/// Availability state of a station, which drives the marker ring colour.
enum StationAvailability { available, low, none }

extension on StationAvailability {
  Color get ringColor => switch (this) {
        StationAvailability.available => BunoColors.secondary,
        StationAvailability.low => BunoColors.warning,
        StationAvailability.none => BunoDark.text_disabled,
      };
}

/// Nearby (unselected) station marker: 30pt dark disc with a 3pt ring.
class StationMarker extends StatelessWidget {
  const StationMarker({
    super.key,
    required this.availability,
    this.onTap,
    this.size = 30,
    this.strokeWidth = BunoStroke.emphasis,
  });

  final StationAvailability availability;
  final VoidCallback? onTap;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: tr('محطة بونو', 'Buno station'),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        // 44pt hit area around the 30pt visual.
        child: SizedBox.square(
          dimension: BunoSize.touchMin,
          child: Center(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BunoDark.background,
                border: Border.all(
                  color: availability.ringColor,
                  width: strokeWidth,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Selected station: a Buno-green ring on a soft green halo, showing the
/// ready count in Sora (Home) or, when [readyCount] is null, a solid centre
/// dot (onboarding illustration).
class SelectedStationMarker extends StatelessWidget {
  const SelectedStationMarker({
    super.key,
    this.readyCount,
    this.size = 40,
    this.haloSize = 60,
    this.strokeWidth = BunoStroke.emphasis,
    this.haloOpacity = 0.18,
    this.dotSize = 15,
  });

  final int? readyCount;
  final double size;
  final double haloSize;
  final double strokeWidth;
  final double haloOpacity;
  final double dotSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: readyCount == null ? tr('المحطة المختارة', 'Selected station') : tr('المحطة المختارة، $readyCount جاهزين', 'Selected station, $readyCount ready'),
      child: Container(
        width: haloSize,
        height: haloSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: BunoColors.primary.withValues(alpha: haloOpacity),
        ),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: BunoDark.background,
            border: Border.all(color: BunoColors.primary, width: strokeWidth),
          ),
          child: readyCount == null
              ? Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: BunoColors.primary,
                  ),
                )
              : Text(
                  '$readyCount',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontFamily: BunoFonts.sora,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1,
                    color: BunoDark.text_primary,
                  ),
                ),
        ),
      ),
    );
  }
}

/// The user's position: white dot with a dark outline.
class UserLocationMarker extends StatelessWidget {
  const UserLocationMarker({super.key, this.size = 21, this.borderWidth = BunoStroke.emphasis});

  final double size;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tr('موقعك', 'Your location'),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Pure white in the reference (#FFFFFF), brighter than text-primary.
          color: const Color(0xFFFFFFFF),
          border: Border.all(color: BunoDark.background, width: borderWidth),
        ),
      ),
    );
  }
}

/// Station pin on /stations: a pill with the station's top [charge]
/// ([Station.topCharge]), ringed in [chargeColor]; a grey "—" when the
/// station is empty. [selected] fills it; [closed] greys it out.
class StationChargePin extends StatelessWidget {
  const StationChargePin({
    super.key,
    required this.charge,
    this.selected = false,
    this.closed = false,
    this.onTap,
  });

  final int? charge;
  final bool selected;
  final bool closed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colour = charge == null || closed ? BunoDark.text_disabled : chargeColor(charge);
    final ink = selected ? BunoDark.on_primary : colour;
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: closed
          ? tr('محطة بونو، مقفولة دلوقتي', 'Buno station, closed now')
          : charge == null
              ? tr('محطة بونو، فاضية', 'Buno station, empty')
              : tr('محطة بونو، أعلى شحن $charge%', 'Buno station, top charge $charge%'),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        // 44pt tall hit area around the pill.
        child: SizedBox(
          height: BunoSize.touchMin,
          child: Center(
            child: AnimatedContainer(
              duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ? Duration.zero : BunoMotion.fast,
              height: selected ? 34 : 28,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: selected ? colour : BunoDark.background,
                borderRadius: BorderRadius.circular(BunoRadius.pill),
                border: Border.all(color: colour, width: BunoStroke.hairline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                textDirection: TextDirection.ltr,
                children: [
                  Text(
                    charge == null ? '—' : '$charge%',
                    style: TextStyle(
                      fontFamily: BunoFonts.sora,
                      fontWeight: FontWeight.w700,
                      fontSize: selected ? 14 : 12,
                      height: 1,
                      color: ink,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: ink),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

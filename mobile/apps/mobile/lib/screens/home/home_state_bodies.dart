import 'package:flutter/material.dart';

import '../../data/mock_rental.dart';
import '../../data/mock_search.dart';
import '../../data/mock_station_info.dart';
import '../../l10n/buno_locale.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_bay_tile.dart' show chargeColor;
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_charge_ring.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_text.dart';
import '../../widgets/buno_text_link.dart';

/// "التحرير" from "محطة التحرير", "Tahrir" from "Tahrir Station".
String shortStationName(String name) => name.replaceFirst('محطة ', '').replaceFirst(' Station', '');

/// "ل" joined to a name: "للتحرير" (ل + التحرير), "لمدينة نصر".
String _to(String name) => name.startsWith('ال') ? 'ل${name.substring(1)}' : 'ل$name';

TextStyle get _secondary => BunoType.bodySm.copyWith(color: BunoDark.text_secondary);

/// A bay is held (reference 112): where and which bay, the countdown in an
/// amber ring, "وصلت؟ امسح", directions and cancel.
class HomeReservedBody extends StatelessWidget {
  const HomeReservedBody({
    super.key,
    required this.reservation,
    required this.remaining,
    required this.hold,
    required this.onScan,
    required this.onDirections,
    required this.onCancel,
    required this.onCountdown,
  });

  final Reservation reservation;
  final Duration remaining;
  final Duration hold;
  final VoidCallback onScan;
  final VoidCallback onDirections;
  final VoidCallback onCancel;

  /// Opens /reserved.
  final VoidCallback onCountdown;

  @override
  Widget build(BuildContext context) {
    final station = reservation.station;
    final charge = station.bays[reservation.bayIndex];
    final m = remaining.inMinutes, s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    final heading = BunoType.h2.copyWith(fontWeight: FontWeight.w700);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BunoText(
                    tr('محجوزك في ${shortStationName(station.name)}', 'Held at ${shortStationName(station.name)}'),
                    maxLines: 1,
                    style: _secondary,
                  ),
                  Row(
                    children: [
                      Flexible(child: BunoText(tr('خانة #${reservation.bayIndex + 1}', 'Bay #${reservation.bayIndex + 1}'), maxLines: 1, style: heading)),
                      if (charge != null) ...[
                        BunoText(' · ', style: heading),
                        BunoText('$charge%', style: heading.copyWith(color: chargeColor(charge))),
                      ],
                    ],
                  ),
                  BunoText(
                    tr('${station.walkMinutes} د مشي · الحجز بيخلص لو موصلتش', '${station.walkMinutes} min walk · the hold ends if you don\'t make it'),
                    maxLines: 2,
                    style: BunoType.caption.copyWith(color: BunoDark.text_secondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: BunoSpace.s3),
            BunoPressable(
              onTap: onCountdown,
              semanticLabel: tr('فاضل على الحجز $m دقيقة', 'Hold ends in $m minutes'),
              child: BunoChargeRing(
                progress: hold == Duration.zero ? 0 : remaining.inMilliseconds / hold.inMilliseconds,
                size: 68,
                strokeWidth: 6,
                color: BunoColors.warning,
                child: Text(
                  '$m:$s',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontFamily: BunoFonts.sora,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    height: 1,
                    color: BunoDark.text_primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: BunoSpace.s4),
        Row(
          children: [
            Expanded(child: BunoPrimaryButton(label: tr('وصلت؟ امسح', 'Here? Scan'), icon: BunoIcons.scan, onPressed: onScan)),
            const SizedBox(width: BunoSpace.s3),
            Expanded(
              child: BunoSecondaryButton(
                label: tr('الاتجاهات', 'Directions'),
                icon: BunoIcons.location,
                height: BunoSize.buttonLg,
                compact: true,
                onPressed: onDirections,
              ),
            ),
          ],
        ),
        BunoTextLink(tr('الغي الحجز', 'Cancel reservation'), onTap: onCancel),
      ],
    );
  }
}

/// "مقفولة دلوقتي" outlined in grey.
class ClosedPill extends StatelessWidget {
  const ClosedPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s3, vertical: BunoSpace.s1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BunoRadius.pill),
        border: Border.all(color: BunoDark.text_disabled, width: BunoStroke.hairline),
      ),
      child: BunoText(
        tr('مقفولة دلوقتي', 'Closed now'),
        maxLines: 1,
        style: BunoType.caption.copyWith(fontWeight: FontWeight.w600, color: BunoDark.text_secondary),
      ),
    );
  }
}

/// A closed station picked on the map (reference 113): when it opens and
/// the nearest open station, with a button to go there.
class HomeClosedBody extends StatelessWidget {
  const HomeClosedBody({super.key, required this.station, required this.open, required this.onTakeMe});

  final Station station;

  /// Nearest open station with a ready unit; null when none is open.
  final Station? open;
  final ValueChanged<Station> onTakeMe;

  @override
  Widget build(BuildContext context) {
    final other = open;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: BunoText(station.name, maxLines: 1, style: BunoType.h2.copyWith(fontWeight: FontWeight.w700))),
            const SizedBox(width: BunoSpace.s2),
            const ClosedPill(),
          ],
        ),
        const SizedBox(height: BunoSpace.s2),
        BunoText(
          tr(
            '${stationInfo(station).opensLabel(stationClock())}. الوحدات اللي جوه مش متاحة لحد ما المكان يفتح.',
            '${stationInfo(station).opensLabel(stationClock())}. The units inside can\'t be taken until it opens.',
          ),
          maxLines: 3,
          style: _secondary,
        ),
        if (other != null) ...[
          const SizedBox(height: BunoSpace.s4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s4, vertical: BunoSpace.s3),
            decoration: BoxDecoration(color: BunoDark.elevated, borderRadius: BorderRadius.circular(BunoRadius.lg)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BunoText(tr('أقرب محطة مفتوحة', 'Nearest open station'), style: BunoType.caption.copyWith(color: BunoDark.text_secondary)),
                      BunoText(
                        tr('${other.name} · ${other.walkMinutes} د', '${other.name} · ${other.walkMinutes} min'),
                        maxLines: 1,
                        style: BunoType.body.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: BunoSpace.s2),
                Semantics(
                  label: tr('${other.readyCount} جاهزين', '${other.readyCount} ready'),
                  excludeSemantics: true,
                  child: BunoText('${other.readyCount}', style: BunoType.h2.copyWith(color: BunoColors.primary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: BunoSpace.s4),
          BunoPrimaryButton(
            label: tr('ودّيني ${_to(shortStationName(other.name))}', 'Take me to ${shortStationName(other.name)}'),
            icon: BunoIcons.location,
            onPressed: () => onTakeMe(other),
          ),
        ],
      ],
    );
  }
}

/// Location refused or off (reference 110): why it is needed, a button to
/// turn it on, and search by name instead.
class HomeLocationOffBody extends StatelessWidget {
  const HomeLocationOffBody({super.key, required this.onEnable, required this.onSearch});

  final VoidCallback onEnable;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: BunoColors.warning.withValues(alpha: 0.12)),
              child: const BunoIcon(BunoIcons.location, color: BunoColors.warning),
            ),
            const SizedBox(width: BunoSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BunoText(
                    tr('شغّل الموقع عشان نوريك الأقرب ليك', 'Turn on location to see what\'s nearest'),
                    maxLines: 2,
                    style: BunoType.title.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: BunoSpace.s1),
                  BunoText(
                    tr('بنستخدمه بس وانت فاتح التطبيق، عشان نحسب المشي لكل محطة.',
                        'Only while the app is open, to work out the walk to each station.'),
                    maxLines: 3,
                    style: _secondary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: BunoSpace.s4),
        BunoPrimaryButton(label: tr('شغّل الموقع', 'Turn on location'), icon: BunoIcons.location, onPressed: onEnable),
        BunoTextLink(tr('أو دوّر على محطة بالاسم', 'Or search a station by name'), onTap: onSearch),
      ],
    );
  }
}

/// The nearest station is over [HomeNothingNearBody.farMeters] away
/// (reference 111): how far, directions, and "بلّغني".
class HomeNothingNearBody extends StatelessWidget {
  const HomeNothingNearBody({
    super.key,
    required this.station,
    required this.meters,
    required this.notifyOn,
    required this.onDirections,
    required this.onNotify,
  });

  /// Beyond this, home says there is no station nearby.
  static const farMeters = 3000.0;

  final Station station;
  final double meters;
  final bool notifyOn;
  final VoidCallback onDirections;
  final VoidCallback onNotify;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BunoText(tr('مفيش محطة قريبة منك', 'No station near you'), style: BunoType.caption.copyWith(color: BunoDark.text_secondary)),
        BunoText(
          tr('أقرب محطة: ${shortStationName(station.name)}', 'Nearest station: ${shortStationName(station.name)}'),
          maxLines: 2,
          style: BunoType.h3.copyWith(fontWeight: FontWeight.w700),
        ),
        BunoText(
          tr('${distanceLabel(meters)} تقريبًا · ${station.readyCount} وحدات جاهزة',
              'About ${distanceLabel(meters)} · ${station.readyCount} units ready'),
          maxLines: 1,
          style: _secondary,
        ),
        const SizedBox(height: BunoSpace.s4),
        Row(
          children: [
            Expanded(child: BunoPrimaryButton(label: tr('الاتجاهات', 'Directions'), icon: BunoIcons.location, onPressed: onDirections)),
            const SizedBox(width: BunoSpace.s3),
            Expanded(
              child: BunoSecondaryButton(
                label: notifyOn ? tr('هنبلّغك', 'We\'ll tell you') : tr('بلّغني', 'Notify me'),
                icon: notifyOn ? BunoIcons.check : BunoIcons.notifications,
                iconColor: notifyOn ? BunoColors.primary : BunoDark.text_secondary,
                height: BunoSize.buttonLg,
                compact: true,
                onPressed: onNotify,
              ),
            ),
          ],
        ),
        const SizedBox(height: BunoSpace.s3),
        BunoText(
          tr('«بلّغني» بيبعتلك إشعار أول ما محطة تفتح على بعد أقل من كيلو منك.',
              '"Notify me" sends you a notification as soon as a station opens less than a kilometre away.'),
          maxLines: 3,
          textAlign: TextAlign.center,
          style: BunoType.caption.copyWith(color: BunoDark.text_secondary),
        ),
      ],
    );
  }
}

/// "بونو بيشتغل إزاي؟" (reference 109): three steps and "فهمت".
Future<void> showHowItWorks(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: BunoDark.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(BunoRadius.xxl)),
    ),
    builder: (_) => const HowItWorksSheet(),
  );
}

class HowItWorksSheet extends StatelessWidget {
  const HowItWorksSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (BunoIcons.location, tr('روح لأقرب محطة', 'Go to the nearest station'),
          tr('الخريطة بتوريك فيها كام وحدة جاهزة.', 'The map shows how many units are ready there.')),
      (BunoIcons.scan, tr('امسح الـ QR اللي عليها', 'Scan its QR code'),
          tr('السعر بيظهرلك قبل ما توافق، والخانة بتفتح لوحدها.', 'You see the price before you agree, and the bay opens by itself.')),
      (BunoIcons.walk, tr('خدها وامشي، ورجّعها في أي محطة', 'Take it, go, and return it at any station'),
          tr('الكابل جوه الوحدة. بتدفع على الوقت اللي استخدمتها فيه بس.', 'The cable is inside the unit. You only pay for the time you used it.')),
    ];
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, BunoSpace.s3, 22, BunoSpace.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: BunoDark.text_disabled, borderRadius: BorderRadius.circular(BunoRadius.pill)),
              ),
            ),
            const SizedBox(height: BunoSpace.s5),
            BunoText(tr('بونو بيشتغل إزاي؟', 'How does Buno work?'), textAlign: TextAlign.center, style: BunoType.h2),
            const SizedBox(height: BunoSpace.s4),
            for (final (icon, title, body) in steps)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: BunoSpace.s2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: BunoColors.primary_soft),
                      child: BunoIcon(icon, color: BunoColors.primary),
                    ),
                    const SizedBox(width: BunoSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BunoText(title, style: BunoType.title.copyWith(fontWeight: FontWeight.w700)),
                          BunoText(body, style: _secondary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: BunoSpace.s4),
            BunoPrimaryButton(label: tr('فهمت', 'Got it'), onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }
}

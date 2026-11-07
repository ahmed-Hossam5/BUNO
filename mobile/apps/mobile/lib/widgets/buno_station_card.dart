import 'package:flutter/widgets.dart';

import '../theme/buno_tokens.dart';
import '../theme/buno_tokens_ext.dart';
import 'buno_chip.dart';
import 'buno_text.dart';
import '../l10n/buno_locale.dart';

/// Data shown on the station card. Copy is kept as the placeholders in the
/// reference (`[price]` etc.) — real pricing is still an open item in the
/// design-system README.
class StationInfo {
  const StationInfo({
    required this.name,
    required this.meta,
    required this.readyCount,
    required this.highestCharge,
    required this.chips,
  });

  final String name;
  final String meta;
  final int readyCount;
  final int highestCharge;
  final List<String> chips;
}

/// Station card content (components.md "Station card"): name, distance +
/// walking time, ready count with a mint dot, highest available charge,
/// price chips.
class BunoStationCard extends StatelessWidget {
  const BunoStationCard({super.key, required this.station});

  final StationInfo station;

  static const _statsWidth = 80.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    station.name,
                    style: BunoType.h3.copyWith(fontWeight: FontWeight.w700, height: 1.3),
                  ),
                  const SizedBox(height: 4),
                  BunoText(
                    station.meta,
                    style: BunoType.bodySm.copyWith(
                      height: 17 / 13,
                      color: BunoDark.text_secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: _statsWidth,
              child: _Stats(
                readyCount: station.readyCount,
                highestCharge: station.highestCharge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final c in station.chips) BunoChip(c)],
        ),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.readyCount, required this.highestCharge});

  final int readyCount;
  final int highestCharge;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(height: 1.5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: BunoColors.secondary,
              ),
            ),
            const SizedBox(width: 8),
            BunoText(
              tr('$readyCount جاهزين', '$readyCount ready'),
              style: BunoType.caption.copyWith(
                height: 1.3,
                fontWeight: FontWeight.w600,
                color: BunoColors.secondary,
              ),
              numberStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 3),
        SizedBox(
          width: double.infinity,
          child: BunoText(
            tr('أعلى شحن $highestCharge%', 'Top charge $highestCharge%'),
            style: BunoType.caption.copyWith(
              fontWeight: FontWeight.w400,
              height: 15 / 12,
              color: BunoDark.text_secondary,
            ),
          ),
        ),
      ],
    );
  }
}

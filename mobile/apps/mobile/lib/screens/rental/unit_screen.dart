import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/mock_rental.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_info_row.dart';
import '../../widgets/buno_text.dart';
import '../../widgets/buno_title_bar.dart';
import 'active_rental_screen.dart' show spokenDuration;
import '../../l10n/buno_locale.dart';

/// The unit in hand (reference 41): its RFID tag, charge, temperature, where
/// it came from and its status. Reads [rentalSession]; without a rental it
/// shows the reference's mock unit.
class UnitScreen extends StatelessWidget {
  const UnitScreen({super.key});

  static const _mockUnit = UnitTag('PB-0417', 31);

  @override
  Widget build(BuildContext context) {
    final s = rentalSession;
    final renting = s.unit != null;
    final unit = s.unit ?? _mockUnit;
    final charge = renting ? s.unitCharge! : 78;
    final code = renting ? s.station!.code : 'BUN-01';
    final bay = renting ? s.bayIndex! + 1 : 6;
    final duration = s.duration ?? const Duration(hours: 1, minutes: 12);
    final kept = s.state == RentalState.kept;
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BunoTitleBar(tr('الوحدة اللي معاك', 'Your unit')),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: BunoSpace.s5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TagCard(id: unit.id, charge: charge),
                      const SizedBox(height: BunoSpace.s3),
                      BunoInfoRow(tr('الشحن', 'Charge'), '$charge%', divider: true),
                      BunoInfoRow(tr('الحرارة', 'Temperature'), '${unit.temperature}°', divider: true),
                      BunoInfoRow(tr('خدتها من', 'Picked up at'), tr('$code · خانة $bay', '$code · bay $bay'), divider: true),
                      BunoInfoRow(tr('الحالة', 'Status'), kept ? tr('بقت بتاعتك', 'Yours now') : tr('معاك · ${spokenDuration(duration)}', 'With you · ${spokenDuration(duration)}')),
                      const SizedBox(height: BunoSpace.s4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const BunoIcon(BunoIcons.scan, size: BunoSize.iconSm, color: BunoColors.primary),
                          const SizedBox(width: BunoSpace.s2),
                          Expanded(
                            child: BunoText(
                              tr('المحطة بتقرا الشريحة وانت بترجّعها، فبتتسجل باسمك بالظبط.', 'The station reads the chip when you return it, so it is logged to you exactly.'),
                              style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (!kept)
                BunoPrimaryButton(
                  label: tr('رجّعها', 'Return it'),
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.returnUnit),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Unit id read from the tag, next to a battery filled to [charge].
class _TagCard extends StatelessWidget {
  const _TagCard({required this.id, required this.charge});

  final String id;
  final int charge;

  static const _cellWidth = 60.0;
  static const _cellHeight = 84.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BunoSpace.s5),
      decoration: BoxDecoration(
        color: BunoDark.card,
        borderRadius: BorderRadius.circular(BunoRadius.xl),
        border: Border.all(color: BunoDark.border),
      ),
      child: Row(
        children: [
          Semantics(
            label: tr('الشحن $charge%', 'Charge $charge%'),
            child: Container(
              width: _cellWidth,
              height: _cellHeight,
              padding: const EdgeInsets.all(BunoSpace.s1),
              alignment: Alignment.bottomCenter,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(BunoRadius.sm),
                border: Border.all(color: BunoColors.primary, width: BunoStroke.defaultWidth),
              ),
              child: FractionallySizedBox(
                heightFactor: charge.clamp(0, 100) / 100,
                widthFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: BunoColors.success,
                    borderRadius: BorderRadius.circular(BunoRadius.xs),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: BunoSpace.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BunoText(id, style: BunoType.number(BunoType.h2)),
                BunoText(
                  tr('اتعرفت بشريحة RFID جوه الوحدة', 'Identified by an RFID chip inside the unit'),
                  style: BunoType.caption.copyWith(color: BunoDark.text_secondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

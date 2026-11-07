import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/repositories.dart';
import '../../data/mock_rental.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_info_row.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_status_pill.dart';
import '../../widgets/buno_tab_header.dart';
import '../../widgets/buno_text.dart';
import '../../widgets/buno_title_bar.dart';
import '../../l10n/buno_locale.dart';

/// /station/info (reference 84_station_info), from the "i" on /station:
/// opening hours, which bays take a return, where it is, and "وديني" to
/// the map. Unknown code → the first mock station.
class StationInfoScreen extends StatelessWidget {
  const StationInfoScreen({super.key, this.code});

  final String? code;

  @override
  Widget build(BuildContext context) {
    final station = Repos.stations.byCode(code) ?? Repos.stations.all.first;
    final info = Repos.stations.infoOf(station);
    final open = info.isOpenAt(DateTime.now());
    final secondary = BunoType.bodySm.copyWith(color: BunoDark.text_secondary, fontWeight: FontWeight.w600);
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BunoTitleBar(tr('عن المحطة', 'About the station')),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: BunoSpace.s5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(station.name, maxLines: 2, style: BunoType.h1),
                      BunoText('${station.code} · ${info.area}', maxLines: 1, style: secondary),
                      const SizedBox(height: BunoSpace.s3),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: BunoStatusPill(
                          open ? tr('مفتوحة دلوقتي', 'Open now') : tr('مقفولة دلوقتي', 'Closed now'),
                          color: open ? BunoColors.primary : BunoColors.warning,
                        ),
                      ),
                      const SizedBox(height: BunoSpace.s6),
                      BunoSectionTitle(tr('مواعيد الفتح', 'Opening hours')),
                      BunoInfoRow(tr('السبت – الخميس', 'Saturday – Thursday'), info.hoursLabel, divider: true),
                      BunoInfoRow(tr('الجمعة', 'Friday'), info.fridayLabel),
                      const SizedBox(height: BunoSpace.s6),
                      BunoSectionTitle(tr('خانات الإرجاع', 'Return bays')),
                      const SizedBox(height: BunoSpace.s2),
                      BunoText(
                        station.emptyCount == 0
                            ? tr('المحطة مليانة دلوقتي، رجّع في أقرب محطة تانية.', 'The station is full right now. Return at the nearest other station.')
                            : tr('${station.emptyCount} خانة فاضية دلوقتي، رجّع في أي واحدة منهم.', '${station.emptyCount} free bays now. Return in any of them.'),
                        maxLines: 2,
                        style: secondary,
                      ),
                      const SizedBox(height: BunoSpace.s3),
                      _ReturnBays(station: station),
                      const SizedBox(height: BunoSpace.s6),
                      BunoSectionTitle(tr('المكان', 'Location')),
                      const SizedBox(height: BunoSpace.s2),
                      Text(info.landmark, style: BunoType.body),
                    ],
                  ),
                ),
              ),
              BunoPrimaryButton(
                label: tr('وديني', 'Take me'),
                leading: const BunoLottieIcon(name: 'navigate', color: BunoDark.on_primary),
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.stations, arguments: station.code),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The 8 bays by number; empty ones (where a unit can go back) in green.
class _ReturnBays extends StatelessWidget {
  const _ReturnBays({required this.station});

  final Station station;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < station.bays.length; i++) ...[
          if (i > 0) const SizedBox(width: BunoSpace.s1),
          Expanded(child: _bay(i)),
        ],
      ],
    );
  }

  Widget _bay(int i) {
    final empty = station.bays[i] == null;
    return Semantics(
      label: empty ? tr('خانة ${i + 1}، فاضية', 'Bay ${i + 1}, empty') : tr('خانة ${i + 1}، فيها وحدة', 'Bay ${i + 1}, has a unit'),
      child: ExcludeSemantics(
        child: Container(
          height: BunoSize.buttonSm,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: empty ? BunoColors.primary_soft : BunoDark.card,
            borderRadius: BorderRadius.circular(BunoRadius.sm),
            border: Border.all(
              color: empty ? BunoColors.primary : BunoDark.border,
              width: empty ? BunoStroke.defaultWidth : BunoStroke.hairline,
            ),
          ),
          child: BunoText(
            '${i + 1}',
            style: BunoType.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: empty ? BunoColors.primary : BunoDark.text_disabled,
            ),
          ),
        ),
      ),
    );
  }
}

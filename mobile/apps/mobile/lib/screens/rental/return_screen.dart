import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/repositories.dart';
import '../../data/mock_rental.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_empty_state.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_text_link.dart';
import '../../widgets/buno_title_bar.dart';
import '../../l10n/buno_locale.dart';

/// /return (reference 10_return_how): how to put the unit back, with the
/// station's 2×4 bays and one empty bay lit. A debug-only link simulates the
/// return into the nearest station and opens /return/done; another shows
/// the station-full state (reference 30_state_station_full).
class ReturnScreen extends StatefulWidget {
  const ReturnScreen({super.key});

  static const _cellWidth = 52.0;
  static const _cellHeight = 84.0;
  static const _gap = BunoSpace.s2;

  /// The bay lit in the diagram: the nearest station's first empty bay.
  static int get litBay => Repos.stations.nearestReturn()?.firstEmptyBay ?? 0;

  @override
  State<ReturnScreen> createState() => _ReturnScreenState();
}

class _ReturnScreenState extends State<ReturnScreen> {
  static const _gap = ReturnScreen._gap;

  /// The station has no empty bay (simulated).
  bool _full = false;

  void _openNearest() => Navigator.of(context).pushNamed(
        AppRoutes.stations,
        arguments: Repos.stations.nearestReturn()?.code,
      );

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
  }

  void _simulateReturn() {
    final station = Repos.stations.nearestReturn();
    if (rentalSession.state != RentalState.active || station == null) {
      _toast(tr('مفيش إيجار شغّال', 'No active rental'));
      return;
    }
    rentalSession.returnTo(station, station.firstEmptyBay!);
    rentalSession.finish(cost: 0);
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.returnDone, ModalRoute.withName(AppRoutes.home));
  }

  @override
  Widget build(BuildContext context) {
    if (_full) {
      return Scaffold(
        backgroundColor: BunoDark.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
            child: BunoEmptyState(
              header: BunoTitleBar(tr('الإرجاع', 'Return')),
              icon: const BunoLottieIcon(name: 'warning', size: 40, color: BunoColors.warning, playKey: 0),
              title: tr('المحطة مليانة', 'Station is full'),
              body: tr('مفيش خانة فاضية هنا. وقّفنا العدّاد [المدة] لحد ما توصل لمحطة تانية، ', "No free bay here. We've paused the timer for [duration] while you get to another station, ") +
                  tr('فمش هتدفع عن وقت المشي.', "so you won't pay for the walk."),
              actionLabel: tr('ودّيني لأقرب محطة فيها مكان', 'Take me to the nearest station with space'),
              onAction: _openNearest,
            ),
          ),
        ),
      );
    }
    final lit = ReturnScreen.litBay;
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BunoTitleBar(tr('ترجّعه إزاي', 'How to return it')),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: BunoSpace.s4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                          label: tr('الخانة المنوّرة رقم ${lit + 1}', 'Lit bay number ${lit + 1}'),
                          excludeSemantics: true,
                          child: Column(
                            children: [
                              for (var row = 0; row < 2; row++) ...[
                                if (row > 0) const SizedBox(height: _gap),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (var col = 0; col < 4; col++) ...[
                                      if (col > 0) const SizedBox(width: _gap),
                                      _BayCell(lit: row * 4 + col == lit),
                                    ],
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: BunoSpace.s6),
                        Text(tr('حطه في الخانة المنوّرة', 'Put it in the lit bay'), textAlign: TextAlign.center, style: BunoType.h2),
                        const SizedBox(height: BunoSpace.s2),
                        Text(
                          tr('أي محطة بونو. الكابل يدخل الأول، والخانة هتتقفل لوحدها.', 'Any Buno station. Cable goes in first, and the bay locks by itself.'),
                          textAlign: TextAlign.center,
                          style: BunoType.bodySm.copyWith(
                            color: BunoDark.text_secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (kDebugMode) ...[
                          const SizedBox(height: BunoSpace.s3),
                          BunoTextLink(
                            tr('تجربة: حطيته في الخانة', 'Test: I put it in the bay'),
                            onTap: _simulateReturn,
                            color: BunoColors.info,
                          ),
                          BunoTextLink(
                            tr('تجربة: المحطة مليانة', 'Test: station full'),
                            onTap: () => setState(() => _full = true),
                            color: BunoColors.info,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              BunoPrimaryButton(
                label: tr('ودّيني لأقرب محطة', 'Take me to the nearest station'),
                leading: const BunoLottieIcon(name: 'navigate', color: BunoDark.on_primary),
                onPressed: _openNearest,
              ),
              const SizedBox(height: BunoSpace.s2),
              BunoTextLink(
                tr('المحطة مش بتستلم؟', "Station won't take it?"),
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.report),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BayCell extends StatelessWidget {
  const _BayCell({required this.lit});

  final bool lit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ReturnScreen._cellWidth,
      height: ReturnScreen._cellHeight,
      decoration: BoxDecoration(
        color: lit ? BunoColors.primary_soft : BunoDark.card,
        borderRadius: BorderRadius.circular(BunoRadius.md),
        border: lit ? Border.all(color: BunoColors.primary, width: BunoStroke.defaultWidth) : null,
        boxShadow: lit ? const [BunoElevation.glow] : null,
      ),
    );
  }
}

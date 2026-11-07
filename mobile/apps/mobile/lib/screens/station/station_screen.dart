import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_routes.dart';
import '../../data/repositories.dart';
import '../../data/mock_rental.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_back_button.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_bay_tile.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_info_row.dart';
import '../../widgets/buno_logo.dart';
import '../../widgets/buno_heart.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_text.dart';
import '../auth/auth_scaffold.dart' show showBunoToast;
import '../../l10n/buno_locale.dart';

/// /station (reference 03_station): the station's 8 bays and prices, with a
/// CTA that takes the most-charged ready unit, or the ready bay the user taps. Unknown code → "station not found".
/// While a rental is active it is the return location instead (reached from
/// /return → /stations, or a scan): an empty bay is lit and the CTA puts the
/// unit back there and opens /return/done, never /confirm.
class StationScreen extends StatelessWidget {
  const StationScreen({super.key, this.code});

  /// Raw QR text or a typed `BUN-01` code.
  final String? code;

  @override
  Widget build(BuildContext context) {
    final station = Repos.stations.byCode(code);
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          child: station == null ? _NotFound(code: code) : _StationBody(station: station),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        BunoLogo(height: 24.4),
        Spacer(),
        BunoBackButton(),
      ],
    );
  }
}

class _StationBody extends StatefulWidget {
  const _StationBody({required this.station});

  final Station station;

  @override
  State<_StationBody> createState() => _StationBodyState();
}

class _StationBodyState extends State<_StationBody> {
  /// The user has a unit out: this station is where it goes back, so empty
  /// bays are picked instead of ready ones.
  late final bool _returning = rentalSession.state == RentalState.active && rentalSession.returnStation == null;

  /// Bay the user tapped; until then the best ready bay, or the first empty
  /// one when [_returning].
  late int? _selected = _returning ? widget.station.firstEmptyBay : widget.station.bestBayIndex;

  void _returnHere(int bay) {
    rentalSession.returnTo(widget.station, bay);
    rentalSession.finish(cost: 0);
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.returnDone, ModalRoute.withName(AppRoutes.home));
  }

  Widget _cta() {
    final station = widget.station;
    final best = _selected;
    if (_returning) {
      return BunoPrimaryButton(
        label: best == null ? tr('المحطة مليانة', 'Station is full') : tr('حطيته في خانة ${best + 1}', 'I put it in bay ${best + 1}'),
        onPressed: best == null ? null : () => _returnHere(best),
      );
    }
    return BunoPrimaryButton(
      label: best == null ? tr('مفيش وحدات جاهزة', 'No units ready') : tr('خد الـ ${station.bays[best]}%', 'Take the ${station.bays[best]}%'),
      icon: BunoIcons.scan,
      onPressed: best == null
          ? null
          : () => Navigator.of(context).pushNamed(
                AppRoutes.confirm,
                arguments: (station, best),
              ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final station = widget.station;
    final best = _selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Header(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: BunoSpace.s4, bottom: BunoSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(station.name, style: BunoType.h1, maxLines: 2)),
                    _InfoButton(station: station),
                    _HeartButton(station: station),
                  ],
                ),
                const SizedBox(height: BunoSpace.s1),
                BunoText(
                  tr('${station.readyCount} جاهزين · ${station.emptyCount} خانة فاضية للإرجاع', '${station.readyCount} ready · ${station.emptyCount} free bays to return') +
                  tr(' · ${station.walkMinutes} دقايق مشي', ' · ${station.walkMinutes} min walk'),
                  maxLines: 2,
                  style: BunoType.bodySm.copyWith(
                    color: BunoDark.text_secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: BunoSpace.s5),
                _BayGrid(
                  station: station,
                  highlight: best,
                  returning: _returning,
                  onSelect: (i) => setState(() => _selected = i),
                ),
                const SizedBox(height: BunoSpace.s5),
                if (_returning)
                  Text(
                    tr('حطه في الخانة المنوّرة. الكابل يدخل الأول، والخانة هتتقفل لوحدها.', 'Put it in the lit bay. Cable goes in first, and the bay locks by itself.'),
                    style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary, fontWeight: FontWeight.w600),
                  )
                else ...[
                  BunoInfoRow(tr('أول ساعة', 'First hour'), tr('[السعر]', '[Price]'), verticalPadding: BunoSpace.s1),
                  BunoInfoRow(tr('بعدها', 'After that'), tr('[السعر] / دقيقة', '[Price] / min'), verticalPadding: BunoSpace.s1),
                ],
              ],
            ),
          ),
        ),
        _cta(),
      ],
    );
  }
}

/// Small "i" that opens /station/info.
class _InfoButton extends StatelessWidget {
  const _InfoButton({required this.station});

  final Station station;

  @override
  Widget build(BuildContext context) {
    return BunoPressable(
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.stationInfo, arguments: station.code),
      semanticLabel: tr('معلومات المحطة', 'Station info'),
      child: SizedBox.square(
        dimension: BunoSize.touchMin,
        child: Center(
          child: Container(
            width: BunoSize.iconMd,
            height: BunoSize.iconMd,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: BunoDark.text_secondary, width: BunoStroke.defaultWidth),
            ),
            child: Text(
              'i',
              style: BunoType.number(BunoType.caption).copyWith(
                fontWeight: FontWeight.w700,
                height: 1,
                color: BunoDark.text_secondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Adds or removes the station from /favorites; the heart plays once when
/// it is added (last frame under reduced motion).
class _HeartButton extends StatefulWidget {
  const _HeartButton({required this.station});

  final Station station;

  @override
  State<_HeartButton> createState() => _HeartButtonState();
}

class _HeartButtonState extends State<_HeartButton> {
  /// Times the heart was turned on here; null until the first, so it doesn't
  /// play on open.
  int? _plays;

  Future<void> _toggle() async {
    HapticFeedback.selectionClick();
    final added = await Repos.favorites.toggle(widget.station);
    if (!mounted) return;
    if (added) setState(() => _plays = (_plays ?? 0) + 1);
    showBunoToast(context, added ? tr('اتضافت للمفضلة', 'Added to favorites') : tr('اتشالت من المفضلة', 'Removed from favorites'));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Repos.favorites,
      builder: (context, _) {
        final on = Repos.favorites.contains(widget.station);
        return BunoPressable(
          onTap: _toggle,
          semanticLabel: on ? tr('شيلها من المفضلة', 'Remove from favorites') : tr('ضيفها للمفضلة', 'Add to favorites'),
          child: SizedBox.square(
            dimension: BunoSize.touchMin,
            child: Center(
              child: BunoHeart(on: on, playKey: _plays),
            ),
          ),
        );
      },
    );
  }
}

/// 2 rows × 4 bays, numbered from the start side. Only ready bays respond
/// to taps, or only empty ones when [returning].
class _BayGrid extends StatelessWidget {
  const _BayGrid({required this.station, required this.highlight, required this.returning, required this.onSelect});

  final Station station;
  final int? highlight;
  final bool returning;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final bays = station.bays;
    const perRow = 4;
    final rows = (bays.length / perRow).ceil();
    return Column(
      children: [
        for (var r = 0; r < rows; r++) ...[
          if (r > 0) const SizedBox(height: BunoSpace.s3),
          Row(
            children: [
              for (var c = 0; c < perRow; c++) ...[
                if (c > 0) const SizedBox(width: BunoSpace.s2),
                Expanded(
                  child: r * perRow + c < bays.length
                      ? _bay(r * perRow + c)
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _bay(int i) => BunoBayTile(
        number: i + 1,
        charge: station.bays[i],
        selected: highlight == i,
        onTap: (returning ? station.bays[i] == null : station.isReady(i)) ? () => onSelect(i) : null,
      );
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.code});

  final String? code;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Header(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: BunoSpace.s7),
            child: Column(
              children: [
                const BunoIcon(BunoIcons.warning, color: BunoColors.warning, size: BunoSize.iconLg),
                const SizedBox(height: BunoSpace.s4),
                Text(tr('مش لاقيين المحطة دي', "We can't find this station"), style: BunoType.h2, textAlign: TextAlign.center),
                const SizedBox(height: BunoSpace.s2),
                if (code != null && code!.isNotEmpty)
                  BunoText(
                    code!,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: BunoType.title.copyWith(color: BunoDark.text_secondary),
                  ),
                const SizedBox(height: BunoSpace.s2),
                Text(
                  tr('اتأكد من الكود المكتوب على المحطة وامسح تاني. مفيش أي فلوس اتخصمت.', 'Check the code printed on the station and scan again. Nothing was charged.'),
                  textAlign: TextAlign.center,
                  style: BunoType.body.copyWith(color: BunoDark.text_secondary),
                ),
              ],
            ),
          ),
        ),
        BunoPrimaryButton(
          label: tr('امسح تاني', 'Scan again'),
          icon: BunoIcons.scan,
          onPressed: () => Navigator.of(context)
              .pushNamedAndRemoveUntil(AppRoutes.scan, (r) => r.isFirst),
        ),
      ],
    );
  }
}

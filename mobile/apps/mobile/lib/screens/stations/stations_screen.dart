import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/mock_loading.dart';
import '../../data/repositories.dart';
import '../../data/mock_rental.dart';
import '../../data/user_location.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_bay_tile.dart' show chargeColor;
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_search_field.dart';
import '../../widgets/buno_skeleton.dart';
import '../../widgets/buno_text.dart';
import '../../widgets/buno_title_bar.dart';
import '../../widgets/map_markers.dart';
import '../home/mock_map.dart';
import '../../l10n/buno_locale.dart';

/// Filter chips on /stations.
enum StationFilter {
  hasUnits(Tr('فيها وحدات', 'Has units')),
  nearest(Tr('الأقرب', 'Nearest')),
  highCharge(Tr('شحن عالي', 'High charge'));

  const StationFilter(this._label);

  final Tr _label;
  String get label => _label.text;

  /// Walk (minutes) that still counts as "nearest".
  static const nearbyMinutes = 10;

  /// Best ready charge (percent) that counts as "high charge".
  static const highChargeMin = 80;

  bool matches(Station s) => switch (this) {
        hasUnits => s.readyCount > 0,
        nearest => s.walkMinutes <= nearbyMinutes,
        highCharge => (s.bestCharge ?? 0) >= highChargeMin,
      };
}

/// "مشي 4 د · 3 جاهزين", or "مفيش وحدات" when nothing is ready.
String stationMeta(Station s) =>
    '${tr('مشي ${s.walkMinutes} د', '${s.walkMinutes} min walk')} · '
        '${s.readyCount == 0 ? tr('مفيش وحدات', 'No units') : tr('${s.readyCount} جاهزين', '${s.readyCount} ready')}';

/// /stations (references 13_map, 14_stations_list): every station on a map
/// or in a list sorted by walk, with search and filter chips. A station
/// opens /station with its code. [selectCode] preselects a pin on the map.
/// The map or list shows a loading skeleton (32_state_loading) for
/// [mockLoadDelay] first.
class StationsScreen extends StatefulWidget {
  const StationsScreen({super.key, this.selectCode});

  final String? selectCode;

  @override
  State<StationsScreen> createState() => _StationsScreenState();
}

class _StationsScreenState extends State<StationsScreen> {
  static const _gutter = 22.0;

  bool _showMap = true;
  String _query = '';
  final _filters = <StationFilter>{};
  late String? _selectedId = Repos.stations.byCode(widget.selectCode)?.id;

  List<Station> get _visible {
    final q = _query.trim().toLowerCase();
    return Repos.stations.all
        .where((s) => q.isEmpty || s.name.contains(q) || s.code.toLowerCase().contains(q))
        .where((s) => _filters.every((f) => f.matches(s)))
        .toList()
      ..sort((a, b) => a.walkMinutes.compareTo(b.walkMinutes));
  }

  void _open(Station s) => Navigator.of(context).pushNamed(AppRoutes.station, arguments: s.code);

  void _toggle(StationFilter f) => setState(() => _filters.contains(f) ? _filters.remove(f) : _filters.add(f));

  @override
  Widget build(BuildContext context) {
    // Walk times follow the user's location.
    return ListenableBuilder(listenable: UserLocation.shared, builder: (context, _) => _build(context));
  }

  Widget _build(BuildContext context) {
    final stations = _visible;
    return Scaffold(
      backgroundColor: BunoDark.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(_gutter, 18, _gutter, BunoSpace.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BunoTitleBar(tr('المحطات', 'Stations')),
                  const SizedBox(height: BunoSpace.s3),
                  _ViewToggle(showMap: _showMap, onChanged: (map) => setState(() => _showMap = map)),
                  const SizedBox(height: BunoSpace.s3),
                  BunoSearchField(
                    hint: tr('دوّر على مكان أو محطة', 'Search a place or station'),
                    onChanged: (q) => setState(() => _query = q),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: _gutter),
              child: Row(
                children: [
                  for (final f in StationFilter.values) ...[
                    if (f.index > 0) const SizedBox(width: BunoSpace.s2),
                    _FilterChip(label: f.label, selected: _filters.contains(f), onTap: () => _toggle(f)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: BunoSpace.s3),
            Expanded(
              child: BunoLoadingGate(
                delay: mockLoadDelay,
                skeleton: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: _gutter),
                  child: BunoSkeletonList(),
                ),
                child: _showMap ? _buildMap(stations) : _buildList(stations),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pin spots as (x in the 390 map frame, share of the free height).
  static const _spots = [(105.0, 0.12), (300.0, 0.32), (90.0, 0.62), (265.0, 0.82)];

  Widget _buildMap(List<Station> stations) {
    final selected = stations.where((s) => s.id == _selectedId).firstOrNull ?? stations.firstOrNull;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return LayoutBuilder(builder: (context, constraints) {
      // Pins stay clear of the station card along the bottom.
      final free = constraints.maxHeight - 130 - bottomInset;
      Offset spot(int i) {
        final (x, y) = _spots[i % _spots.length];
        return Offset(x, 30 + y * (free - 30));
      }

      return Stack(
        children: [
          Positioned.fill(
            child: MockMap(
              stations: [
                for (final s in stations)
                  MapStation(
                    spot(Repos.stations.all.indexOf(s)),
                    s.readyCount == 0 ? StationAvailability.none : StationAvailability.available,
                    id: s.id,
                  ),
              ],
              selected: null,
              selectedReadyCount: null,
              user: Offset(MockMap.frameWidth / 2, 30 + 0.47 * (free - 30)),
              markerBuilder: (pin) {
                final s = Repos.stations.all.firstWhere((s) => s.id == pin.id);
                return StationChargePin(
                  charge: s.topCharge,
                  selected: s == selected,
                  onTap: () => s == selected ? _open(s) : setState(() => _selectedId = s.id),
                );
              },
            ),
          ),
          if (selected != null)
            Positioned(
              left: _gutter,
              right: _gutter,
              bottom: BunoSpace.s4 + bottomInset,
              child: _StationCard(station: selected, onTap: () => _open(selected)),
            )
          else
            const Center(child: _NoMatches()),
        ],
      );
    });
  }

  Widget _buildList(List<Station> stations) {
    if (stations.isEmpty) return const Center(child: _NoMatches());
    return ListView(
      padding: EdgeInsets.fromLTRB(_gutter, 0, _gutter, BunoSpace.s6 + MediaQuery.paddingOf(context).bottom),
      children: [for (final s in stations) _StationRow(station: s, onTap: () => _open(s))],
    );
  }
}

/// Map / list switch: a pill split in two, the active half in green.
class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.showMap, required this.onChanged});

  final bool showMap;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget half(String label, bool map) {
      final on = showMap == map;
      return Expanded(
        child: Semantics(
          selected: on,
          child: BunoPressable(
            onTap: () => onChanged(map),
            semanticLabel: label,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? BunoColors.primary : null,
                borderRadius: BorderRadius.circular(BunoRadius.pill),
              ),
              child: Text(
                label,
                style: BunoType.bodySm.copyWith(
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: on ? BunoDark.on_primary : BunoDark.text_secondary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: BunoSize.touchMin,
      padding: const EdgeInsets.all(BunoSpace.s1),
      decoration: BoxDecoration(
        color: BunoDark.card,
        borderRadius: BorderRadius.circular(BunoRadius.pill),
        border: Border.all(color: BunoDark.border, width: BunoStroke.hairline),
      ),
      child: Row(children: [half(tr('خريطة', 'Map'), true), half(tr('قايمة', 'List'), false)]),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: BunoPressable(
        onTap: onTap,
        semanticLabel: label,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? BunoColors.primary : BunoDark.background,
            borderRadius: BorderRadius.circular(BunoRadius.pill),
            border: Border.all(
              color: selected ? BunoColors.primary : BunoDark.border,
              width: BunoStroke.hairline,
            ),
          ),
          child: Text(
            label,
            style: BunoType.bodySm.copyWith(
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: selected ? BunoDark.on_primary : BunoDark.text_secondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// [Station.topCharge] in its threshold colour, or a grey "—".
class _BestCharge extends StatelessWidget {
  const _BestCharge(this.charge, {this.size = 18});

  final int? charge;
  final double size;

  @override
  Widget build(BuildContext context) {
    return BunoText(
      charge == null ? '—' : '$charge%',
      style: BunoType.title.copyWith(
        fontSize: size,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: charge == null ? BunoDark.text_disabled : chargeColor(charge),
      ),
    );
  }
}

class _NameAndMeta extends StatelessWidget {
  const _NameAndMeta(this.station);

  final Station station;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          station.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: BunoType.title.copyWith(fontSize: 16, fontWeight: FontWeight.w700, height: 1.3),
        ),
        BunoText(
          stationMeta(station),
          maxLines: 1,
          style: BunoType.caption.copyWith(fontWeight: FontWeight.w400, height: 1.4, color: BunoDark.text_secondary),
        ),
      ],
    );
  }
}

/// The selected pin's station, floating over the map.
class _StationCard extends StatelessWidget {
  const _StationCard({required this.station, required this.onTap});

  final Station station;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BunoPressable(
      onTap: onTap,
      semanticLabel: tr('${station.name}، ${stationMeta(station)}', '${station.name}, ${stationMeta(station)}'),
      child: Container(
        padding: const EdgeInsets.all(BunoSpace.s4),
        decoration: BoxDecoration(
          color: BunoDark.card,
          borderRadius: BorderRadius.circular(BunoRadius.xl),
          border: Border.all(color: BunoDark.border),
        ),
        child: Row(
          children: [
            Expanded(child: _NameAndMeta(station)),
            const SizedBox(width: BunoSpace.s3),
            _BestCharge(station.topCharge, size: 24),
            const SizedBox(width: BunoSpace.s3),
            Container(
              width: BunoSize.buttonLg,
              height: BunoSize.buttonLg,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: BunoColors.primary,
                borderRadius: BorderRadius.circular(BunoRadius.lg),
              ),
              child: const BunoLottieIcon(name: 'navigate', color: BunoDark.on_primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _StationRow extends StatelessWidget {
  const _StationRow({required this.station, required this.onTap});

  final Station station;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BunoPressable(
      onTap: onTap,
      semanticLabel: tr('${station.name}، ${stationMeta(station)}', '${station.name}, ${stationMeta(station)}'),
      child: Container(
        height: 73,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: BunoDark.border)),
        ),
        child: Row(
          children: [
            Expanded(child: _NameAndMeta(station)),
            const SizedBox(width: BunoSpace.s3),
            _BestCharge(station.topCharge),
          ],
        ),
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  const _NoMatches();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(BunoSpace.s6),
      child: Text(
        tr('مفيش محطات بالفلتر ده', 'No stations match this filter'),
        textAlign: TextAlign.center,
        style: BunoType.body.copyWith(color: BunoDark.text_secondary),
      ),
    );
  }
}

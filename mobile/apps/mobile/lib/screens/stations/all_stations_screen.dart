import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/mock_rental.dart';
import '../../data/mock_search.dart';
import '../../data/mock_station_info.dart';
import '../../data/repositories.dart';
import '../../data/user_location.dart';
import '../../l10n/buno_locale.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_bottom_nav.dart';
import '../../widgets/buno_count_badge.dart';
import '../../widgets/buno_heart.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_text.dart';
import '../home/home_state_bodies.dart' show ClosedPill;

/// Filter chips on /stations/all.
enum AllStationsFilter {
  hasUnits(Tr('فيها وحدات', 'Has units')),
  openNow(Tr('مفتوحة دلوقتي', 'Open now')),
  hasReturn(Tr('فيها مكان للإرجاع', 'Has return space')),
  favorites(Tr('المفضلة', 'Favourites'));

  const AllStationsFilter(this._label);

  final Tr _label;
  String get label => _label.text;

  bool matches(Station s) => switch (this) {
        hasUnits => s.readyCount > 0,
        openNow => isStationOpen(s),
        hasReturn => s.emptyCount > 0,
        favorites => Repos.favorites.contains(s),
      };
}

/// /stations/all (reference 108), from home's "كل المحطات": every station
/// nearest first with ready and free counts and distance; closed ones
/// dimmed. "الخريطة" goes back to home's map. A row opens /station.
class AllStationsScreen extends StatefulWidget {
  const AllStationsScreen({super.key});

  @override
  State<AllStationsScreen> createState() => _AllStationsScreenState();
}

class _AllStationsScreenState extends State<AllStationsScreen> {
  static const _gutter = 20.0;

  final _filters = <AllStationsFilter>{};

  List<Station> get _visible => Repos.stations.all.where((s) => _filters.every((f) => f.matches(s))).toList()
    ..sort((a, b) => (a.metersAway ?? double.infinity).compareTo(b.metersAway ?? double.infinity));

  void _toggle(AllStationsFilter f) => setState(() => _filters.contains(f) ? _filters.remove(f) : _filters.add(f));

  void _backToMap() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacementNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BunoDark.background,
      bottomNavigationBar: BunoBottomNav(
        items: [
          BunoNavItem(icon: BunoIcons.home, label: tr('الرئيسية', 'Home')),
          BunoNavItem(icon: BunoIcons.history, label: tr('رحلاتي', 'Trips')),
          BunoNavItem(icon: BunoIcons.wallet, label: tr('المحفظة', 'Wallet')),
          BunoNavItem(icon: BunoIcons.profile, label: tr('حسابي', 'Profile')),
        ],
        currentIndex: 0,
        onSelected: (i) => i == 0 ? _backToMap() : AppRoutes.goToTab(context, i, 0),
      ),
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: Listenable.merge([UserLocation.shared, Repos.favorites]),
          builder: (context, _) => _body(context),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final stations = _visible;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(_gutter, 18, _gutter, BunoSpace.s3),
          child: Row(
            children: [
              Expanded(child: BunoText(tr('كل المحطات', 'All stations'), maxLines: 1, style: BunoType.h1)),
              const SizedBox(width: BunoSpace.s3),
              BunoPressable(
                onTap: _backToMap,
                semanticLabel: tr('الخريطة', 'Map'),
                child: Container(
                  height: BunoSize.touchMin,
                  padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s4),
                  decoration: BoxDecoration(
                    color: BunoDark.card,
                    borderRadius: BorderRadius.circular(BunoRadius.pill),
                    border: Border.all(color: BunoDark.border, width: BunoStroke.hairline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BunoIcon(BunoIcons.location, size: BunoSize.iconSm, color: BunoColors.primary),
                      const SizedBox(width: BunoSpace.s2),
                      BunoText(tr('الخريطة', 'Map'), style: BunoType.bodySm.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: _gutter),
          child: Row(
            children: [
              for (final f in AllStationsFilter.values) ...[
                if (f.index > 0) const SizedBox(width: BunoSpace.s2),
                _FilterChip(label: f.label, selected: _filters.contains(f), onTap: () => _toggle(f)),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(_gutter, BunoSpace.s3, _gutter, 0),
          child: BunoText(tr('مترتبة حسب الأقرب ليك', 'Sorted by distance from you'), style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary)),
        ),
        Expanded(
          child: stations.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(BunoSpace.s6),
                    child: BunoText(
                      tr('مفيش محطات بالفلتر ده', 'No stations match this filter'),
                      textAlign: TextAlign.center,
                      style: BunoType.body.copyWith(color: BunoDark.text_secondary),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(_gutter, 0, _gutter, BunoSpace.s6),
                  children: [
                    for (final s in stations)
                      _Row(
                        station: s,
                        favorite: Repos.favorites.contains(s),
                        onTap: () => Navigator.of(context).pushNamed(AppRoutes.station, arguments: s.code),
                      ),
                  ],
                ),
        ),
      ],
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
          height: BunoSize.touchMin,
          padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? BunoColors.primary : BunoDark.card,
            borderRadius: BorderRadius.circular(BunoRadius.pill),
            border: Border.all(color: selected ? BunoColors.primary : BunoDark.border, width: BunoStroke.hairline),
          ),
          child: Text(
            label,
            style: BunoType.bodySm.copyWith(
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: selected ? BunoDark.on_primary : BunoDark.text_primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.station, required this.favorite, required this.onTap});

  final Station station;
  final bool favorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final open = isStationOpen(station);
    final meters = station.metersAway;
    final distance = meters == null ? tr('${station.walkMinutes} د', '${station.walkMinutes} min') : distanceLabel(meters);
    return BunoPressable(
      onTap: onTap,
      semanticLabel: [
        station.name,
        if (!open) tr('مقفولة دلوقتي', 'closed now'),
        tr('${station.readyCount} جاهز', '${station.readyCount} ready'),
        tr('${station.emptyCount} فاضي', '${station.emptyCount} free'),
        distance,
      ].join(tr('، ', ', ')),
      child: Opacity(
        opacity: open ? 1 : 0.45,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(vertical: BunoSpace.s3),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: BunoDark.border))),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: BunoText(station.name, maxLines: 1, style: BunoType.title.copyWith(fontWeight: FontWeight.w700)),
                        ),
                        if (favorite) ...[
                          const SizedBox(width: BunoSpace.s1),
                          const BunoHeart(on: true, size: 16),
                        ],
                      ],
                    ),
                    BunoText(stationInfo(station).landmark, maxLines: 1, style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary)),
                    if (!open) ...[
                      const SizedBox(height: BunoSpace.s1),
                      const ClosedPill(),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: BunoSpace.s2),
              BunoCountBadge.ready(station.readyCount),
              const SizedBox(width: BunoSpace.s1),
              BunoCountBadge.free(station.emptyCount),
              const SizedBox(width: BunoSpace.s2),
              SizedBox(
                width: 52,
                child: BunoText(
                  distance,
                  maxLines: 1,
                  textAlign: TextAlign.end,
                  style: BunoType.bodySm.copyWith(fontWeight: FontWeight.w600, color: BunoDark.text_secondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

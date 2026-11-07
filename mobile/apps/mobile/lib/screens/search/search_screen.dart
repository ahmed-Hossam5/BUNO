import 'package:flutter/material.dart';

import '../../data/mock_rental.dart';
import '../../data/mock_search.dart';
import '../../data/mock_station_info.dart';
import '../../l10n/buno_locale.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_count_badge.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_search_field.dart';
import '../../widgets/buno_text.dart';

/// /search (reference 107), from home's search field: stations (ready and
/// free counts, walk) and places (with their nearest station) matching the
/// query, then recent searches. Pops with the picked [Station] or
/// [MapPlace]; "إلغاء" pops with nothing.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _gutter = 20.0;

  String _query = '';

  void _pick(Object item) {
    recentSearches.add(item);
    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final stations = searchStations(_query);
    final places = searchPlaces(_query);
    final typed = _query.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(_gutter, 18, BunoSpace.s2, BunoSpace.s2),
              child: Row(
                children: [
                  Expanded(
                    child: BunoSearchField(
                      hint: tr('دوّر على محطة أو مكان', 'Search a station or place'),
                      leadingIcon: BunoIcons.search,
                      autofocus: true,
                      onChanged: (q) => setState(() => _query = q),
                    ),
                  ),
                  BunoPressable(
                    onTap: () => Navigator.of(context).pop(),
                    semanticLabel: tr('إلغاء', 'Cancel'),
                    child: Container(
                      height: BunoSize.touchMin,
                      padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s3),
                      alignment: Alignment.center,
                      child: Text(
                        tr('إلغاء', 'Cancel'),
                        style: BunoType.body.copyWith(fontWeight: FontWeight.w600, color: BunoDark.text_secondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: recentSearches,
                builder: (context, recent, _) => ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(_gutter, 0, _gutter, BunoSpace.s6 + MediaQuery.paddingOf(context).bottom),
                  children: [
                    if (stations.isNotEmpty) ...[
                      _SectionTitle(tr('محطات', 'Stations')),
                      for (final s in stations) _StationResult(station: s, onTap: () => _pick(s)),
                    ],
                    if (places.isNotEmpty) ...[
                      _SectionTitle(tr('أماكن', 'Places')),
                      for (final p in places) _PlaceResult(place: p, onTap: () => _pick(p)),
                    ],
                    if (typed && stations.isEmpty && places.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: BunoSpace.s6),
                        child: BunoText(
                          tr('مفيش نتايج لـ «${_query.trim()}»', 'No results for "${_query.trim()}"'),
                          textAlign: TextAlign.center,
                          style: BunoType.body.copyWith(color: BunoDark.text_secondary),
                        ),
                      ),
                    if (recent.isNotEmpty) ...[
                      _SectionTitle(tr('آخر بحث', 'Recent')),
                      for (final item in recent) _RecentRow(item: item, onTap: () => _pick(item)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: BunoSpace.s5, bottom: BunoSpace.s1),
      child: BunoText(text, style: BunoType.bodySm.copyWith(fontWeight: FontWeight.w600, color: BunoDark.text_secondary)),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.semanticLabel, required this.onTap, required this.child});

  final String semanticLabel;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BunoPressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(vertical: BunoSpace.s3),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: BunoDark.border))),
        child: child,
      ),
    );
  }
}

/// Name and landmark, ready and free counts, walk minutes.
class _StationResult extends StatelessWidget {
  const _StationResult({required this.station, required this.onTap});

  final Station station;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final info = stationInfo(station);
    return _ResultRow(
      onTap: onTap,
      semanticLabel: tr(
        '${station.name}، ${station.readyCount} جاهز، ${station.emptyCount} فاضي، ${station.walkMinutes} د',
        '${station.name}, ${station.readyCount} ready, ${station.emptyCount} free, ${station.walkMinutes} min',
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BunoText(station.name, maxLines: 1, style: BunoType.title.copyWith(fontWeight: FontWeight.w700)),
                BunoText(info.landmark, maxLines: 1, style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary)),
              ],
            ),
          ),
          const SizedBox(width: BunoSpace.s2),
          BunoCountBadge.ready(station.readyCount),
          const SizedBox(width: BunoSpace.s1),
          BunoCountBadge.free(station.emptyCount),
          const SizedBox(width: BunoSpace.s2),
          SizedBox(
            width: 40,
            child: BunoText(
              tr('${station.walkMinutes} د', '${station.walkMinutes} min'),
              textAlign: TextAlign.end,
              style: BunoType.bodySm.copyWith(fontWeight: FontWeight.w600, color: BunoDark.text_secondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// A place and the station nearest to it.
class _PlaceResult extends StatelessWidget {
  const _PlaceResult({required this.place, required this.onTap});

  final MapPlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final near = place.nearestStation;
    final meta = tr(
      '${place.area} · أقرب محطة ليها: ${near.name} · ${place.nearestWalkMinutes} د',
      '${place.area} · nearest station: ${near.name} · ${place.nearestWalkMinutes} min',
    );
    return _ResultRow(
      onTap: onTap,
      semanticLabel: '${place.name}، $meta',
      child: Row(
        children: [
          const BunoIcon(BunoIcons.location, color: BunoDark.text_secondary),
          const SizedBox(width: BunoSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BunoText(place.name, maxLines: 1, style: BunoType.title.copyWith(fontWeight: FontWeight.w700)),
                BunoText(meta, maxLines: 1, style: BunoType.bodySm.copyWith(color: BunoDark.text_secondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.item, required this.onTap});

  final Object item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = switch (item) {
      Station s => s.name,
      MapPlace p => p.name,
      _ => '',
    };
    return BunoPressable(
      onTap: onTap,
      semanticLabel: name,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            const BunoIcon(BunoIcons.history, color: BunoDark.text_secondary),
            const SizedBox(width: BunoSpace.s3),
            Expanded(child: BunoText(name, maxLines: 1, style: BunoType.body.copyWith(fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}

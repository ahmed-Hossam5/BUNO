import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../l10n/buno_locale.dart';
import 'mock_map_places.dart';
import 'mock_rental.dart';
import 'mock_station_info.dart';
import 'user_location.dart';

/// A named place on campus (or near it) that home's search finds, placed
/// like the mock stations: (bearing in degrees, metres) from
/// [UserLocation.origin]. Mock.
class MapPlace {
  const MapPlace(this._name, this._area, this.bearing, this.meters);

  final Tr _name;
  final Tr _area;
  final double bearing;
  final double meters;

  String get name => _name.text;
  String get area => _area.text;

  LatLng get position => offsetBy(UserLocation.shared.origin, bearing, meters);

  /// Matches [q] in either language, so a search works whatever the app
  /// language is.
  bool matches(String q) => _name.ar.contains(q) || _name.en.toLowerCase().contains(q.toLowerCase());

  /// The open station closest to this place, else the closest one.
  Station get nearestStation {
    final all = mockStations.where((s) => placeOf(s) != null).toList();
    final open = all.where(isStationOpen).toList();
    final pool = open.isEmpty ? all : open;
    pool.sort((a, b) => distanceMeters(position, placeOf(a)!).compareTo(distanceMeters(position, placeOf(b)!)));
    return pool.first;
  }

  /// Walk from this place to [nearestStation], in minutes.
  int get nearestWalkMinutes => walkMinutesBetween(position, placeOf(nearestStation)!);
}

const mockPlaces = [
  MapPlace(Tr('مكتبة الجامعة', 'University library'), Tr('الحرم الجامعي', 'Campus'), 45, 300),
  MapPlace(Tr('مكتبة ألف', 'Alef Bookstore'), Tr('وسط البلد', 'Downtown'), 300, 950),
  MapPlace(Tr('الكافيتريا الرئيسية', 'Main cafeteria'), Tr('الحرم الجامعي', 'Campus'), 35, 360),
  MapPlace(Tr('مبنى الهندسة', 'Engineering building'), Tr('الحرم الجامعي', 'Campus'), 150, 700),
  MapPlace(Tr('البوابة الرئيسية', 'Main gate'), Tr('الحرم الجامعي', 'Campus'), 30, 250),
];

/// Stations whose name, code or landmark contains [q], nearest first.
List<Station> searchStations(String q) {
  final query = q.trim();
  if (query.isEmpty) return const [];
  final lower = query.toLowerCase();
  return mockStations
      .where((s) =>
          s.name.toLowerCase().contains(lower) ||
          s.code.toLowerCase().contains(lower) ||
          stationInfo(s).landmark.toLowerCase().contains(lower) ||
          stationInfo(s).area.toLowerCase().contains(lower))
      .toList()
    ..sort((a, b) => a.walkMinutes.compareTo(b.walkMinutes));
}

/// Places whose name contains [q].
List<MapPlace> searchPlaces(String q) {
  final query = q.trim();
  return query.isEmpty ? const [] : mockPlaces.where((p) => p.matches(query)).toList();
}

/// "240 م" under a kilometre, else "1.4 كم" ("18 كم" from 10 km).
String distanceLabel(double meters) {
  if (meters < 1000) {
    final m = (meters / 10).round() * 10;
    return tr('$m م', '$m m');
  }
  final km = meters / 1000;
  final text = km >= 10 ? km.round().toString() : km.toStringAsFixed(1);
  return tr('$text كم', '$text km');
}

/// What the user picked in search lately (a [Station] or a [MapPlace]),
/// newest first. Memory only.
class RecentSearches extends ValueNotifier<List<Object>> {
  RecentSearches() : super(_seed);

  static const max = 5;

  static List<Object> get _seed => [mockPlaces[2], mockPlaces[3]];

  void add(Object item) {
    assert(item is Station || item is MapPlace);
    value = [item, ...value.where((o) => o != item)].take(max).toList();
  }

  @visibleForTesting
  void reset() => value = _seed;
}

final recentSearches = RecentSearches();

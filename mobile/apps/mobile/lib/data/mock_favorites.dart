import 'package:flutter/foundation.dart';

import 'mock_rental.dart';
import '../l10n/buno_locale.dart';

/// Stations the user hearted on /station, listed on /favorites. Nothing is
/// sent anywhere.
class FavoriteStations extends ChangeNotifier {
  FavoriteStations([Iterable<String> seed = _seed]) : _ids = {...seed};

  /// One of each case on /favorites: plenty ready, a few, none.
  static const _seed = ['st-04', 'st-01', 'st-02'];

  /// The user's own name for a favourite, shown as a tag on its card.
  static Map<String, String> get _labels => {'st-04': tr('الجامعة', 'University'), 'st-01': tr('الشغل', 'Work')};

  final Set<String> _ids;

  bool contains(Station station) => _ids.contains(station.id);

  /// Favourites in the order they were added.
  List<Station> get stations => [
        for (final id in _ids)
          for (final s in mockStations)
            if (s.id == id) s,
      ];

  String? labelOf(Station station) => _labels[station.id];

  /// Adds or removes [station]; returns whether it is a favourite now.
  bool toggle(Station station) {
    final added = _ids.add(station.id);
    if (!added) _ids.remove(station.id);
    notifyListeners();
    return added;
  }

  /// Test only: back to the seeded favourites, or [ids].
  @visibleForTesting
  void debugReset([Iterable<String> ids = _seed]) {
    _ids
      ..clear()
      ..addAll(ids);
    notifyListeners();
  }
}

/// The one favourites list the screens read.
final favoriteStations = FavoriteStations();

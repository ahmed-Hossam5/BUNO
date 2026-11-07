import 'package:flutter/foundation.dart';

import 'mock_favorites.dart';
import 'mock_promo.dart';
import 'mock_rental.dart';
import 'mock_station_info.dart';

/// Where screens get stations, favourites and promo codes. Each repository
/// keeps what it last loaded, so screens read it synchronously and listen
/// for changes; the calls that would reach a server return futures.
///
/// Today every implementation wraps the local mocks. A server-backed one
/// (apps/server, via buno_shared) can replace them in [Repos] without
/// touching the screens.
abstract interface class StationsRepository implements Listenable {
  List<Station> get all;

  /// The station whose code appears in [raw] (typed or scanned); null when
  /// none matches.
  Station? byCode(String? raw);

  /// Closest station with a ready unit; null when none has one.
  Station? nearestReady();

  /// Closest station with an empty bay; null when all are full.
  Station? nearestReturn();

  StationInfo infoOf(Station station);

  /// Reloads [all] (bays change as units are taken and returned).
  Future<void> refresh();
}

abstract interface class FavoritesRepository implements Listenable {
  /// In the order they were added.
  List<Station> get stations;
  bool contains(Station station);

  /// The user's name for a favourite ("الجامعة"), if any.
  String? labelOf(Station station);

  /// Adds or removes [station]; completes with whether it is a favourite now.
  Future<bool> toggle(Station station);
}

abstract interface class PromoRepository implements Listenable {
  /// Newest first.
  List<PromoOffer> get offers;

  /// The last offer a code added, for the "اتفعّل" banner.
  PromoOffer? get lastAdded;

  Future<PromoResult> redeem(String code);
}

/// The repositories the app uses. Tests and a future server build can
/// replace them.
abstract final class Repos {
  static StationsRepository stations = MockStationsRepository();
  static FavoritesRepository favorites = MockFavoritesRepository(favoriteStations);
  static PromoRepository promo = MockPromoRepository(promoSession);

  /// Back to the mock repositories.
  @visibleForTesting
  static void reset() {
    stations = MockStationsRepository();
    favorites = MockFavoritesRepository(favoriteStations);
    promo = MockPromoRepository(promoSession);
  }
}

class MockStationsRepository extends ChangeNotifier implements StationsRepository {
  @override
  List<Station> get all => List.unmodifiable(mockStations);

  @override
  Station? byCode(String? raw) => stationByCode(raw);

  @override
  Station? nearestReady() => nearestReadyStation();

  @override
  Station? nearestReturn() => nearestReturnStation();

  @override
  StationInfo infoOf(Station station) => stationInfo(station);

  /// The mock bays are already live; nothing to load.
  @override
  Future<void> refresh() async => notifyListeners();
}

class MockFavoritesRepository implements FavoritesRepository {
  MockFavoritesRepository(this._mock);

  final FavoriteStations _mock;

  @override
  List<Station> get stations => _mock.stations;

  @override
  bool contains(Station station) => _mock.contains(station);

  @override
  String? labelOf(Station station) => _mock.labelOf(station);

  @override
  Future<bool> toggle(Station station) async => _mock.toggle(station);

  @override
  void addListener(VoidCallback listener) => _mock.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => _mock.removeListener(listener);
}

class MockPromoRepository implements PromoRepository {
  MockPromoRepository(this._mock);

  final PromoSession _mock;

  @override
  List<PromoOffer> get offers => _mock.offers;

  @override
  PromoOffer? get lastAdded => _mock.lastAdded;

  @override
  Future<PromoResult> redeem(String code) async => _mock.redeem(code);

  @override
  void addListener(VoidCallback listener) => _mock.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => _mock.removeListener(listener);
}

/// HTTP paths, one group per server module. `<x>` marks a path parameter.
abstract final class ApiPaths {
  static const health = '/health';

  static const auth = '/v1/auth';
  static const authSendCode = '$auth/code';
  static const authVerify = '$auth/verify';

  static const stations = '/v1/stations';

  /// `GET` one station by its printed code, e.g. `BUN-01`.
  static String station(String code) => '$stations/$code';

  static const wallet = '/v1/wallet';

  static const rentals = '/v1/rentals';
  static const currentRental = '$rentals/current';
  static String returnRental(String id) => '$rentals/$id/return';

  static const promo = '/v1/promo';
  static const promoOffers = '$promo/offers';
  static const promoRedeem = '$promo/redeem';

  static const favorites = '/v1/favorites';
  static String favorite(String stationCode) => '$favorites/$stationCode';
}

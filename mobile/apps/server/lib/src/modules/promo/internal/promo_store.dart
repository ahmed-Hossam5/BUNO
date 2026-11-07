import 'package:buno_shared/buno_shared.dart';

import '../../../core/http.dart';

/// In-memory codes and offers, seeded like the app's `promoSession`.
class PromoStore {
  /// Codes that work, upper-case.
  static const _codes = {
    'WELCOME30': PromoOfferDto(title: '[المدة] ببلاش', source: 'من كود WELCOME30 · لحد [التاريخ]'),
    'BUNO10': PromoOfferDto(title: 'خصم على إيجار', source: 'من كود BUNO10 · لحد [التاريخ]'),
  };

  static const _seed = [
    PromoOfferDto(title: 'دعوة صاحب', source: 'اتضافت لما [اسم الصاحب] خد أول بونو'),
    PromoOfferDto(title: 'خصم أول اشتراك', source: 'انتهى في [التاريخ]', expired: true),
  ];

  final _offers = <String, List<PromoOfferDto>>{};
  final _used = <String, Set<String>>{};

  List<PromoOfferDto> offersOf(String userId) => List.unmodifiable(_offers[userId] ?? _seed);

  /// Adds [raw]'s offer (case and spaces ignored); throws `invalidCode` or
  /// `codeAlreadyUsed`.
  PromoOfferDto redeem(String userId, String raw) {
    final code = raw.replaceAll(' ', '').toUpperCase();
    final offer = _codes[code];
    if (offer == null) throw const ApiException(ApiError.invalidCode, 404);
    if (!(_used[userId] ??= {}).add(code)) throw const ApiException(ApiError.codeAlreadyUsed, 409);
    (_offers[userId] ??= List.of(_seed)).insert(0, offer);
    return offer;
  }
}

import 'package:flutter/foundation.dart';
import '../l10n/buno_locale.dart';

/// A reward on /promo: free minutes from a code, a referral, a plan discount.
class PromoOffer {
  const PromoOffer({required this._title, required this._source, this.expired = false});

  final Tr _title;
  final Tr _source;

  String get title => _title.text;

  /// Where it came from and until when.
  String get source => _source.text;
  final bool expired;
}

enum PromoResult { added, alreadyUsed, invalid }

/// Discount codes typed on /promo. Amounts and dates stay placeholders until
/// real pricing exists; nothing is sent anywhere.
class PromoSession extends ChangeNotifier {
  PromoSession() : _offers = List.of(_seed);

  /// Codes that work in the mock, upper-case.
  static const _codes = {
    'WELCOME30': PromoOffer(title: Tr('[المدة] ببلاش', '[Duration] free'), source: Tr('من كود WELCOME30 · لحد [التاريخ]', 'From code WELCOME30 · until [date]')),
    'BUNO10': PromoOffer(title: Tr('خصم على إيجار', 'Rental discount'), source: Tr('من كود BUNO10 · لحد [التاريخ]', 'From code BUNO10 · until [date]')),
  };

  static const _seed = [
    PromoOffer(title: Tr('دعوة صاحب', 'Friend invite'), source: Tr('اتضافت لما [اسم الصاحب] خد أول بونو', 'Added when [friend name] took their first Buno')),
    PromoOffer(title: Tr('خصم أول اشتراك', 'First plan discount'), source: Tr('انتهى في [التاريخ]', 'Expired on [date]'), expired: true),
  ];

  final List<PromoOffer> _offers;
  final Set<String> _used = {};

  /// Newest first.
  List<PromoOffer> get offers => List.unmodifiable(_offers);

  /// The last code that worked, for the "اتفعّل" banner.
  PromoOffer? lastAdded;

  /// Checks [raw] (case and spaces ignored) and adds its offer.
  PromoResult redeem(String raw) {
    final code = raw.replaceAll(' ', '').toUpperCase();
    final offer = _codes[code];
    if (offer == null) return PromoResult.invalid;
    if (!_used.add(code)) return PromoResult.alreadyUsed;
    _offers.insert(0, offer);
    lastAdded = offer;
    notifyListeners();
    return PromoResult.added;
  }

  /// Test only: forgets every redeemed code.
  @visibleForTesting
  void debugReset() {
    _offers
      ..clear()
      ..addAll(_seed);
    _used.clear();
    lastAdded = null;
    notifyListeners();
  }
}

/// The one promo session the screens read.
final promoSession = PromoSession();

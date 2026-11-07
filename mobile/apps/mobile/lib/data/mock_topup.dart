import 'mock_rental.dart';
import '../l10n/buno_locale.dart';

/// How the user pays for a wallet top-up (/topup).
enum TopupMethod {
  vodafoneCash(
    Tr('فودافون كاش', 'Vodafone Cash'),
    Tr('حوّل وارفع صورة الإيصال', 'Transfer and upload the receipt'),
    Tr('حوّل %s جنيه على', 'Send %s EGP to'),
    '01X XXXX XXXX',
  ),
  instaPay(
    Tr('إنستا باي', 'InstaPay'),
    Tr('تحويل لحظي', 'Instant transfer'),
    Tr('حوّل %s جنيه على', 'Send %s EGP to'),
    'buno@instapay',
  ),
  cash(
    Tr('كاش عند المكان', 'Cash at a shop'),
    Tr('ادفع للموظف واخد كود', 'Pay the staff and get a code'),
    Tr('ادفع %s جنيه للموظف عند', 'Pay %s EGP to the staff at'),
    Tr('[اسم المكان]', '[Place name]'),
  );

  const TopupMethod(this._title, this._subtitle, this._payTo, this._account);

  final Tr _title;
  final Tr _subtitle;
  final Tr _payTo;
  final Object _account;

  String get title => _title.text;
  String get subtitle => _subtitle.text;

  /// Where the money goes. Placeholder until the real accounts exist.
  String get account => '$_account';

  /// "Transfer [amount] EGP to" line on /topup/transfer.
  String payTo(int amount) => _payTo.text.replaceFirst('%s', '$amount');
}

/// A top-up the user is paying for: from /topup through /topup/pending.
class TopupRequest {
  const TopupRequest({required this.amount, required this.method});

  /// EGP.
  final int amount;
  final TopupMethod method;
}

/// A reviewed top-up: the wallet went from [before] to [after] (EGP).
class TopupReceipt {
  const TopupReceipt({required this.request, required this.before, required this.after});

  final TopupRequest request;
  final double before;
  final double after;
}

/// Amount chips on /topup.
const topupAmounts = [50, 100, 200, 500];

/// Mock time for staff to review a transfer.
const topupReviewDelay = Duration(seconds: 2);

/// Stand-in for the review: waits [topupReviewDelay], then adds the amount
/// to [rentalSession]'s balance. Nothing is sent anywhere.
Future<TopupReceipt> reviewTopup(TopupRequest request) async {
  await Future<void>.delayed(topupReviewDelay);
  final before = rentalSession.balance;
  rentalSession.balance += request.amount;
  return TopupReceipt(request: request, before: before, after: rentalSession.balance);
}

import 'package:flutter/foundation.dart';

import '../l10n/buno_locale.dart';

/// Mock subscription (/subscription, reference 60). Prices, dates and the
/// plan allowances are shown as placeholders; [rentalsIncluded] and
/// [hoursIncluded] only size the usage bars.
class MockSubscription {
  MockSubscription._();

  static const plan = Tr('مريح', 'Comfort');

  static const rentalsUsed = 14;
  static const rentalsIncluded = 20;
  static const hoursUsed = 21;
  static const hoursIncluded = 40;

  /// Longest single rental on the plan, in hours.
  static const maxRentalHours = 3;

  /// False once the user cancels auto-renew; the plan runs to the end of
  /// the month.
  static final autoRenew = ValueNotifier<bool>(true);

  static void reset() => autoRenew.value = true;
}

/// Mock state of the once-a-term emergency rental (/emergency, reference 63).
class MockEmergency {
  MockEmergency._();

  static final used = ValueNotifier<bool>(false);

  static void reset() => used.value = false;
}

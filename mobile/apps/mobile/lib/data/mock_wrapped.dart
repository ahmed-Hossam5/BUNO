import 'package:flutter/foundation.dart';

import 'mock_rental.dart';
import 'mock_settings.dart';

/// Last month with Buno, for /wrapped (references 66–68). Mock numbers until
/// the backend keeps real usage.
class MonthWrapped {
  const MonthWrapped({
    required this.dailyMinutes,
    required this.rentals,
    required this.stationsVisited,
    required this.favoriteStation,
    required this.favoriteRentals,
    required this.deadPhonePercent,
  });

  /// Minutes charged from Buno on each day of the month, day 1 first.
  final List<int> dailyMinutes;
  final int rentals;
  final int stationsVisited;
  final Station favoriteStation;

  /// Rentals picked up at [favoriteStation].
  final int favoriteRentals;

  /// Share of the month's days the phone hit 0% ("never" at 0).
  final int deadPhonePercent;

  /// Whole hours charged over the month.
  int get hoursCharged => (dailyMinutes.fold<int>(0, (a, b) => a + b) / 60).round();
}

class MockWrapped {
  MockWrapped._();

  static final month = MonthWrapped(
    dailyMinutes: const [
      30, 0, 45, 0, 15, 60, 0, 40, 75, 0, 50, 0, 30, 0, 90, //
      0, 55, 0, 25, 0, 70, 40, 0, 20, 0, 100, 0, 50, 0, 45,
    ],
    rentals: 12,
    stationsVisited: 6,
    favoriteStation: mockStations.first,
    favoriteRentals: 5,
    deadPhonePercent: 0,
  );

  /// Today, for [bannerVisible]; tests swap it.
  static DateTime Function() clock = DateTime.now;

  /// The home banner runs on the first [bannerDays] days of a month.
  static const bannerDays = 3;

  /// Closed from home's banner (this month).
  static final dismissed = ValueNotifier<bool>(false);

  static bool isStartOfMonth(DateTime d) => d.day <= bannerDays;

  /// Home shows the banner at the start of a month until closed, or whenever
  /// the debug toggle ([MockSettings.wrappedNow]) is on.
  static bool get bannerVisible =>
      MockSettings.wrappedNow.value || (isStartOfMonth(clock()) && !dismissed.value);

  static void dismiss() {
    dismissed.value = true;
    MockSettings.wrappedNow.value = false;
  }

  static void reset() {
    clock = DateTime.now;
    dismissed.value = false;
  }
}

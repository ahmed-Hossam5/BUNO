import '../l10n/buno_locale.dart';

/// One trust level (/trust, reference 59): what it unlocks and how many
/// on-time returns reach it.
class TrustLevel {
  const TrustLevel({
    required this.number,
    required this.name,
    required this.maxHours,
    required this.maxUnits,
    required this.returnsNeeded,
  });

  final int number;
  final Tr name;

  /// Longest rental allowed, in hours.
  final int maxHours;

  /// Units held at the same time.
  final int maxUnits;

  /// On-time returns needed to reach this level. Mock: on screen it is
  /// `[العدد]`; it only picks the level and sizes the progress bar.
  final int returnsNeeded;

  /// Arabic: "ساعتين", "4 ساعات" (3..10), "24 ساعة".
  String get hoursText => switch (maxHours) {
        2 => tr('ساعتين', '2 hours'),
        >= 3 && <= 10 => tr('$maxHours ساعات', '$maxHours hours'),
        _ => tr('$maxHours ساعة', '$maxHours hours'),
      };

  String get unitsText => maxUnits == 1 ? tr('وحدة واحدة', '1 unit') : tr('وحدتين في نفس الوقت', '2 units at once');
}

/// Mock trust state. Levels go up with on-time returns; a late return drops
/// one level (the note at the bottom of /trust).
class MockTrust {
  MockTrust._();

  static const levels = [
    TrustLevel(number: 1, name: Tr('عميل جديد', 'New'), maxHours: 2, maxUnits: 1, returnsNeeded: 0),
    TrustLevel(number: 2, name: Tr('عميل منتظم', 'Regular'), maxHours: 4, maxUnits: 1, returnsNeeded: 3),
    TrustLevel(number: 3, name: Tr('عميل موثوق', 'Trusted'), maxHours: 24, maxUnits: 2, returnsNeeded: 10),
  ];

  static const _defaultReturns = 6;

  /// On-time returns so far.
  static int onTimeReturns = _defaultReturns;

  static TrustLevel get current => levels.lastWhere((l) => onTimeReturns >= l.returnsNeeded);

  /// `null` at the top level.
  static TrustLevel? get next {
    final i = levels.indexOf(current);
    return i + 1 < levels.length ? levels[i + 1] : null;
  }

  static void reset() => onTimeReturns = _defaultReturns;
}

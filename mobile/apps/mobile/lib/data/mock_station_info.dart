import 'mock_rental.dart';
import '../l10n/buno_locale.dart';

/// The time opening hours are checked against. Tests pin it.
DateTime Function() stationClock = DateTime.now;

/// Where a station is and when it is open (/station/info, /favorites).
/// Hours are whole hours, 0–24; [fridayOpens] null = closed on Friday.
class StationInfo {
  const StationInfo({
    required this._area,
    required this._landmark,
    required this.opens,
    required this.closes,
    this.fridayOpens,
    this.fridayCloses,
  });

  final Tr _area;
  final Tr _landmark;

  String get area => _area.text;

  /// How to spot it once there.
  String get landmark => _landmark.text;
  final int opens;
  final int closes;
  final int? fridayOpens;
  final int? fridayCloses;

  bool get allDay => opens == 0 && closes == 24;

  bool isOpenAt(DateTime t) {
    final friday = t.weekday == DateTime.friday;
    final from = friday ? fridayOpens : opens;
    final to = friday ? fridayCloses : closes;
    return from != null && to != null && t.hour >= from && t.hour < to;
  }

  /// The next whole hour at which it opens, within a week after [t]; null
  /// when it never opens.
  DateTime? nextOpening(DateTime t) {
    final start = DateTime(t.year, t.month, t.day, t.hour);
    for (var h = 1; h <= 24 * 7; h++) {
      final at = start.add(Duration(hours: h));
      if (isOpenAt(at)) return at;
    }
    return null;
  }

  /// "بتفتح بكرة الساعة 10 الصبح" (today / tomorrow / a weekday), or a
  /// plain "مقفولة" when it never opens.
  String opensLabel(DateTime now) {
    final at = nextOpening(now);
    if (at == null) return tr('مقفولة', 'Closed');
    final days = DateTime(at.year, at.month, at.day).difference(DateTime(now.year, now.month, now.day)).inDays;
    final day = switch (days) {
      0 => tr('النهارده', 'today'),
      1 => tr('بكرة', 'tomorrow'),
      _ => tr('يوم ${_weekdaysAr[at.weekday - 1]}', 'on ${_weekdaysEn[at.weekday - 1]}'),
    };
    final h12 = at.hour % 12 == 0 ? 12 : at.hour % 12;
    final part = at.hour < 12
        ? tr('الصبح', 'AM')
        : at.hour < 18
            ? tr('الضهر', 'PM')
            : tr('بالليل', 'PM');
    return tr('بتفتح $day الساعة $h12 $part', 'Opens $day at $h12 $part');
  }

  static const _weekdaysAr = ['الاتنين', 'التلات', 'الأربع', 'الخميس', 'الجمعة', 'السبت', 'الحد'];
  static const _weekdaysEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  /// e.g. "8 ص – 10 م", or "24 ساعة".
  String get hoursLabel => allDay ? tr('24 ساعة', '24 hours') : _range(opens, closes);

  /// Friday's hours, or "مقفولة".
  String get fridayLabel =>
      fridayOpens == null ? tr('مقفولة', 'Closed') : fridayOpens == 0 && fridayCloses == 24 ? tr('24 ساعة', '24 hours') : _range(fridayOpens!, fridayCloses!);

  static String _range(int from, int to) => '${_hour(from)} – ${_hour(to)}';

  static String _hour(int h) {
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12 ${h < 12 || h == 24 ? tr('ص', 'AM') : tr('م', 'PM')}';
  }
}

const _info = {
  'st-01': StationInfo(
    area: Tr('وسط البلد', 'Downtown'),
    landmark: Tr('جنب البوابة الرئيسية، قدام الكافتيريا', 'By the main gate, in front of the cafeteria'),
    opens: 0,
    closes: 24,
    fridayOpens: 0,
    fridayCloses: 24,
  ),
  'st-02': StationInfo(area: Tr('الزمالك', 'Zamalek'), landmark: Tr('في بهو المكتبة، الدور الأرضي', 'In the library lobby, ground floor'), opens: 8, closes: 22, fridayOpens: 12, fridayCloses: 22),
  'st-03': StationInfo(area: Tr('مدينة نصر', 'Nasr City'), landmark: Tr('عند مدخل مبنى المحاضرات', 'At the lecture building entrance'), opens: 8, closes: 18),
  'st-04': StationInfo(area: Tr('المعادي', 'Maadi'), landmark: Tr('جوه المبنى الإداري، جنب الأمن', 'Inside the admin building, next to security'), opens: 7, closes: 23, fridayOpens: 10, fridayCloses: 23),
};

/// Mock details for [station].
StationInfo stationInfo(Station station) => _info[station.id] ?? _info['st-01']!;

/// Whether [station] is open now ([stationClock]); its units can't be taken
/// or returned while it is closed.
bool isStationOpen(Station station) => stationInfo(station).isOpenAt(stationClock());

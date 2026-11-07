import 'package:flutter/foundation.dart';
import '../l10n/buno_locale.dart';

/// Exam week (debug toggle [MockSettings.examMode], or /exam): the next
/// exam and the study-night pack (8 pm to 8 am for one [السعر]). Mock data.
class MockExam {
  MockExam._();

  static String get subject => tr('[اسم المادة]', '[Course name]');
  static String get details => tr('[اليوم] · [الساعة] · [القاعة]', '[Day] · [Time] · [Hall]');
  static const daysLeft = 2;
}

/// The study-night pack: off until "فعّل الباقة الليلة".
class StudyNightSession extends ChangeNotifier {
  static const startHour = 20;
  static const endHour = 8;
  static const length = Duration(hours: 24 - startHour + endHour);

  /// Clock used for the countdown; tests replace it.
  DateTime Function() now = DateTime.now;

  bool _active = false;
  bool get active => _active;

  void start() {
    if (_active) return;
    _active = true;
    notifyListeners();
  }

  /// The pack's end: the next 8 am.
  DateTime get endsAt {
    final t = now();
    final today = DateTime(t.year, t.month, t.day, endHour);
    return t.isBefore(today) ? today : today.add(const Duration(days: 1));
  }

  /// Time left until [endsAt], at most [length] (in the daytime the pack
  /// hasn't started yet).
  Duration get remaining {
    final left = endsAt.difference(now());
    return left > length ? length : left;
  }

  /// 0 at 8 pm, 1 at 8 am.
  double get progress => 1 - remaining.inSeconds / length.inSeconds;

  @visibleForTesting
  void debugReset() {
    _active = false;
    now = DateTime.now;
    notifyListeners();
  }
}

final studyNight = StudyNightSession();

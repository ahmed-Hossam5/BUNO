import 'package:flutter/foundation.dart';

import 'phone_battery.dart';
import '../l10n/buno_locale.dart';

/// In-memory app settings (/settings). Nothing is persisted yet.
class MockSettings {
  MockSettings._();

  static final hourReminder = ValueNotifier<bool>(true);
  static final lowBatteryAlert = ValueNotifier<bool>(true);

  /// In-app "تقليل الحركة": BunoLottieIcon rests on its last frame while
  /// this is true, on top of the platform's reduced-motion setting.
  static final reduceMotion = ValueNotifier<bool>(false);

  /// Debug-only "تجربة: من غير نت": the home scan button and /confirm's
  /// unlock open /offline instead.
  static final simulateOffline = ValueNotifier<bool>(false);

  /// Debug-only "تجربة: أسبوع الامتحانات": home leads with the next exam
  /// and the study-night pack (as on /exam).
  static final examMode = ValueNotifier<bool>(false);

  /// Debug-only "تجربة: ملخص الشهر": home shows the /wrapped banner now,
  /// not only at the start of a month.
  static final wrappedNow = ValueNotifier<bool>(false);

  static void reset() {
    hourReminder.value = true;
    lowBatteryAlert.value = true;
    reduceMotion.value = false;
    simulateOffline.value = false;
    examMode.value = false;
    wrappedNow.value = false;
    PhoneBattery.debugOverride.value = BatteryDebug.real;
  }
}

/// Mock user shown on /profile/edit.
class MockProfile {
  MockProfile._();

  static String name = tr('[اسم المستخدم]', '[User name]');
  static String phone = '+20 1X XXXX XXXX';
  static String email = 'name@[uni].edu.eg';
}

class BunoNotification {
  const BunoNotification({
    required this.lottie,
    required this.title,
    required this.body,
    required this.time,
    this.unread = false,
  });

  /// Animated icon in assets/lottie/.
  final String lottie;
  final String title;
  final String body;
  final String time;
  final bool unread;
}

/// A getter so the copy follows the app language.
List<BunoNotification> get mockNotifications => [
  BunoNotification(lottie: 'clock', title: tr('فاضل 10 دقايق', '10 minutes left'), body: tr('وتبدأ الساعة التانية', 'until the next hour starts'), time: tr('دلوقتي', 'Now'), unread: true),
  BunoNotification(lottie: 'success', title: tr('رجع مكانه', 'Returned'), body: tr('الإيصال جاهز', 'Your receipt is ready'), time: '10:40', unread: true),
  BunoNotification(lottie: 'receipt', title: tr('اتضاف [المبلغ]', '[Amount] added'), body: tr('فودافون كاش', 'Vodafone Cash'), time: tr('امبارح', 'Yesterday')),
  BunoNotification(lottie: 'battery_low', title: tr('موبايلك تحت 20%', 'Your phone is under 20%'), body: tr('فيه محطة على بعد [الوقت]', 'There is a station [time] away'), time: tr('امبارح', 'Yesterday')),
  BunoNotification(lottie: 'heart', title: tr('صاحبك اشترك بكودك', 'Your friend joined with your code'), body: tr('30 دقيقة ببلاش ليك', '30 free minutes for you'), time: tr('السبت', 'Saturday')),
];

import 'package:buno/app_routes.dart';
import 'package:buno/data/mock_exam.dart';
import 'package:buno/data/mock_settings.dart';
import 'package:buno/main.dart';
import 'package:buno/screens/exam/exam_cards.dart';
import 'package:buno/screens/exam/exam_night_screen.dart';
import 'package:buno/screens/home/home_screen.dart';
import 'package:buno/screens/stations/stations_screen.dart';
import 'package:buno/widgets/buno_buttons.dart';
import 'package:buno/widgets/buno_charge_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_battery.dart';
import 'home_screen_test.dart' show loadBunoFonts;
import 'reduced_motion.dart';

const _sizes = [
  Size(390, 844),
  Size(375, 667),
  Size(360, 640),
  Size(320, 568),
  Size(430, 932),
  Size(412, 915),
];

Future<void> _pumpApp(WidgetTester tester, String route, {Size size = const Size(390, 844)}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(BunoApp(initialRoute: route));
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(find.text(text), 80, scrollable: find.byType(Scrollable).first);
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

/// 8:18 pm: 11:42 left until 8 am.
final _evening = DateTime(2026, 10, 27, 20, 18);

void main() {
  setUpAll(loadBunoFonts);
  setUp(useReducedMotion);
  setUp(() => useFakeBattery(level: 80));
  setUp(MockSettings.reset);
  setUp(studyNight.debugReset);

  group('no overflow, RTL', () {
    for (final size in _sizes) {
      final label = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('/exam at $label', (tester) async {
        await _pumpApp(tester, AppRoutes.exam, size: size);
        expect(tester.takeException(), isNull);
        expect(Directionality.of(tester.element(find.byType(HomeScreen))), TextDirection.rtl);
        expect(find.byType(ExamHomeCards), findsOneWidget);
        expect(find.byType(BunoPrimaryButton), findsOneWidget);
      });

      testWidgets('/exam/night at $label', (tester) async {
        studyNight.now = () => _evening;
        await _pumpApp(tester, AppRoutes.examNight, size: size);
        expect(tester.takeException(), isNull);
        expect(Directionality.of(tester.element(find.byType(ExamNightScreen))), TextDirection.rtl);
        expect(find.byType(BunoPrimaryButton), findsOneWidget);
      });
    }
  });

  testWidgets('settings toggle turns exam mode on for home', (tester) async {
    await _pumpApp(tester, AppRoutes.settings);
    await _tapText(tester, 'تجربة: أسبوع الامتحانات');
    expect(MockSettings.examMode.value, isTrue);
    Navigator.of(tester.element(find.byType(Scaffold).first)).pushNamed(AppRoutes.home);
    await tester.pumpAndSettle();
    expect(find.byType(ExamHomeCards), findsOneWidget);

    MockSettings.examMode.value = false;
    await tester.pumpAndSettle();
    expect(find.byType(ExamHomeCards), findsNothing);
  });

  testWidgets('home study-night card starts the pack and opens /exam/night', (tester) async {
    studyNight.now = () => _evening;
    MockSettings.examMode.value = true;
    await _pumpApp(tester, AppRoutes.home);
    await _tapText(tester, 'فعّل الباقة الليلة');
    expect(studyNight.active, isTrue);
    expect(find.byType(ExamNightScreen), findsOneWidget);
    expect(find.text('11:42'), findsOneWidget);
    final ring = tester.widget<BunoChargeRing>(find.byType(BunoChargeRing));
    expect(ring.progress, closeTo(18 / (12 * 60), 0.001));

    await tester.tap(find.textContaining('فكّرني الساعة', findRichText: true));
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);

    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();
    expect(find.byType(StationsScreen), findsOneWidget);

    // Back home, the card now says the pack is running.
    Navigator.of(tester.element(find.byType(StationsScreen))).popUntil((r) => r.isFirst);
    await tester.pumpAndSettle();
    expect(find.text('شوف الباقة'), findsOneWidget);
  });

  test('study night: daytime is a full 12 hours, 7:30 am has 30 minutes left', () {
    studyNight.now = () => DateTime(2026, 10, 27, 14);
    expect(studyNight.remaining, const Duration(hours: 12));
    expect(studyNight.progress, 0);
    studyNight.now = () => DateTime(2026, 10, 28, 7, 30);
    expect(studyNight.remaining, const Duration(minutes: 30));
  });
}

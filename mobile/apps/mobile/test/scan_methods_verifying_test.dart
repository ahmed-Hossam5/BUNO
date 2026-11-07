import 'package:buno/data/mock_rental.dart';
import 'package:buno/main.dart';
import 'package:buno/screens/rental/release_screen.dart';
import 'package:buno/screens/rental/unlocking_screen.dart';
import 'package:buno/screens/rental/verifying_screen.dart';
import 'package:buno/screens/scan/scan_code_screen.dart';
import 'package:buno/screens/scan/scan_methods_screen.dart';
import 'package:buno/screens/scan/scan_nfc_screen.dart';
import 'package:buno/screens/scan/scan_screen.dart';
import 'package:buno/screens/station/station_screen.dart';
import 'package:buno/widgets/buno_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_battery.dart';
import 'fake_scan_camera.dart';
import 'home_screen_test.dart' show loadBunoFonts;
import 'reduced_motion.dart';

Future<void> _pumpRoute(WidgetTester tester, Size size, String route, [Object? args]) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(BunoApp(key: UniqueKey()));
  await tester.pumpAndSettle();
  tester.state<NavigatorState>(find.byType(Navigator)).pushNamed(route, arguments: args);
  await tester.pumpAndSettle();
}

/// Runs the four checks, then the unlocking stages through to /release.
Future<void> _finishVerifying(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(VerifyingScreen.checkDuration);
  }
  await tester.pumpAndSettle();
  for (var i = 0; i < 5; i++) {
    await tester.pump(UnlockingScreen.stageDuration);
  }
  await tester.pumpAndSettle();
}

Finder _check(String title, String status) => find.bySemanticsLabel('$title، $status');

String _cta(WidgetTester tester) =>
    tester.widget<BunoPrimaryButton>(find.byType(BunoPrimaryButton)).label;

void main() {
  setUpAll(loadBunoFonts);
  setUp(useFakeBattery);
  setUp(useReducedMotion);
  setUp(useFakeScanCamera);
  tearDown(rentalSession.reset);

  // Same phone sizes as home_screen_test.dart.
  const sizes = [
    Size(390, 844),
    Size(375, 667),
    Size(360, 640),
    Size(320, 568),
    Size(430, 932),
    Size(412, 915),
  ];

  for (final size in sizes) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('/scan/methods: no overflow and RTL at $label', (tester) async {
      await _pumpRoute(tester, size, '/scan/methods');
      expect(tester.takeException(), isNull);
      expect(Directionality.of(tester.element(find.byType(ScanMethodsScreen))), TextDirection.rtl);
      // RTL: the QR card's title sits right of its "fastest" tag.
      expect(tester.getCenter(find.text('امسح الـ QR').first).dx,
          greaterThan(tester.getCenter(find.text('الأسرع')).dx));
    });

    testWidgets('/scan/nfc: no overflow and RTL at $label', (tester) async {
      await _pumpRoute(tester, size, '/scan/nfc');
      expect(tester.takeException(), isNull);
      expect(Directionality.of(tester.element(find.byType(ScanNfcScreen))), TextDirection.rtl);
      // Same title bar as /release: back sits at the end (left in RTL).
      expect(tester.getCenter(find.bySemanticsLabel('رجوع')).dx, lessThan(size.width / 2));
    });

    testWidgets('/verifying: no overflow and RTL at $label', (tester) async {
      await _pumpRoute(tester, size, '/verifying');
      expect(tester.takeException(), isNull);
      expect(Directionality.of(tester.element(find.byType(VerifyingScreen))), TextDirection.rtl);
      await _finishVerifying(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(ReleaseScreen), findsOneWidget);
    });
  }

  testWidgets('/scan "other ways" opens /scan/methods; QR goes back to the camera', (tester) async {
    await _pumpRoute(tester, const Size(390, 844), '/scan');
    await tester.tap(find.text('طرق تانية للفتح'));
    await tester.pumpAndSettle();
    expect(find.byType(ScanMethodsScreen), findsOneWidget);
    expect(_cta(tester), 'امسح الـ QR');

    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();
    expect(find.byType(ScanMethodsScreen), findsNothing);
    expect(find.byType(ScanScreen), findsOneWidget);
    // Popped back, not a second camera on top.
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.pop();
    await tester.pumpAndSettle();
    expect(find.byType(ScanScreen), findsNothing);
  });

  testWidgets('/scan/methods: selecting NFC or code changes the CTA and opens it', (tester) async {
    await _pumpRoute(tester, const Size(390, 844), '/scan/methods');

    await tester.tap(find.text('اكتب كود المحطة'));
    await tester.pumpAndSettle();
    expect(_cta(tester), 'اكتب الكود');
    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();
    expect(find.byType(ScanCodeScreen), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('قرّب الموبايل (NFC)'));
    await tester.pumpAndSettle();
    expect(_cta(tester), 'قرّب الموبايل');
    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();
    expect(find.byType(ScanNfcScreen), findsOneWidget);
  });

  testWidgets('/scan/nfc: debug tap opens /station for BUN-01; QR link opens /scan', (tester) async {
    await _pumpRoute(tester, const Size(390, 844), '/scan/nfc');
    await tester.tap(find.text('محاكاة لمس NFC (ديباج)'));
    await tester.pumpAndSettle();
    expect(tester.widget<StationScreen>(find.byType(StationScreen)).code, 'BUN-01');
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('امسح الـ QR بدل كده'));
    await tester.pumpAndSettle();
    expect(find.byType(ScanScreen), findsOneWidget);
    expect(find.byType(ScanNfcScreen), findsNothing);
  });

  testWidgets('/verifying: checks complete in order, back disabled, then /unlocking', (tester) async {
    final station = mockStations[3];
    await _pumpRoute(tester, const Size(390, 844), '/verifying', (station, 1));

    expect(_check('الكود بتاع بونو', 'جاري'), findsOneWidget);
    expect(_check('حسابك ورصيدك', 'لسه'), findsOneWidget);
    expect(find.textContaining('آخر نبضة', findRichText: true), findsOneWidget);

    await tester.pump(VerifyingScreen.checkDuration);
    expect(_check('الكود بتاع بونو', 'تم'), findsOneWidget);
    expect(_check('المحطة متصلة دلوقتي', 'جاري'), findsOneWidget);

    // System back does nothing while checking.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(VerifyingScreen), findsOneWidget);

    await tester.pump(VerifyingScreen.checkDuration);
    await tester.pump(VerifyingScreen.checkDuration);
    expect(_check('الكود لسه صالح', 'تم'), findsOneWidget);
    expect(_check('حسابك ورصيدك', 'جاري'), findsOneWidget);
    expect(rentalSession.state, RentalState.idle);

    await tester.pump(VerifyingScreen.checkDuration);
    await tester.pumpAndSettle();
    expect(find.byType(VerifyingScreen), findsNothing);
    expect(find.byType(UnlockingScreen), findsOneWidget);
    expect(rentalSession.station, same(station));
    expect(rentalSession.bayIndex, 1);

    for (var i = 0; i < 5; i++) {
      await tester.pump(UnlockingScreen.stageDuration);
    }
    await tester.pumpAndSettle();
    expect(find.byType(ReleaseScreen), findsOneWidget);
  });
}

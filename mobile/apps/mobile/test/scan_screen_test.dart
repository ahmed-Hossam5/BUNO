import 'package:buno/main.dart';
import 'package:buno/screens/scan/scan_code_screen.dart';
import 'package:buno/screens/scan/scan_screen.dart';
import 'package:buno/screens/station/station_screen.dart';
import 'package:buno/widgets/buno_buttons.dart';
import 'package:buno/widgets/buno_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_battery.dart';
import 'fake_scan_camera.dart';
import 'home_screen_test.dart' show loadBunoFonts;
import 'reduced_motion.dart';

Future<void> _pumpRoute(WidgetTester tester, Size size, String route) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(BunoApp(key: UniqueKey()));
  await tester.pumpAndSettle();
  tester.state<NavigatorState>(find.byType(Navigator)).pushNamed(route);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadBunoFonts);
  setUp(useFakeBattery);
  setUp(useReducedMotion);
  setUp(useFakeScanCamera);

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

    testWidgets('/scan: no overflow and RTL at $label', (tester) async {
      await _pumpRoute(tester, size, '/scan');
      expect(tester.takeException(), isNull);
      expect(find.byType(ScanScreen), findsOneWidget);
      expect(Directionality.of(tester.element(find.byType(ScanScreen))),
          TextDirection.rtl);
      // RTL: close on the right, torch on the left (as in 01_scan).
      final close = tester.getCenter(find.bySemanticsLabel('قفل'));
      final torch = tester.getCenter(find.bySemanticsLabel('نوّر الكشاف'));
      expect(close.dx, greaterThan(size.width / 2));
      expect(torch.dx, lessThan(size.width / 2));
    });

    testWidgets('/scan/code: no overflow and RTL at $label', (tester) async {
      await _pumpRoute(tester, size, '/scan/code');
      expect(tester.takeException(), isNull);
      expect(find.byType(ScanCodeScreen), findsOneWidget);
      expect(Directionality.of(tester.element(find.byType(BunoPrimaryButton))),
          TextDirection.rtl);
      await tester.enterText(find.byType(TextField), 'BUN-01');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('/station placeholder: no overflow at $label', (tester) async {
      await _pumpRoute(tester, size, '/station');
      expect(tester.takeException(), isNull);
      expect(find.byType(StationScreen), findsOneWidget);
    });
  }

  testWidgets('home scan button opens /scan', (tester) async {
    // Charged phone: home's main button scans (below 20% it reserves).
    useFakeBattery(level: 80);
    await _pumpRoute(tester, const Size(390, 844), '/');
    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();
    expect(find.byType(ScanScreen), findsOneWidget);
  });

  testWidgets('a station QR opens /station once, with the code', (tester) async {
    await _pumpRoute(tester, const Size(390, 844), '/scan');
    final camera = FakeScanCamera.last!;
    camera.detect('https://buno.app/s/BUN-02');
    camera.detect('https://buno.app/s/BUN-02');
    await tester.pumpAndSettle();
    expect(find.byType(StationScreen), findsOneWidget);
    expect(tester.widget<StationScreen>(find.byType(StationScreen)).code,
        'https://buno.app/s/BUN-02');
    expect(camera.paused, isTrue);

    await tester.tap(find.bySemanticsLabel('رجوع'));
    await tester.pumpAndSettle();
    expect(camera.paused, isFalse);
  });

  testWidgets('torch and debug simulate scan', (tester) async {
    await _pumpRoute(tester, const Size(390, 844), '/scan');
    await tester.tap(find.bySemanticsLabel('نوّر الكشاف'));
    await tester.pumpAndSettle();
    expect(FakeScanCamera.last!.torchToggles, 1);
    expect(find.bySemanticsLabel('اطفي الكشاف'), findsOneWidget);

    await tester.tap(find.text('محاكاة مسح (ديباج)'));
    await tester.pumpAndSettle();
    expect(tester.widget<StationScreen>(find.byType(StationScreen)).code,
        ScanScreen.debugCode);
  });

  testWidgets('code screen: formats, validates, continues', (tester) async {
    await _pumpRoute(tester, const Size(390, 844), '/scan');
    await tester.tap(find.text('مش راضي يمسح؟ اكتب الكود'));
    await tester.pumpAndSettle();
    expect(find.byType(ScanCodeScreen), findsOneWidget);

    BunoPrimaryButton cta() => tester.widget(find.byType(BunoPrimaryButton));
    expect(cta().onPressed, isNull);

    final field = find.byType(TextField);
    await tester.enterText(field, 'bun01');
    await tester.pump();
    expect(tester.widget<TextField>(field).controller!.text, 'BUN-01');
    expect(cta().onPressed, isNotNull);

    await tester.enterText(field, 'BUNXY');
    await tester.pump();
    expect(tester.widget<BunoOtpField>(find.byType(BunoOtpField)).hasError,
        isTrue);
    expect(cta().onPressed, isNull);

    await tester.enterText(field, 'BUN-07');
    await tester.pump();
    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();
    expect(tester.widget<StationScreen>(find.byType(StationScreen)).code,
        'BUN-07');
  });
}

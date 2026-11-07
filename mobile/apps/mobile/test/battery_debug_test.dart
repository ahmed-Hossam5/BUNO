import 'package:buno/app_routes.dart';
import 'package:buno/data/mock_settings.dart';
import 'package:buno/data/phone_battery.dart';
import 'package:buno/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_battery.dart';
import 'fake_scan_camera.dart';
import 'home_screen_test.dart' show loadBunoFonts;
import 'reduced_motion.dart';

void main() {
  setUpAll(loadBunoFonts);
  setUp(useReducedMotion);
  setUp(useFakeScanCamera);
  tearDown(MockSettings.reset);

  test('the override replaces the real reading and notifies', () async {
    useFakeBattery(level: 80);
    final battery = PhoneBattery.shared;
    var notified = 0;
    void listener() => notified++;
    battery.addListener(listener);
    await battery.refresh();
    expect(battery.reading, const BatteryReading(percent: 80, charging: false));

    notified = 0;
    PhoneBattery.debugOverride.value = BatteryDebug.percent12;
    expect(notified, 1);
    expect(battery.reading, const BatteryReading(percent: 12, charging: false));

    PhoneBattery.debugOverride.value = BatteryDebug.charging;
    expect(battery.reading.charging, isTrue);

    PhoneBattery.debugOverride.value = BatteryDebug.real;
    expect(battery.reading.percent, 80);
    battery.removeListener(listener);
  });

  testWidgets('picking a value in /settings drives home\'s battery pill and button', (tester) async {
    useFakeBattery(level: 80);
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const BunoApp(initialRoute: AppRoutes.settings));
    await tester.pumpAndSettle();

    Future<void> pick(String label) async {
      final option = find.textContaining(label, findRichText: true).last;
      await tester.ensureVisible(option);
      await tester.tap(option);
      await tester.pumpAndSettle();
    }

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    Future<void> showHome() async {
      navigator.pop();
      await tester.pumpAndSettle();
    }

    Future<void> showSettings() async {
      navigator.pushNamed(AppRoutes.settings);
      await tester.pumpAndSettle();
    }

    expect(find.text('تجربة: البطارية'), findsOneWidget);
    await pick('12%');
    expect(PhoneBattery.debugOverride.value, BatteryDebug.percent12);
    await showHome();
    expect(find.bySemanticsLabel(RegExp('شحن موبايلك 12%')), findsOneWidget);
    expect(find.text('احجزلي وودّيني'), findsOneWidget);

    await showSettings();
    await pick('بيشحن');
    await showHome();
    expect(find.bySemanticsLabel(RegExp('شحن موبايلك 47%، بيشحن')), findsOneWidget);
    expect(find.text('امسح وخد بونو'), findsOneWidget);

    await showSettings();
    await pick('31%');
    await showHome();
    expect(find.bySemanticsLabel(RegExp('شحن موبايلك 31%')), findsOneWidget);
    expect(find.text('امسح وخد بونو'), findsOneWidget);

    await showSettings();
    await pick('حقيقي');
    await showHome();
    expect(find.bySemanticsLabel(RegExp('شحن موبايلك 80%')), findsOneWidget);
  });
}

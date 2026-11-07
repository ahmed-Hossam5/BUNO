import 'package:buno/app_routes.dart';
import 'package:buno/data/mock_loading.dart';
import 'package:buno/data/mock_offline_code.dart';
import 'package:buno/data/mock_rental.dart';
import 'package:buno/data/mock_settings.dart';
import 'package:buno/data/mock_topup.dart';
import 'package:buno/main.dart';
import 'package:buno/screens/history/history_screen.dart';
import 'package:buno/screens/offline/no_internet_screen.dart';
import 'package:buno/screens/offline/offline_code_screen.dart';
import 'package:buno/screens/rental/report_screen.dart';
import 'package:buno/screens/rental/unlocking_screen.dart';
import 'package:buno/screens/scan/scan_code_screen.dart';
import 'package:buno/screens/scan/scan_screen.dart';
import 'package:buno/screens/stations/stations_screen.dart';
import 'package:buno/screens/topup/transfer_screen.dart';
import 'package:buno/widgets/buno_buttons.dart';
import 'package:buno/widgets/buno_empty_state.dart';
import 'package:buno/widgets/buno_skeleton.dart';
import 'package:buno/widgets/map_markers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_battery.dart';
import 'fake_scan_camera.dart';
import 'home_screen_test.dart' show loadBunoFonts;
import 'reduced_motion.dart';

Future<void> _pumpRoute(WidgetTester tester, String route, {Size size = const Size(390, 844), Object? arguments}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(BunoApp(key: UniqueKey()));
  await tester.pumpAndSettle();
  tester.state<NavigatorState>(find.byType(Navigator)).pushNamed(route, arguments: arguments);
  await tester.pumpAndSettle();
}

/// Opens [route] and taps its way to the empty state under test.
typedef _Reach = Future<void> Function(WidgetTester tester, Size size);

Future<void> _tapLink(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

final Map<String, _Reach> _states = {
  '26 no internet': (t, size) => _pumpRoute(t, AppRoutes.offline, size: size),
  '28 scan failed': (t, size) async {
    await _pumpRoute(t, AppRoutes.scan, size: size);
    FakeScanCamera.last!.detect('not-a-buno-code');
    await t.pumpAndSettle();
  },
  '42 fake QR': (t, size) async {
    await _pumpRoute(t, AppRoutes.scan, size: size);
    FakeScanCamera.last!.detect('https://example.com/pay?BUN-01');
    await t.pumpAndSettle();
  },
  '29 bay stuck': (t, size) async {
    await _pumpRoute(t, AppRoutes.unlocking, size: size);
    await _tapLink(t, 'تجربة: الخانة علقت');
  },
  '30 station full': (t, size) async {
    await _pumpRoute(t, AppRoutes.returnUnit, size: size);
    await _tapLink(t, 'تجربة: المحطة مليانة');
  },
  '31 top-up declined': (t, size) async {
    await _pumpRoute(t, AppRoutes.topupPending, size: size);
    await _tapLink(t, 'تجربة: التحويل اترفض');
  },
  '33 no history': (t, size) async {
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      home: HistoryScreen(session: RentalSession()),
    ));
    await t.pumpAndSettle();
  },
};

void main() {
  setUpAll(loadBunoFonts);
  setUp(useFakeBattery);
  setUp(useReducedMotion);
  setUp(useFakeScanCamera);

  tearDown(rentalSession.reset);
  tearDown(MockSettings.reset);

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
    final at = '${size.width.toInt()}x${size.height.toInt()}';

    for (final MapEntry(key: name, value: reach) in _states.entries) {
      testWidgets('$name: no overflow and RTL at $at', (tester) async {
        await reach(tester, size);
        expect(tester.takeException(), isNull);
        final state = find.byType(BunoEmptyState);
        expect(state, findsOneWidget);
        expect(Directionality.of(tester.element(state)), TextDirection.rtl);
        // One primary button, at the bottom.
        expect(find.byType(BunoPrimaryButton), findsOneWidget);
        expect(tester.getBottomLeft(find.byType(BunoPrimaryButton)).dy, greaterThan(size.height * 0.7));
        // Drain the mock timers (unlock, top-up review) before teardown.
        await tester.pump(const Duration(seconds: 3));
      });
    }

    testWidgets('32 loading skeleton then /stations: no overflow and RTL at $at', (tester) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(BunoApp(key: UniqueKey()));
      await tester.pumpAndSettle();
      tester.state<NavigatorState>(find.byType(Navigator)).pushNamed(AppRoutes.stations);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.byType(BunoSkeletonList), findsOneWidget);
      expect(Directionality.of(tester.element(find.byType(BunoSkeletonList))), TextDirection.rtl);
      expect(find.byType(StationChargePin), findsNothing);

      await tester.pumpAndSettle();
      expect(find.byType(BunoSkeletonList), findsNothing);
      expect(find.byType(StationChargePin), findsNWidgets(mockStations.length));
    });

    testWidgets('/offline-code: no overflow and RTL at $at', (tester) async {
      await _pumpRoute(tester, AppRoutes.offlineCode, size: size);
      expect(tester.takeException(), isNull);
      expect(Directionality.of(tester.element(find.byType(OfflineCodeScreen))), TextDirection.rtl);
    });
  }

  testWidgets('/history shows the skeleton for the mock load delay', (tester) async {
    await _pumpRoute(tester, AppRoutes.home);
    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed(AppRoutes.history);
    await tester.pump();
    await tester.pump(mockLoadDelay - const Duration(milliseconds: 100));
    expect(find.byType(BunoSkeletonList), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(BunoSkeletonList), findsNothing);
    expect(find.text('[السعر]'), findsNWidgets(rentalSession.history.length));
  });

  testWidgets('no internet: link opens /offline-code, retry goes back', (tester) async {
    await _pumpRoute(tester, AppRoutes.offline);
    await _tapLink(tester, 'افتح بكود من غير نت');
    expect(find.byType(OfflineCodeScreen), findsOneWidget);

    await _tapLink(tester, 'جرّب الاتصال تاني');
    await tester.tap(find.text('جرّب تاني'));
    await tester.pumpAndSettle();
    expect(find.byType(BunoEmptyState), findsNothing);
  });

  test('offline code: six digits, steady within a window, new in the next', () {
    final t0 = DateTime.fromMillisecondsSinceEpoch(offlineCodePeriod.inMilliseconds * 1000);
    final code = offlineCode(t0);
    expect(code, matches(RegExp(r'^\d{6}$')));
    expect(offlineCode(t0.add(const Duration(seconds: 29))), code);
    expect(offlineCode(t0.add(offlineCodePeriod)), isNot(code));
    expect(offlineCodeRemaining(t0), 1);
    expect(offlineCodeRemaining(t0.add(const Duration(seconds: 15))), closeTo(0.5, 1e-9));
  });

  testWidgets('/offline-code changes the code when the 30 s window rolls over', (tester) async {
    var now = DateTime.fromMillisecondsSinceEpoch(offlineCodePeriod.inMilliseconds * 1000 + 29000);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      home: OfflineCodeScreen(clock: () => now),
    ));
    final first = offlineCode(now);
    expect(find.bySemanticsLabel('الكود ${first.split('').join(' ')}'), findsOneWidget);

    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    final next = offlineCode(now);
    expect(next, isNot(first));
    expect(find.bySemanticsLabel('الكود ${next.split('').join(' ')}'), findsOneWidget);
  });

  testWidgets('scan failed: retry resumes the camera, link opens /scan/code', (tester) async {
    await _pumpRoute(tester, AppRoutes.scan);
    FakeScanCamera.last!.detect('hello');
    await tester.pumpAndSettle();
    expect(find.byType(BunoEmptyState), findsOneWidget);
    expect(FakeScanCamera.last!.paused, isTrue);

    await tester.tap(find.text('جرّب تاني'));
    await tester.pumpAndSettle();
    expect(find.byType(BunoEmptyState), findsNothing);
    expect(FakeScanCamera.last!.paused, isFalse);

    FakeScanCamera.last!.detect('hello');
    await tester.pumpAndSettle();
    await _tapLink(tester, 'اكتب كود المحطة');
    expect(find.byType(ScanCodeScreen), findsOneWidget);
  });

  testWidgets('fake QR: a foreign link warns, report opens /report, scan another resumes', (tester) async {
    expect(ScanScreen.isForeignLink('https://evil.example/BUN-01'), isTrue);
    expect(ScanScreen.isForeignLink('https://buno.app/s/BUN-01'), isFalse);
    expect(ScanScreen.isForeignLink('https://s.buno.app/BUN-01'), isFalse);
    expect(ScanScreen.isForeignLink('BUN-01'), isFalse);
    expect(ScanScreen.isForeignLink('hello'), isFalse);

    await _pumpRoute(tester, AppRoutes.scan);
    FakeScanCamera.last!.detect('https://example.com/pay?BUN-01');
    await tester.pumpAndSettle();
    expect(find.text('الكود ده مش بتاع بونو'), findsOneWidget);
    expect(find.text('الكود مش واضح'), findsNothing);

    await tester.tap(find.text('بلّغ عن الكود'));
    await tester.pumpAndSettle();
    expect(find.byType(ReportScreen), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    await _tapLink(tester, 'امسح كود تاني');
    expect(find.byType(BunoEmptyState), findsNothing);
    expect(FakeScanCamera.last!.paused, isFalse);

    // A plain non-Buno QR still gets the ordinary scan-failed state.
    FakeScanCamera.last!.detect('hello');
    await tester.pumpAndSettle();
    expect(find.text('الكود مش واضح'), findsOneWidget);
  });

  testWidgets('bay stuck: report link, retry restarts, back cancels the rental', (tester) async {
    await _pumpRoute(tester, AppRoutes.unlocking);
    await _tapLink(tester, 'تجربة: الخانة علقت');
    await _tapLink(tester, 'عندي مشكلة');
    expect(find.byType(ReportScreen), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('جرّب تاني'));
    await tester.pumpAndSettle();
    expect(find.byType(BunoEmptyState), findsNothing);
    expect(find.byType(UnlockingScreen), findsOneWidget);

    await _tapLink(tester, 'تجربة: الخانة علقت');
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(BunoEmptyState), findsOneWidget, reason: 'stays stuck after the mock unlock completes');
    await tester.tap(find.bySemanticsLabel('رجوع'));
    await tester.pumpAndSettle();
    expect(find.byType(UnlockingScreen), findsNothing);
    expect(rentalSession.state, RentalState.idle);
  });

  testWidgets('station full: button opens /stations', (tester) async {
    await _pumpRoute(tester, AppRoutes.returnUnit);
    await _tapLink(tester, 'تجربة: المحطة مليانة');
    expect(find.textContaining('[المدة]', findRichText: true), findsOneWidget);
    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();
    expect(find.byType(StationsScreen), findsOneWidget);
  });

  testWidgets('top-up declined: balance unchanged, button reopens the transfer', (tester) async {
    final before = rentalSession.balance;
    await _pumpRoute(tester, AppRoutes.topupPending);
    await _tapLink(tester, 'تجربة: التحويل اترفض');
    await tester.pump(topupReviewDelay);
    await tester.pumpAndSettle();
    expect(find.byType(BunoEmptyState), findsOneWidget);
    expect(rentalSession.balance, before);

    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();
    expect(find.byType(TransferScreen), findsOneWidget);
  });

  testWidgets('debug "من غير نت" in /settings: home scan and /confirm open /offline', (tester) async {
    // Charged phone: home's main button scans (below 20% it reserves).
    useFakeBattery(level: 80);
    await _pumpRoute(tester, AppRoutes.settings);
    await _tapLink(tester, 'تجربة: من غير نت');
    expect(MockSettings.simulateOffline.value, isTrue);

    await _pumpRoute(tester, AppRoutes.home);
    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();
    expect(find.byType(NoInternetScreen), findsOneWidget);
    expect(find.byType(ScanScreen), findsNothing);

    await _pumpRoute(tester, AppRoutes.confirm);
    await tester.tap(find.text('تمام، افتح الخانة'));
    await tester.pumpAndSettle();
    expect(find.byType(NoInternetScreen), findsOneWidget);
    expect(find.byType(UnlockingScreen), findsNothing);
    expect(rentalSession.state, RentalState.idle);

    await _tapLink(tester, 'افتح بكود من غير نت');
    expect(find.byType(OfflineCodeScreen), findsOneWidget);
  });

  testWidgets('with "من غير نت" off, home scan opens /scan as usual', (tester) async {
    // Charged phone: home's main button scans (below 20% it reserves).
    useFakeBattery(level: 80);
    await _pumpRoute(tester, AppRoutes.home);
    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();
    expect(find.byType(ScanScreen), findsOneWidget);
  });
}

import 'package:buno/data/mock_rental.dart';
import 'package:buno/main.dart';
import 'package:buno/screens/rental/active_rental_screen.dart';
import 'package:buno/screens/rental/release_screen.dart';
import 'package:buno/screens/rental/unlocking_screen.dart';
import 'package:buno/screens/rental/verifying_screen.dart';
import 'package:buno/screens/station/confirm_screen.dart';
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

/// Runs the mock stages through to /release.
Future<void> _finishUnlocking(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(UnlockingScreen.stageDuration);
  }
  await tester.pumpAndSettle();
}

/// /confirm opens /verifying first; runs its four checks to /unlocking.
Future<void> _passChecks(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 4; i++) {
    await tester.pump(VerifyingScreen.checkDuration);
  }
}

Finder _stage(String title, String status) => find.bySemanticsLabel('$title، $status');

void main() {
  setUpAll(loadBunoFonts);
  setUp(useFakeBattery);
  setUp(useReducedMotion);
  setUp(useFakeScanCamera);

  tearDown(() {
    // Put the unit back so the next test starts idle with full bays.
    if (rentalSession.state == RentalState.active) {
      rentalSession.returnTo(rentalSession.station!, rentalSession.bayIndex!);
      rentalSession.finish();
    }
    rentalSession.reset();
  });

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
    testWidgets('/unlocking and /release: no overflow and RTL at '
        '${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      await _pumpRoute(tester, size, '/unlocking');
      expect(tester.takeException(), isNull);
      expect(Directionality.of(tester.element(find.byType(UnlockingScreen))), TextDirection.rtl);

      await _finishUnlocking(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(ReleaseScreen), findsOneWidget);
      expect(Directionality.of(tester.element(find.byType(ReleaseScreen))), TextDirection.rtl);
    });
  }

  testWidgets('/unlocking: stages advance in order, back is disabled', (tester) async {
    final station = mockStations[3];
    await _pumpRoute(tester, const Size(390, 844), '/confirm', (station, 4));
    await tester.tap(find.byType(BunoPrimaryButton));
    await _passChecks(tester);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(UnlockingScreen), findsOneWidget);
    expect(find.bySemanticsLabel('خانة 5'), findsOneWidget);
    expect(_stage('الطلب اتبعت', 'جاري'), findsOneWidget);
    expect(_stage('المحطة استلمت الأمر', 'لسه'), findsOneWidget);
    expect(find.text('مفيش فلوس بتتخصم غير لما الوحدة تخرج فعلًا.'), findsOneWidget);

    await tester.pump(UnlockingScreen.stageDuration);
    expect(_stage('الطلب اتبعت', 'تم'), findsOneWidget);
    expect(_stage('المحطة استلمت الأمر', 'جاري'), findsOneWidget);
    expect(_stage('القفل بيفتح', 'لسه'), findsOneWidget);

    await tester.pump(UnlockingScreen.stageDuration);
    expect(_stage('القفل بيفتح', 'جاري'), findsOneWidget);
    expect(rentalSession.state, RentalState.released);

    await tester.pump(UnlockingScreen.stageDuration);
    expect(_stage('القفل بيفتح', 'تم'), findsOneWidget);
    expect(_stage('اسحب الوحدة', 'جاري'), findsOneWidget);

    // System back does nothing while unlocking.
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(UnlockingScreen), findsOneWidget);

    await tester.pump(UnlockingScreen.stageDuration);
    await tester.pumpAndSettle();
    expect(find.byType(UnlockingScreen), findsNothing);
    expect(find.byType(ReleaseScreen), findsOneWidget);
  });

  testWidgets('/release: خدتها starts the rental and replaces the flow', (tester) async {
    await _pumpRoute(tester, const Size(390, 844), '/confirm', (mockStations.first, 0));
    await tester.tap(find.byType(BunoPrimaryButton));
    await _passChecks(tester);
    await _finishUnlocking(tester);

    expect(find.text('الكابل جوه الوحدة. وصّله بموبايلك وامشي.'), findsOneWidget);
    expect(find.bySemanticsLabel('خانة 1'), findsOneWidget);
    expect(tester.widget<BunoPrimaryButton>(find.byType(BunoPrimaryButton)).label, 'خدتها');

    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();
    expect(rentalSession.state, RentalState.active);
    expect(rentalSession.startedAt, isNotNull);
    expect(mockStations.first.bays[0], isNull);
    expect(find.byType(ActiveRentalScreen), findsOneWidget);
    // Read from startedAt (just now), not the 01:12 mock.
    expect(find.text('00:00'), findsOneWidget);

    // Nothing of the rental flow is left behind /rental.
    expect(find.byType(ReleaseScreen, skipOffstage: false), findsNothing);
    expect(find.byType(ConfirmScreen, skipOffstage: false), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ReleaseScreen), findsNothing);
  });

  testWidgets('/release: back cancels the open bay', (tester) async {
    await _pumpRoute(tester, const Size(390, 844), '/confirm', (mockStations.first, 1));
    await tester.tap(find.byType(BunoPrimaryButton));
    await _passChecks(tester);
    await _finishUnlocking(tester);
    expect(rentalSession.state, RentalState.released);

    await tester.tap(find.bySemanticsLabel('رجوع'));
    await tester.pumpAndSettle();
    expect(rentalSession.state, RentalState.idle);
    expect(find.byType(ConfirmScreen), findsOneWidget);
  });
}

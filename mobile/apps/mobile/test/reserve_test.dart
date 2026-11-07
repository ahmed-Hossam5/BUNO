import 'package:buno/app_routes.dart';
import 'package:buno/data/mock_rental.dart';
import 'package:buno/main.dart';
import 'package:buno/screens/home/home_screen.dart';
import 'package:buno/screens/reserve/reserve_screen.dart';
import 'package:buno/screens/reserve/reserved_screen.dart';
import 'package:buno/screens/scan/scan_screen.dart';
import 'package:buno/widgets/buno_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_battery.dart';
import 'fake_scan_camera.dart';
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

/// Removes the app so /reserved's ticker doesn't outlive the test.
Future<void> _unmount(WidgetTester tester) => tester.pumpWidget(const SizedBox());

void main() {
  setUpAll(loadBunoFonts);
  setUp(useReducedMotion);
  setUp(useFakeScanCamera);
  setUp(reservationSession.cancel);
  tearDown(reservationSession.cancel);

  group('ReservationSession', () {
    late DateTime now;
    late ReservationSession session;

    setUp(() {
      now = DateTime(2026, 10, 26, 12);
      session = ReservationSession(hold: const Duration(minutes: 10), clock: () => now);
    });

    test('holds the best ready bay until the hold runs out', () {
      final st = mockStations.first;
      final r = session.reserve(st);
      expect(r.station, st);
      expect(r.bayIndex, st.bestBayIndex);
      expect(session.remaining, const Duration(minutes: 10));

      now = now.add(const Duration(minutes: 2, seconds: 36));
      expect(session.remaining, const Duration(minutes: 7, seconds: 24));
      expect(session.expireIfDue(), isFalse);

      now = now.add(const Duration(minutes: 8));
      expect(session.current, isNull);
      expect(session.remaining, Duration.zero);
      var notified = false;
      session.addListener(() => notified = true);
      expect(session.expireIfDue(), isTrue);
      expect(notified, isTrue);
      expect(session.expireIfDue(), isFalse);
    });

    test('one at a time; cancel releases the bay', () {
      session.reserve(mockStations.first);
      expect(() => session.reserve(mockStations.first), throwsStateError);
      session.cancel();
      expect(session.current, isNull);
      expect(session.reserve(mockStations.first), isNotNull);
    });

    test('a station without ready units cannot be reserved', () {
      expect(() => session.reserve(mockStations[2]), throwsArgumentError);
    });

    test('a bay opening for a rental ends the reservation', () async {
      final rental = RentalSession(unlockDelay: Duration.zero, reservation: session);
      final st = Station(id: 't', code: 'BUN-99', name: 't', walkMinutes: 1, bays: [80, 60]);
      session.reserve(st);
      final unlocking = rental.unlock(st, 1);
      // Still held while the bay is unlocking.
      expect(session.current, isNotNull);
      await unlocking;
      expect(rental.state, RentalState.released);
      expect(session.current, isNull);
    });

    test('nearest ready station skips stations with only low units', () {
      expect(nearestReadyStation()!.code, 'BUN-01');
    });
  });

  for (final route in [AppRoutes.reserve, AppRoutes.reserved]) {
    for (final size in _sizes) {
      testWidgets('$route: no overflow and RTL at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        useFakeBattery();
        await _pumpApp(tester, route, size: size);
        expect(tester.takeException(), isNull);
        final ctx = tester.element(find.byType(BunoPrimaryButton));
        expect(Directionality.of(ctx), TextDirection.rtl);
        // One primary button, at the bottom.
        expect(find.byType(BunoPrimaryButton), findsOneWidget);
        expect(tester.getCenter(find.byType(BunoPrimaryButton)).dy, greaterThan(size.height / 2));
        await _unmount(tester);
      });
    }
  }

  testWidgets('phone below 20%: home → reserve → countdown → scan', (tester) async {
    useFakeBattery(level: 18);
    await _pumpApp(tester, AppRoutes.home);

    await tester.tap(find.text('احجزلي وودّيني'));
    await tester.pumpAndSettle();
    expect(find.byType(ReserveScreen), findsOneWidget);
    expect(find.text('محطة التحرير'), findsOneWidget);

    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();
    expect(find.byType(ReservedScreen), findsOneWidget);
    final r = reservationSession.current!;
    expect(r.station.code, 'BUN-01');
    expect(find.textContaining('#${r.bayIndex + 1}', findRichText: true), findsOneWidget);

    // The countdown starts from the full hold.
    expect(find.text('10:00').evaluate().length + find.text('09:59').evaluate().length, 1);

    await tester.tap(find.text('وصلت؟ امسح'));
    await tester.pumpAndSettle();
    expect(find.byType(ScanScreen), findsOneWidget);
    expect(reservationSession.current, isNotNull);
    await _unmount(tester);
  });

  testWidgets('cancel releases the bay and goes home', (tester) async {
    useFakeBattery(level: 18);
    await _pumpApp(tester, AppRoutes.reserved);
    expect(reservationSession.current, isNotNull);

    await tester.tap(find.text('ألغي الحجز'));
    await tester.pumpAndSettle();
    expect(reservationSession.current, isNull);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(ReservedScreen), findsNothing);
    expect(find.text('اتلغى الحجز'), findsOneWidget);
  });

  testWidgets('charged phone scans; with a bay held, home opens the countdown', (tester) async {
    useFakeBattery(level: 80);
    await _pumpApp(tester, AppRoutes.home);
    expect(find.text('امسح وخد بونو'), findsOneWidget);
    expect(find.text('احجزلي وودّيني'), findsNothing);

    reservationSession.reserve(mockStations.first);
    await tester.pump();
    // Home shows the held bay (reference 112); its ring opens /reserved.
    await tester.tap(find.bySemanticsLabel(RegExp('^فاضل على الحجز')));
    await tester.pumpAndSettle();
    expect(find.byType(ReservedScreen), findsOneWidget);
    await _unmount(tester);
  });
}

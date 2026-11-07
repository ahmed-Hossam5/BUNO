import 'package:buno/data/mock_rental.dart';
import 'package:buno/main.dart';
import 'package:buno/screens/home/home_screen.dart';
import 'package:buno/screens/rental/active_rental_screen.dart';
import 'package:buno/screens/rental/receipt_screen.dart';
import 'package:buno/screens/rental/report_screen.dart';
import 'package:buno/screens/rental/return_done_screen.dart';
import 'package:buno/screens/rental/return_screen.dart';
import 'package:buno/screens/rental/verifying_screen.dart';
import 'package:buno/screens/station/station_screen.dart';
import 'package:buno/screens/stations/stations_screen.dart';
import 'package:buno/widgets/buno_buttons.dart';
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

/// Takes the best unit of the first station: the session ends up active.
Future<void> _startRental(WidgetTester tester) async {
  final station = mockStations.first;
  final unlocking = rentalSession.unlock(station, station.bestBayIndex!);
  await tester.pump(rentalSession.unlockDelay);
  await unlocking;
  rentalSession.confirmPickup();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
}

BunoPrimaryButton _primary(WidgetTester tester) =>
    tester.widget<BunoPrimaryButton>(find.byType(BunoPrimaryButton));

void main() {
  setUpAll(loadBunoFonts);
  setUp(useFakeBattery);
  setUp(useReducedMotion);
  setUp(useFakeScanCamera);

  // Returns move units between bays; put every station back as it was.
  late List<List<int?>> bays;
  late List<List<UnitTag?>> units;
  setUp(() {
    bays = [for (final s in mockStations) List.of(s.bays)];
    units = [for (final s in mockStations) List.of(s.units)];
  });
  tearDown(() {
    if (rentalSession.state == RentalState.active) {
      rentalSession.returnTo(rentalSession.station!, rentalSession.bayIndex!);
      rentalSession.finish();
    }
    rentalSession.reset();
    for (final (i, s) in mockStations.indexed) {
      s.bays.setAll(0, bays[i]);
      s.units.setAll(0, units[i]);
    }
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

  const screens = {
    '/report': ReportScreen,
    '/return': ReturnScreen,
    '/return/done': ReturnDoneScreen,
    '/receipt': ReceiptScreen,
  };

  for (final size in sizes) {
    final at = '${size.width.toInt()}x${size.height.toInt()}';
    for (final MapEntry(key: route, value: type) in screens.entries) {
      testWidgets('$route: no overflow and RTL at $at', (tester) async {
        await _pumpRoute(tester, size, route);
        expect(tester.takeException(), isNull);
        expect(find.byType(type), findsOneWidget);
        expect(Directionality.of(tester.element(find.byType(type))), TextDirection.rtl);
        expect(find.byType(BunoPrimaryButton), findsOneWidget);
      });
    }

    testWidgets('/station while renting (return mode): no overflow and RTL at $at', (tester) async {
      await _pumpRoute(tester, size, '/');
      await _startRental(tester);
      tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/station', arguments: 'BUN-01');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(Directionality.of(tester.element(find.byType(StationScreen))), TextDirection.rtl);
      expect(_primary(tester).label, 'حطيته في خانة 1');
    });

    testWidgets('hour-warning sheet: no overflow and RTL at $at', (tester) async {
      await _pumpRoute(tester, size, '/rental');
      await _tapText(tester, 'تجربة: تنبيه الساعة');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(HourWarningSheet), findsOneWidget);
      expect(Directionality.of(tester.element(find.byType(HourWarningSheet))), TextDirection.rtl);
    });
  }

  testWidgets('hour warning opens at 50 minutes; CTA goes to /return', (tester) async {
    await _pumpRoute(tester, const Size(390, 844), '/');
    tester.state<NavigatorState>(find.byType(Navigator)).push(MaterialPageRoute<void>(
          builder: (_) => const ActiveRentalScreen(initialElapsed: Duration(minutes: 49, seconds: 58)),
        ));
    await tester.pumpAndSettle();
    expect(find.byType(HourWarningSheet), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byType(HourWarningSheet), findsOneWidget);

    // Shown once, not every tick after.
    await tester.tap(find.text('هكمّل الساعة التانية'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(find.byType(HourWarningSheet), findsNothing);

    await _tapText(tester, 'تجربة: تنبيه الساعة');
    await tester.pumpAndSettle();
    await tester.tap(find.text('ودّيني أرجّعه'));
    await tester.pumpAndSettle();
    expect(find.byType(HourWarningSheet), findsNothing);
    expect(find.byType(ReturnScreen), findsOneWidget);
  });

  testWidgets('/rental links to /report and /return', (tester) async {
    await _pumpRoute(tester, const Size(390, 844), '/rental');
    await tester.tap(find.text('فيه مشكلة؟'));
    await tester.pumpAndSettle();
    expect(find.byType(ReportScreen), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('رجوع'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('رجّعه'));
    await tester.pumpAndSettle();
    expect(find.byType(ReturnScreen), findsOneWidget);

    await tester.tap(find.text('المحطة مش بتستلم؟'));
    await tester.pumpAndSettle();
    expect(find.byType(ReportScreen), findsOneWidget);
  });

  testWidgets('/report: send needs a choice, then snackbar and back', (tester) async {
    await _pumpRoute(tester, const Size(390, 844), '/report');
    expect(_primary(tester).onPressed, isNull);
    expect(find.text('العداد وقف من لحظة البلاغ.'), findsOneWidget);

    await tester.tap(find.text('سخن أو مكسور'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('سخن أو مكسور، مختار'), findsOneWidget);

    await tester.tap(find.text('ابعت البلاغ'));
    await tester.pumpAndSettle();
    expect(find.byType(ReportScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text(ReportScreen.sentMessage), findsOneWidget);
  });

  testWidgets('return → done → receipt → home', (tester) async {
    await _pumpRoute(tester, const Size(390, 844), '/');
    await _startRental(tester);
    final pickup = rentalSession.station!;
    final dropoff = nearestReturnStation()!;
    final bay = dropoff.firstEmptyBay!;
    final balance = rentalSession.balance;

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/return');
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('الخانة المنوّرة رقم ${bay + 1}'), findsOneWidget);

    await _tapText(tester, 'تجربة: حطيته في الخانة');
    await tester.pumpAndSettle();
    expect(rentalSession.state, RentalState.returned);
    expect(rentalSession.returnStation, dropoff);
    expect(rentalSession.returnBayIndex, bay);
    expect(dropoff.bays[bay], rentalSession.unitCharge);
    expect(rentalSession.balance, balance);
    expect(find.byType(ReturnDoneScreen), findsOneWidget);
    expect(find.byType(ReturnScreen, skipOffstage: false), findsNothing);
    expect(find.text('أقل من دقيقة · من المحفظة'), findsOneWidget);

    await tester.tap(find.text('شوف الإيصال'));
    await tester.pumpAndSettle();
    expect(find.byType(ReceiptScreen), findsOneWidget);
    expect(find.byType(ReturnDoneScreen, skipOffstage: false), findsNothing);
    expect(find.text(pickup.name), findsWidgets);
    expect(find.text(dropoff.name), findsWidgets);
    expect(find.text('أقل من دقيقة'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('4 من 5'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('4 من 5، متقيّم'), findsOneWidget);
    expect(find.bySemanticsLabel('5 من 5'), findsOneWidget);

    await tester.tap(find.text('PDF'));
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);

    await tester.tap(find.text('تمام'));
    await tester.pumpAndSettle();
    expect(rentalSession.state, RentalState.idle);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(ReceiptScreen, skipOffstage: false), findsNothing);
  });

  // Regression: in profile/release builds the only way on from /return is
  // "nearest station" → /stations → /station, whose CTA used to open /confirm
  // and hit the "already renting" guard. It must return the unit instead.
  testWidgets('active rental: /return → nearest station → pick a bay → returned', (tester) async {
    await _pumpRoute(tester, const Size(390, 844), '/');
    await _startRental(tester);
    final dropoff = nearestReturnStation()!;
    final emptyBays = [for (var i = 0; i < 8; i++) if (dropoff.bays[i] == null) i];
    final bay = emptyBays.last;

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/return');
    await tester.pumpAndSettle();
    await tester.tap(find.text('ودّيني لأقرب محطة'));
    await tester.pumpAndSettle();
    expect(find.byType(StationsScreen), findsOneWidget);

    // The map preselects the nearest return station; its card opens /station.
    await tester.tap(find.bySemanticsLabel(RegExp('^${dropoff.name}،')));
    await tester.pumpAndSettle();
    expect(find.byType(StationScreen), findsOneWidget);
    expect(_primary(tester).label, 'حطيته في خانة ${emptyBays.first + 1}');

    // Choose another empty bay; ready bays can't be picked for a return.
    await tester.tap(find.bySemanticsLabel('خانة ${bay + 1} فاضية'));
    await tester.pumpAndSettle();
    expect(_primary(tester).label, 'حطيته في خانة ${bay + 1}');

    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();
    expect(find.text('عندك إيجار شغّال بالفعل'), findsNothing);
    expect(find.byType(VerifyingScreen), findsNothing);
    expect(find.byType(ReturnDoneScreen), findsOneWidget);
    expect(rentalSession.state, RentalState.returned);
    expect(rentalSession.returnStation, dropoff);
    expect(rentalSession.returnBayIndex, bay);
    expect(dropoff.bays[bay], rentalSession.unitCharge);
    expect(dropoff.units[bay], rentalSession.unit);
  });

  testWidgets('active rental: a second rental is still blocked', (tester) async {
    await _pumpRoute(tester, const Size(390, 844), '/');
    await _startRental(tester);
    final other = mockStations[3];
    final bay = other.bestBayIndex!;

    expect(() => rentalSession.unlock(other, bay), throwsStateError);

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/confirm', arguments: (other, bay));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();
    expect(find.text('عندك إيجار شغّال بالفعل'), findsOneWidget);
    expect(find.byType(VerifyingScreen), findsNothing);
    expect(rentalSession.state, RentalState.active);
    expect(other.bays[bay], isNotNull);
  });

  testWidgets('/return: simulate does nothing without an active rental', (tester) async {
    await _pumpRoute(tester, const Size(390, 844), '/return');
    await _tapText(tester, 'تجربة: حطيته في الخانة');
    await tester.pump();
    expect(find.text('مفيش إيجار شغّال'), findsOneWidget);
    expect(find.byType(ReturnScreen), findsOneWidget);
    expect(rentalSession.state, RentalState.idle);
  });
}

import 'package:buno/app_routes.dart';
import 'package:buno/data/mock_rental.dart';
import 'package:buno/main.dart';
import 'package:buno/screens/history/history_screen.dart';
import 'package:buno/screens/rental/receipt_screen.dart';
import 'package:buno/screens/station/station_screen.dart';
import 'package:buno/screens/stations/all_stations_screen.dart';
import 'package:buno/screens/stations/stations_screen.dart';
import 'package:buno/theme/buno_tokens.dart';
import 'package:buno/widgets/buno_bottom_nav.dart';
import 'package:buno/widgets/buno_text.dart';
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

/// Colour of the list's charge text [text] ("92%", "—").
Color? _chargeColour(WidgetTester tester, String text) =>
    tester.widget<BunoText>(find.byWidgetPredicate((w) => w is BunoText && w.text == text)).style.color;

/// Station names in the order the list shows them (top to bottom).
List<String> _listedNames(WidgetTester tester) {
  final names = mockStations.map((s) => s.name).toSet();
  final found = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().where(names.contains);
  return found.toList();
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
    final at = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('/stations map and list: no overflow and RTL at $at', (tester) async {
      await _pumpRoute(tester, AppRoutes.stations, size: size);
      expect(tester.takeException(), isNull);
      expect(Directionality.of(tester.element(find.byType(StationsScreen))), TextDirection.rtl);
      expect(find.byType(StationChargePin), findsNWidgets(mockStations.length));

      await tester.tap(find.text('قايمة'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(StationChargePin), findsNothing);
    });

    testWidgets('/history list and empty state: no overflow and RTL at $at', (tester) async {
      await _pumpRoute(tester, AppRoutes.history, size: size);
      expect(tester.takeException(), isNull);
      expect(Directionality.of(tester.element(find.byType(HistoryScreen))), TextDirection.rtl);
      expect(find.text('[السعر]'), findsNWidgets(rentalSession.history.length));

      tester.view.physicalSize = size * 3;
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
        home: HistoryScreen(session: RentalSession()),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('لسه مأجرتش'), findsOneWidget);
    });
  }

  testWidgets('/stations pins and rows: green, amber, red for only-low units, grey dash when empty', (tester) async {
    await _pumpRoute(tester, AppRoutes.stations);
    final pins = tester.widgetList<StationChargePin>(find.byType(StationChargePin)).map((p) => p.charge);
    expect(pins.toSet(), {92, 41, 15, null});


    await tester.tap(find.text('قايمة'));
    await tester.pumpAndSettle();
    expect(_chargeColour(tester, '92%'), BunoColors.success);
    expect(_chargeColour(tester, '41%'), BunoColors.warning);
    expect(_chargeColour(tester, '15%'), BunoColors.error);
    expect(_chargeColour(tester, '—'), BunoDark.text_disabled);
  });

  testWidgets('/stations list sorts by walk, filters, and opens a station', (tester) async {
    await _pumpRoute(tester, AppRoutes.stations);
    await tester.tap(find.text('قايمة'));
    await tester.pumpAndSettle();

    final byWalk = [...mockStations]..sort((a, b) => a.walkMinutes.compareTo(b.walkMinutes));
    expect(_listedNames(tester), byWalk.map((s) => s.name).toList());

    await tester.tap(find.text('فيها وحدات'));
    await tester.pumpAndSettle();
    expect(_listedNames(tester), byWalk.where((s) => s.readyCount > 0).map((s) => s.name).toList());

    await tester.tap(find.text('الأقرب'));
    await tester.pumpAndSettle();
    expect(
      _listedNames(tester),
      byWalk.where((s) => s.readyCount > 0 && s.walkMinutes <= StationFilter.nearbyMinutes).map((s) => s.name).toList(),
    );

    await tester.tap(find.text(byWalk.first.name));
    await tester.pumpAndSettle();
    final station = tester.widget<StationScreen>(find.byType(StationScreen));
    expect(station.code, byWalk.first.code);
  });

  testWidgets('/stations map: tapping the selected pin opens its station', (tester) async {
    final target = mockStations[1];
    await _pumpRoute(tester, AppRoutes.stations, arguments: target.code);
    final pin = find.byWidgetPredicate((w) => w is StationChargePin && w.selected);
    expect(tester.widget<StationChargePin>(pin).charge, target.topCharge);
    await tester.tap(pin);
    await tester.pumpAndSettle();
    expect(tester.widget<StationScreen>(find.byType(StationScreen)).code, target.code);
  });

  testWidgets('home "all stations" chip opens /stations/all', (tester) async {
    await _pumpRoute(tester, AppRoutes.home);
    await tester.tap(find.text('كل المحطات'));
    await tester.pumpAndSettle();
    expect(find.byType(AllStationsScreen), findsOneWidget);
  });

  testWidgets('/return "take me to the nearest station" opens /stations', (tester) async {
    await _pumpRoute(tester, AppRoutes.returnUnit);
    await tester.tap(find.text('ودّيني لأقرب محطة'));
    await tester.pumpAndSettle();
    expect(tester.widget<StationsScreen>(find.byType(StationsScreen)).selectCode, nearestReturnStation()!.code);
  });

  testWidgets('/history is the second tab, and a trip opens its receipt', (tester) async {
    await _pumpRoute(tester, AppRoutes.wallet);
    await tester.tap(find.text('رحلاتي').last);
    await tester.pumpAndSettle();
    expect(find.byType(HistoryScreen), findsOneWidget);
    expect(tester.widget<BunoBottomNav>(find.byType(BunoBottomNav)).currentIndex, 1);

    final trip = rentalSession.history.first;
    await tester.tap(find.text(trip.station.name).first);
    await tester.pumpAndSettle();
    expect(tester.widget<ReceiptScreen>(find.byType(ReceiptScreen)).trip, trip);
    expect(find.text(trip.returnStation!.name), findsOneWidget);

    // "تمام" goes back to the list and leaves the session alone.
    await tester.tap(find.text('تمام'));
    await tester.pumpAndSettle();
    expect(find.byType(HistoryScreen), findsOneWidget);
  });

  testWidgets('empty history offers to find a station', (tester) async {
    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: HistoryScreen(session: RentalSession()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('دوّر على محطة'));
    await tester.pumpAndSettle();
    expect(find.byType(StationsScreen), findsOneWidget);
  });

  test('finishing a rental adds a trip, newest first', () async {
    final station = Station(id: 'x', code: 'BUN-99', name: 'x', walkMinutes: 1, bays: [80, null]);
    final session = RentalSession(unlockDelay: Duration.zero);
    await session.unlock(station, 0);
    session.confirmPickup();
    session.returnTo(station, 0);
    session.finish();
    expect(session.history, hasLength(1));
    expect(session.history.first.station, station);
  });

  test('tripDay names recent days', () {
    final now = DateTime(2026, 10, 24, 12); // a Saturday
    expect(tripDay(DateTime(2026, 10, 24, 9), now: now), 'النهارده');
    expect(tripDay(DateTime(2026, 10, 23, 22), now: now), 'امبارح');
    expect(tripDay(DateTime(2026, 10, 22), now: now), 'الخميس');
    expect(tripDay(DateTime(2026, 10, 1), now: now), '1/10');
  });
}

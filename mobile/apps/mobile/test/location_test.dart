import 'package:buno/app_routes.dart';
import 'package:buno/data/mock_first_run.dart';
import 'package:buno/data/mock_map_places.dart';
import 'package:buno/data/mock_rental.dart';
import 'package:buno/data/user_location.dart';
import 'package:buno/main.dart';
import 'package:buno/screens/home/home_map.dart';
import 'package:buno/widgets/buno_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import 'fake_battery.dart';
import 'fake_location.dart';
import 'fake_scan_camera.dart';
import 'home_screen_test.dart' show loadBunoFonts;
import 'reduced_motion.dart';

/// Home's location-off card (reference 110) and its button.
const _pill = 'شغّل الموقع عشان نوريك الأقرب ليك';
const _enable = 'شغّل الموقع';

/// Somewhere far from the default point (Alexandria).
const _here = LatLng(31.2001, 29.9187);

Future<void> _pumpHome(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(BunoApp(key: UniqueKey()));
  await tester.pumpAndSettle();
}

LatLng _mapUser(WidgetTester tester) => tester.widget<HomeMap>(find.byType(HomeMap)).user;

void main() {
  setUpAll(loadBunoFonts);
  setUp(() => useFakeBattery(level: 80));
  setUp(useReducedMotion);
  setUp(useFakeScanCamera);
  // Back to the silent default for the other test files.
  tearDown(() => UserLocation.shared = UserLocation());

  group('walk time', () {
    test('haversine distance at 80 m a minute, rounded', () {
      const a = LatLng(30, 31);
      final b = offsetBy(a, 0, 800);
      expect(distanceMeters(a, b), closeTo(800, 2));
      expect(walkMinutesBetween(a, b), 10);
      expect(walkMinutesBetween(a, offsetBy(a, 90, 330)), 4);
      expect(walkMinutesBetween(a, offsetBy(a, 200, 1020)), 13);
      expect(walkMinutesBetween(a, a), 1, reason: 'never "0 min"');
    });

    test('mock stations sit 150 m to 1 km around the first fix', () {
      for (final s in mockStations) {
        final d = distanceMeters(UserLocation.shared.origin, placeOf(s)!);
        expect(d, inInclusiveRange(150, 1000), reason: s.code);
      }
      expect(mockStations.map((s) => s.code), ['BUN-01', 'BUN-02', 'BUN-03', 'BUN-04']);
    });
  });

  testWidgets('allowed: map on the real position, stations around it, no pill', (tester) async {
    final location = useFakeLocation();
    await _pumpHome(tester);
    location.move(_here);
    await tester.pumpAndSettle();

    expect(_mapUser(tester), _here);
    expect(UserLocation.shared.origin, _here);
    expect(distanceMeters(_here, placeOf(mockStations.first)!), closeTo(330, 2));
    expect(find.bySemanticsLabel('4 دقايق مشي'), findsOneWidget);
    expect(find.textContaining(_pill, findRichText: true), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('denied: asks once, default point, pill opens settings, rest still works', (tester) async {
    final location = useFakeLocation(access: LocationAccess.denied);
    await _pumpHome(tester);

    expect(location.requests, 1);
    expect(_mapUser(tester), mockUserLocation);
    // No known location: no ring and no walk; the pins stay.
    expect(find.bySemanticsLabel('4 دقايق مشي'), findsNothing);
    expect(find.byType(HomeUserRing), findsNothing);
    expect(find.bySemanticsLabel(RegExp('أقرب محطة، التحرير')), findsOneWidget);
    expect(find.text('الخريطة على وسط الحرم'), findsOneWidget);
    await tester.tap(find.text(_enable));
    await tester.pumpAndSettle();
    expect(location.opened, [LocationAccess.denied]);

    // Back from settings with location allowed: the pill goes.
    location.access = LocationAccess.granted;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.textContaining(_pill, findRichText: true), findsNothing);
    expect(location.requests, 1, reason: 'asked once per run');
  });

  testWidgets('location off: pill opens the location settings', (tester) async {
    final location = useFakeLocation(access: LocationAccess.serviceOff);
    await _pumpHome(tester);
    expect(location.requests, 0);
    expect(find.textContaining(_pill, findRichText: true), findsOneWidget);
    await tester.tap(find.text(_enable));
    expect(location.opened, [LocationAccess.serviceOff]);
  });

  testWidgets('moving: map follows, stations stay, walk times update', (tester) async {
    final location = useFakeLocation();
    await _pumpHome(tester);
    location.move(_here);
    await tester.pumpAndSettle();
    final tahrir = placeOf(mockStations.first)!;

    // Walk 330 m straight to BUN-01.
    final there = offsetBy(_here, 40, 330);
    location.move(there);
    await tester.pumpAndSettle();
    expect(_mapUser(tester), there);
    expect(placeOf(mockStations.first), tahrir, reason: 'stations stay around the first fix');
    expect(mockStations.first.walkMinutes, 1);

    // /stations shows the new walk.
    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed(AppRoutes.stations);
    await tester.pumpAndSettle();
    await tester.tap(find.text('قايمة'));
    await tester.pumpAndSettle();
    expect(find.byWidgetPredicate((w) => w is BunoText && w.text == 'مشي 1 د · 4 جاهزين'), findsOneWidget);

    // Location switched off on the way: back on the default point's walks, pill on home.
    location.switchOff();
    await tester.pumpAndSettle();
    expect(UserLocation.shared.needsEnabling, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('/permissions: the location switch asks for the real permission', (tester) async {
    final location = useFakeLocation(access: LocationAccess.denied, afterRequest: LocationAccess.granted);
    MockPermissions.reset();
    addTearDown(MockPermissions.reset);
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    // Straight to /permissions: home would ask on its own.
    await tester.pumpWidget(BunoApp(key: UniqueKey(), initialRoute: AppRoutes.permissions));
    await tester.pumpAndSettle();

    expect(MockPermissions.location.value, isFalse, reason: 'shows the real permission');
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(location.requests, 1);
    expect(MockPermissions.location.value, isTrue);
  });

  testWidgets('/permissions: refused for good opens the settings', (tester) async {
    final location = useFakeLocation(access: LocationAccess.blocked);
    MockPermissions.reset();
    addTearDown(MockPermissions.reset);
    // Straight to /permissions: home would ask on its own.
    await tester.pumpWidget(BunoApp(key: UniqueKey(), initialRoute: AppRoutes.permissions));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(location.opened, [LocationAccess.blocked]);
    expect(MockPermissions.location.value, isFalse);
  });
}

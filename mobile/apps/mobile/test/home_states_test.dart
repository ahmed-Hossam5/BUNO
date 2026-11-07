import 'package:buno/app_routes.dart';
import 'package:buno/data/mock_map_places.dart';
import 'package:buno/data/mock_rental.dart';
import 'package:buno/data/mock_search.dart';
import 'package:buno/data/mock_station_info.dart';
import 'package:buno/data/repositories.dart';
import 'package:buno/data/user_location.dart';
import 'package:buno/l10n/buno_locale.dart';
import 'package:buno/main.dart';
import 'package:buno/screens/home/home_map.dart';
import 'package:buno/screens/home/home_screen.dart';
import 'package:buno/screens/home/home_sheet.dart';
import 'package:buno/screens/home/home_state_bodies.dart';
import 'package:buno/screens/search/search_screen.dart';
import 'package:buno/screens/stations/all_stations_screen.dart';
import 'package:buno/screens/stations/stations_screen.dart';
import 'package:buno/screens/reserve/reserved_screen.dart';
import 'package:buno/theme/buno_tokens.dart';
import 'package:buno/widgets/buno_buttons.dart';
import 'package:buno/widgets/buno_text.dart';
import 'package:buno/widgets/map_markers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_battery.dart';
import 'fake_location.dart';
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

/// Monday 20:00: محطة مدينة نصر (8–18) is closed, the rest are open.
final _mondayEvening = DateTime(2026, 11, 9, 20);

Future<void> _pump(WidgetTester tester, String route, {Size size = const Size(390, 844)}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(BunoApp(key: UniqueKey(), initialRoute: route));
  await tester.pumpAndSettle();
}

/// Removes the app so home's countdown ticker doesn't outlive the test.
Future<void> _unmount(WidgetTester tester) => tester.pumpWidget(const SizedBox());

/// A [BunoText] whose text contains [part] (numbers in it are isolated, so
/// find.text can't see them).
Finder _bunoText(String part) => find.byWidgetPredicate((w) => w is BunoText && w.text.contains(part));

Finder _textIn<T>(String text) => find.descendant(of: find.byType(T), matching: find.text(text, findRichText: true));

/// Home states that replace the station card (references 110–113).
enum _State { locationOff, far, reserved, closed }

/// Sets [state] up before home is pumped; [_State.far] also needs
/// [_moveFar] after, [_State.closed] a search for the closed station.
Future<void> _enter(WidgetTester tester, _State state) async {
  switch (state) {
    case _State.locationOff:
      useFakeLocation(access: LocationAccess.serviceOff);
    case _State.far:
      await _goFar(tester);
    case _State.reserved:
      reservationSession.reserve(mockStations.first);
    case _State.closed:
      stationClock = () => _mondayEvening;
  }
}

late FakeLocationSource _far;
Future<void> _goFar(WidgetTester tester) async {
  _far = useFakeLocation();
}

/// A first fix at the default point (stations sit around it), then 18 km
/// south of it.
Future<void> _moveFar(WidgetTester tester) async {
  _far.move(mockUserLocation);
  await tester.pump();
  _far.move(offsetBy(mockUserLocation, 180, 18000));
  await tester.pumpAndSettle();
}

/// Picks [query]'s first result in /search from home.
Future<void> _searchAndPick(WidgetTester tester, String query, String result, {String field = 'دوّر على محطة أو مكان'}) async {
  await tester.tap(find.bySemanticsLabel(field));
  await tester.pumpAndSettle();
  expect(find.byType(SearchScreen), findsOneWidget);
  await tester.enterText(find.byType(TextField), query);
  await tester.pumpAndSettle();
  await tester.tap(find.text(result).first);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadBunoFonts);
  setUp(() => useFakeBattery(level: 80));
  setUp(useReducedMotion);
  setUp(useFakeScanCamera);
  setUp(() => HomeScreen.ringHintSeen.value = true);
  tearDown(() {
    reservationSession.cancel();
    stationClock = DateTime.now;
    UserLocation.shared = UserLocation();
    HomeScreen.nearbyAlert.value = false;
    recentSearches.reset();
    Repos.reset();
  });

  group('opening hours', () {
    test('closed at night, opens the next morning', () {
      final nasr = mockStations[2], info = stationInfo(nasr);
      expect(info.isOpenAt(_mondayEvening), isFalse);
      expect(info.nextOpening(_mondayEvening), DateTime(2026, 11, 10, 8));
      expect(info.opensLabel(_mondayEvening), 'بتفتح بكرة الساعة 8 الصبح');
      // Closed on Friday: Thursday evening's next opening is Saturday.
      expect(info.opensLabel(DateTime(2026, 11, 5, 20)), 'بتفتح يوم السبت الساعة 8 الصبح');
      expect(info.opensLabel(DateTime(2026, 11, 9, 6)), 'بتفتح النهارده الساعة 8 الصبح');
    });

    test('closed stations are skipped for reserving and returning', () {
      stationClock = () => DateTime(2026, 11, 9, 3); // Tahrir is the only 24h one.
      expect(isStationOpen(mockStations[1]), isFalse);
      expect(nearestReadyStation()!.code, 'BUN-01');
      expect(nearestReturnStation()!.code, 'BUN-01');
    });

    test('distance labels', () {
      expect(distanceLabel(237), '240 م');
      expect(distanceLabel(1430), '1.4 كم');
      expect(distanceLabel(18200), '18 كم');
    });
  });

  for (final size in _sizes) {
    final at = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('/search: no overflow and RTL at $at', (tester) async {
      await _pump(tester, AppRoutes.search, size: size);
      await tester.enterText(find.byType(TextField), 'مكتب');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(Directionality.of(tester.element(find.byType(SearchScreen))), TextDirection.rtl);
      // Field on the right, "إلغاء" on the left.
      expect(tester.getCenter(find.byType(TextField)).dx, greaterThan(tester.getCenter(find.text('إلغاء')).dx));
      expect(find.text('محطات'), findsOneWidget);
      expect(find.text('أماكن'), findsOneWidget);
      expect(find.text('آخر بحث'), findsOneWidget);
    });

    testWidgets('/stations/all: no overflow and RTL at $at', (tester) async {
      stationClock = () => _mondayEvening;
      await _pump(tester, AppRoutes.allStations, size: size);
      expect(tester.takeException(), isNull);
      expect(Directionality.of(tester.element(find.byType(AllStationsScreen))), TextDirection.rtl);
      expect(find.byType(BunoPrimaryButton), findsNothing);
      // Title on the right, "الخريطة" on the left.
      expect(tester.getCenter(find.text('كل المحطات')).dx, greaterThan(tester.getCenter(find.text('الخريطة')).dx));
    });

    for (final state in _State.values) {
      testWidgets('home ${state.name}: no overflow, one primary button at $at', (tester) async {
        await _enter(tester, state);
        await _pump(tester, AppRoutes.home, size: size);
        if (state == _State.far) await _moveFar(tester);
        if (state == _State.closed) await _searchAndPick(tester, 'مدينة نصر', 'محطة مدينة نصر');
        expect(tester.takeException(), isNull);
        expect(find.byType(BunoPrimaryButton), findsOneWidget);
        expect(Directionality.of(tester.element(find.byType(BunoPrimaryButton))), TextDirection.rtl);
        await _unmount(tester);
      });
    }
  }

  testWidgets('107: search picks a station (selected on the map) or a place (map centres there)', (tester) async {
    await _pump(tester, AppRoutes.home);

    // Station: the sheet and the map pin switch to it.
    await _searchAndPick(tester, 'الزمالك', 'محطة الزمالك');
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('المحطة اللي اخترتها'), findsOneWidget);
    expect(_textIn<HomeSheet>('محطة الزمالك'), findsOneWidget);
    expect(tester.widget<HomeMap>(find.byType(HomeMap)).nearest!.code, 'BUN-02');
    expect(recentSearches.value.first, mockStations[1]);

    // Place: the map centres on it.
    await _searchAndPick(tester, 'ألف', 'مكتبة ألف');
    final alef = mockPlaces.firstWhere((p) => p.name == 'مكتبة ألف');
    expect(tester.widget<HomeMap>(find.byType(HomeMap)).focus, alef.position);
    expect(find.text('أقرب محطة'), findsOneWidget);

    // Back to my location clears both.
    await tester.tap(find.bySemanticsLabel('رجّعني لمكاني'));
    await tester.pumpAndSettle();
    expect(tester.widget<HomeMap>(find.byType(HomeMap)).focus, isNull);
  });

  testWidgets('107: results show counts and walk; recent searches are kept and reusable', (tester) async {
    await _pump(tester, AppRoutes.search);
    expect(find.text('الكافيتريا الرئيسية'), findsOneWidget, reason: 'seeded recent');
    await tester.enterText(find.byType(TextField), 'التحرير');
    await tester.pumpAndSettle();
    final tahrir = mockStations.first;
    expect(find.bySemanticsLabel(RegExp('^محطة التحرير، ${tahrir.readyCount} جاهز، ${tahrir.emptyCount} فاضي، ${tahrir.walkMinutes} د')), findsOneWidget);
    expect(_bunoText('${tahrir.walkMinutes} د'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'مكتبة الجامعة');
    await tester.pumpAndSettle();
    expect(find.textContaining('أقرب محطة ليها:', findRichText: true), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'زززز');
    await tester.pumpAndSettle();
    expect(find.textContaining('مفيش نتايج', findRichText: true), findsOneWidget);

    // "إلغاء" goes back with nothing picked.
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('أقرب محطة'), findsOneWidget);
  });

  testWidgets('108: sorted by distance, filters, closed dimmed, "الخريطة" back', (tester) async {
    stationClock = () => _mondayEvening;
    await _pump(tester, AppRoutes.home);
    await tester.tap(find.text('كل المحطات'));
    await tester.pumpAndSettle();
    expect(find.byType(AllStationsScreen), findsOneWidget);

    List<String> listed() {
      final names = mockStations.map((s) => s.name).toSet();
      return tester.widgetList<RichText>(find.byType(RichText)).map((t) => t.text.toPlainText()).where(names.contains).toList();
    }

    final byDistance = [...mockStations]..sort((a, b) => a.metersAway!.compareTo(b.metersAway!));
    expect(listed(), byDistance.map((s) => s.name).toList());

    // Nasr City is closed: dimmed with its pill.
    expect(find.text('مقفولة دلوقتي'), findsOneWidget);
    final dimmed = tester.widget<Opacity>(find.ancestor(of: find.text('محطة مدينة نصر'), matching: find.byType(Opacity)).first);
    expect(dimmed.opacity, lessThan(1));

    await tester.tap(find.text('مفتوحة دلوقتي'));
    await tester.pumpAndSettle();
    expect(listed(), isNot(contains('محطة مدينة نصر')));
    await tester.tap(find.text('مفتوحة دلوقتي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('فيها وحدات'));
    await tester.pumpAndSettle();
    expect(listed(), byDistance.where((s) => s.readyCount > 0).map((s) => s.name).toList());
    await tester.tap(find.text('فيها وحدات'));
    await tester.pumpAndSettle();

    // The chips scroll; favourites starts off-screen, as in the reference.
    await tester.ensureVisible(find.text('المفضلة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('المفضلة'));
    await tester.pumpAndSettle();
    expect(listed(), byDistance.where(Repos.favorites.contains).map((s) => s.name).toList());

    await tester.tap(find.text('الخريطة'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(AllStationsScreen), findsNothing);
  });

  testWidgets('109: "إزاي بيشتغل؟" opens three steps; "فهمت" closes', (tester) async {
    await _pump(tester, AppRoutes.home);
    await tester.tap(find.bySemanticsLabel('إزاي بيشتغل؟'));
    await tester.pumpAndSettle();
    expect(find.byType(HowItWorksSheet), findsOneWidget);
    expect(find.text('بونو بيشتغل إزاي؟'), findsOneWidget);
    expect(find.text('روح لأقرب محطة'), findsOneWidget);
    expect(find.text('امسح الـ QR اللي عليها'), findsOneWidget);
    expect(find.text('خدها وامشي، ورجّعها في أي محطة'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('فهمت'));
    await tester.pumpAndSettle();
    expect(find.byType(HowItWorksSheet), findsNothing);
  });

  testWidgets('110: location off → campus default, turn-on card, search by name', (tester) async {
    final location = useFakeLocation(access: LocationAccess.denied);
    await _pump(tester, AppRoutes.home);
    expect(tester.widget<HomeMap>(find.byType(HomeMap)).user, mockUserLocation);
    expect(tester.widget<HomeMap>(find.byType(HomeMap)).showUser, isFalse);
    expect(find.text('الخريطة على وسط الحرم'), findsOneWidget);
    expect(find.byType(HomeLocationOffBody), findsOneWidget);
    expect(find.textContaining('بنستخدمه بس وانت فاتح التطبيق', findRichText: true), findsOneWidget);

    await tester.tap(find.text('شغّل الموقع'));
    expect(location.opened, [LocationAccess.denied]);

    await tester.tap(find.text('أو دوّر على محطة بالاسم'));
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
  });

  testWidgets('111: nothing within 3 km → distance, directions, "بلّغني" in memory', (tester) async {
    await _goFar(tester);
    await _pump(tester, AppRoutes.home);
    expect(find.byType(HomeNothingNearBody), findsNothing);
    await _moveFar(tester);

    expect(find.byType(HomeNothingNearBody), findsOneWidget);
    expect(find.text('مفيش محطة قريبة منك'), findsOneWidget);
    final nearest = tester.widget<HomeNothingNearBody>(find.byType(HomeNothingNearBody)).station;
    expect(nearest.metersAway, greaterThan(HomeNothingNearBody.farMeters));
    expect(find.text('أقرب محطة: ${shortStationName(nearest.name)}'), findsOneWidget);
    expect(find.textContaining('كم', findRichText: true), findsWidgets);

    await tester.tap(find.text('بلّغني'));
    await tester.pumpAndSettle();
    expect(HomeScreen.nearbyAlert.value, isTrue);
    expect(find.textContaining('هنبلّغك أول ما محطة تفتح', findRichText: true), findsOneWidget);
    expect(find.text('هنبلّغك'), findsOneWidget);

    await tester.tap(find.text('الاتجاهات'));
    await tester.pumpAndSettle();
    expect(tester.widget<StationsScreen>(find.byType(StationsScreen)).selectCode, nearest.code);
  });

  testWidgets('112: a held bay turns the pin amber with the countdown; cancel releases it', (tester) async {
    final r = reservationSession.reserve(mockStations.first);
    await _pump(tester, AppRoutes.home);

    expect(find.byType(HomeReservedBody), findsOneWidget);
    expect(find.text('محجوزك في التحرير'), findsOneWidget);
    expect(_bunoText('خانة #${r.bayIndex + 1}'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^محجوزك، فاضل')), findsOneWidget);
    expect(tester.widget<HomeMap>(find.byType(HomeMap)).reservedLeft, isNotNull);
    expect(tester.widget<HomeSheet>(find.byType(HomeSheet)).tint, BunoColors.warning);
    expect(find.text('وصلت؟ امسح'), findsOneWidget);
    expect(find.text('الاتجاهات'), findsOneWidget);

    // The countdown ticks every second.
    final before = reservationSession.remaining;
    await tester.pump(const Duration(seconds: 2));
    expect(reservationSession.remaining, lessThan(before));

    await tester.tap(find.bySemanticsLabel(RegExp('^فاضل على الحجز')));
    await tester.pumpAndSettle();
    expect(find.byType(ReservedScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(ReservedScreen))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('الغي الحجز'));
    await tester.pumpAndSettle();
    expect(reservationSession.current, isNull);
    expect(find.text('اتلغى الحجز'), findsOneWidget);
    expect(find.byType(HomeReservedBody), findsNothing);
    expect(find.text('امسح وخد بونو'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('113: a closed station is grey, says when it opens, and offers the nearest open one', (tester) async {
    stationClock = () => _mondayEvening;
    await _pump(tester, AppRoutes.home);
    expect(find.byWidgetPredicate((w) => w is StationChargePin && w.closed), findsOneWidget);

    await _searchAndPick(tester, 'مدينة نصر', 'محطة مدينة نصر');
    expect(find.byType(HomeClosedBody), findsOneWidget);
    expect(find.text('مقفولة دلوقتي'), findsOneWidget);
    expect(_bunoText('بتفتح بكرة الساعة 8 الصبح'), findsOneWidget);
    expect(find.text('أقرب محطة مفتوحة'), findsOneWidget);
    expect(tester.widget<HomeSheet>(find.byType(HomeSheet)).tint, BunoDark.text_disabled);
    expect(find.bySemanticsLabel('مدينة نصر، مقفولة دلوقتي'), findsOneWidget);

    await tester.tap(find.text('ودّيني للتحرير'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeClosedBody), findsNothing);
    expect(find.text('المحطة اللي اخترتها'), findsOneWidget);
    expect(tester.widget<HomeMap>(find.byType(HomeMap)).nearest!.code, 'BUN-01');
  });

  for (final state in _State.values) {
    testWidgets('home ${state.name} in English: left-to-right, no Arabic left', (tester) async {
      BunoLocale.current.value = BunoLocale.english;
      addTearDown(BunoLocale.reset);
      await _enter(tester, state);
      await _pump(tester, AppRoutes.home);
      if (state == _State.far) await _moveFar(tester);
      if (state == _State.closed) await _searchAndPick(tester, 'Nasr', 'Nasr City Station', field: 'Search a station or place');
      expect(tester.takeException(), isNull);
      expect(Directionality.of(tester.element(find.byType(BunoPrimaryButton))), TextDirection.ltr);
      final arabic = RegExp(r'[\u0600-\u06FF]');
      final leftovers = [
        for (final e in find.byType(RichText).evaluate()) (e.widget as RichText).text.toPlainText(),
      ].where(arabic.hasMatch).toList();
      expect(leftovers, isEmpty);
      await _unmount(tester);
    });
  }
}

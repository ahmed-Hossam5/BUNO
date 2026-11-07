import 'package:buno/app_routes.dart';
import 'package:buno/data/mock_favorites.dart';
import 'package:buno/data/mock_promo.dart';
import 'package:buno/data/mock_rental.dart';
import 'package:buno/data/mock_settings.dart';
import 'package:buno/data/mock_station_info.dart';
import 'package:buno/data/repositories.dart';
import 'package:buno/main.dart';
import 'package:buno/screens/favorites/favorites_screen.dart';
import 'package:buno/screens/promo/promo_screen.dart';
import 'package:buno/screens/rental/rate_sheet.dart';
import 'package:buno/screens/station/station_info_screen.dart';
import 'package:buno/widgets/buno_buttons.dart';
import 'package:buno/widgets/buno_pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_battery.dart';
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

/// /station needs its code as `arguments`, so it is pushed over home.
Future<void> _pumpStation(WidgetTester tester) async {
  await _pumpApp(tester, AppRoutes.home);
  tester.state<NavigatorState>(find.byType(Navigator)).pushNamed(AppRoutes.station, arguments: 'BUN-01');
  await tester.pumpAndSettle();
}

Future<void> _tapLabel(WidgetTester tester, String label) async {
  final button = find.byWidgetPredicate((w) => w is BunoPressable && w.semanticLabel == label);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadBunoFonts);
  setUp(useReducedMotion);
  setUp(() => useFakeBattery(level: 80));
  setUp(MockSettings.reset);
  setUp(favoriteStations.debugReset);
  setUp(promoSession.debugReset);
  tearDown(Repos.reset);

  group('no overflow, RTL', () {
    for (final size in _sizes) {
      final label = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('/favorites at $label', (tester) async {
        await _pumpApp(tester, AppRoutes.favorites, size: size);
        expect(tester.takeException(), isNull);
        expect(Directionality.of(tester.element(find.byType(FavoritesScreen))), TextDirection.rtl);
        expect(find.byType(BunoPrimaryButton), findsOneWidget);
      });

      testWidgets('/favorites empty at $label', (tester) async {
        favoriteStations.debugReset(const []);
        await _pumpApp(tester, AppRoutes.favorites, size: size);
        expect(tester.takeException(), isNull);
        expect(find.text('لسه مفيش محطات في المفضلة'), findsOneWidget);
        expect(find.byType(BunoPrimaryButton), findsOneWidget);
      });

      testWidgets('/station/info at $label', (tester) async {
        await _pumpApp(tester, AppRoutes.stationInfo, size: size);
        expect(tester.takeException(), isNull);
        expect(Directionality.of(tester.element(find.byType(StationInfoScreen))), TextDirection.rtl);
        expect(find.byType(BunoPrimaryButton), findsOneWidget);
      });

      testWidgets('/promo at $label', (tester) async {
        await _pumpApp(tester, AppRoutes.promo, size: size);
        expect(tester.takeException(), isNull);
        expect(Directionality.of(tester.element(find.byType(PromoScreen))), TextDirection.rtl);
        expect(find.byType(BunoPrimaryButton), findsOneWidget);
      });

      testWidgets('rate sheet at $label', (tester) async {
        await _pumpApp(tester, AppRoutes.receipt, size: size);
        await _tapLabel(tester, '2 من 5');
        expect(tester.takeException(), isNull);
        expect(Directionality.of(tester.element(find.byType(RateSheet))), TextDirection.rtl);
      });
    }
  });

  group('favorites', () {
    testWidgets('the heart on /station adds and removes it', (tester) async {
      favoriteStations.debugReset(const []);
      await _pumpStation(tester);
      final station = mockStations.first;
      expect(favoriteStations.contains(station), isFalse);

      await _tapLabel(tester, 'ضيفها للمفضلة');
      expect(favoriteStations.contains(station), isTrue);
      expect(find.text('اتضافت للمفضلة'), findsOneWidget);

      await _tapLabel(tester, 'شيلها من المفضلة');
      expect(favoriteStations.contains(station), isFalse);
    });

    testWidgets('/station header (name, i, heart) fits at 320 px, text scale 1.3', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.view.physicalSize = const Size(320, 568) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(BunoApp(initialRoute: AppRoutes.home));
      await tester.pumpAndSettle();
      tester.state<NavigatorState>(find.byType(Navigator)).pushNamed(AppRoutes.station, arguments: 'BUN-04');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('محطة المعادي'), findsOneWidget);
    });

    testWidgets('/favorites lists them; removing the last shows the empty state', (tester) async {
      favoriteStations.debugReset(['st-01']);
      await _pumpApp(tester, AppRoutes.favorites);
      expect(find.text('محطة التحرير'), findsOneWidget);

      await _tapLabel(tester, 'شيلها من المفضلة');
      expect(find.text('لسه مفيش محطات في المفضلة'), findsOneWidget);
    });

    testWidgets('a station with no ready unit says so and cannot be navigated to', (tester) async {
      favoriteStations.debugReset(['st-02']);
      await _pumpApp(tester, AppRoutes.favorites);
      expect(find.text('مفيش وحدات دلوقتي'), findsOneWidget);
      await _tapLabel(tester, 'وديني محطة الزمالك');
      expect(find.byType(FavoritesScreen), findsOneWidget);
    });
  });

  testWidgets('the المفضلة row on /profile opens /favorites', (tester) async {
    await _pumpApp(tester, AppRoutes.profile);
    final row = find.text('المفضلة');
    await tester.scrollUntilVisible(row, 80, scrollable: find.byType(Scrollable).first);
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.byType(FavoritesScreen), findsOneWidget);
  });

  group('repositories', () {
    testWidgets('/favorites reads from Repos.favorites', (tester) async {
      final fake = _FakeFavorites([mockStations[2]]);
      Repos.favorites = fake;
      await _pumpApp(tester, AppRoutes.favorites);
      expect(find.text('محطة مدينة نصر'), findsOneWidget);
      expect(find.text('محطة التحرير'), findsNothing);

      await _tapLabel(tester, 'شيلها من المفضلة');
      expect(fake.toggled, [mockStations[2]]);
      expect(find.text('لسه مفيش محطات في المفضلة'), findsOneWidget);
    });

    testWidgets('/promo redeems through Repos.promo', (tester) async {
      final fake = _FakePromo();
      Repos.promo = fake;
      await _pumpApp(tester, AppRoutes.promo);
      await tester.enterText(find.byType(TextField), 'anything');
      await _tapLabel(tester, 'فعّل الكود');
      expect(fake.codes, ['anything']);
      expect(find.text('الكود ده مش صحيح'), findsOneWidget);
    });
  });

  group('station info', () {
    testWidgets('the "i" on /station opens it for that station', (tester) async {
      await _pumpStation(tester);
      await _tapLabel(tester, 'معلومات المحطة');
      expect(find.byType(StationInfoScreen), findsOneWidget);
      expect(find.text('محطة التحرير'), findsOneWidget);
      expect(find.text('مواعيد الفتح'), findsOneWidget);
      expect(find.text('خانات الإرجاع'), findsOneWidget);
    });

    test('opening hours', () {
      final info = stationInfo(mockStations[1]); // 8 am – 10 pm, Friday from noon
      expect(info.isOpenAt(DateTime(2026, 10, 27, 9)), isTrue); // Tuesday
      expect(info.isOpenAt(DateTime(2026, 10, 27, 22)), isFalse);
      expect(info.isOpenAt(DateTime(2026, 10, 30, 9)), isFalse); // Friday
      expect(info.hoursLabel, '8 ص – 10 م');
      expect(stationInfo(mockStations.first).hoursLabel, '24 ساعة');
    });
  });

  group('promo', () {
    testWidgets('the wallet\'s كود خصم opens /promo', (tester) async {
      await _pumpApp(tester, AppRoutes.wallet);
      await _tapLabel(tester, 'كود خصم');
      expect(find.byType(PromoScreen), findsOneWidget);
    });

    testWidgets('a good code is added once; a bad one is refused', (tester) async {
      await _pumpApp(tester, AppRoutes.promo);
      final offers = promoSession.offers.length;

      await tester.enterText(find.byType(TextField), 'welcome30');
      await _tapLabel(tester, 'فعّل الكود');
      expect(find.text('اتفعّل!'), findsOneWidget);
      expect(promoSession.offers.length, offers + 1);

      await tester.enterText(find.byType(TextField), 'WELCOME30');
      await _tapLabel(tester, 'فعّل الكود');
      expect(find.text('الكود ده اتفعّل قبل كده'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'NOPE');
      await _tapLabel(tester, 'فعّل الكود');
      expect(find.text('الكود ده مش صحيح'), findsOneWidget);
      expect(promoSession.offers.length, offers + 1);
    });
  });

  group('rate sheet', () {
    testWidgets('4 or 5 stars: no sheet', (tester) async {
      await _pumpApp(tester, AppRoutes.receipt);
      await _tapLabel(tester, '4 من 5');
      expect(find.byType(RateSheet), findsNothing);
    });

    testWidgets('3 stars: pick a reason and send', (tester) async {
      await _pumpApp(tester, AppRoutes.receipt);
      await _tapLabel(tester, '3 من 5');
      expect(find.byType(RateSheet), findsOneWidget);

      final send = find.widgetWithText(BunoPrimaryButton, 'ابعت');
      expect(tester.widget<BunoPrimaryButton>(send).onPressed, isNull);

      await tester.tap(find.text(RateSheet.reasons.first));
      await tester.pumpAndSettle();
      expect(tester.widget<BunoPrimaryButton>(send).onPressed, isNotNull);

      await tester.tap(send);
      await tester.pumpAndSettle();
      expect(find.byType(RateSheet), findsNothing);
      expect(find.text('شكرًا، وصلتنا ملاحظتك'), findsOneWidget);

      // Sent once: lower stars don't ask again.
      await _tapLabel(tester, '1 من 5، متقيّم');
      expect(find.byType(RateSheet), findsNothing);
    });
  });
}

class _FakeFavorites extends ChangeNotifier implements FavoritesRepository {
  _FakeFavorites(this._stations);

  final List<Station> _stations;
  final toggled = <Station>[];

  @override
  List<Station> get stations => List.of(_stations);

  @override
  bool contains(Station station) => _stations.contains(station);

  @override
  String? labelOf(Station station) => null;

  @override
  Future<bool> toggle(Station station) async {
    toggled.add(station);
    final added = !_stations.remove(station);
    if (added) _stations.add(station);
    notifyListeners();
    return added;
  }
}

class _FakePromo extends ChangeNotifier implements PromoRepository {
  final codes = <String>[];

  @override
  List<PromoOffer> get offers => const [];

  @override
  PromoOffer? get lastAdded => null;

  @override
  Future<PromoResult> redeem(String code) async {
    codes.add(code);
    return PromoResult.invalid;
  }
}

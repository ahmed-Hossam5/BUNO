import 'package:buno/app_routes.dart';
import 'package:buno/data/mock_rental.dart';
import 'package:buno/screens/account/notifications_screen.dart';
import 'package:buno/screens/history/history_screen.dart';
import 'package:buno/screens/rental/active_rental_screen.dart';
import 'package:buno/screens/rental/late_return_banner.dart';
import 'package:buno/screens/rental/receipt_screen.dart';
import 'package:buno/screens/rental/unit_screen.dart';
import 'package:buno/theme/buno_tokens.dart';
import 'package:buno/widgets/buno_buttons.dart';
import 'package:buno/widgets/buno_status_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'home_screen_test.dart' show loadBunoFonts;

const _sizes = [
  Size(390, 844),
  Size(375, 667),
  Size(360, 640),
  Size(320, 568),
  Size(430, 932),
  Size(412, 915),
];

const _bannerTitles = ['خلّصت شحن؟', 'فاضل وقت قليل', 'آخر فرصة للإرجاع', 'الوحدة بقت بتاعتك'];

/// Home stands in for the real one (it needs the battery plugin).
Route<dynamic>? _routes(RouteSettings s) => s.name == AppRoutes.home
    ? MaterialPageRoute<void>(settings: s, builder: (_) => const Scaffold(body: Text('home')))
    : AppRoutes.onGenerateRoute(s);

Future<void> _pumpRoute(WidgetTester tester, String route, {Size size = const Size(390, 844)}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(fontFamily: 'ReadexPro', scaffoldBackgroundColor: BunoDark.background),
    initialRoute: route,
    onGenerateRoute: _routes,
  ));
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUpAll(loadBunoFonts);

  group('late stages and unit tags (RentalSession)', () {
    late DateTime now;
    late RentalSession session;
    late Station pickup;

    setUp(() {
      now = DateTime(2026, 10, 24, 9);
      session = RentalSession(balance: 50, unlockDelay: Duration.zero, clock: () => now);
      pickup = Station(id: 'a', code: 'BUN-91', name: 'A', walkMinutes: 3, bays: [80, 95, null], units: [
        const UnitTag('PB-0001', 29),
        const UnitTag('PB-0002', 33),
        null,
      ]);
    });

    test('stage thresholds', () {
      expect(LateStage.reachedAt(const Duration(hours: 22, minutes: 59)), isNull);
      expect(LateStage.reachedAt(const Duration(hours: 23)), LateStage.reminder);
      expect(LateStage.reachedAt(const Duration(hours: 23, minutes: 30)), LateStage.warning);
      expect(LateStage.reachedAt(const Duration(hours: 23, minutes: 54)), LateStage.lastChance);
      expect(LateStage.reachedAt(const Duration(hours: 24)), LateStage.kept);
    });

    test('stations without explicit units get one tag per full bay', () {
      final s = Station(id: 'x', code: 'BUN-98', name: 'x', walkMinutes: 1, bays: [50, null, 30]);
      expect(s.units[1], isNull);
      expect(s.units[0]!.id, matches(RegExp(r'^PB-\d{4}$')));
      expect(s.units[0]!.id, isNot(s.units[2]!.id));
      for (final st in mockStations) {
        for (var i = 0; i < st.bays.length; i++) {
          expect(st.units[i] == null, st.bays[i] == null, reason: '${st.code} bay $i');
        }
      }
    });

    test('the unit travels with the rental', () async {
      await session.unlock(pickup, 1);
      expect(session.unit!.id, 'PB-0002');
      session.confirmPickup();
      expect(pickup.units[1], isNull);

      final dropoff = Station(id: 'b', code: 'BUN-92', name: 'B', walkMinutes: 8, bays: [null]);
      session.returnTo(dropoff, 0);
      expect(dropoff.units[0]!.id, 'PB-0002');
    });

    test('jumping the clock walks the stages; 24 h closes the rental', () async {
      await session.unlock(pickup, 0);
      session.confirmPickup();
      expect(session.lateStage, isNull);
      expect(session.closeIfOverdue(), isFalse);

      for (final stage in [LateStage.reminder, LateStage.warning, LateStage.lastChance]) {
        session.debugJumpTo(stage.at);
        expect(session.state, RentalState.active);
        expect(session.lateStage, stage);
        expect(session.elapsed, stage.at);
      }
      expect(session.lateStagesReached, [LateStage.reminder, LateStage.warning, LateStage.lastChance]);

      session.debugJumpTo(LateStage.kept.at);
      expect(session.state, RentalState.kept);
      expect(session.lateStage, LateStage.kept);
      expect(session.lateStagesReached, LateStage.values);
      expect(session.duration, const Duration(hours: 24));
      expect(session.balance, 50 - mockNoReturnFee);
      expect(() => session.debugJumpTo(Duration.zero), throwsStateError);

      // Recorded as a kept trip, newest first.
      final trip = session.history.first;
      expect(trip.kept, isTrue);
      expect(trip.returnStation, isNull);
      expect(trip.station, pickup);
      expect(trip.duration, const Duration(hours: 24));

      session.reset();
      expect(session.state, RentalState.idle);
      expect(session.unit, isNull);
      expect(session.lateStagesReached, isEmpty);
    });

    test('real time past 24 h closes it on the next check, with the fee', () async {
      await session.unlock(pickup, 0);
      session.confirmPickup();
      now = now.add(const Duration(hours: 24, minutes: 3));
      expect(session.closeIfOverdue(fee: 20), isTrue);
      expect(session.state, RentalState.kept);
      expect(session.balance, 30);
      expect(session.duration, const Duration(hours: 24), reason: 'ends at 24 h, not when noticed');
    });
  });

  for (final size in _sizes) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('/rental/unit: no overflow and RTL at $label', (tester) async {
      await _pumpRoute(tester, AppRoutes.rentalUnit, size: size);
      expect(tester.takeException(), isNull);
      expect(find.byType(UnitScreen), findsOneWidget);
      expect(Directionality.of(tester.element(find.byType(BunoPrimaryButton))), TextDirection.rtl);

      expect(find.textContaining('PB-0417', findRichText: true), findsOneWidget);
      expect(find.textContaining('78%', findRichText: true), findsWidgets);
      // BunoText isolates the number, so match it alone.
      expect(find.textContaining('31', findRichText: true), findsOneWidget);
      expect(find.textContaining('BUN-01', findRichText: true), findsOneWidget);
      expect(tester.widget<BunoPrimaryButton>(find.byType(BunoPrimaryButton)).label, 'رجّعها');
      // Title on the right in RTL.
      expect(tester.getCenter(find.text('الوحدة اللي معاك')).dx, greaterThan(size.width / 2 - 1));
    });

    testWidgets('/rental: each late stage fits at $label', (tester) async {
      await _pumpRoute(tester, AppRoutes.rental, size: size);
      expect(find.byType(LateReturnBanner), findsNothing);

      for (var i = 0; i < LateStage.values.length; i++) {
        await _tapText(tester, 'تجربة: تأخير');
        expect(tester.takeException(), isNull, reason: LateStage.values[i].name);
        expect(tester.widget<LateReturnBanner>(find.byType(LateReturnBanner)).stage, LateStage.values[i]);
        expect(find.text(_bannerTitles[i]), findsOneWidget);
        expect(Directionality.of(tester.element(find.byType(LateReturnBanner))), TextDirection.rtl);
      }
    });
  }

  testWidgets('/rental: banners show countdowns and fees; stage 4 closes', (tester) async {
    await _pumpRoute(tester, AppRoutes.rental);

    await _tapText(tester, 'تجربة: تأخير');
    expect(find.text('خلّصت شحن؟'), findsOneWidget);
    expect(tester.widget<BunoPrimaryButton>(find.byType(BunoPrimaryButton)).label, 'رجّعه');

    await _tapText(tester, 'تجربة: تأخير');
    expect(find.textContaining('00:30', findRichText: true), findsOneWidget);

    await _tapText(tester, 'تجربة: تأخير');
    expect(find.textContaining('00:06', findRichText: true), findsOneWidget);
    expect(find.textContaining('[رسوم عدم الإرجاع]', findRichText: true), findsOneWidget);

    await _tapText(tester, 'تجربة: تأخير');
    expect(find.textContaining('[المبلغ]', findRichText: true), findsOneWidget);
    expect(tester.widget<BunoPrimaryButton>(find.byType(BunoPrimaryButton)).label, 'تمام');
    expect(find.text('تجربة: تأخير'), findsNothing);
    expect(find.textContaining('الإيجار اتقفل', findRichText: true), findsOneWidget);
    expect(find.byType(BunoStatusPill), findsOneWidget);

    // The timer stops once the rental is closed.
    await tester.pump(const Duration(minutes: 5));
    expect(find.text('24:00'), findsOneWidget);
  });

  testWidgets('/rental links to /rental/unit', (tester) async {
    await _pumpRoute(tester, AppRoutes.rental);
    await _tapText(tester, 'الوحدة اللي معاك');
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(UnitScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('late notices on /notifications', (tester) async {
    final start = DateTime(2026, 10, 24, 9, 5);
    expect(lateNotification(LateStage.reminder, start).time, '08:05');
    expect(lateNotification(LateStage.lastChance, start).time, '08:59');
    expect(lateNotification(LateStage.kept, start).time, '09:05');

    await _pumpRoute(tester, AppRoutes.notifications);
    expect(find.text('البونو لسه معاك'), findsNothing, reason: 'no rental, no late notice');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a kept trip in /history and its receipt', (tester) async {
    final session = RentalSession(unlockDelay: Duration.zero);
    final pickup = Station(id: 'k', code: 'BUN-97', name: 'محطة الاختبار', walkMinutes: 2, bays: [80]);
    await tester.runAsync(() => session.unlock(pickup, 0));
    session.confirmPickup();
    session.debugJumpTo(LateStage.kept.at);
    final trip = session.history.single;

    for (final size in _sizes) {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ThemeData(fontFamily: 'ReadexPro', scaffoldBackgroundColor: BunoDark.background),
        onGenerateRoute: _routes,
        home: HistoryScreen(session: session),
      ));
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull, reason: '$size');
      expect(find.textContaining('الوحدة بقت معاك', findRichText: true), findsOneWidget);
      expect(find.text('[المبلغ]'), findsOneWidget);
    }

    await tester.tap(find.text('محطة الاختبار'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.widget<ReceiptScreen>(find.byType(ReceiptScreen)).trip, trip);
    expect(tester.takeException(), isNull);
    expect(find.textContaining('الوحدة بقت معاك', findRichText: true), findsOneWidget);
    expect(find.textContaining('رسوم عدم الإرجاع', findRichText: true), findsOneWidget);
    expect(find.textContaining('أول ساعة', findRichText: true), findsNothing);
  });

  // Last: uses (and closes) the shared rentalSession.
  testWidgets('a real rental: jump to each stage, notices, unit, close', (tester) async {
    final station = mockStations.first;
    await tester.runAsync(() => rentalSession.unlock(station, station.bestBayIndex!));
    rentalSession.confirmPickup();
    final unitId = rentalSession.unit!.id;

    await _pumpRoute(tester, AppRoutes.rental);
    expect(find.textContaining(unitId, findRichText: true), findsOneWidget);

    await _tapText(tester, 'تجربة: تأخير');
    await _tapText(tester, 'تجربة: تأخير');
    expect(rentalSession.lateStage, LateStage.warning);
    expect(find.text('فاضل وقت قليل'), findsOneWidget);

    // Two notices so far, newest first.
    await tester.pumpWidget(const SizedBox());
    await _pumpRoute(tester, AppRoutes.notifications);
    expect(find.text('فاضل نص ساعة'), findsOneWidget);
    expect(find.text('البونو لسه معاك'), findsOneWidget);
    expect(find.text('آخر فرصة للإرجاع'), findsNothing);
    expect(tester.getTopLeft(find.text('فاضل نص ساعة')).dy,
        lessThan(tester.getTopLeft(find.text('البونو لسه معاك')).dy));

    await tester.pumpWidget(const SizedBox());
    await _pumpRoute(tester, AppRoutes.rental);
    await _tapText(tester, 'تجربة: تأخير');
    await _tapText(tester, 'تجربة: تأخير');
    expect(rentalSession.state, RentalState.kept);
    expect(find.text('الوحدة بقت بتاعتك'), findsOneWidget);
    expect(rentalSession.history.first.kept, isTrue);

    await _tapText(tester, 'الوحدة اللي معاك');
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining(unitId, findRichText: true), findsOneWidget);
    expect(find.text('بقت بتاعتك'), findsOneWidget);
    expect(find.byType(BunoPrimaryButton), findsNothing);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump(const Duration(seconds: 1));

    await tester.pumpWidget(const SizedBox());
    await _pumpRoute(tester, AppRoutes.notifications);
    expect(find.text('الوحدة بقت بتاعتك'), findsOneWidget);
    expect(find.text('آخر فرصة للإرجاع'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await _pumpRoute(tester, AppRoutes.rental);
    await _tapText(tester, 'تمام');
    await tester.pump(const Duration(seconds: 1));
    expect(rentalSession.state, RentalState.idle);
    expect(find.text('home'), findsOneWidget);
    expect(find.byType(ActiveRentalScreen), findsNothing);
    expect(find.byType(NotificationsScreen), findsNothing);
  });
}

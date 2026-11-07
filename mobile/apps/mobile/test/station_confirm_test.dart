import 'package:buno/data/mock_rental.dart';
import 'package:buno/main.dart';
import 'package:buno/screens/rental/unlocking_screen.dart';
import 'package:buno/screens/rental/verifying_screen.dart';
import 'package:buno/screens/scan/scan_screen.dart';
import 'package:buno/screens/station/confirm_screen.dart';
import 'package:buno/screens/station/station_screen.dart';
import 'package:buno/screens/topup/topup_screen.dart';
import 'package:buno/theme/buno_tokens.dart';
import 'package:buno/widgets/buno_buttons.dart';
import 'package:buno/widgets/buno_bay_tile.dart';
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

String _cta(WidgetTester tester) =>
    tester.widget<BunoPrimaryButton>(find.byType(BunoPrimaryButton).last).label;

void main() {
  setUpAll(loadBunoFonts);
  setUp(useFakeBattery);
  setUp(useReducedMotion);
  setUp(useFakeScanCamera);

  late double balance;
  setUp(() => balance = rentalSession.balance);
  tearDown(() {
    rentalSession.balance = balance;
    if (rentalSession.state != RentalState.active) rentalSession.reset();
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
    final label = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('/station: no overflow and RTL at $label', (tester) async {
      await _pumpRoute(tester, size, '/station', 'BUN-01');
      expect(tester.takeException(), isNull);
      expect(Directionality.of(tester.element(find.byType(StationScreen))), TextDirection.rtl);
      // Bay 1 sits on the right in RTL, bay 4 on the left.
      final bay1 = tester.getCenter(find.bySemanticsLabel('خانة 1، 92%'));
      final bay4 = tester.getCenter(find.bySemanticsLabel('خانة 4، 71%'));
      expect(bay1.dx, greaterThan(bay4.dx));
    });

    testWidgets('/station not found: no overflow at $label', (tester) async {
      await _pumpRoute(tester, size, '/station', 'BUN-07');
      expect(tester.takeException(), isNull);
      expect(find.text('مش لاقيين المحطة دي'), findsOneWidget);
    });

    testWidgets('/confirm: no overflow and RTL at $label', (tester) async {
      await _pumpRoute(tester, size, '/confirm', (mockStations.first, 0));
      expect(tester.takeException(), isNull);
      expect(Directionality.of(tester.element(find.byType(ConfirmScreen))), TextDirection.rtl);
    });

    testWidgets('low-balance sheet: no overflow at $label', (tester) async {
      rentalSession.balance = 5;
      await _pumpRoute(tester, size, '/confirm', (mockStations.first, 0));
      await tester.tap(find.byType(BunoPrimaryButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(LowBalanceSheet), findsOneWidget);
    });
  }

  test('charge colours', () {
    expect(chargeColor(92), BunoColors.success);
    expect(chargeColor(50), BunoColors.success);
    expect(chargeColor(49), BunoColors.warning);
    expect(chargeColor(20), BunoColors.warning);
    expect(chargeColor(19), BunoColors.error);
    expect(chargeColor(null), BunoDark.border);
  });

  testWidgets('/station: 8 bay tiles, best-bay CTA opens /confirm', (tester) async {
    await _pumpRoute(tester, const Size(390, 844), '/station', 'BUN-01');
    expect(find.text('محطة التحرير'), findsOneWidget);
    expect(find.byType(BunoBayTile), findsNWidgets(8));
    expect(find.textContaining('\u20664\u2069 جاهزين', findRichText: true), findsOneWidget);
    expect(find.text('[السعر]'), findsOneWidget);
    expect(_cta(tester), 'خد الـ 92%');

    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();
    final confirm = tester.widget<ConfirmScreen>(find.byType(ConfirmScreen));
    expect(confirm.station.code, 'BUN-01');
    expect(confirm.bayIndex, 0);
  });

  testWidgets('/station: tapping a ready bay picks it, low and empty bays do nothing', (tester) async {
    await _pumpRoute(tester, const Size(390, 844), '/station', 'BUN-01');
    BunoBayTile tile(int n) => tester.widget<BunoBayTile>(find.byType(BunoBayTile).at(n - 1));
    expect(tile(1).selected, isTrue);

    // Bay 3 holds 15%, bay 5 is empty: not tappable.
    expect(tile(3).onTap, isNull);
    expect(tile(5).onTap, isNull);
    double opacity(int n) => tester
        .widget<Opacity>(find.descendant(of: find.byType(BunoBayTile).at(n - 1), matching: find.byType(Opacity)))
        .opacity;
    expect(opacity(3), BunoBayTile.lowOpacity);
    expect([opacity(1), opacity(5)], [1, 1]);
    await tester.tap(find.bySemanticsLabel('خانة 3، 15%'));
    await tester.tap(find.bySemanticsLabel('خانة 5 فاضية'));
    await tester.pumpAndSettle();
    expect(_cta(tester), 'خد الـ 92%');
    expect(tile(1).selected, isTrue);

    await tester.tap(find.bySemanticsLabel('خانة 2، 88%'));
    await tester.pumpAndSettle();
    expect(tile(2).selected, isTrue);
    expect(tile(1).selected, isFalse);
    expect(_cta(tester), 'خد الـ 88%');

    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();
    expect(tester.widget<ConfirmScreen>(find.byType(ConfirmScreen)).bayIndex, 1);
  });

  testWidgets('/station: empty station has no CTA action', (tester) async {
    await _pumpRoute(tester, const Size(390, 844), '/station', 'BUN-03');
    expect(tester.widget<BunoPrimaryButton>(find.byType(BunoPrimaryButton)).onPressed, isNull);
  });

  testWidgets('/station not found: scan again opens /scan', (tester) async {
    await _pumpRoute(tester, const Size(390, 844), '/station', 'nonsense');
    await tester.tap(find.text('امسح تاني'));
    await tester.pumpAndSettle();
    expect(find.byType(ScanScreen), findsOneWidget);
  });

  testWidgets('/confirm: CTA verifies, then unlocks and opens /unlocking', (tester) async {
    rentalSession.balance = 50;
    final station = mockStations[3];
    await _pumpRoute(tester, const Size(390, 844), '/confirm', (station, 2));
    expect(find.text('[رسوم عدم الإرجاع]'), findsOneWidget);
    expect(_cta(tester), 'تمام، افتح الخانة');

    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();
    expect(find.byType(VerifyingScreen), findsOneWidget);
    expect(rentalSession.state, RentalState.idle, reason: 'nothing unlocks before the checks pass');
    for (var i = 0; i < 4; i++) {
      await tester.pump(VerifyingScreen.checkDuration);
    }
    expect(rentalSession.state, RentalState.unlocking);
    expect(rentalSession.station, same(station));
    expect(rentalSession.bayIndex, 2);
    await tester.pumpAndSettle();
    expect(find.byType(UnlockingScreen), findsOneWidget);
    // Let the mock unlock delay and stages finish.
    for (var i = 0; i < 5; i++) {
      await tester.pump(UnlockingScreen.stageDuration);
    }
    await tester.pumpAndSettle();
    expect(rentalSession.state, RentalState.released);
  });

  testWidgets('/confirm: low balance shows sheet, chip + CTA open /topup', (tester) async {
    rentalSession.balance = mockMinBalance - 1;
    await _pumpRoute(tester, const Size(390, 844), '/confirm', (mockStations.first, 0));
    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();
    expect(rentalSession.state, RentalState.idle);
    expect(find.text('رصيدك مش مكفّي'), findsOneWidget);
    expect(_cta(tester), 'اشحن 100');

    await tester.tap(find.textContaining('200', findRichText: true).first);
    await tester.pumpAndSettle();
    expect(_cta(tester), 'اشحن 200');

    await tester.tap(find.byType(BunoPrimaryButton).last);
    await tester.pumpAndSettle();
    expect(find.byType(LowBalanceSheet), findsNothing);
    expect(tester.widget<TopupScreen>(find.byType(TopupScreen)).amount, 200);
  });
}

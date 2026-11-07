import 'package:buno/app_routes.dart';
import 'package:buno/data/mock_rental.dart';
import 'package:buno/data/mock_sos.dart';
import 'package:buno/main.dart';
import 'package:buno/screens/rental/verifying_screen.dart';
import 'package:buno/screens/scan/scan_screen.dart';
import 'package:buno/screens/sos/sos_got_screen.dart';
import 'package:buno/screens/sos/sos_screen.dart';
import 'package:buno/screens/station/confirm_screen.dart';
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

String _cta(WidgetTester tester) => tester.widget<BunoPrimaryButton>(find.byType(BunoPrimaryButton)).label;

void main() {
  setUpAll(loadBunoFonts);
  setUp(useReducedMotion);
  setUp(useFakeScanCamera);
  setUp(() => useFakeBattery(level: 2));
  setUp(sosSession.debugReset);
  late double balance;
  setUp(() => balance = rentalSession.balance);
  tearDown(() => rentalSession.balance = balance);

  group('no overflow, RTL', () {
    for (final size in _sizes) {
      final label = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('/sos at $label', (tester) async {
        await _pumpApp(tester, AppRoutes.sos, size: size);
        expect(tester.takeException(), isNull);
        expect(Directionality.of(tester.element(find.byType(SosScreen))), TextDirection.rtl);
        expect(find.byType(BunoPrimaryButton), findsOneWidget);
        // The ring sits centred; the first friend's avatar on the right.
        expect(tester.getCenter(find.text('أ')).dx, greaterThan(size.width / 2));
      });

      testWidgets('/sos waiting at $label', (tester) async {
        sosSession.send(mockSosFriends.first);
        await _pumpApp(tester, AppRoutes.sos, size: size);
        expect(tester.takeException(), isNull);
        expect(find.text('مستني أحمد يرد'), findsOneWidget);
        expect(find.byType(BunoPrimaryButton), findsNothing);
      });

      testWidgets('/sos/help at $label', (tester) async {
        await _pumpApp(tester, AppRoutes.sosHelp, size: size);
        expect(tester.takeException(), isNull);
        expect(find.byType(BunoPrimaryButton), findsOneWidget);
      });

      testWidgets('/sos/got at $label', (tester) async {
        sosSession
          ..send(mockSosFriends[1])
          ..markPaid();
        await _pumpApp(tester, AppRoutes.sosGot, size: size);
        expect(tester.takeException(), isNull);
        expect(Directionality.of(tester.element(find.byType(SosGotScreen))), TextDirection.rtl);
        expect(find.text('سارة لحقك!'), findsOneWidget);
        // The friend's avatar starts the pair (right in RTL), the user's ends it.
        expect(tester.getCenter(find.text('س')).dx, greaterThan(tester.getCenter(find.text('م')).dx));
      });
    }
  });

  testWidgets('/sos: real %, first friend pre-selected, picking another renames the button', (tester) async {
    await _pumpApp(tester, AppRoutes.sos);
    expect(find.bySemanticsLabel('بطارية موبايلك 2%'), findsOneWidget);
    expect(_cta(tester), 'ابعت لأحمد');
    await tester.tap(find.text('سارة'));
    await tester.pumpAndSettle();
    expect(_cta(tester), 'ابعت لسارة');
  });

  testWidgets('WhatsApp link shows a snackbar', (tester) async {
    await _pumpApp(tester, AppRoutes.sos);
    await tester.tap(find.text('أو ابعت لينك على واتساب'));
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('send → waiting; cancel gives today\'s request back', (tester) async {
    await _pumpApp(tester, AppRoutes.sos);
    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();
    expect(sosSession.state, SosState.waiting);
    expect(find.text('مستني أحمد يرد'), findsOneWidget);
    expect(sosSession.canSendToday, isFalse);

    await tester.tap(find.text('إلغي الطلب'));
    await tester.pumpAndSettle();
    expect(sosSession.state, SosState.idle);
    expect(sosSession.canSendToday, isTrue);
    expect(find.byType(BunoPrimaryButton), findsOneWidget);
  });

  testWidgets('debug "صاحبك دفع" → /sos/got → "امسح وخد" opens /scan', (tester) async {
    await _pumpApp(tester, AppRoutes.sos);
    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تجربة: صاحبك دفع'));
    await tester.pumpAndSettle();
    expect(find.text('أحمد لحقك!'), findsOneWidget);
    expect(sosSession.firstHourPaidBy, mockSosFriends.first);

    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();
    expect(find.byType(ScanScreen), findsOneWidget);
  });

  testWidgets('/confirm says who paid, skips the balance check and uses it once', (tester) async {
    rentalSession.balance = 0;
    sosSession
      ..send(mockSosFriends.first)
      ..markPaid();
    await _pumpApp(tester, AppRoutes.confirm);
    expect(find.text('الساعة الأولى مدفوعة من أحمد'), findsOneWidget);

    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(LowBalanceSheet), findsNothing);
    expect(find.byType(VerifyingScreen), findsOneWidget);
    expect(sosSession.firstHourPaidBy, isNull);

    // Stop the verifying flow before it rents anything.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
    if (rentalSession.state != RentalState.idle) rentalSession.reset();
  });

  testWidgets('one SOS a day: after it is used the button is off', (tester) async {
    sosSession
      ..send(mockSosFriends.first)
      ..markPaid()
      ..useFirstHour();
    await _pumpApp(tester, AppRoutes.sos);
    expect(tester.widget<BunoPrimaryButton>(find.byType(BunoPrimaryButton)).onPressed, isNull);
    expect(find.textContaining('تقدر تطلب تاني بكرة'), findsOneWidget);
  });

  test('a new day frees the request', () {
    var now = DateTime(2026, 10, 27, 23);
    final s = SosSession(clock: () => now)..send(mockSosFriends.first);
    s
      ..markPaid()
      ..useFirstHour();
    expect(s.canSendToday, isFalse);
    expect(() => s.send(mockSosFriends[1]), throwsStateError);
    now = DateTime(2026, 10, 28, 1);
    expect(s.canSendToday, isTrue);
  });

  testWidgets('/sos/help: pays the first hour from the wallet', (tester) async {
    rentalSession.balance = 50;
    await _pumpApp(tester, AppRoutes.sosHelp);
    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pump();
    expect(rentalSession.balance, 50 - mockMinBalance);
    expect(find.textContaining('دفعت لمحمد أول ساعة'), findsWidgets);
  });

  testWidgets('/sos/help: not enough balance opens the sheet without "اطلب من صاحبك"', (tester) async {
    rentalSession.balance = 5;
    await _pumpApp(tester, AppRoutes.sosHelp);
    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();
    expect(find.byType(LowBalanceSheet), findsOneWidget);
    expect(find.text('اطلب من صاحبك'), findsNothing);
    expect(rentalSession.balance, 5);
  });

  testWidgets('low-balance sheet: "اطلب من صاحبك" opens /sos', (tester) async {
    rentalSession.balance = 5;
    await _pumpApp(tester, AppRoutes.confirm);
    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('اطلب من صاحبك'));
    await tester.pumpAndSettle();
    expect(find.byType(LowBalanceSheet), findsNothing);
    expect(find.byType(SosScreen), findsOneWidget);
  });

  for (final size in _sizes) {
    testWidgets('home low: "اطلب من صاحبك" under the button opens /sos at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      useFakeBattery(level: 12);
      await _pumpApp(tester, AppRoutes.home, size: size);
      expect(tester.takeException(), isNull);
      final button = tester.getCenter(find.byType(BunoPrimaryButton));
      final link = find.text('اطلب من صاحبك');
      expect(tester.getCenter(link).dy, greaterThan(button.dy));
      await tester.tap(link);
      await tester.pumpAndSettle();
      expect(find.byType(SosScreen), findsOneWidget);
    });
  }

  testWidgets('home calm: no "اطلب من صاحبك"', (tester) async {
    useFakeBattery(level: 80);
    await _pumpApp(tester, AppRoutes.home);
    expect(find.text('اطلب من صاحبك'), findsNothing);
  });
}

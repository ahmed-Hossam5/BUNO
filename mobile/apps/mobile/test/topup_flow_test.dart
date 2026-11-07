import 'dart:convert';

import 'package:buno/data/mock_rental.dart';
import 'package:buno/data/mock_topup.dart';
import 'package:buno/main.dart';
import 'package:buno/screens/station/confirm_screen.dart';
import 'package:buno/screens/topup/topup_done_screen.dart';
import 'package:buno/screens/topup/topup_pending_screen.dart';
import 'package:buno/screens/topup/topup_screen.dart';
import 'package:buno/screens/topup/transfer_screen.dart';
import 'package:buno/screens/wallet/wallet_screen.dart';
import 'package:buno/widgets/buno_amount_chip.dart';
import 'package:buno/widgets/buno_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

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

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

Future<void> _tapChip(WidgetTester tester, int amount) async {
  await tester.tap(find.byWidgetPredicate((w) => w is BunoAmountChip && w.amount == amount));
  await tester.pumpAndSettle();
}

BunoAmountChip _selectedChip(WidgetTester tester) =>
    tester.widgetList<BunoAmountChip>(find.byType(BunoAmountChip)).singleWhere((c) => c.selected);

/// Lets the mock review finish and /topup/done take over.
Future<void> _finishReview(WidgetTester tester) async {
  await tester.pump(topupReviewDelay);
  await tester.pumpAndSettle();
}

bool _canSend(WidgetTester tester) =>
    tester.widget<BunoPrimaryButton>(find.byType(BunoPrimaryButton)).onPressed != null;

// A 1x1 transparent PNG.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

void main() {
  setUpAll(loadBunoFonts);
  setUp(useFakeBattery);
  setUp(useReducedMotion);
  setUp(useFakeScanCamera);

  late double balance;
  setUp(() => balance = rentalSession.balance);
  tearDown(() => rentalSession.balance = balance);

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
    '/topup': TopupScreen,
    '/topup/transfer': TransferScreen,
    '/topup/pending': TopupPendingScreen,
    '/topup/done': TopupDoneScreen,
  };

  for (final size in sizes) {
    final at = '${size.width.toInt()}x${size.height.toInt()}';
    for (final MapEntry(key: route, value: type) in screens.entries) {
      testWidgets('$route: no overflow and RTL at $at', (tester) async {
        await _pumpRoute(tester, size, route);
        expect(tester.takeException(), isNull);
        expect(find.byType(type), findsOneWidget);
        expect(Directionality.of(tester.element(find.byType(type))), TextDirection.rtl);
        expect(find.byType(BunoPrimaryButton), type == TopupPendingScreen ? findsNothing : findsOneWidget);
        if (type == TopupPendingScreen) await _finishReview(tester);
      });
    }
  }

  testWidgets('/topup keeps the amount it was opened with', (tester) async {
    await _pumpRoute(tester, const Size(390, 844), '/topup', 200);
    expect(_selectedChip(tester).amount, 200);

    await _tapChip(tester, 500);
    await _tapText(tester, 'إنستا باي');
    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();
    final transfer = tester.widget<TransferScreen>(find.byType(TransferScreen));
    expect(transfer.request.amount, 500);
    expect(transfer.request.method, TopupMethod.instaPay);
  });

  testWidgets('/topup/transfer: send needs a photo or a reference number; copy copies', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    const request = TopupRequest(amount: 100, method: TopupMethod.vodafoneCash);
    var picks = 0;
    await _pumpRoute(tester, const Size(390, 844), '/');
    tester.state<NavigatorState>(find.byType(Navigator)).push(MaterialPageRoute<void>(
          builder: (_) => TransferScreen(
            request: request,
            pickReceipt: () async {
              picks++;
              return XFile.fromData(_png, mimeType: 'image/png');
            },
          ),
        ));
    await tester.pumpAndSettle();
    expect(_canSend(tester), isFalse);

    await _tapText(tester, 'نسخ');
    expect(copied, request.method.account);
    expect(find.text('اتنسخ'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '8821340');
    await tester.pump();
    expect(_canSend(tester), isTrue);
    await tester.enterText(find.byType(TextField), '  ');
    await tester.pump();
    expect(_canSend(tester), isFalse);

    await _tapText(tester, 'ارفع صورة الإيصال');
    expect(picks, 1);
    expect(_canSend(tester), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wallet → top-up → done adds to the balance and returns to the wallet', (tester) async {
    await _pumpRoute(tester, const Size(390, 844), '/wallet');
    final before = rentalSession.balance;

    await _tapText(tester, 'اشحن');
    expect(find.byType(TopupScreen), findsOneWidget);
    await _tapChip(tester, 200);
    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '8821340');
    await tester.pump();
    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();
    expect(find.byType(TopupPendingScreen), findsOneWidget);
    expect(rentalSession.balance, before);

    await _finishReview(tester);
    expect(find.byType(TopupDoneScreen), findsOneWidget);
    expect(rentalSession.balance, before + 200);
    expect(find.text('${(before + 200).round()}'), findsOneWidget);

    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();
    expect(find.byType(WalletScreen), findsOneWidget);
    expect(find.byType(TopupScreen), findsNothing);
  });

  testWidgets('low-balance sheet → top-up → done returns to /confirm', (tester) async {
    rentalSession.balance = mockMinBalance - 1;
    await _pumpRoute(tester, const Size(390, 844), '/confirm', (mockStations.first, 0));
    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BunoPrimaryButton).last);
    await tester.pumpAndSettle();
    expect(tester.widget<TopupScreen>(find.byType(TopupScreen)).amount, 100);

    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '1');
    await tester.pump();
    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();
    await _finishReview(tester);
    expect(rentalSession.balance, mockMinBalance - 1 + 100);

    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();
    expect(find.byType(ConfirmScreen), findsOneWidget);
    expect(find.byType(LowBalanceSheet), findsNothing);
  });
}

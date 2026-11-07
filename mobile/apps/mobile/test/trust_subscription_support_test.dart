import 'package:buno/app_routes.dart';
import 'package:buno/data/mock_subscription.dart';
import 'package:buno/data/mock_trust.dart';
import 'package:buno/main.dart';
import 'package:buno/screens/account/plans_screen.dart';
import 'package:buno/screens/scan/scan_screen.dart';
import 'package:buno/screens/stations/stations_screen.dart';
import 'package:buno/screens/subscription/subscription_screen.dart';
import 'package:buno/screens/support/emergency_screen.dart';
import 'package:buno/screens/support/guarantee_screen.dart';
import 'package:buno/screens/trust/trust_screen.dart';
import 'package:buno/widgets/buno_buttons.dart';
import 'package:buno/widgets/buno_pressable.dart';
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

Finder _pressable(String label) => find.byWidgetPredicate((w) => w is BunoPressable && w.semanticLabel == label);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadBunoFonts);
  setUp(useReducedMotion);
  setUp(useFakeScanCamera);
  setUp(() => useFakeBattery(level: 80));
  setUp(MockTrust.reset);
  setUp(MockSubscription.reset);
  setUp(MockEmergency.reset);

  const screens = {
    AppRoutes.trust: TrustScreen,
    AppRoutes.subscription: SubscriptionScreen,
    AppRoutes.guarantee: GuaranteeScreen,
    AppRoutes.emergency: EmergencyScreen,
  };

  group('no overflow, RTL', () {
    for (final MapEntry(key: route, value: type) in screens.entries) {
      for (final size in _sizes) {
        testWidgets('$route at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
          await _pumpApp(tester, route, size: size);
          expect(tester.takeException(), isNull);
          expect(find.byType(type), findsOneWidget);
          expect(Directionality.of(tester.element(find.byType(type))), TextDirection.rtl);
          expect(find.byType(BunoPrimaryButton).evaluate().length, lessThanOrEqualTo(1));
        });
      }
    }
  });

  group('/trust', () {
    testWidgets('6 on-time returns: regular, threshold as a placeholder', (tester) async {
      await _pumpApp(tester, AppRoutes.trust);
      expect(MockTrust.current.number, 2);
      expect(find.text('مستواك'), findsOneWidget);
      expect(find.textContaining(RegExp(r'فاضل \[العدد\] إيجارات للمستوى .*3'), findRichText: true), findsOneWidget);
      expect(find.textContaining(RegExp(r'6.* / \[العدد\]'), findRichText: true), findsOneWidget);
      for (final l in MockTrust.levels) {
        expect(find.text(l.name.ar), findsWidgets);
      }
    });

    test('levels follow on-time returns', () {
      MockTrust.onTimeReturns = 0;
      expect(MockTrust.current.number, 1);
      MockTrust.onTimeReturns = 3;
      expect(MockTrust.current.number, 2);
      MockTrust.onTimeReturns = 10;
      expect(MockTrust.current.number, 3);
      expect(MockTrust.next, isNull);
    });

    testWidgets('top level shows no progress bar', (tester) async {
      MockTrust.onTimeReturns = 12;
      await _pumpApp(tester, AppRoutes.trust);
      expect(tester.takeException(), isNull);
      expect(find.text('إنت في أعلى مستوى'), findsOneWidget);
    });

    testWidgets('opened from profile', (tester) async {
      await _pumpApp(tester, AppRoutes.profile);
      await _tap(tester, find.text('مستواك في بونو'));
      expect(find.byType(TrustScreen), findsOneWidget);
    });

    testWidgets("opened from the wallet card's level badge", (tester) async {
      await _pumpApp(tester, AppRoutes.wallet);
      await _tap(tester, _pressable('مستواك: عميل منتظم'));
      expect(find.byType(TrustScreen), findsOneWidget);
    });
  });

  group('/subscription', () {
    testWidgets('shows the plan with placeholders and usage', (tester) async {
      await _pumpApp(tester, AppRoutes.subscription);
      expect(find.text('مريح'), findsOneWidget);
      expect(find.text('شغّال'), findsOneWidget);
      expect(find.textContaining('[التاريخ]'), findsOneWidget);
      expect(find.textContaining('[السعر]'), findsOneWidget);
      expect(find.textContaining('[عدد الإيجارات]', findRichText: true), findsOneWidget);
      expect(find.textContaining('[الساعات]', findRichText: true), findsOneWidget);
    });

    testWidgets('change plan opens /plans', (tester) async {
      await _pumpApp(tester, AppRoutes.subscription);
      await _tap(tester, _pressable('غيّر الباقة'));
      expect(find.byType(PlansScreen), findsOneWidget);
    });

    testWidgets('cancel asks first; "لأ" keeps auto-renew', (tester) async {
      await _pumpApp(tester, AppRoutes.subscription);
      await _tap(tester, _pressable('ألغي التجديد التلقائي'));
      expect(find.text('تلغي التجديد التلقائي؟'), findsOneWidget);
      await tester.tap(find.text('لأ'));
      await tester.pumpAndSettle();
      expect(MockSubscription.autoRenew.value, isTrue);
    });

    testWidgets('confirming cancels auto-renew', (tester) async {
      await _pumpApp(tester, AppRoutes.subscription);
      await _tap(tester, _pressable('ألغي التجديد التلقائي'));
      await tester.tap(find.text('ألغي'));
      await tester.pumpAndSettle();
      expect(MockSubscription.autoRenew.value, isFalse);
      expect(find.text('مش هيتجدد'), findsOneWidget);
      expect(_pressable('ألغي التجديد التلقائي'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('/guarantee and /emergency', () {
    testWidgets('both are linked from /help', (tester) async {
      await _pumpApp(tester, AppRoutes.help);
      await _tap(tester, find.text('المحطة مليانة؟ علينا'));
      expect(find.byType(GuaranteeScreen), findsOneWidget);
      Navigator.of(tester.element(find.byType(GuaranteeScreen))).pop();
      await tester.pumpAndSettle();
      await _tap(tester, find.text('إيجار الطوارئ'));
      expect(find.byType(EmergencyScreen), findsOneWidget);
    });

    testWidgets('guarantee: the primary button opens /stations', (tester) async {
      await _pumpApp(tester, AppRoutes.guarantee);
      expect(find.textContaining('[السعر]'), findsOneWidget);
      expect(find.textContaining('[المدة]', findRichText: true), findsOneWidget);
      await _tap(tester, find.byType(BunoPrimaryButton));
      expect(find.byType(StationsScreen), findsOneWidget);
    });

    testWidgets('emergency: using it opens /scan and marks it used', (tester) async {
      await _pumpApp(tester, AppRoutes.emergency);
      expect(find.text('لسه ماستخدمتهاش'), findsOneWidget);
      await _tap(tester, find.byType(BunoPrimaryButton));
      expect(find.byType(ScanScreen), findsOneWidget);
      expect(MockEmergency.used.value, isTrue);
    });

    testWidgets('emergency: once used, the button is off', (tester) async {
      MockEmergency.used.value = true;
      await _pumpApp(tester, AppRoutes.emergency);
      expect(find.text('استخدمتها'), findsOneWidget);
      expect(tester.widget<BunoPrimaryButton>(find.byType(BunoPrimaryButton)).onPressed, isNull);
    });
  });
}

import 'package:buno/app_routes.dart';
import 'package:buno/data/mock_first_run.dart';
import 'package:buno/main.dart';
import 'package:buno/screens/auth/apple_sign_in_button.dart';
import 'package:buno/screens/auth/verify_uni_screen.dart';
import 'package:buno/screens/home/home_screen.dart';
import 'package:buno/screens/onboarding/onboarding_screen.dart';
import 'package:buno/screens/permissions/permissions_screen.dart';
import 'package:buno/screens/splash/splash_screen.dart';
import 'package:buno/widgets/buno_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_battery.dart';
import 'fake_scan_camera.dart';
import 'home_screen_test.dart' show loadBunoFonts;
import 'reduced_motion.dart';

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _pumpRoute(WidgetTester tester, String route, {Size size = const Size(390, 844)}) async {
  _setSize(tester, size);
  await tester.pumpWidget(BunoApp(key: UniqueKey()));
  await tester.pumpAndSettle();
  tester.state<NavigatorState>(find.byType(Navigator)).pushNamed(route);
  await tester.pumpAndSettle();
}

/// Starts the app the way main() does, on /splash, without waiting it out.
Future<void> _startApp(WidgetTester tester, {Size size = const Size(390, 844)}) async {
  _setSize(tester, size);
  await tester.pumpWidget(BunoApp(key: UniqueKey(), initialRoute: AppRoutes.splash));
  await tester.pump();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadBunoFonts);
  setUp(useFakeBattery);
  setUp(useReducedMotion);
  setUp(useFakeScanCamera);
  setUp(MockFirstRun.reset);
  setUp(MockPermissions.reset);

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

    testWidgets('/splash: no overflow and RTL at $at', (tester) async {
      await _startApp(tester, size: size);
      expect(tester.takeException(), isNull);
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(Directionality.of(tester.element(find.byType(SplashScreen))), TextDirection.rtl);
      await tester.pumpAndSettle();
    });

    for (final (route, type) in [
      (AppRoutes.permissions, PermissionsScreen),
      (AppRoutes.verifyUni, VerifyUniScreen),
    ]) {
      testWidgets('$route: no overflow and RTL at $at', (tester) async {
        await _pumpRoute(tester, route, size: size);
        expect(tester.takeException(), isNull);
        expect(Directionality.of(tester.element(find.byType(type))), TextDirection.rtl);
        // One primary button, at the bottom.
        expect(find.byType(BunoPrimaryButton), findsOneWidget);
        expect(tester.getBottomLeft(find.byType(BunoPrimaryButton)).dy, greaterThan(size.height * 0.7));
      });
    }
  }

  testWidgets('/splash goes to onboarding the first time, home after that', (tester) async {
    await _startApp(tester);
    await tester.pump(SplashScreen.duration - const Duration(milliseconds: 100));
    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
    expect(MockFirstRun.onboardingSeen, isTrue);
    expect(tester.state<NavigatorState>(find.byType(Navigator)).canPop(), isFalse);

    await _startApp(tester);
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(tester.state<NavigatorState>(find.byType(Navigator)).canPop(), isFalse);
  });

  testWidgets('sign-up: code → permissions → verify-uni (skip) → home', (tester) async {
    await _pumpRoute(tester, AppRoutes.verify);
    await tester.enterText(find.byType(TextField), '4817');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(PermissionsScreen), findsOneWidget);
    expect(tester.state<NavigatorState>(find.byType(Navigator)).canPop(), isFalse);

    await _tapText(tester, 'كمّل');
    expect(find.byType(VerifyUniScreen), findsOneWidget);

    await _tapText(tester, 'مش طالب؟ تخطّى');
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(MockFirstRun.uniEmail, isNull);
  });

  testWidgets('sign-up with Apple: straight to permissions, then verify-uni → home', (tester) async {
    await _pumpRoute(tester, AppRoutes.signup);
    await tester.ensureVisible(find.byType(AppleSignInButton));
    await tester.tap(find.byType(AppleSignInButton));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(PermissionsScreen), findsOneWidget);
    expect(tester.state<NavigatorState>(find.byType(Navigator)).canPop(), isFalse);

    await _tapText(tester, 'كمّل');
    await _tapText(tester, 'مش طالب؟ تخطّى');
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('/permissions: switches toggle, "بعدين" also moves on', (tester) async {
    await _pumpRoute(tester, AppRoutes.permissions);
    expect(MockPermissions.camera.value, isFalse);
    await _tapText(tester, 'الكاميرا');
    expect(MockPermissions.camera.value, isTrue);

    final location = find.ancestor(of: find.text('الموقع'), matching: find.byType(MergeSemantics));
    await tester.tap(find.descendant(of: location, matching: find.byType(Switch)));
    await tester.pumpAndSettle();
    expect(MockPermissions.location.value, isFalse);

    await _tapText(tester, 'بعدين');
    expect(find.byType(VerifyUniScreen), findsOneWidget);

    // Back returns to the permissions.
    await tester.tap(find.bySemanticsLabel('رجوع'));
    await tester.pumpAndSettle();
    expect(find.byType(PermissionsScreen), findsOneWidget);
  });

  testWidgets('/verify-uni: rejects a non-.edu.eg e-mail, sends a good one and enters the app', (tester) async {
    await _pumpRoute(tester, AppRoutes.verifyUni);
    await tester.enterText(find.byType(TextField), 'sara@gmail.com');
    await _tapText(tester, 'ابعت لينك التأكيد');
    expect(find.byType(VerifyUniScreen), findsOneWidget);
    expect(find.textContaining('اكتب إيميل الجامعة'), findsOneWidget);
    expect(MockFirstRun.uniEmail, isNull);

    await tester.enterText(find.byType(TextField), 'sara@sut.edu.eg');
    await _tapText(tester, 'ابعت لينك التأكيد');
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(MockFirstRun.uniEmail, 'sara@sut.edu.eg');
  });

  test('isUniEmail', () {
    expect(isUniEmail('name@sut.edu.eg'), isTrue);
    expect(isUniEmail(' Name@Cairo.EDU.EG '), isTrue);
    expect(isUniEmail('name@gmail.com'), isFalse);
    expect(isUniEmail('name@edu.eg.com'), isFalse);
    expect(isUniEmail('@sut.edu.eg'), isFalse);
  });
}

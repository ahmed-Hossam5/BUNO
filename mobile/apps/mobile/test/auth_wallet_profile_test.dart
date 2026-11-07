import 'package:buno/app_routes.dart';
import 'package:buno/data/mock_auth.dart';
import 'package:buno/screens/auth/apple_sign_in_button.dart';
import 'package:buno/screens/auth/verify_code_screen.dart';
import 'package:buno/screens/history/history_screen.dart';
import 'package:buno/screens/home/home_screen.dart';
import 'package:buno/screens/permissions/permissions_screen.dart';
import 'package:buno/screens/profile/profile_screen.dart';
import 'package:buno/screens/wallet/wallet_screen.dart';
import 'package:buno/theme/buno_tokens.dart';
import 'package:buno/widgets/buno_back_button.dart';
import 'package:buno/widgets/buno_bottom_nav.dart';
import 'package:buno/widgets/buno_buttons.dart';
import 'package:buno/widgets/buno_logo.dart';
import 'package:buno/widgets/buno_pressable.dart';
import 'package:buno/widgets/buno_text_field.dart';
import 'package:buno/widgets/buno_wallet_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_battery.dart';
import 'home_screen_test.dart' show loadBunoFonts;
import 'reduced_motion.dart';

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
    onGenerateRoute: AppRoutes.onGenerateRoute,
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadBunoFonts);
  setUp(useFakeBattery);
  setUp(useReducedMotion);

  const sizes = [
    Size(390, 844),
    Size(375, 667),
    Size(360, 640),
    Size(320, 568),
    Size(430, 932),
    Size(412, 915),
  ];
  const routes = [AppRoutes.login, AppRoutes.signup, AppRoutes.verify, AppRoutes.wallet, AppRoutes.profile];

  for (final route in routes) {
    for (final size in sizes) {
      testWidgets('$route: no overflow, RTL at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        await _pumpRoute(tester, route, size: size);
        expect(tester.takeException(), isNull);
        // The header logo (the wallet card has its own after it).
        final logo = find.byType(BunoLogo).first;
        expect(Directionality.of(tester.element(logo)), TextDirection.rtl);
        if (route == AppRoutes.wallet || route == AppRoutes.profile) {
          // Tab screens: title on the right, logo on the left.
          expect(tester.getCenter(logo).dx, lessThan(size.width / 2));
        } else {
          // Auth screens: logo on the right, back button on the left.
          expect(tester.getCenter(logo).dx, greaterThan(size.width / 2));
          expect(tester.getCenter(find.byType(BunoBackButton)).dx, lessThan(size.width / 2));
        }
      });
    }
  }

  testWidgets('login: validates, then e-mail sign-in enters the app', (tester) async {
    await _pumpRoute(tester, AppRoutes.login);
    // Email login only: no phone field and no Google option.
    expect(find.text('رقم الموبايل'), findsNothing);
    expect(find.textContaining('Google'), findsNothing);
    expect(find.byType(AppleSignInButton), findsOneWidget);

    await tester.tap(find.text('تسجيل الدخول'));
    await tester.pump();
    expect(find.text('اكتب إيميل صحيح'), findsOneWidget);
    expect(find.text('اكتب كلمة السر'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'sara@example.com');
    await tester.enterText(fields.at(1), 'secret-pass');
    await tester.tap(find.text('تسجيل الدخول'));
    await tester.pump(); // loading spinner
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('login: Sign in with Apple (iCloud) enters the app', (tester) async {
    await _pumpRoute(tester, AppRoutes.login);
    await tester.tap(find.byType(AppleSignInButton));
    await tester.pump(const Duration(seconds: 1)); // mock network delay
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('signup: validates, sends a code to the e-mail, verifies', (tester) async {
    await _pumpRoute(tester, AppRoutes.signup);
    await tester.tap(find.text('إنشاء الحساب'));
    await tester.pump();
    expect(find.text('اكتب اسمك'), findsOneWidget);
    expect(find.text('كلمة السر لازم تكون 8 حروف على الأقل'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'سارة');
    await tester.enterText(fields.at(1), 'sara@example.com');
    await tester.enterText(fields.at(2), 'short');
    await tester.tap(find.text('إنشاء الحساب'));
    await tester.pump();
    expect(find.text('كلمة السر لازم تكون 8 حروف على الأقل'), findsOneWidget);

    // Unticking the terms blocks sign-up.
    await tester.enterText(fields.at(2), 'long-enough');
    await tester.tap(find.byType(BunoCheckbox));
    await tester.pump();
    await tester.tap(find.text('إنشاء الحساب'));
    await tester.pump();
    expect(find.text('لازم توافق على الشروط الأول'), findsOneWidget);

    await tester.tap(find.byType(BunoCheckbox));
    await tester.pump();
    await tester.tap(find.text('إنشاء الحساب'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(VerifyCodeScreen), findsOneWidget);
    expect(find.text('sara@example.com'), findsOneWidget);
    expect(MockAuth.pendingEmail, 'sara@example.com');

    // Typing 4 digits auto-confirms and moves on to /permissions.
    await tester.enterText(find.byType(TextField), '4817');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(PermissionsScreen), findsOneWidget);
  });

  testWidgets('verify: timer counts down, then offers to resend', (tester) async {
    await _pumpRoute(tester, AppRoutes.verify);
    expect(find.textContaining('00:42'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.textContaining('00:40'), findsOneWidget);
    await tester.pump(const Duration(seconds: 41));
    expect(find.text('ابعته تاني'), findsOneWidget);

    // Confirm with an incomplete code shows the error state.
    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pump();
    expect(find.text('الكود مش صح، جرّب تاني'), findsOneWidget);
  });

  testWidgets('tabs: wallet <-> profile <-> home via the bottom nav', (tester) async {
    await _pumpRoute(tester, AppRoutes.wallet);
    BunoBottomNav nav() => tester.widget(find.byType(BunoBottomNav));
    expect(nav().currentIndex, 2);

    await tester.tap(find.text('حسابي').last);
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(nav().currentIndex, 3);

    await tester.tap(find.text('رحلاتي').last);
    await tester.pumpAndSettle();
    expect(find.byType(HistoryScreen), findsOneWidget);
    expect(nav().currentIndex, 1);

    await tester.tap(find.text('الرئيسية'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('wallet: card eye hides the balance', (tester) async {
    await _pumpRoute(tester, AppRoutes.wallet);
    expect(find.byType(BunoWalletCard), findsOneWidget);
    expect(find.textContaining('[الرصيد]', findRichText: true), findsOneWidget);

    await tester.tap(find.byWidgetPredicate((w) => w is BunoPressable && w.semanticLabel == 'اخفي الرصيد'));
    await tester.pumpAndSettle();
    expect(find.textContaining('[الرصيد]', findRichText: true), findsNothing);

    await tester.tap(find.byWidgetPredicate((w) => w is BunoPressable && w.semanticLabel == 'اظهر الرصيد'));
    await tester.pumpAndSettle();
    expect(find.textContaining('[الرصيد]', findRichText: true), findsOneWidget);
  });

  testWidgets('profile: payment methods opens wallet, logout returns to login', (tester) async {
    await _pumpRoute(tester, AppRoutes.profile);
    await tester.tap(find.text('طرق الدفع'));
    await tester.pumpAndSettle();
    expect(find.byType(WalletScreen), findsOneWidget);

    await tester.tap(find.text('حسابي').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('تسجيل الخروج'), 200);
    await tester.tap(find.text('تسجيل الخروج'));
    await tester.pumpAndSettle();
    expect(find.byType(BunoTextField), findsWidgets); // login form
    expect(find.text('أهلًا تاني'), findsOneWidget);
  });
}

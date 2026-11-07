import 'package:buno/app_routes.dart';
import 'package:buno/data/mock_settings.dart';
import 'package:buno/main.dart';
import 'package:buno/screens/account/edit_profile_screen.dart';
import 'package:buno/screens/account/help_screen.dart';
import 'package:buno/screens/account/notifications_screen.dart';
import 'package:buno/screens/account/plans_screen.dart';
import 'package:buno/screens/account/referral_screen.dart';
import 'package:buno/screens/account/settings_screen.dart';
import 'package:buno/screens/auth/login_screen.dart';
import 'package:buno/screens/history/history_screen.dart';
import 'package:buno/screens/profile/profile_screen.dart';
import 'package:buno/screens/subscription/subscription_screen.dart';
import 'package:buno/widgets/buno_lottie_icon.dart';
import 'package:buno/widgets/buno_pressable.dart';
import 'package:buno/widgets/buno_title_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

import 'fake_battery.dart';
import 'fake_scan_camera.dart';
import 'home_screen_test.dart' show loadBunoFonts;
import 'reduced_motion.dart';

Future<void> _pumpRoute(WidgetTester tester, Size size, String route) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(BunoApp(key: UniqueKey()));
  await tester.pumpAndSettle();
  tester.state<NavigatorState>(find.byType(Navigator)).pushNamed(route);
  await tester.pumpAndSettle();
}

Finder _pressable(String label) =>
    find.byWidgetPredicate((w) => w is BunoPressable && w.semanticLabel == label);

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadBunoFonts);
  setUp(useFakeBattery);
  setUp(useReducedMotion);
  setUp(useFakeScanCamera);
  setUp(MockSettings.reset);

  const sizes = [
    Size(390, 844),
    Size(375, 667),
    Size(360, 640),
    Size(320, 568),
    Size(430, 932),
    Size(412, 915),
  ];

  const screens = {
    AppRoutes.notifications: NotificationsScreen,
    AppRoutes.settings: SettingsScreen,
    AppRoutes.editProfile: EditProfileScreen,
    AppRoutes.help: HelpScreen,
    AppRoutes.plans: PlansScreen,
    AppRoutes.referral: ReferralScreen,
  };

  for (final MapEntry(key: route, value: type) in screens.entries) {
    for (final size in sizes) {
      testWidgets('$route: no overflow and RTL at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        await _pumpRoute(tester, size, route);
        expect(find.byType(type), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(Directionality.of(tester.element(find.byType(BunoTitleBar))), TextDirection.rtl);
      });
    }
  }

  testWidgets('profile rows open the account screens', (tester) async {
    await _pumpRoute(tester, const Size(390, 844), AppRoutes.profile);
    for (final (label, type) in [
      ('الإشعارات', NotificationsScreen),
      ('الإعدادات', SettingsScreen),
      ('الباقات', PlansScreen),
      ('ادعي صاحبك', ReferralScreen),
      ('المساعدة والدعم', HelpScreen),
    ]) {
      await _tapText(tester, label);
      expect(find.byType(type), findsOneWidget, reason: label);
      await tester.tap(find.bySemanticsLabel('رجوع').last);
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
    }
    // The list may have scrolled the user card out (and away): scroll back up.
    await tester.scrollUntilVisible(_pressable('تعديل'), -80, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(_pressable('تعديل'));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsOneWidget);
  });

  testWidgets('wallet: اشتراكي opens /subscription, الإيصالات opens /history', (tester) async {
    await _pumpRoute(tester, const Size(390, 844), AppRoutes.wallet);
    await _tapText(tester, 'اشتراكي');
    expect(find.byType(SubscriptionScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(SubscriptionScreen))).pop();
    await tester.pumpAndSettle();
    await _tapText(tester, 'الإيصالات');
    expect(find.byType(HistoryScreen), findsOneWidget);
  });

  testWidgets('settings: reduce motion stops BunoLottieIcon app-wide', (tester) async {
    // Platform reduced motion off, so only the in-app toggle can stop it.
    TestWidgetsFlutterBinding.instance.platformDispatcher.clearAccessibilityFeaturesTestValue();
    await tester.pumpWidget(
      const MaterialApp(home: BunoLottieIcon(name: 'chat_typing', loop: true)),
    );
    final controller = tester.widget<Lottie>(find.byType(Lottie)).controller! as AnimationController;
    for (var i = 0; i < 50 && controller.duration == null; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    expect(controller.isAnimating, isTrue);
    MockSettings.reduceMotion.value = true;
    await tester.pump();
    expect(controller.isAnimating, isFalse);
    expect(controller.value, 1);
    MockSettings.reduceMotion.value = false;
    await tester.pump();
    expect(controller.isAnimating, isTrue);
    MockSettings.reduceMotion.value = true;
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('settings: toggles, delete confirm, logout', (tester) async {
    await _pumpRoute(tester, const Size(390, 844), AppRoutes.settings);
    expect(MockSettings.reduceMotion.value, isFalse);
    final reduceMotionRow = find.ancestor(of: find.text('تقليل الحركة'), matching: find.byType(MergeSemantics));
    await tester.tap(find.descendant(of: reduceMotionRow, matching: find.byType(Switch)));
    await tester.pumpAndSettle();
    expect(MockSettings.reduceMotion.value, isTrue);

    // The list is lazy; the debug rows push delete below the fold.
    await tester.scrollUntilVisible(find.text('حذف الحساب'), 200);
    await _tapText(tester, 'حذف الحساب');
    expect(find.byType(AlertDialog), findsOneWidget);
    await _tapText(tester, 'لأ');
    expect(find.byType(SettingsScreen), findsOneWidget);
    await _tapText(tester, 'حذف الحساب');
    await _tapText(tester, 'امسح');
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('notifications: tapping clears the unread dot', (tester) async {
    await _pumpRoute(tester, const Size(390, 844), AppRoutes.notifications);
    expect(find.bySemanticsLabel(RegExp('غير مقروء')), findsNWidgets(2));
    await tester.tap(find.text('رجع مكانه'));
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp('غير مقروء')), findsOneWidget);
  });

  testWidgets('edit profile: save shows a snackbar and pops', (tester) async {
    await _pumpRoute(tester, const Size(390, 844), AppRoutes.profile);
    await tester.tap(_pressable('تعديل'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'منى');
    await _tapText(tester, 'حفظ');
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('اتحفظت بياناتك'), findsOneWidget);
    expect(MockProfile.name, 'منى');
  });

  testWidgets('help: search filters and rows expand', (tester) async {
    await _pumpRoute(tester, const Size(390, 844), AppRoutes.help);
    await _tapText(tester, 'أرجّع فين؟');
    expect(find.textContaining('أي محطة بونو', findRichText: true), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'الاشتراك');
    await tester.pumpAndSettle();
    expect(find.text('الخانة مش بتفتح'), findsNothing);
    expect(find.text('إزاي ألغي الاشتراك؟'), findsOneWidget);
  });

  testWidgets('plans: middle selected, picking another changes subscribe', (tester) async {
    await _pumpRoute(tester, const Size(390, 844), AppRoutes.plans);
    expect(find.text('اشترك في «مريح»'), findsOneWidget);
    await _tapText(tester, 'الترم');
    await _tapText(tester, 'اشترك في «الترم»');
    expect(find.text('اشتركت في «الترم»'), findsOneWidget);
  });

  testWidgets('referral: copy puts the code on the clipboard, share shows a snackbar', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await _pumpRoute(tester, const Size(390, 844), AppRoutes.referral);
    await tester.tap(_pressable('نسخ'));
    await tester.pumpAndSettle();
    expect(copied, 'BUNO-MO12');
    expect(find.text('اتنسخ الكود'), findsOneWidget);
    await _tapText(tester, 'ابعت على واتساب');
    expect(find.textContaining('واتساب'), findsWidgets);
  });
}

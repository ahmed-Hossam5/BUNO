import 'package:buno/app_routes.dart';
import 'package:buno/l10n/buno_locale.dart';
import 'package:buno/main.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_battery.dart';
import 'fake_scan_camera.dart';
import 'home_screen_test.dart' show loadBunoFonts;
import 'reduced_motion.dart';

final _arabic = RegExp(r'[؀-ۿ]');

/// Every piece of text painted on screen right now.
List<String> _paintedText(WidgetTester tester) => [
      for (final e in find.byType(RichText).evaluate())
        (e.widget as RichText).text.toPlainText(),
    ];

/// Every screen in English at the 6 phone sizes: laid out left-to-right,
/// no overflow, and no Arabic left over.
void main() {
  setUpAll(loadBunoFonts);
  setUp(() => useFakeBattery(level: 80));
  setUp(useReducedMotion);
  setUp(useFakeScanCamera);
  setUp(() => BunoLocale.current.value = BunoLocale.english);
  tearDown(BunoLocale.reset);

  const sizes = [
    Size(390, 844),
    Size(375, 667),
    Size(360, 640),
    Size(320, 568),
    Size(430, 932),
    Size(412, 915),
  ];

  const routes = [
    AppRoutes.home, AppRoutes.onboarding, AppRoutes.login, AppRoutes.signup,
    AppRoutes.verify, AppRoutes.splash, AppRoutes.permissions, AppRoutes.verifyUni,
    AppRoutes.rental, AppRoutes.rentalUnit, AppRoutes.wallet, AppRoutes.profile,
    AppRoutes.scan, AppRoutes.scanCode, AppRoutes.scanMethods, AppRoutes.scanNfc,
    AppRoutes.reserve, AppRoutes.reserved, AppRoutes.station, AppRoutes.confirm,
    AppRoutes.verifying, AppRoutes.unlocking, AppRoutes.release, AppRoutes.report,
    AppRoutes.returnUnit, AppRoutes.returnDone, AppRoutes.receipt, AppRoutes.stations,
    AppRoutes.history, AppRoutes.topup, AppRoutes.topupTransfer, AppRoutes.topupPending,
    AppRoutes.topupDone, AppRoutes.notifications, AppRoutes.settings, AppRoutes.editProfile,
    AppRoutes.help, AppRoutes.plans, AppRoutes.referral, AppRoutes.offline,
    AppRoutes.offlineCode, AppRoutes.stationInfo, AppRoutes.favorites, AppRoutes.promo,
    AppRoutes.sos, AppRoutes.sosHelp, AppRoutes.sosGot,
    AppRoutes.exam, AppRoutes.examNight, AppRoutes.trust, AppRoutes.subscription,
    AppRoutes.guarantee, AppRoutes.emergency, AppRoutes.wrapped,
    AppRoutes.ops, AppRoutes.opsTasks, AppRoutes.opsStation, AppRoutes.opsRebalance,
    AppRoutes.search, AppRoutes.allStations,
  ];

  for (final route in routes) {
    for (final size in sizes) {
      testWidgets('$route in English, ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(BunoApp(initialRoute: route));
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);

        final body = find.byType(Navigator).first;
        expect(Directionality.of(tester.element(body)), TextDirection.ltr);
        // The language picker names Arabic in Arabic, on purpose.
        final leftovers = _paintedText(tester)
            .where((t) => _arabic.hasMatch(t) && t != BunoLocale.nameOf(BunoLocale.arabic))
            .toList();
        expect(leftovers, isEmpty, reason: 'Arabic text on $route in English');

        // Let timers (splash, verifying, pending top-up) run out.
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(minutes: 1));
      });
    }
  }

  testWidgets('switching the language in settings relays out the app', (tester) async {
    BunoLocale.reset();
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const BunoApp(initialRoute: AppRoutes.settings));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('الإعدادات'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('الإعدادات'))), TextDirection.rtl);

    await tester.ensureVisible(find.text('English'));
    await tester.tap(find.text('English'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Settings'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('Settings'))), TextDirection.ltr);
    expect(_paintedText(tester).where(_arabic.hasMatch), ['العربية']);

    await tester.tap(find.text('العربية'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('الإعدادات'), findsOneWidget);
  });
}

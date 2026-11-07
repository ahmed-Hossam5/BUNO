import 'package:buno/app_routes.dart';
import 'package:buno/main.dart';
import 'package:buno/widgets/buno_bay_tile.dart';
import 'package:buno/widgets/buno_buttons.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_battery.dart';
import 'fake_scan_camera.dart';
import 'home_screen_test.dart' show loadBunoFonts;
import 'reduced_motion.dart';

/// Every screen at the 6 phone sizes with the system text scale at 1.3:
/// no overflow, and every tappable node has a label.
void main() {
  setUpAll(loadBunoFonts);
  setUp(() => useFakeBattery(level: 80));
  setUp(useReducedMotion);
  setUp(useFakeScanCamera);

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
    AppRoutes.guarantee, AppRoutes.emergency,
  ];

  for (final route in routes) {
    for (final size in sizes) {
      testWidgets('$route at text scale 1.3, ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        final semantics = tester.ensureSemantics();
        tester.view.physicalSize = size * 3;
        tester.view.devicePixelRatio = 3;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(BunoApp(initialRoute: route));
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);

        final unlabelled = <String>[];
        void visit(SemanticsNode n) {
          final d = n.getSemanticsData();
          if (!n.isMergedIntoParent && d.hasAction(SemanticsAction.tap) && d.label.trim().isEmpty && d.value.isEmpty) {
            unlabelled.add(n.toStringDeep());
          }
          n.visitChildren((c) {
            visit(c);
            return true;
          });
        }

        visit(tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!);
        expect(unlabelled, isEmpty, reason: 'tappable without a label');

        // Let timers (splash, verifying, pending top-up) run out.
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(minutes: 1));
        semantics.dispose();
      });
    }
  }

  testWidgets('primary button and bay tile give light haptic feedback', (tester) async {
    final calls = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') calls.add(call.arguments);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.rtl,
      child: Column(children: [
        BunoPrimaryButton(label: 'خدتها', onPressed: () {}),
        BunoBayTile(number: 1, charge: 80, onTap: () {}),
        const BunoBayTile(number: 2, charge: null),
      ]),
    ));
    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.tap(find.byType(BunoBayTile).first);
    await tester.tap(find.byType(BunoBayTile).last);
    expect(calls, ['HapticFeedbackType.lightImpact', 'HapticFeedbackType.lightImpact']);
  });
}

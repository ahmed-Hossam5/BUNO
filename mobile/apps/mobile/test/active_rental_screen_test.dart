import 'package:buno/screens/rental/active_rental_screen.dart';
import 'package:buno/theme/buno_tokens.dart';
import 'package:buno/widgets/buno_buttons.dart';
import 'package:buno/widgets/buno_charge_bar.dart';
import 'package:buno/widgets/buno_logo.dart';
import 'package:buno/widgets/buno_status_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'home_screen_test.dart' show loadBunoFonts;

Future<void> _pumpAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(fontFamily: 'ReadexPro', scaffoldBackgroundColor: BunoDark.background),
    home: const ActiveRentalScreen(),
  ));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(loadBunoFonts);

  const sizes = [
    Size(390, 844),
    Size(375, 667),
    Size(360, 640),
    Size(320, 568),
    Size(430, 932),
    Size(412, 915),
  ];

  for (final size in sizes) {
    testWidgets('rental: no overflow and RTL at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      await _pumpAt(tester, size);
      expect(tester.takeException(), isNull);

      expect(Directionality.of(tester.element(find.byType(BunoPrimaryButton))),
          TextDirection.rtl);
      // Logo on the right, status pill on the left.
      expect(tester.getCenter(find.byType(BunoLogo)).dx, greaterThan(size.width / 2));
      expect(tester.getCenter(find.byType(BunoStatusPill)).dx, lessThan(size.width / 2));
      // The charge bar fills from the right in RTL.
      final bar = tester.getRect(find.byType(BunoChargeBar));
      final fill = tester.getRect(find.descendant(
          of: find.byType(BunoChargeBar), matching: find.byType(FractionallySizedBox)));
      expect(fill.right, moreOrLessEquals(bar.right, epsilon: 0.5));
    });
  }

  testWidgets('rental: timer readout and actions', (tester) async {
    await _pumpAt(tester, const Size(390, 844));
    expect(find.text('01:12'), findsOneWidget);

    // رجّعه and فيه مشكلة؟ open /return and /report (return_flow_test.dart).
    expect(tester.widget<BunoPrimaryButton>(find.byType(BunoPrimaryButton)).label, 'رجّعه');
    expect(find.text('فيه مشكلة؟'), findsOneWidget);

    await tester.tap(find.text('تفاصيل الحساب'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SnackBar), findsOneWidget);
    expect(tester.takeException(), isNull);

    // The timer advances once a minute.
    await tester.pump(const Duration(minutes: 1));
    expect(find.text('01:13'), findsOneWidget);
  });
}

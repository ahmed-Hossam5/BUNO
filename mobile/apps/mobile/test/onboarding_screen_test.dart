import 'package:buno/screens/onboarding/onboarding_illustrations.dart';
import 'package:buno/screens/onboarding/onboarding_screen.dart';
import 'package:buno/theme/buno_tokens.dart';
import 'package:buno/widgets/buno_buttons.dart';
import 'package:buno/widgets/buno_logo.dart';
import 'package:buno/widgets/buno_page_dots.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'home_screen_test.dart' show loadBunoFonts;

Future<void> _pumpAt(WidgetTester tester, Size size, {VoidCallback? onFinished, VoidCallback? onHaveAccount}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(fontFamily: 'ReadexPro', scaffoldBackgroundColor: BunoDark.background),
    home: OnboardingScreen(onFinished: onFinished, onHaveAccount: onHaveAccount ?? () {}),
  ));
  await tester.pumpAndSettle();
}

/// x of the active (wide) page dot.
double _activeDotX(WidgetTester tester) {
  final dots = find.descendant(
      of: find.byType(BunoPageDots), matching: find.byType(AnimatedContainer));
  final rects = [for (final e in dots.evaluate()) tester.getRect(find.byWidget(e.widget))];
  rects.sort((a, b) => b.width.compareTo(a.width));
  return rects.first.center.dx;
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
    testWidgets('onboarding: no overflow on any page at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      await _pumpAt(tester, size, onFinished: () {});
      for (var page = 0; page < 3; page++) {
        expect(tester.takeException(), isNull, reason: 'page ${page + 1}');
        if (page < 2) {
          await tester.tap(find.byType(BunoPrimaryButton));
          await tester.pumpAndSettle();
        }
      }
    });
  }

  testWidgets('onboarding: RTL layout and page order', (tester) async {
    await _pumpAt(tester, const Size(390, 844), onFinished: () {});
    expect(Directionality.of(tester.element(find.byType(BunoPrimaryButton))), TextDirection.rtl);
    expect(tester.getCenter(find.byType(BunoLogo)).dx, greaterThan(195));
    expect(tester.getCenter(find.text('تخطي')).dx, lessThan(195));

    // Page 1: its dot is the rightmost (reading order in Arabic).
    final first = _activeDotX(tester);
    expect(first, greaterThan(195));
    expect(find.byType(NearbyStationsIllustration), findsOneWidget);

    // Swiping towards the right (finger moves left→right) goes forward in RTL.
    await tester.drag(find.byType(PageView), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(find.text('امسح الكود وخد بونو'), findsOneWidget);
    expect(_activeDotX(tester), lessThan(first));
  });

  testWidgets('onboarding: CTA walks the pages, last page finishes', (tester) async {
    var finished = 0, haveAccount = 0;
    await _pumpAt(tester, const Size(390, 844),
        onFinished: () => finished++, onHaveAccount: () => haveAccount++);

    expect(find.text('يلا'), findsOneWidget);
    await tester.tap(find.text('يلا'));
    await tester.pumpAndSettle();
    expect(find.byType(ScanIllustration), findsOneWidget);

    await tester.tap(find.text('يلا'));
    await tester.pumpAndSettle();
    expect(find.byType(ReturnIllustration), findsOneWidget);
    expect(find.text('ابدأ دلوقتي'), findsOneWidget);
    // "Skip" is hidden on the last page.
    expect(
      tester.widget<Visibility>(find.ancestor(of: find.text('تخطي'), matching: find.byType(Visibility))).visible,
      isFalse,
    );

    await tester.tap(find.text('ابدأ دلوقتي'));
    await tester.pump();
    expect(finished, 1);

    await tester.tap(find.text('عندي حساب'));
    await tester.pump();
    expect(haveAccount, 1);
  });

  testWidgets('onboarding: skip finishes immediately', (tester) async {
    var finished = 0;
    await _pumpAt(tester, const Size(390, 844), onFinished: () => finished++);
    await tester.tap(find.text('تخطي'));
    await tester.pump();
    expect(finished, 1);
  });
}

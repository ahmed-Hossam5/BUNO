import 'package:buno/app_routes.dart';
import 'package:buno/data/mock_settings.dart';
import 'package:buno/data/mock_wrapped.dart';
import 'package:buno/l10n/buno_locale.dart';
import 'package:buno/main.dart';
import 'package:buno/screens/home/home_screen.dart';
import 'package:buno/screens/wrapped/wrapped_banner.dart';
import 'package:buno/screens/wrapped/wrapped_screen.dart';
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

final _arabic = RegExp(r'[؀-ۿ]');

Future<void> _pumpApp(WidgetTester tester, String route, {Size size = const Size(390, 844), bool settle = true}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(BunoApp(initialRoute: route));
  if (settle) await tester.pumpAndSettle();
}

/// Taps the end side of the story (left in Arabic, right in English).
Future<void> _next(WidgetTester tester) async {
  final box = tester.getRect(find.byType(WrappedScreen));
  final rtl = Directionality.of(tester.element(find.byType(WrappedScreen))) == TextDirection.rtl;
  await tester.tapAt(Offset(rtl ? box.left + 30 : box.right - 30, box.center.dy));
  await tester.pumpAndSettle();
}

Future<void> _back(WidgetTester tester) async {
  final box = tester.getRect(find.byType(WrappedScreen));
  await tester.tapAt(Offset(box.right - 30, box.center.dy));
  await tester.pumpAndSettle();
}

int _page(WidgetTester tester) => tester.widget<PageView>(find.byType(PageView)).controller!.page!.round();

void main() {
  setUpAll(loadBunoFonts);
  setUp(useFakeScanCamera);
  setUp(() => useFakeBattery(level: 80));
  setUp(MockSettings.reset);
  setUp(MockWrapped.reset);

  group('reduced motion', () {
    setUp(useReducedMotion);

    group('no overflow, RTL, every page', () {
      for (final size in _sizes) {
        testWidgets('/wrapped at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
          await _pumpApp(tester, AppRoutes.wrapped, size: size);
          for (var page = 0; page < WrappedScreen.pageCount; page++) {
            expect(_page(tester), page);
            expect(tester.takeException(), isNull);
            expect(Directionality.of(tester.element(find.byType(WrappedScreen))), TextDirection.rtl);
            expect(find.byType(BunoPrimaryButton).evaluate().length, lessThanOrEqualTo(1));
            if (page < WrappedScreen.pageCount - 1) await _next(tester);
          }
        });
      }
    });

    testWidgets('mock month: 14 hours, 6 stations, favourite station', (tester) async {
      final m = MockWrapped.month;
      expect(m.hoursCharged, 14);
      expect(m.dailyMinutes, hasLength(30));
      await _pumpApp(tester, AppRoutes.wrapped);
      expect(find.text('شحنت وانت ماشي'), findsOneWidget);
      expect(find.textContaining('14', findRichText: true), findsOneWidget);
      await _next(tester);
      expect(find.textContaining('6', findRichText: true), findsWidgets);
      expect(find.text(m.favoriteStation.name), findsOneWidget);
      expect(find.textContaining('عمرك ما وصلت', findRichText: true), findsOneWidget);
    });

    testWidgets('start side goes back, no page past the last', (tester) async {
      await _pumpApp(tester, AppRoutes.wrapped);
      await _back(tester);
      expect(_page(tester), 0);
      await _next(tester);
      await _next(tester);
      expect(_page(tester), 2);
      await _next(tester);
      expect(_page(tester), 2);
      await _back(tester);
      expect(_page(tester), 1);
    });

    testWidgets('swipe advances', (tester) async {
      await _pumpApp(tester, AppRoutes.wrapped);
      // Arabic: the next page comes in from the left.
      await tester.fling(find.byType(PageView), const Offset(300, 0), 1000);
      await tester.pumpAndSettle();
      expect(_page(tester), 1);
    });

    testWidgets('no auto-advance under reduced motion', (tester) async {
      await _pumpApp(tester, AppRoutes.wrapped);
      await tester.pump(WrappedScreen.storyDuration * 2);
      expect(_page(tester), 0);
    });

    testWidgets('share and save show a snackbar', (tester) async {
      await _pumpApp(tester, AppRoutes.wrapped);
      await _next(tester);
      await _next(tester);
      expect(find.byType(ShareCard), findsOneWidget);
      await tester.tap(find.text('شير على الستوري'));
      await tester.pump();
      expect(find.text('الكارت جاهز للستوري'), findsOneWidget);
      expect(_page(tester), 2);
      await tester.tap(find.text('حفظ'));
      await tester.pump();
      expect(find.text('اتحفظ في الصور'), findsOneWidget);
    });

    testWidgets('English: every page left-to-right, no Arabic', (tester) async {
      BunoLocale.current.value = BunoLocale.english;
      addTearDown(BunoLocale.reset);
      await _pumpApp(tester, AppRoutes.wrapped, size: const Size(320, 568));
      for (var page = 0; page < WrappedScreen.pageCount; page++) {
        expect(tester.takeException(), isNull);
        expect(Directionality.of(tester.element(find.byType(WrappedScreen))), TextDirection.ltr);
        final arabic = [
          for (final e in find.byType(RichText).evaluate())
            if (_arabic.hasMatch((e.widget as RichText).text.toPlainText())) (e.widget as RichText).text.toPlainText(),
        ];
        expect(arabic, isEmpty, reason: 'page ${page + 1}');
        if (page < WrappedScreen.pageCount - 1) await _next(tester);
      }
      expect(find.text('Share to story'), findsOneWidget);
    });

    group('home banner', () {
      testWidgets('hidden mid-month', (tester) async {
        MockWrapped.clock = () => DateTime(2026, 11, 10);
        await _pumpApp(tester, AppRoutes.home);
        expect(find.byType(WrappedBanner), findsNothing);
      });

      for (final size in _sizes) {
        testWidgets('on the 1st, opens /wrapped at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
          MockWrapped.clock = () => DateTime(2026, 11, 1);
          await _pumpApp(tester, AppRoutes.home, size: size);
          expect(tester.takeException(), isNull);
          expect(find.byType(WrappedBanner), findsOneWidget);
          await tester.tap(find.text('شهرك مع بونو جاهز'));
          await tester.pumpAndSettle();
          expect(find.byType(WrappedScreen), findsOneWidget);
          await tester.tap(find.bySemanticsLabel('اقفل'));
          await tester.pumpAndSettle();
          expect(find.byType(HomeScreen), findsOneWidget);
        });
      }

      testWidgets('the cross hides it', (tester) async {
        MockWrapped.clock = () => DateTime(2026, 11, 2);
        await _pumpApp(tester, AppRoutes.home);
        await tester.tap(find.bySemanticsLabel('اخفي'));
        await tester.pumpAndSettle();
        expect(find.byType(WrappedBanner), findsNothing);
        expect(find.byType(WrappedScreen), findsNothing);
      });

      testWidgets('settings debug toggle shows it now', (tester) async {
        MockWrapped.clock = () => DateTime(2026, 11, 20);
        await _pumpApp(tester, AppRoutes.settings);
        final toggle = find.text('تجربة: ملخص الشهر');
        await tester.ensureVisible(toggle);
        await tester.pumpAndSettle();
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(MockSettings.wrappedNow.value, isTrue);
        await tester.pumpWidget(const SizedBox());
        await _pumpApp(tester, AppRoutes.home);
        expect(find.byType(WrappedBanner), findsOneWidget);
      });
    });
  });

  testWidgets('pages advance on their own, bars fill', (tester) async {
    await _pumpApp(tester, AppRoutes.wrapped, settle: false);
    await tester.pump(const Duration(seconds: 1));
    expect(_page(tester), 0);
    await tester.pump(WrappedScreen.storyDuration);
    await tester.pump(const Duration(seconds: 1));
    expect(_page(tester), 1);
    // The last page stays.
    for (var i = 0; i < 4; i++) {
      await tester.pump(WrappedScreen.storyDuration);
    }
    expect(_page(tester), 2);
    await tester.pumpWidget(const SizedBox());
  });
}

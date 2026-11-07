import 'package:buno/data/mock_rental.dart';
import 'package:buno/data/phone_battery.dart';
import 'package:buno/screens/home/home_map.dart';
import 'package:buno/screens/home/home_screen.dart';
import 'package:buno/screens/home/home_sheet.dart';
import 'package:buno/screens/home/mock_map.dart';
import 'package:buno/screens/rental/return_screen.dart';
import 'package:buno/screens/reserve/reserve_screen.dart';
import 'package:buno/screens/stations/all_stations_screen.dart';
import 'package:buno/theme/buno_tokens.dart';
import 'package:buno/widgets/buno_charge_ring.dart';
import 'package:buno/main.dart';
import 'package:buno/screens/scan/scan_screen.dart';
import 'package:buno/screens/wallet/wallet_screen.dart';
import 'package:buno/widgets/buno_bottom_nav.dart';
import 'package:buno/widgets/buno_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart' show FlutterMap;
import 'package:flutter_test/flutter_test.dart';

import 'fake_battery.dart';
import 'fake_scan_camera.dart';
import 'reduced_motion.dart';

Future<void> loadBunoFonts() async {
  final families = {
    'Sora': ['Sora-Regular', 'Sora-SemiBold', 'Sora-Bold'],
    'ReadexPro': [
      'ReadexPro-Regular',
      'ReadexPro-Medium',
      'ReadexPro-SemiBold',
      'ReadexPro-Bold',
    ],
  };
  for (final e in families.entries) {
    final loader = FontLoader(e.key);
    for (final f in e.value) {
      loader.addFont(rootBundle.load('assets/fonts/$f.ttf'));
    }
    await loader.load();
  }
}

Future<void> _pumpAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const BunoApp());
  await tester.pumpAndSettle();
}

/// Sets up the battery (and, for [HomeMode.buno], a running rental picked
/// up at 31% and now charging at 47%) before home is pumped.
Future<void> _enter(WidgetTester tester, HomeMode mode) async {
  useFakeBattery(level: mode == HomeMode.low ? 12 : 80);
  if (mode != HomeMode.buno) return;
  PhoneBattery.debugOverride.value = BatteryDebug.percent31;
  final unlocking = rentalSession.unlock(
    mockStations.first,
    mockStations.first.bestBayIndex!,
  );
  await tester.pump(rentalSession.unlockDelay);
  await unlocking;
  rentalSession.confirmPickup();
  PhoneBattery.debugOverride.value = BatteryDebug.charging;
}

/// Puts the unit back so later tests start idle with the same bays.
Future<void> _leaveRental(WidgetTester tester) async {
  PhoneBattery.debugOverride.value = BatteryDebug.real;
  if (rentalSession.state != RentalState.active) return;
  await tester.pumpWidget(const SizedBox());
  final st = rentalSession.station!, bay = rentalSession.bayIndex!;
  rentalSession
    ..returnTo(st, bay)
    ..finish()
    ..reset();
}

/// The phone-battery ring around the user's dot.
Color _ringColor(WidgetTester tester) => tester
    .widget<BunoChargeRing>(
      find.descendant(of: find.byType(HomeUserRing), matching: find.byType(BunoChargeRing)),
    )
    .color;

void main() {
  setUpAll(loadBunoFonts);
  setUp(useFakeBattery);
  setUp(useReducedMotion);
  setUp(useFakeScanCamera);
  setUp(() => HomeScreen.ringHintSeen.value = false);

  // Reference frame first, then small/large phones.
  const sizes = [
    Size(390, 844), // iPhone 12-15 (the Brand Board frame)
    Size(375, 667), // iPhone SE
    Size(360, 640), // small Android
    Size(320, 568), // smallest supported width
    Size(430, 932), // iPhone Pro Max
    Size(412, 915), // Pixel
  ];

  for (final mode in HomeMode.values) {
    for (final size in sizes) {
      testWidgets(
        '${mode.name}: no overflow and RTL at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await _enter(tester, mode);
          await _pumpAt(tester, size);
          expect(tester.takeException(), isNull);

          final ctx = tester.element(find.byType(BunoPrimaryButton));
          expect(Directionality.of(ctx), TextDirection.rtl);

          // RTL mirrors the header: search on the right, profile on the left.
          final logo = tester.getCenter(find.bySemanticsLabel('دوّر على محطة أو مكان'));
          final profile = tester.getCenter(
            find.bySemanticsLabel('حسابي').first,
          );
          expect(logo.dx, greaterThan(size.width / 2));
          expect(profile.dx, lessThan(size.width / 2));

          // First nav item (home) sits on the right.
          final home = tester.getCenter(find.text('الرئيسية'));
          final account = tester.getCenter(find.text('حسابي').last);
          expect(home.dx, greaterThan(account.dx));
          expect(find.byType(BunoPrimaryButton), findsOneWidget);
          await _leaveRental(tester);
        },
      );
    }
  }

  testWidgets('mock map without tiles; ring on the user, nearest pin and walk chip', (
    tester,
  ) async {
    useFakeBattery(level: 80);
    await _pumpAt(tester, const Size(390, 844));
    // Tests have no network: the drawn map stands in for the tiles.
    expect(find.byType(MockMap), findsOneWidget);
    expect(find.byType(FlutterMap), findsNothing);
    expect(find.bySemanticsLabel(RegExp('أقرب محطة، التحرير، أعلى شحن 92%')), findsOneWidget);
    expect(find.bySemanticsLabel('4 دقايق مشي'), findsOneWidget);
    // The ring sits above the sheet, the nearest pin above the ring.
    final ring = tester.getRect(find.byType(HomeUserRing));
    final sheet = tester.getRect(find.byType(HomeSheet));
    expect(ring.bottom, lessThan(sheet.top));
    expect(
      tester.getCenter(find.bySemanticsLabel(RegExp('أقرب محطة، التحرير'))).dy,
      lessThan(ring.top),
    );
  });

  testWidgets('chips: "كل المحطات" opens /stations/all', (tester) async {
    useFakeBattery(level: 80);
    await _pumpAt(tester, const Size(390, 844));
    expect(find.text('محطة التحرير', findRichText: true), findsOneWidget);
    expect(find.text('المفضلة'), findsOneWidget);
    expect(find.text('فيها مكان للإرجاع'), findsOneWidget);
    expect(find.text('اطلب من صاحبك'), findsNothing);
    await tester.tap(find.text('كل المحطات'));
    await tester.pumpAndSettle();
    expect(find.byType(AllStationsScreen), findsOneWidget);
  });

  testWidgets('ring hint shows once and goes on tap', (tester) async {
    useFakeBattery(level: 80);
    await _pumpAt(tester, const Size(390, 844));
    const hint = 'الحلقة حواليك = بطارية موبايلك';
    expect(find.text(hint), findsOneWidget);
    await tester.tap(find.text(hint));
    await tester.pumpAndSettle();
    expect(find.text(hint), findsNothing);
    expect(HomeScreen.ringHintSeen.value, isTrue);
  });

  testWidgets('dragging the sheet up shows the other stations', (tester) async {
    useFakeBattery(level: 80);
    await _pumpAt(tester, const Size(390, 844));
    final before = tester.getRect(find.byType(HomeSheet)).top;
    await tester.drag(find.text('أقرب محطة'), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(HomeSheet)).top, lessThan(before - 100));
    expect(find.text('محطة الزمالك', findRichText: true), findsOneWidget);
  });

  testWidgets('20% or more: calm ring, nearest station, scan', (tester) async {
    useFakeBattery(level: 80);
    await _pumpAt(tester, const Size(390, 844));
    expect(find.bySemanticsLabel(RegExp('بطارية موبايلك 80%')), findsOneWidget);
    expect(find.descendant(of: find.byType(HomeUserRing), matching: find.text('80%')), findsOneWidget);
    expect(find.text('امسح وخد بونو'), findsOneWidget);
    expect(_ringColor(tester), BunoColors.success);
  });

  testWidgets('below 20%: red ring, warning pill, ask a friend, reserve', (
    tester,
  ) async {
    useFakeBattery(level: 12);
    await _pumpAt(tester, const Size(390, 844));
    expect(_ringColor(tester), BunoColors.error);
    expect(find.textContaining('موبايلك هيفصل قريب', findRichText: true), findsOneWidget);
    expect(find.text('الحلقة حواليك = بطارية موبايلك'), findsNothing);
    expect(find.text('اطلب من صاحبك'), findsOneWidget);
    expect(find.text('فيها مكان للإرجاع'), findsNothing);
    await tester.tap(find.text('احجزلي وودّيني'));
    await tester.pumpAndSettle();
    expect(find.byType(ReserveScreen), findsOneWidget);
  });

  testWidgets('charging from Buno: bolt in the dot, gain pill, rental card', (
    tester,
  ) async {
    await _enter(tester, HomeMode.buno);
    await _pumpAt(tester, const Size(390, 844));
    expect(_ringColor(tester), BunoColors.primary);
    expect(tester.widget<HomeUserRing>(find.byType(HomeUserRing)).bolt, isTrue);
    expect(find.textContaining('بيشحن من بونو', findRichText: true), findsOneWidget);
    expect(find.textContaining('+16%', findRichText: true), findsOneWidget);
    expect(find.textContaining('موبايلك هيفصل قريب', findRichText: true), findsNothing);
    expect(find.text('[السعر]'), findsOneWidget);
    expect(find.text('تفاصيل'), findsOneWidget);
    await tester.tap(find.text('رجّعه'));
    await tester.pumpAndSettle();
    expect(find.byType(ReturnScreen), findsOneWidget);
    await _leaveRental(tester);
  });

  testWidgets('interactions: CTA, bottom nav', (tester) async {
    // Charged phone: the main button scans (below 20% it reserves).
    useFakeBattery(level: 80);
    await _pumpAt(tester, const Size(390, 844));

    // The scan CTA opens /scan.
    await tester.tap(find.byType(BunoPrimaryButton));
    await tester.pumpAndSettle();
    expect(find.byType(ScanScreen), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('قفل'));
    await tester.pumpAndSettle();

    BunoBottomNav nav() => tester.widget(find.byType(BunoBottomNav));
    expect(nav().currentIndex, 0);
    // The nav now switches screens: Wallet opens with its tab selected.
    await tester.tap(find.text('المحفظة'));
    await tester.pumpAndSettle();
    expect(find.byType(WalletScreen), findsOneWidget);
    expect(nav().currentIndex, 2);
    expect(tester.takeException(), isNull);
  });
}

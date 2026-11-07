import 'package:battery_plus/battery_plus.dart';
import 'package:buno/data/phone_battery.dart';
import 'package:buno/screens/home/home_top_bar.dart';
import 'package:buno/theme/buno_tokens.dart';
import 'package:buno/widgets/buno_icon.dart';
import 'package:buno/widgets/buno_lottie_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_battery.dart';
import 'home_screen_test.dart' show loadBunoFonts;
import 'reduced_motion.dart';

Future<void> _pumpBar(WidgetTester tester, PhoneBattery battery) async {
  await tester.pumpWidget(MaterialApp(
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: ListenableBuilder(
          listenable: battery,
          builder: (_, _) => HomeTopBar(battery: battery.reading),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

Text _pct(WidgetTester tester) =>
    tester.widget<Text>(find.textContaining('%'));

BunoIcons _icon(WidgetTester tester) => tester
    .widgetList<BunoIcon>(find.byType(BunoIcon))
    .map((i) => i.icon)
    .firstWhere((i) => i.fileName.startsWith('battery') || i == BunoIcons.charging);

/// Low battery shows the looping battery_low animation instead of a BunoIcon.
void _expectLowIcon(WidgetTester tester) {
  final icon = tester.widget<BunoLottieIcon>(find.byType(BunoLottieIcon));
  expect(icon.name, 'battery_low');
  expect(icon.loop, isTrue);
  expect(icon.color, BunoColors.warning);
}

void main() {
  setUpAll(loadBunoFonts);
  setUp(useReducedMotion);

  testWidgets('shows the real level: low battery in warning colour', (tester) async {
    final battery = PhoneBattery(reader: FakeBatteryReader(levelValue: 18));
    await _pumpBar(tester, battery);
    expect(find.text('18%'), findsOneWidget);
    expect(_pct(tester).style!.color, BunoColors.warning);
    _expectLowIcon(tester);
  });

  testWidgets('mid and full levels use mint and the matching icon', (tester) async {
    final reader = FakeBatteryReader(levelValue: 57);
    final battery = PhoneBattery(reader: reader);
    await _pumpBar(tester, battery);
    expect(find.text('57%'), findsOneWidget);
    expect(_pct(tester).style!.color, BunoColors.secondary);
    expect(_icon(tester), BunoIcons.battery);

    reader.levelValue = 92;
    await battery.refresh();
    await tester.pump();
    expect(find.text('92%'), findsOneWidget);
    expect(_icon(tester), BunoIcons.batteryFull);
  });

  testWidgets('plugging in updates immediately and shows the charging bolt', (tester) async {
    final reader = FakeBatteryReader(levelValue: 15);
    final battery = PhoneBattery(reader: reader);
    await _pumpBar(tester, battery);
    _expectLowIcon(tester);

    reader.levelValue = 16;
    reader.emit(BatteryState.charging);
    await tester.pumpAndSettle();
    expect(find.text('16%'), findsOneWidget);
    expect(_icon(tester), BunoIcons.charging);
    // Charging is not "low": mint, not warning.
    expect(_pct(tester).style!.color, BunoColors.secondary);
  });

  testWidgets('re-reads the level periodically', (tester) async {
    final reader = FakeBatteryReader(levelValue: 40);
    final battery = PhoneBattery(reader: reader, pollEvery: const Duration(seconds: 30));
    await _pumpBar(tester, battery);
    expect(find.text('40%'), findsOneWidget);

    reader.levelValue = 39;
    await tester.pump(const Duration(seconds: 31));
    await tester.pump();
    expect(find.text('39%'), findsOneWidget);
  });

  testWidgets('unreadable battery (simulator / unsupported browser) shows --%', (tester) async {
    final battery = PhoneBattery(reader: FakeBatteryReader(fail: true));
    await _pumpBar(tester, battery);
    expect(find.text('--%'), findsOneWidget);
    expect(_pct(tester).style!.color, BunoDark.text_secondary);
  });

  testWidgets('a -1 level is treated as unknown, not as a number', (tester) async {
    final battery = PhoneBattery(reader: FakeBatteryReader(levelValue: -1));
    await _pumpBar(tester, battery);
    expect(find.text('--%'), findsOneWidget);
  });

  testWidgets('stops listening when nothing shows the battery', (tester) async {
    final reader = FakeBatteryReader(levelValue: 50);
    final battery = PhoneBattery(reader: reader, pollEvery: const Duration(seconds: 30));
    await _pumpBar(tester, battery);
    await tester.pumpWidget(const SizedBox());
    final reads = reader.reads;
    await tester.pump(const Duration(minutes: 2));
    expect(reader.reads, reads);
  });
}

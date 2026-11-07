import 'package:buno/app_routes.dart';
import 'package:buno/data/mock_ops.dart';
import 'package:buno/data/mock_rental.dart';
import 'package:buno/data/mock_settings.dart';
import 'package:buno/main.dart';
import 'package:buno/screens/ops/ops_home_screen.dart';
import 'package:buno/screens/ops/ops_rebalance_screen.dart';
import 'package:buno/screens/ops/ops_scaffold.dart';
import 'package:buno/screens/ops/ops_station_screen.dart';
import 'package:buno/screens/ops/ops_tasks_screen.dart';
import 'package:buno/widgets/buno_buttons.dart';
import 'package:buno/widgets/buno_step_row.dart';
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

Future<void> _pumpApp(WidgetTester tester, String route, {Size size = const Size(390, 844)}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(BunoApp(initialRoute: route));
  await tester.pumpAndSettle();
}

/// Rebalancing moves units between [mockStations]; put them back after
/// each test.
void _restoreStations() {
  final saved = [for (final s in mockStations) (List.of(s.bays), List.of(s.units))];
  addTearDown(() {
    for (var i = 0; i < mockStations.length; i++) {
      mockStations[i].bays.setAll(0, saved[i].$1);
      mockStations[i].units.setAll(0, saved[i].$2);
    }
  });
}

Station _station(String id, List<int?> bays, {int walk = 1}) =>
    Station(id: id, code: 'BUN-99', name: id, walkMinutes: walk, bays: bays);

Future<void> _scrollTo(WidgetTester tester, Finder f) =>
    tester.scrollUntilVisible(f, 100, scrollable: find.byType(Scrollable).first);

void main() {
  setUpAll(loadBunoFonts);
  setUp(useFakeScanCamera);
  setUp(() => useFakeBattery(level: 80));
  setUp(MockSettings.reset);
  setUp(MockOps.reset);
  setUp(useReducedMotion);
  setUp(_restoreStations);

  group('no overflow, RTL', () {
    const routes = [AppRoutes.ops, AppRoutes.opsTasks, AppRoutes.opsStation, AppRoutes.opsRebalance];
    for (final route in routes) {
      for (final size in _sizes) {
        testWidgets('$route at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
          await _pumpApp(tester, route, size: size);
          expect(tester.takeException(), isNull);
          expect(Directionality.of(tester.element(find.byType(OpsPill).first)), TextDirection.rtl);
          expect(find.text('تشغيل'), findsOneWidget);
          expect(find.byType(BunoPrimaryButton).evaluate().length, lessThanOrEqualTo(1));
        });
      }
    }
  });

  group('tasks from the mock state', () {
    test('every type, most urgent first', () {
      final tasks = opsTasks();
      expect(tasks.map((t) => t.type), [
        OpsTaskType.safety,
        OpsTaskType.transfer,
        OpsTaskType.transfer,
        OpsTaskType.wallet,
        OpsTaskType.maintenance,
        OpsTaskType.late,
        OpsTaskType.maintenance,
      ]);
      for (var i = 1; i < tasks.length; i++) {
        expect(tasks[i - 1].urgency, greaterThanOrEqualTo(tasks[i].urgency));
      }
    });

    test('hot unit: bay 3 of the first station, locked by the station', () {
      final hot = opsTasks().first;
      expect(hot.id, 'hot:PB-0405');
      expect(hot.title, 'افحص خانة 3 في ${mockStations[0].name}');
      expect(hot.meta, 'من دقيقتين');
      expect(MockOps.isLocked(mockStations[0], 2), isTrue);
      expect(MockOps.isLocked(mockStations[0], 0), isFalse);
    });

    test('top-ups are grouped by method', () {
      final wallet = opsTasks().where((t) => t.type == OpsTaskType.wallet).toList();
      expect(wallet, hasLength(1));
      expect(wallet.single.title, 'راجع 2 تحويل فودافون كاش');
      expect(wallet.single.detail, 'أقدم واحد من 12 دقيقة.');
    });

    test('health below 70% is a task, offline stations are skipped', () {
      final ids = opsTasks().map((t) => t.id);
      expect(ids, containsAll(['health:PB-0388', 'health:PB-0507']));
      expect(ids, isNot(contains('health:PB-0615'))); // 74%, and offline
      expect(MockOps.statusOf(mockStations[3]), OpsStationStatus.offline);
    });

    test('an empty station gets half the gap from the richest one', () {
      final rich = _station('rich', [90, 80, 70, 60, 50, 40, null, null]);
      final empty = _station('empty', [10, null, null, null, null, null, null, null], walk: 7);
      final tasks = opsTasks(stations: [rich, empty], late: const [], topups: const []);
      expect(tasks.single.id, 'move:rich>empty');
      expect(tasks.single.title, 'انقل 3 وحدات لـempty');
      expect(tasks.single.detail, contains('خانات 1 و2 و3'));
      expect(tasks.single.meta, '~ 6 دقايق مشي');
    });

    test('a full station sends units to the one with most room', () {
      final full = _station('full', [90, 80, 70, 60, 50, 40, 30, 25]);
      final room = _station('room', [60, 50, 40, null, null, null, null, null]);
      final tasks = opsTasks(stations: [full, room], late: const [], topups: const []);
      expect(tasks.single.id, 'move:full>room');
      expect(MockOps.statusOf(full), OpsStationStatus.full);
    });

    test('done tasks drop out', () {
      final first = opsTasks().first;
      MockOps.markDone(first.id);
      expect(opsTasks().map((t) => t.id), isNot(contains(first.id)));
    });
  });

  testWidgets('/ops: three numbers, hot banner, stations with status', (tester) async {
    await _pumpApp(tester, AppRoutes.ops);
    expect(find.text('وحدات برّه'), findsOneWidget);
    expect(find.text('متأخر'), findsOneWidget);
    expect(find.textContaining('اتقفلت'), findsOneWidget);
    for (final (s, status) in [
      (mockStations[0], 'تمام'),
      (mockStations[1], 'فاضية'),
      (mockStations[2], 'فاضية'),
      (mockStations[3], 'مش متصلة'),
    ]) {
      await _scrollTo(tester, find.text(s.name));
      expect(MockOps.statusOf(s).label, status);
    }
  });

  testWidgets('the hot banner opens the station on the locked bay', (tester) async {
    await _pumpApp(tester, AppRoutes.ops);
    await tester.tap(find.text('شوف'));
    await tester.pumpAndSettle();
    expect(find.byType(OpsStationScreen), findsOneWidget);
  });

  testWidgets('/ops/tasks: a chip per type with tasks', (tester) async {
    await _pumpApp(tester, AppRoutes.opsTasks);
    expect(find.textContaining(RegExp('7\\W* مفتوحة')), findsOneWidget);
    expect(find.textContaining('متأخر'), findsWidgets);

    await tester.tap(find.textContaining('محفظة').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('راجع'), findsOneWidget);
    expect(find.textContaining('افحص'), findsNothing);

    await tester.tap(find.textContaining('صيانة').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('صحتها'), findsNWidgets(2));
    expect(find.textContaining('راجع'), findsNothing);
  });

  testWidgets('approving the top-ups removes the task and its chip', (tester) async {
    await _pumpApp(tester, AppRoutes.opsTasks);
    await tester.tap(find.textContaining('محفظة').first);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('راجع'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('وصلت، ضيف الرصيد'));
    await tester.pumpAndSettle();
    expect(find.textContaining('راجع'), findsNothing);
    expect(find.textContaining('محفظة'), findsNothing);
    expect(find.textContaining(RegExp('6\\W* مفتوحة')), findsOneWidget);
  });

  testWidgets('/ops/station: 8 bays; open and lock the selected bay', (tester) async {
    await _pumpApp(tester, AppRoutes.opsStation);
    final s = mockStations.first;
    expect(find.textContaining('PB-0'), findsNWidgets(6));
    expect(find.text('فاضية'), findsNWidgets(2));
    expect(find.text('متصلة'), findsOneWidget);
    expect(MockOps.isLocked(s, 2), isTrue);

    // The hot bay starts selected.
    await tester.tap(find.text('افتح خانة'));
    await tester.pumpAndSettle();
    expect(MockOps.isLocked(s, 2), isFalse);

    await tester.tap(find.textContaining('PB-0417'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('اقفل خانة'));
    await tester.pumpAndSettle();
    expect(MockOps.isLocked(s, 0), isTrue);
  });

  testWidgets('/ops/station "نقل" plans a run from that station', (tester) async {
    await _pumpApp(tester, AppRoutes.opsStation);
    await tester.tap(find.text('نقل'));
    await tester.pumpAndSettle();
    expect(find.byType(OpsRebalanceScreen), findsOneWidget);
    expect(MockOps.rebalance.from, mockStations.first);
    expect(MockOps.rebalance.to, mockStations[2]);
  });

  testWidgets('/ops/rebalance: units travel with the operator until dropped', (tester) async {
    await _pumpApp(tester, AppRoutes.opsRebalance);
    final run = MockOps.rebalance;
    final from = run.from;
    final to = run.to;
    expect((from, to), (mockStations[0], mockStations[2]));
    expect(run.bays, [0, 1]);
    expect(find.byType(BunoStepRow), findsNWidgets(4));
    expect(find.textContaining('نقل'), findsWidgets);

    await tester.tap(find.text('افتح الخانات'));
    await tester.pumpAndSettle();
    expect(run.step, RebalanceStep.verify);

    await tester.tap(find.text('خدت الوحدات'));
    await tester.pumpAndSettle();
    expect(run.step, RebalanceStep.walk);
    expect(run.carried.map((c) => c.unit.id), ['PB-0417', 'PB-0398']);
    expect(from.units[0], isNull);
    expect(to.units.whereType<UnitTag>(), isEmpty);
    expect(find.textContaining('اتقرت'), findsOneWidget);

    await tester.tap(find.text('وصلت ${to.name}'));
    await tester.pumpAndSettle();
    expect(run.step, RebalanceStep.drop);

    await tester.tap(find.text('حطّيتهم'));
    await tester.pumpAndSettle();
    expect(run.carried, isEmpty);
    expect(to.units.whereType<UnitTag>().map((u) => u.id), ['PB-0417', 'PB-0398']);
    expect(to.bays.take(2), [92, 88]);
    expect(run.started, isFalse);
    expect(MockOps.isDone('move:st-01>st-03'), isTrue);
  });

  testWidgets('a transfer task plans its own run', (tester) async {
    await _pumpApp(tester, AppRoutes.ops);
    final task = opsTasks().firstWhere((t) => t.type == OpsTaskType.transfer);
    openOpsTask(tester.element(find.byType(OpsHomeScreen)), task);
    await tester.pumpAndSettle();
    expect(find.byType(OpsRebalanceScreen), findsOneWidget);
    expect(MockOps.rebalance.from, task.station);
    expect(MockOps.rebalance.to, task.target);
  });

  testWidgets('bottom nav: tasks tab, then today; unbuilt tabs say soon', (tester) async {
    await _pumpApp(tester, AppRoutes.ops);
    await tester.tap(find.text('المهام'));
    await tester.pumpAndSettle();
    expect(find.byType(OpsTasksScreen), findsOneWidget);
    await tester.tap(find.text('البلاغات'));
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
    await tester.tap(find.text('اليوم'));
    await tester.pumpAndSettle();
    expect(find.byType(OpsHomeScreen), findsOneWidget);
  });

  testWidgets('settings debug row enters ops mode; the pill leaves it', (tester) async {
    await _pumpApp(tester, AppRoutes.settings);
    await _scrollTo(tester, find.text('دخول كفريق التشغيل'));
    await tester.tap(find.text('دخول كفريق التشغيل'));
    await tester.pumpAndSettle();
    expect(find.byType(OpsHomeScreen), findsOneWidget);

    await tester.tap(find.text('تشغيل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('اخرج'));
    await tester.pumpAndSettle();
    expect(find.byType(OpsHomeScreen), findsNothing);
    expect(find.byType(OpsPill), findsNothing);
  });
}

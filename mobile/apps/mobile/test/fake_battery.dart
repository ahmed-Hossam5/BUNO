import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:buno/data/phone_battery.dart';

/// Test double for the phone battery: set [levelValue]/[stateValue] and
/// call [emit] to simulate a plug/unplug event.
class FakeBatteryReader implements BatteryReader {
  FakeBatteryReader({this.levelValue = 18, this.stateValue = BatteryState.discharging, this.fail = false});

  int levelValue;
  BatteryState stateValue;
  bool fail;
  int reads = 0;
  final _events = StreamController<BatteryState>.broadcast();

  @override
  Future<int> level() async {
    reads++;
    if (fail) throw Exception('UNAVAILABLE');
    return levelValue;
  }

  @override
  Future<BatteryState> state() async => stateValue;

  @override
  Stream<BatteryState> get stateChanges => _events.stream;

  void emit(BatteryState s) {
    stateValue = s;
    _events.add(s);
  }
}

/// Installs a fake as the app-wide battery and returns it.
FakeBatteryReader useFakeBattery({int level = 18, BatteryState state = BatteryState.discharging, bool fail = false}) {
  final reader = FakeBatteryReader(levelValue: level, stateValue: state, fail: fail);
  PhoneBattery.shared = PhoneBattery(reader: reader);
  return reader;
}

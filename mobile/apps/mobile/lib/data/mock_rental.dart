import 'package:flutter/foundation.dart';

import 'mock_map_places.dart';
import 'mock_station_info.dart';
import 'phone_battery.dart';
import 'user_location.dart';
import '../l10n/buno_locale.dart';

/// Lowest charge (percent) a unit needs to be rented out.
const minReadyCharge = 20;

/// What a power bank's RFID tag reports: its id (printed on the unit, e.g.
/// `PB-0417`) and temperature in °C.
class UnitTag {
  const UnitTag(this.id, this.temperature);

  final String id;
  final int temperature;
}

/// A Buno station. Each bay holds a power bank's charge in percent, or null
/// when the bay is empty. Bays change as units are picked up and returned.
class Station {
  /// Without [units], every full bay gets a generated tag.
  Station({
    required this.id,
    required this.code,
    required this._name,
    this._nameEn,
    required this._walkMinutes,
    required List<int?> bays,
    List<UnitTag?>? units,
  })  : bays = List.of(bays, growable: false),
        units = List.of(units ?? [for (final b in bays) b == null ? null : _generatedTag()], growable: false) {
    assert(this.units.length == this.bays.length, 'One tag slot per bay');
  }

  static var _nextTag = 900;
  static UnitTag _generatedTag() => UnitTag('PB-${(_nextTag++).toString().padLeft(4, '0')}', 30);

  final String id;

  /// Printed on the station and in its QR, e.g. `BUN-01`.
  final String code;
  final String _name;
  final String? _nameEn;

  /// In the app language; [_name] alone when there is no English name.
  String get name => _nameEn == null ? _name : tr(_name, _nameEn);
  /// Used when the station has no map position ([placeOf]).
  final int _walkMinutes;

  /// Straight-line walk from the user's location to the station, in
  /// minutes ([walkMinutesBetween]).
  int get walkMinutes {
    final place = placeOf(this);
    return place == null ? _walkMinutes : walkMinutesBetween(UserLocation.shared.center, place);
  }

  /// Straight-line metres from the user's location; null when the station
  /// has no map position ([placeOf]).
  double? get metersAway {
    final place = placeOf(this);
    return place == null ? null : distanceMeters(UserLocation.shared.center, place);
  }

  final List<int?> bays;

  /// Tag of the unit in each bay, parallel to [bays]; null when empty.
  final List<UnitTag?> units;

  /// Whether bay [i] holds a unit charged enough to rent ([minReadyCharge]).
  bool isReady(int i) => (bays[i] ?? -1) >= minReadyCharge;

  /// Bays holding a unit ready to rent.
  int get readyCount => Iterable<int>.generate(bays.length).where(isReady).length;

  /// Bays a power bank can be returned to.
  int get emptyCount => bays.where((b) => b == null).length;

  /// First empty bay; null when the station is full.
  int? get firstEmptyBay {
    final i = bays.indexOf(null);
    return i < 0 ? null : i;
  }

  /// Charge of the best ready unit ([bestBayIndex]); null if none is ready.
  int? get bestCharge {
    final i = bestBayIndex;
    return i == null ? null : bays[i];
  }

  /// Charge shown for the station on /stations: the best ready unit, else
  /// the best low one (below [minReadyCharge]); null when every bay is empty.
  int? get topCharge {
    int? top;
    for (final c in bays) {
      if (c != null && (top == null || c > top)) top = c;
    }
    return top;
  }

  /// Ready bay holding the most-charged unit (first one on a tie); null if
  /// none is ready.
  int? get bestBayIndex {
    int? best;
    for (var i = 0; i < bays.length; i++) {
      if (isReady(i) && (best == null || bays[i]! > bays[best]!)) best = i;
    }
    return best;
  }
}

/// Stand-in station list until the real backend exists. One of each case on
/// /stations: best ready 92% (green), 41% (amber), only low units (red),
/// empty (grey).
final mockStations = [
  Station(id: 'st-01', code: 'BUN-01', name: 'محطة التحرير', nameEn: 'Tahrir Station', walkMinutes: 4, bays: [92, 88, 15, 71, null, 64, 9, null], units: [
    UnitTag('PB-0417', 31), UnitTag('PB-0398', 30), UnitTag('PB-0405', 27), UnitTag('PB-0421', 29), //
    null, UnitTag('PB-0433', 30), UnitTag('PB-0388', 26), null,
  ]),
  Station(id: 'st-02', code: 'BUN-02', name: 'محطة الزمالك', nameEn: 'Zamalek Station', walkMinutes: 9, bays: [15, null, null, 9, null, null, null, null], units: [
    UnitTag('PB-0512', 28), null, null, UnitTag('PB-0507', 27), null, null, null, null,
  ]),
  Station(id: 'st-03', code: 'BUN-03', name: 'محطة مدينة نصر', nameEn: 'Nasr City Station', walkMinutes: 15, bays: [null, null, null, null, null, null, null, null]),
  Station(id: 'st-04', code: 'BUN-04', name: 'محطة المعادي', nameEn: 'Maadi Station', walkMinutes: 22, bays: [41, 33, 27, null, 25, 22, 12, null], units: [
    UnitTag('PB-0611', 32), UnitTag('PB-0604', 31), UnitTag('PB-0619', 30), null, //
    UnitTag('PB-0608', 33), UnitTag('PB-0615', 29), UnitTag('PB-0602', 28), null,
  ]),
];

/// The station whose code appears in [raw] (a typed `BUN-01`, or QR text that
/// contains it; case and the dash are optional). Null when none matches.
Station? stationByCode(String? raw) {
  final m = RegExp(r'BUN-?(\d{2})', caseSensitive: false).firstMatch(raw ?? '');
  if (m == null) return null;
  final code = 'BUN-${m[1]}';
  for (final s in mockStations) {
    if (s.code == code) return s;
  }
  return null;
}

/// Closest open station (by walk) with an empty bay to return to; null when
/// every open station is full.
Station? nearestReturnStation() {
  Station? best;
  for (final s in mockStations) {
    if (s.emptyCount > 0 && isStationOpen(s) && (best == null || s.walkMinutes < best.walkMinutes)) best = s;
  }
  return best;
}

/// Lowest balance (EGP) that covers the first hour. Placeholder until real
/// pricing exists; /confirm shows the low-balance sheet below it.
const mockMinBalance = 20.0;

/// A rental that ended: picked up at [station], returned to [returnStation],
/// or [kept] when it wasn't back within 24 h.
class FinishedTrip {
  const FinishedTrip({
    required this.station,
    required this.returnStation,
    required this.startedAt,
    required this.endedAt,
  });

  final Station station;

  /// Null when the unit was kept ([LateStage.kept]).
  final Station? returnStation;
  final DateTime startedAt;
  final DateTime endedAt;

  Duration get duration => endedAt.difference(startedAt);

  /// Not returned within 24 h: the unit is the user's and the no-return fee
  /// was taken.
  bool get kept => returnStation == null;
}

/// Three past trips so /history has something to show.
List<FinishedTrip> _seedTrips() {
  final now = DateTime.now();
  FinishedTrip trip(int daysAgo, int from, int to, Duration length) {
    final end = DateTime(now.year, now.month, now.day - daysAgo, 18, 30);
    return FinishedTrip(
      station: mockStations[from],
      returnStation: mockStations[to],
      startedAt: end.subtract(length),
      endedAt: end,
    );
  }

  return [
    trip(1, 0, 1, const Duration(hours: 1, minutes: 12)),
    trip(3, 1, 1, const Duration(minutes: 48)),
    trip(5, 3, 0, const Duration(hours: 2)),
  ];
}

/// Late-return stages (references 44–47), by time since pickup. At [kept]
/// the rental closes: the unit is the user's and the fee is taken.
enum LateStage {
  reminder(Duration(hours: 23)),
  warning(Duration(hours: 23, minutes: 30)),
  lastChance(Duration(hours: 23, minutes: 54)),
  kept(Duration(hours: 24));

  const LateStage(this.at);

  /// Time since pickup at which this stage starts.
  final Duration at;

  /// The latest stage reached after [elapsed]; null before [reminder].
  static LateStage? reachedAt(Duration elapsed) {
    LateStage? reached;
    for (final s in values) {
      if (elapsed >= s.at) reached = s;
    }
    return reached;
  }
}

/// No-return fee (EGP) taken at [LateStage.kept]. Placeholder until real
/// pricing exists; screens show `[رسوم عدم الإرجاع]`.
const mockNoReturnFee = 0.0;

/// idle → unlocking → released (bay open, unit not taken yet) → active
/// (unit taken, time and cost running) → returned, or kept when it isn't
/// back within 24 h ([LateStage.kept]).
enum RentalState { idle, unlocking, released, active, returned, kept }

/// The user's current rental. Screens listen to [rentalSession] and call
/// [unlock] / [confirmPickup] / [returnTo] / [finish] / [reset]; nothing is
/// sent anywhere.
class RentalSession extends ChangeNotifier {
  RentalSession({
    this.balance = 0,
    this.unlockDelay = const Duration(milliseconds: 700),
    DateTime Function()? clock,
    List<FinishedTrip> history = const [],
    this.reservation,
  })  : _clock = clock ?? DateTime.now,
        _history = List.of(history);

  /// Simulated time for the bay to release the power bank.
  final Duration unlockDelay;

  /// The user's held bay, if any; it ends once a bay opens for a rental.
  final ReservationSession? reservation;
  final DateTime Function() _clock;

  /// Wallet balance in EGP.
  double balance;

  final List<FinishedTrip> _history;

  /// Finished trips, newest first; [finish] adds one.
  List<FinishedTrip> get history => List.unmodifiable(_history);

  /// Added to [_clock] by [debugJumpTo]; cleared with the rental.
  Duration _clockOffset = Duration.zero;
  DateTime _now() => _clock().add(_clockOffset);

  RentalState _state = RentalState.idle;
  Station? _station;
  int? _bayIndex;
  int? _unitCharge;
  UnitTag? _unit;
  DateTime? _startedAt;
  int? _phoneChargeAtPickup;
  DateTime? _endedAt;
  Station? _returnStation;
  int? _returnBayIndex;

  RentalState get state => _state;

  /// Where the unit was picked up.
  Station? get station => _station;
  int? get bayIndex => _bayIndex;

  /// Charge (percent) of the rented unit, read from its bay at unlock.
  int? get unitCharge => _unitCharge;

  /// Tag of the rented unit, read from its bay at unlock.
  UnitTag? get unit => _unit;

  /// Set when the unit is taken ([confirmPickup]); null before that.
  DateTime? get startedAt => _startedAt;

  /// The phone's charge (percent) when the unit was taken, for home's
  /// "+N% since you took it"; null before pickup or when unreadable.
  int? get phoneChargeAtPickup => _phoneChargeAtPickup;

  /// Where the unit was returned ([returnTo]); null until then.
  Station? get returnStation => _returnStation;
  int? get returnBayIndex => _returnBayIndex;

  /// Unlocks [bayIndex] at [station]: unlocking, then released once
  /// [unlockDelay] has passed. Only from idle or returned, and only for a
  /// bay that holds a ready unit ([Station.isReady]). Nothing is charged yet.
  /// Once the bay opens, any [reservation] is released.
  Future<void> unlock(Station station, int bayIndex) async {
    if (_state != RentalState.idle && _state != RentalState.returned && _state != RentalState.kept) {
      throw StateError('Already renting (state: $_state)');
    }
    final charge = station.bays[bayIndex];
    if (charge == null) {
      throw ArgumentError.value(bayIndex, 'bayIndex', 'Bay is empty');
    }
    if (!station.isReady(bayIndex)) {
      throw ArgumentError.value(bayIndex, 'bayIndex', 'Unit is below $minReadyCharge%');
    }
    _clear();
    _station = station;
    _bayIndex = bayIndex;
    _unitCharge = charge;
    _unit = station.units[bayIndex];
    _setState(RentalState.unlocking);

    await Future<void>.delayed(unlockDelay);
    // Cancelled (reset) while the bay was unlocking.
    if (_state != RentalState.unlocking || _station != station) return;
    reservation?.cancel();
    _setState(RentalState.released);
  }

  /// The user took the unit out of the open bay: the bay empties and the
  /// rental starts (released → active).
  void confirmPickup() {
    if (_state != RentalState.released) {
      throw StateError('No open bay to pick up from (state: $_state)');
    }
    _station!.bays[_bayIndex!] = null;
    _station!.units[_bayIndex!] = null;
    _startedAt = _now();
    _phoneChargeAtPickup = PhoneBattery.shared.reading.percent;
    _setState(RentalState.active);
  }

  /// Time since the power bank was taken; zero unless active.
  Duration get elapsed => _state == RentalState.active ? _now().difference(_startedAt!) : Duration.zero;

  /// Length of the rental: running while active, fixed once returned
  /// ([finish]) or kept; null before pickup.
  Duration? get duration => switch (_state) {
        RentalState.active => elapsed,
        RentalState.returned || RentalState.kept => _endedAt!.difference(_startedAt!),
        _ => null,
      };

  /// Late-return stage reached so far: [LateStage.kept] once closed by
  /// [closeIfOverdue]; null when not late or not renting.
  LateStage? get lateStage => switch (_state) {
        RentalState.active => LateStage.reachedAt(elapsed),
        RentalState.kept => LateStage.kept,
        _ => null,
      };

  /// Every stage this rental has passed, oldest first (one notification
  /// each on /notifications).
  List<LateStage> get lateStagesReached {
    final stage = lateStage;
    return stage == null ? const [] : LateStage.values.sublist(0, stage.index + 1);
  }

  /// Closes an active rental that has run [LateStage.kept]'s 24 h: the unit
  /// becomes the user's and [fee] (EGP) is taken from [balance] (active →
  /// kept) and a kept trip ([FinishedTrip.kept]) is added to [history].
  /// Returns whether it closed. /rental calls this as its timer ticks.
  bool closeIfOverdue({double fee = mockNoReturnFee}) {
    if (_state != RentalState.active || elapsed < LateStage.kept.at) return false;
    balance -= fee;
    _endedAt = _startedAt!.add(LateStage.kept.at);
    _history.insert(
      0,
      FinishedTrip(station: _station!, returnStation: null, startedAt: _startedAt!, endedAt: _endedAt!),
    );
    _setState(RentalState.kept);
    return true;
  }

  /// Debug only: moves the clock so the active rental has run [to], then
  /// closes it if that is past 24 h ([closeIfOverdue]).
  void debugJumpTo(Duration to) {
    if (_state != RentalState.active) {
      throw StateError('No running rental (state: $_state)');
    }
    _clockOffset += to - elapsed;
    if (!closeIfOverdue()) notifyListeners();
  }

  /// The unit went into empty bay [bayIndex] at [station] (any station). The
  /// bay fills with the unit's charge; call [finish] afterwards.
  void returnTo(Station station, int bayIndex) {
    if (_state != RentalState.active) {
      throw StateError('Nothing to return (state: $_state)');
    }
    if (_returnStation != null) {
      throw StateError('Already returned to ${_returnStation!.id}');
    }
    if (station.bays[bayIndex] != null) {
      throw ArgumentError.value(bayIndex, 'bayIndex', 'Bay is not empty');
    }
    station.bays[bayIndex] = _unitCharge;
    station.units[bayIndex] = _unit;
    _returnStation = station;
    _returnBayIndex = bayIndex;
    notifyListeners();
  }

  /// Ends the rental after [returnTo] and takes [cost] (EGP) from [balance].
  void finish({double cost = 0}) {
    if (_state != RentalState.active || _returnStation == null) {
      throw StateError('Return the unit to a bay first (state: $_state)');
    }
    balance -= cost;
    _endedAt = _now();
    _history.insert(
      0,
      FinishedTrip(
        station: _station!,
        returnStation: _returnStation!,
        startedAt: _startedAt!,
        endedAt: _endedAt!,
      ),
    );
    _setState(RentalState.returned);
  }

  /// Back to idle: after the receipt is dismissed (or the kept-unit banner),
  /// or to cancel while the bay is open (released) before anything is
  /// charged. Not while active,
  /// since the unit is out of its bay.
  void reset() {
    if (_state == RentalState.active) {
      throw StateError('The unit is out; return it first');
    }
    _clear();
    _setState(RentalState.idle);
  }

  void _clear() {
    _station = null;
    _bayIndex = null;
    _unitCharge = null;
    _unit = null;
    _clockOffset = Duration.zero;
    _startedAt = null;
    _phoneChargeAtPickup = null;
    _endedAt = null;
    _returnStation = null;
    _returnBayIndex = null;
  }

  void _setState(RentalState next) {
    _state = next;
    notifyListeners();
  }
}

/// The one session the screens read.
final rentalSession = RentalSession(balance: 50, history: _seedTrips(), reservation: reservationSession);

/// How long a reservation holds a bay. Placeholder until the real rule
/// exists; screens say `[المدة]`, only the countdown uses the value.
const mockReserveHold = Duration(minutes: 10);

/// Closest open station (by walk) with a ready unit to reserve; null when
/// none has one.
Station? nearestReadyStation() {
  Station? best;
  for (final s in mockStations) {
    if (s.readyCount > 0 && isStationOpen(s) && (best == null || s.walkMinutes < best.walkMinutes)) best = s;
  }
  return best;
}

/// A bay held for the user until [until] (/reserve, /reserved).
class Reservation {
  const Reservation({required this.station, required this.bayIndex, required this.until});

  final Station station;
  final int bayIndex;
  final DateTime until;
}

/// The user's reservation, if any. One at a time; nothing is sent anywhere.
class ReservationSession extends ChangeNotifier {
  ReservationSession({this.hold = mockReserveHold, DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final Duration hold;
  final DateTime Function() _clock;

  Reservation? _current;

  /// The held bay; null when none, after [cancel], or once it ran out.
  Reservation? get current {
    final r = _current;
    return r != null && _clock().isBefore(r.until) ? r : null;
  }

  /// Time left on [current]; zero without one.
  Duration get remaining {
    final r = current;
    return r == null ? Duration.zero : r.until.difference(_clock());
  }

  /// Holds the best ready bay at [station] for [hold]. Throws while another
  /// reservation is running.
  Reservation reserve(Station station) {
    if (current != null) throw StateError('Already holding a bay');
    expireIfDue();
    final bay = station.bestBayIndex;
    if (bay == null) throw ArgumentError.value(station.id, 'station', 'No ready unit');
    _current = Reservation(station: station, bayIndex: bay, until: _clock().add(hold));
    notifyListeners();
    return _current!;
  }

  /// Releases the bay.
  void cancel() {
    if (_current == null) return;
    _current = null;
    notifyListeners();
  }

  /// Notifies once [current] has run out; /reserved calls this as it ticks.
  /// Returns whether it expired.
  bool expireIfDue() {
    if (_current == null || current != null) return false;
    _current = null;
    notifyListeners();
    return true;
  }
}

/// The one reservation the screens read.
final reservationSession = ReservationSession();

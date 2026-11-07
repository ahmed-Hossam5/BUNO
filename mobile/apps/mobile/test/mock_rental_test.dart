import 'package:buno/data/mock_rental.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fresh stations per test: bays change as units are taken and returned.
Station _pickup() => Station(id: 'a', code: 'BUN-91', name: 'A', walkMinutes: 3, bays: [80, 95, null]);
Station _dropoff() => Station(id: 'b', code: 'BUN-92', name: 'B', walkMinutes: 8, bays: [70, null]);

void main() {
  test('mock stations: four, with empty bays as null', () {
    expect(mockStations, hasLength(4));
    // BUN-01: 15% and 9% are below minReadyCharge, so not ready.
    expect(mockStations[0].readyCount, 4);
    expect(mockStations[0].emptyCount, 2);
    expect(mockStations[1].readyCount, 0, reason: 'only 15% and 9% units');
    expect(mockStations[3].readyCount, 5);
    expect(mockStations[2].readyCount, 0);
    expect(mockStations.every((s) => s.bays.length == 8), isTrue);
  });

  test('stations by code, best bay', () {
    expect(mockStations.map((s) => s.code), ['BUN-01', 'BUN-02', 'BUN-03', 'BUN-04']);
    expect(stationByCode('BUN-02'), same(mockStations[1]));
    expect(stationByCode('bun04'), same(mockStations[3]));
    expect(stationByCode('https://buno.app/s/BUN-01'), same(mockStations[0]));
    expect(stationByCode('BUN-07'), isNull);
    expect(stationByCode(null), isNull);
    expect(mockStations[0].bestBayIndex, 0);
    expect(mockStations[3].bestBayIndex, 0);
    expect(mockStations[2].bestBayIndex, isNull);
  });

  test('top charge: best ready, else best low, null when empty', () {
    expect(mockStations.map((s) => s.topCharge), [92, 15, null, 41]);
    expect(mockStations[1].bestCharge, isNull);
  });

  test('units below minReadyCharge are not ready, never the best bay', () {
    final s = Station(id: 'c', code: 'BUN-93', name: 'C', walkMinutes: 1, bays: [19, 20, null]);
    expect([s.isReady(0), s.isReady(1), s.isReady(2)], [false, true, false]);
    expect(s.readyCount, 1);
    expect(s.emptyCount, 1);
    expect(s.bestBayIndex, 1);
    final low = Station(id: 'd', code: 'BUN-94', name: 'D', walkMinutes: 1, bays: [5, 19, null]);
    expect(low.readyCount, 0);
    expect(low.bestBayIndex, isNull);
  });

  test('idle -> unlocking -> released -> active -> returned -> idle', () async {
    var now = DateTime(2026, 10, 24, 12);
    final session = RentalSession(balance: 50, unlockDelay: Duration.zero, clock: () => now);
    final states = <RentalState>[];
    session.addListener(() => states.add(session.state));
    final pickup = _pickup();
    final dropoff = _dropoff();

    final unlocking = session.unlock(pickup, 1);
    expect(session.state, RentalState.unlocking);
    expect(session.unitCharge, 95);

    await unlocking;
    // Bay open, unit not taken: no clock, bay still full.
    expect(session.state, RentalState.released);
    expect(session.startedAt, isNull);
    expect(session.elapsed, Duration.zero);
    expect(pickup.bays, [80, 95, null]);

    now = now.add(const Duration(minutes: 1));
    session.confirmPickup();
    expect(session.state, RentalState.active);
    expect(session.startedAt, DateTime(2026, 10, 24, 12, 1));
    expect(pickup.bays, [80, null, null]);

    now = now.add(const Duration(minutes: 12));
    expect(session.elapsed, const Duration(minutes: 12));
    expect(session.duration, const Duration(minutes: 12));

    session.returnTo(dropoff, 1);
    expect(dropoff.bays, [70, 95]);
    expect(session.returnStation, dropoff);
    expect(session.returnBayIndex, 1);
    expect(session.state, RentalState.active);

    session.finish(cost: 7.5);
    expect(session.state, RentalState.returned);
    expect(session.balance, 42.5);
    // The duration stops at finish.
    now = now.add(const Duration(minutes: 5));
    expect(session.duration, const Duration(minutes: 12));

    session.reset();
    expect(session.state, RentalState.idle);
    expect(session.station, isNull);
    expect(session.duration, isNull);
    expect(states, [
      RentalState.unlocking,
      RentalState.released,
      RentalState.active,
      RentalState.active, // returnTo: bays changed
      RentalState.returned,
      RentalState.idle,
    ]);
  });

  test('cancelling while released charges nothing and leaves the bay full', () async {
    final session = RentalSession(balance: 50, unlockDelay: Duration.zero);
    final pickup = _pickup();

    await session.unlock(pickup, 0);
    session.reset();

    expect(session.state, RentalState.idle);
    expect(session.balance, 50);
    expect(pickup.bays, [80, 95, null]);
  });

  test('cancelling while unlocking stays idle once the delay ends', () async {
    final session = RentalSession(unlockDelay: const Duration(milliseconds: 10));

    final unlocking = session.unlock(_pickup(), 0);
    session.reset();
    await unlocking;

    expect(session.state, RentalState.idle);
  });

  test('rejects invalid transitions', () async {
    final session = RentalSession(unlockDelay: Duration.zero);
    final pickup = _pickup();
    final dropoff = _dropoff();

    expect(() => session.confirmPickup(), throwsStateError);
    expect(() => session.finish(), throwsStateError);
    expect(() => session.unlock(pickup, 2), throwsArgumentError);

    await session.unlock(pickup, 0);
    expect(() => session.unlock(pickup, 1), throwsStateError);
    expect(() => session.returnTo(dropoff, 1), throwsStateError);
    expect(() => session.finish(), throwsStateError);

    session.confirmPickup();
    expect(() => session.reset(), throwsStateError);
    expect(() => session.finish(), throwsStateError, reason: 'not returned yet');
    expect(() => session.returnTo(dropoff, 0), throwsArgumentError, reason: 'bay is full');

    session.returnTo(dropoff, 1);
    expect(() => session.returnTo(pickup, 0), throwsStateError, reason: 'already returned');
  });

  test('unlock rejects a unit below minReadyCharge', () async {
    final session = RentalSession(unlockDelay: Duration.zero);
    final station = Station(id: 'e', code: 'BUN-95', name: 'E', walkMinutes: 1, bays: [19, 20]);

    await expectLater(session.unlock(station, 0), throwsArgumentError);
    expect(session.state, RentalState.idle);
    expect(session.station, isNull);

    await session.unlock(station, 1);
    expect(session.state, RentalState.released);
    expect(session.unitCharge, 20);
  });

  test('nearest return station has an empty bay', () {
    final s = nearestReturnStation()!;
    expect(s.emptyCount, greaterThan(0));
    for (final o in mockStations.where((o) => o.emptyCount > 0)) {
      expect(s.walkMinutes, lessThanOrEqualTo(o.walkMinutes));
    }
    expect(s.bays[s.firstEmptyBay!], isNull);
  });

  test('a single global session starts idle', () {
    expect(identical(rentalSession, rentalSession), isTrue);
    expect(rentalSession.state, RentalState.idle);
  });
}

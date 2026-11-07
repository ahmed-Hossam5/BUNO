import 'package:buno_shared/buno_shared.dart';

/// In-memory rentals: at most one active per user, plus the finished ones.
class RentalStore {
  final _active = <String, RentalDto>{};
  final _history = <String, List<RentalDto>>{};
  var _next = 0;

  RentalDto? activeFor(String userId) => _active[userId];

  RentalDto start({
    required String userId,
    required String stationCode,
    required int bay,
    required int unitCharge,
    required DateTime at,
  }) =>
      _active[userId] = RentalDto(
        id: 'r-${++_next}',
        stationCode: stationCode,
        bay: bay,
        unitCharge: unitCharge,
        startedAt: at,
        status: RentalStatus.active,
      );

  RentalDto finish(String userId, {required String returnStationCode, required DateTime at}) {
    final r = _active.remove(userId)!;
    final done = RentalDto(
      id: r.id,
      stationCode: r.stationCode,
      bay: r.bay,
      unitCharge: r.unitCharge,
      startedAt: r.startedAt,
      status: RentalStatus.returned,
      returnStationCode: returnStationCode,
      endedAt: at,
    );
    (_history[userId] ??= []).insert(0, done);
    return done;
  }
}

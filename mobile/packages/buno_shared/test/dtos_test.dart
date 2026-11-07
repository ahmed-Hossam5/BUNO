import 'package:buno_shared/buno_shared.dart';
import 'package:test/test.dart';

void main() {
  test('StationDto round-trips and counts bays', () {
    const s = StationDto(id: 'st-01', code: 'BUN-01', name: 'محطة التحرير', walkMinutes: 4, bays: [92, 15, null]);
    final back = StationDto.fromJson(s.toJson());
    expect(back.code, 'BUN-01');
    expect(back.bays, [92, 15, null]);
    expect(back.readyCount, 1);
    expect(back.emptyCount, 1);
  });

  test('RentalDto round-trips', () {
    final r = RentalDto(
      id: 'r-1',
      stationCode: 'BUN-01',
      bay: 0,
      unitCharge: 92,
      startedAt: DateTime.utc(2026, 11, 4, 10),
      status: RentalStatus.active,
    );
    final back = RentalDto.fromJson(r.toJson());
    expect(back.status, RentalStatus.active);
    expect(back.startedAt, r.startedAt);
    expect(back.endedAt, isNull);
  });

  test('paths', () {
    expect(ApiPaths.station('BUN-02'), '/v1/stations/BUN-02');
    expect(ApiPaths.returnRental('r-1'), '/v1/rentals/r-1/return');
  });
}

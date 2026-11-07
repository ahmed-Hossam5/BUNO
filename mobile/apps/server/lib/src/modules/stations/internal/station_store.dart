import 'package:buno_shared/buno_shared.dart';

/// In-memory stations, seeded like the app's `mockStations`.
class StationStore {
  final _stations = <_Station>[
    _Station('st-01', 'BUN-01', 'محطة التحرير', 4, [92, 88, 15, 71, null, 64, 9, null]),
    _Station('st-02', 'BUN-02', 'محطة الزمالك', 9, [15, null, null, 9, null, null, null, null]),
    _Station('st-03', 'BUN-03', 'محطة مدينة نصر', 15, List.filled(baysPerStation, null)),
    _Station('st-04', 'BUN-04', 'محطة المعادي', 22, [41, 33, 27, null, 25, 22, 12, null]),
  ];

  List<StationDto> all() => [for (final s in _stations) s.toDto()];

  StationDto? byCode(String code) => _find(code)?.toDto();

  /// The live bay list, for the module to change; null for an unknown code.
  List<int?>? baysOf(String code) => _find(code)?.bays;

  _Station? _find(String code) {
    final upper = code.toUpperCase();
    for (final s in _stations) {
      if (s.code == upper) return s;
    }
    return null;
  }
}

class _Station {
  _Station(this.id, this.code, this.name, this.walkMinutes, List<int?> bays) : bays = List.of(bays, growable: false);

  final String id;
  final String code;
  final String name;
  final int walkMinutes;
  final List<int?> bays;

  StationDto toDto() => StationDto(id: id, code: code, name: name, walkMinutes: walkMinutes, bays: List.unmodifiable(bays));
}

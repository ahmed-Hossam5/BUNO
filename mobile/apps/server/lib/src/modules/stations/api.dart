import 'package:buno_shared/buno_shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../core/http.dart';
import '../../core/module.dart';
import 'internal/station_store.dart';

/// Stations and what is in each bay.
abstract interface class StationsApi {
  List<StationDto> all();

  /// Null when no station has [code].
  StationDto? byCode(String code);

  /// Empties [bay] at [code] and returns the charge of the unit taken.
  /// Throws `bayNotReady` unless it holds a unit at [minReadyCharge] or more.
  int takeUnit(String code, int bay);

  /// Puts a unit with [charge] into empty [bay]; throws `bayNotEmpty`.
  void putUnit(String code, int bay, int charge);
}

class StationsModule implements BunoModule, StationsApi {
  final _store = StationStore();

  @override
  void mount(Router router, ModuleContext context) {
    router
      ..get(ApiPaths.stations, (Request _) => jsonOk([for (final s in all()) s.toJson()]))
      ..get('${ApiPaths.stations}/<code>', (Request r) {
        final s = byCode(r.params['code']!);
        if (s == null) throw const ApiException.notFound();
        return jsonOk(s.toJson());
      });
  }

  @override
  List<StationDto> all() => _store.all();

  @override
  StationDto? byCode(String code) => _store.byCode(code);

  @override
  int takeUnit(String code, int bay) {
    final bays = _bays(code, bay);
    final charge = bays[bay];
    if (charge == null || charge < minReadyCharge) throw const ApiException(ApiError.bayNotReady, 409);
    bays[bay] = null;
    return charge;
  }

  @override
  void putUnit(String code, int bay, int charge) {
    final bays = _bays(code, bay);
    if (bays[bay] != null) throw const ApiException(ApiError.bayNotEmpty, 409);
    bays[bay] = charge;
  }

  List<int?> _bays(String code, int bay) {
    final bays = _store.baysOf(code);
    if (bays == null) throw const ApiException.notFound();
    if (bay < 0 || bay >= bays.length) throw const ApiException.badRequest();
    return bays;
  }
}

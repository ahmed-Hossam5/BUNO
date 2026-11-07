import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:buno_shared/buno_shared.dart';

import '../../core/http.dart';
import '../../core/module.dart';
import '../stations/api.dart';

/// Each user's hearted stations, by code. Uses stations to check codes and
/// to send the stations' current bays.
class FavoritesModule implements BunoModule {
  FavoritesModule({required this._stations});

  final StationsApi _stations;

  /// User id → station codes, in the order they were added.
  final _byUser = <String, Set<String>>{};

  @override
  void mount(Router router, ModuleContext context) {
    router
      ..get(ApiPaths.favorites, context.authed(_list))
      ..put('${ApiPaths.favorites}/<code>', context.authed(_add))
      ..delete('${ApiPaths.favorites}/<code>', context.authed(_remove));
  }

  Response _list(Request r) => jsonOk([
        for (final code in _byUser[userIdOf(r)] ?? const <String>{})
          if (_stations.byCode(code) case final s?) s.toJson(),
      ]);

  Response _add(Request r) {
    final station = _stations.byCode(r.params['code']!);
    if (station == null) throw const ApiException.notFound();
    (_byUser[userIdOf(r)] ??= {}).add(station.code);
    return noContent();
  }

  Response _remove(Request r) {
    _byUser[userIdOf(r)]?.remove(r.params['code']!.toUpperCase());
    return noContent();
  }
}

import 'package:buno_shared/buno_shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../core/http.dart';
import '../../core/module.dart';
import '../stations/api.dart';
import '../wallet/api.dart';
import 'internal/rental_store.dart';

/// Unlock a bay, run the rental, return the unit. Uses stations for the
/// bays and wallet for the balance check; nothing is charged yet, since
/// pricing is a placeholder.
class RentalsModule implements BunoModule {
  RentalsModule({required this._stations, required this._wallet, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final StationsApi _stations;
  final WalletApi _wallet;
  final DateTime Function() _clock;
  final _store = RentalStore();

  @override
  void mount(Router router, ModuleContext context) {
    router
      ..post(ApiPaths.rentals, context.authed(_start))
      ..get(ApiPaths.currentRental, context.authed(_current))
      ..post('${ApiPaths.rentals}/<id>/return', context.authed(_return));
  }

  Future<Response> _start(Request r) async {
    final user = userIdOf(r);
    final body = parse(await readJson(r), BayRequest.fromJson);
    if (_store.activeFor(user) != null) throw const ApiException(ApiError.alreadyRenting, 409);
    if (_wallet.balanceOf(user) < minRentBalance) throw const ApiException(ApiError.lowBalance, 402);
    final charge = _stations.takeUnit(body.stationCode, body.bay);
    final rental = _store.start(
      userId: user,
      stationCode: body.stationCode.toUpperCase(),
      bay: body.bay,
      unitCharge: charge,
      at: _clock(),
    );
    return jsonOk(rental.toJson(), status: 201);
  }

  Response _current(Request r) {
    final rental = _store.activeFor(userIdOf(r));
    if (rental == null) throw const ApiException(ApiError.noActiveRental, 404);
    return jsonOk(rental.toJson());
  }

  Future<Response> _return(Request r) async {
    final user = userIdOf(r);
    final body = parse(await readJson(r), BayRequest.fromJson);
    final rental = _store.activeFor(user);
    if (rental == null || rental.id != r.params['id']) throw const ApiException(ApiError.noActiveRental, 404);
    _stations.putUnit(body.stationCode, body.bay, rental.unitCharge);
    final done = _store.finish(user, returnStationCode: body.stationCode.toUpperCase(), at: _clock());
    return jsonOk(done.toJson());
  }
}

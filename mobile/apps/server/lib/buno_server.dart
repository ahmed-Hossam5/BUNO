/// Composition root of the Buno modular monolith: builds every module,
/// wires their dependencies through public interfaces, and mounts their
/// routes on one handler.
library;

import 'package:buno_shared/buno_shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'src/core/http.dart';
import 'src/core/module.dart';
import 'src/modules/auth/api.dart';
import 'src/modules/favorites/api.dart';
import 'src/modules/promo/api.dart';
import 'src/modules/rentals/api.dart';
import 'src/modules/stations/api.dart';
import 'src/modules/wallet/api.dart';

/// A fresh server with its own in-memory data. [clock] drives rental times.
Handler buildBunoServer({DateTime Function()? clock}) {
  final auth = AuthModule();
  final stations = StationsModule();
  final wallet = WalletModule();
  final modules = <BunoModule>[
    auth,
    stations,
    wallet,
    RentalsModule(stations: stations, wallet: wallet, clock: clock),
    PromoModule(),
    FavoritesModule(stations: stations),
  ];

  final router = Router()..get(ApiPaths.health, (Request _) => jsonOk({'status': 'ok'}));
  final context = ModuleContext(authed: auth.authed);
  for (final m in modules) {
    m.mount(router, context);
  }
  return const Pipeline().addMiddleware(handleApiErrors()).addHandler(router.call);
}

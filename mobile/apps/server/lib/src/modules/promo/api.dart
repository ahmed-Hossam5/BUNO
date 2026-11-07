import 'package:buno_shared/buno_shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../core/http.dart';
import '../../core/module.dart';
import 'internal/promo_store.dart';

/// Discount codes and each user's offers. Amounts and dates stay
/// placeholders, like /promo in the app.
class PromoModule implements BunoModule {
  final _store = PromoStore();

  @override
  void mount(Router router, ModuleContext context) {
    router
      ..get(ApiPaths.promoOffers, context.authed(_offers))
      ..post(ApiPaths.promoRedeem, context.authed(_redeem));
  }

  Response _offers(Request r) => jsonOk([for (final o in _store.offersOf(userIdOf(r))) o.toJson()]);

  Future<Response> _redeem(Request r) async {
    final code = (await readJson(r))['code'];
    if (code is! String) throw const ApiException.badRequest();
    final offer = _store.redeem(userIdOf(r), code);
    return jsonOk(offer.toJson(), status: 201);
  }
}

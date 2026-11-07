import 'package:buno_shared/buno_shared.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../core/http.dart';
import '../../core/module.dart';
import 'internal/balances.dart';

/// Each user's balance in EGP. Top-ups aren't built yet.
abstract interface class WalletApi {
  double balanceOf(String userId);

  /// Takes [amount] off; throws `lowBalance` when it doesn't cover it.
  void debit(String userId, double amount);
}

class WalletModule implements BunoModule, WalletApi {
  final _balances = Balances();

  @override
  void mount(Router router, ModuleContext context) {
    router.get(
      ApiPaths.wallet,
      context.authed((r) => jsonOk(WalletDto(balance: balanceOf(userIdOf(r))).toJson())),
    );
  }

  @override
  double balanceOf(String userId) => _balances.of(userId);

  @override
  void debit(String userId, double amount) {
    if (_balances.of(userId) < amount) throw const ApiException(ApiError.lowBalance, 402);
    _balances.add(userId, -amount);
  }
}

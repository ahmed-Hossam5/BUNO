/// In-memory balances. New users start with [startingBalance], like the
/// app's mock session.
class Balances {
  static const startingBalance = 50.0;

  final _byUser = <String, double>{};

  double of(String userId) => _byUser[userId] ?? startingBalance;

  void add(String userId, double amount) => _byUser[userId] = of(userId) + amount;
}

import 'package:buno_shared/buno_shared.dart';

/// In-memory users (one per e-mail) and their tokens.
class Sessions {
  final _users = <String, String>{};
  final _tokens = <String, String>{};
  var _next = 0;

  SessionDto open(String email) {
    final key = email.trim().toLowerCase();
    final userId = _users.putIfAbsent(key, () => 'u-${_users.length + 1}');
    final token = 'tok-${++_next}-${DateTime.now().microsecondsSinceEpoch}';
    _tokens[token] = userId;
    return SessionDto(token: token, userId: userId);
  }

  String? userFor(String token) => _tokens[token];
}

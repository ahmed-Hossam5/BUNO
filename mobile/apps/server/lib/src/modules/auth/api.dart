import 'package:buno_shared/buno_shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../core/http.dart';
import '../../core/module.dart';
import 'internal/sessions.dart';

/// Sign-in by e-mail code. Mock: nothing is sent and any [authCodeLength]
/// digits pass, like the app.
abstract interface class AuthApi {
  /// See [ModuleContext.authed].
  Handler authed(Handler handler);
}

class AuthModule implements BunoModule, AuthApi {
  final _sessions = Sessions();

  @override
  void mount(Router router, ModuleContext context) {
    router
      ..post(ApiPaths.authSendCode, _sendCode)
      ..post(ApiPaths.authVerify, _verify);
  }

  Future<Response> _sendCode(Request request) async {
    final email = (await readJson(request))['email'];
    if (email is! String || !email.contains('@')) throw const ApiException.badRequest();
    return noContent();
  }

  Future<Response> _verify(Request request) async {
    final body = parse(await readJson(request), VerifyCodeRequest.fromJson);
    if (!RegExp('^\\d{$authCodeLength}\$').hasMatch(body.code)) {
      throw const ApiException(ApiError.invalidCode, 401);
    }
    return jsonOk(_sessions.open(body.email).toJson());
  }

  @override
  Handler authed(Handler handler) => (request) {
        final header = request.headers['authorization'] ?? '';
        final userId = header.startsWith('Bearer ') ? _sessions.userFor(header.substring(7)) : null;
        if (userId == null) throw const ApiException(ApiError.unauthorized, 401);
        return handler(request.change(context: {userIdKey: userId}));
      };
}

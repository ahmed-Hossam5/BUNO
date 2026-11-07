import 'dart:convert';

import 'package:buno_shared/buno_shared.dart';
import 'package:shelf/shelf.dart';

/// Thrown by module code; [handleApiErrors] turns it into
/// `{"error": "<name>"}` with [status].
class ApiException implements Exception {
  const ApiException(this.error, this.status);

  const ApiException.badRequest() : this(ApiError.badRequest, 400);
  const ApiException.notFound() : this(ApiError.notFound, 404);

  final ApiError error;
  final int status;

  @override
  String toString() => 'ApiException(${error.name}, $status)';
}

const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

Response jsonOk(Object? body, {int status = 200}) => Response(status, body: jsonEncode(body), headers: _jsonHeaders);

Response noContent() => Response(204);

/// The request body as a JSON object; [ApiException.badRequest] when it
/// isn't one.
Future<Json> readJson(Request request) async {
  try {
    final body = jsonDecode(await request.readAsString());
    if (body is Json) return body;
  } on FormatException {
    // Falls through to the bad request below.
  }
  throw const ApiException.badRequest();
}

/// Parses [json] with [fromJson]; a missing or mistyped field is a bad
/// request rather than a crash.
T parse<T>(Json json, T Function(Json) fromJson) {
  try {
    return fromJson(json);
  } on TypeError {
    throw const ApiException.badRequest();
  }
}

const userIdKey = 'buno.userId';

/// The signed-in user; only inside a handler wrapped by
/// `ModuleContext.authed`.
String userIdOf(Request request) => request.context[userIdKey]! as String;

Middleware handleApiErrors() => (inner) => (request) async {
      try {
        return await inner(request);
      } on ApiException catch (e) {
        return jsonOk({'error': e.error.name}, status: e.status);
      }
    };

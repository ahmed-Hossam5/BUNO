import 'dart:io';

import 'package:buno_server/buno_server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

/// `dart run bin/server.dart` (PORT defaults to 8080).
Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final handler = const Pipeline().addMiddleware(logRequests()).addHandler(buildBunoServer());
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  stdout.writeln('Buno server on http://${server.address.host}:${server.port}');
}

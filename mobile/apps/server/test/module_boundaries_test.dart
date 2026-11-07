import 'dart:io';

import 'package:test/test.dart';

/// The modular-monolith rule: a module may use another module only through
/// its `api.dart`, never its `internal/` files.
void main() {
  final modulesDir = Directory('lib/src/modules');
  final importRe = RegExp(r'''^import\s+'([^']+)';''', multiLine: true);

  test('modules only import each other through api.dart', () {
    final violations = <String>[];
    for (final file in modulesDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      final owner = _moduleOf(file.uri);
      for (final m in importRe.allMatches(file.readAsStringSync())) {
        final target = file.uri.resolve(m[1]!);
        final other = _moduleOf(target);
        if (other != null && other != owner && !target.path.endsWith('/$other/api.dart')) {
          violations.add('${file.path} → ${m[1]}');
        }
      }
    }
    expect(violations, isEmpty);
  });

  test('every module has an api.dart', () {
    for (final dir in modulesDir.listSync().whereType<Directory>()) {
      expect(File('${dir.path}/api.dart').existsSync(), isTrue, reason: dir.path);
    }
  });
}

/// The module a `lib/src/modules/<name>/...` uri belongs to, or null.
String? _moduleOf(Uri uri) {
  final segments = uri.pathSegments;
  final i = segments.lastIndexOf('modules');
  return i >= 0 && i + 1 < segments.length && segments[i - 1] == 'src' ? segments[i + 1] : null;
}

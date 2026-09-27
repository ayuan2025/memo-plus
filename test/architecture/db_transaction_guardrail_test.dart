import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('database transactions stay inside the allowlist', () async {
    const allowlist = <String>{
      'lib/data/db/app_database_write_dao.dart',
    };

    final libDir = Directory('lib');
    final violations = <String>[];
    await for (final entry in libDir.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entry is! File || p.extension(entry.path) != '.dart') continue;
      final relative = p
          .relative(entry.path, from: Directory.current.path)
          .replaceAll('\\', '/');
      if (allowlist.contains(relative)) continue;
      final contents = await entry.readAsString();
      if (contents.contains('.transaction(')) {
        violations.add(relative);
      }
    }

    expect(
      violations,
      isEmpty,
      reason: violations.isEmpty
          ? null
          : 'Unexpected direct transaction usage:\n${violations.join('\n')}',
    );
  });
}

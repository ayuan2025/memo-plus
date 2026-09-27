import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'lib code does not issue write-like calls directly from databaseProvider',
    () async {
      final forbiddenPattern = RegExp(
        r'(read|watch)\(databaseProvider\)\.'
        r'(upsert|update|delete|replace|enqueue|mark|claim|clear|rewrite|insert|remove|retry|complete|rebuild|save|invalidate|create|discard)'
        r'[A-Za-z0-9_]*\s*\(',
      );

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
        final contents = await entry.readAsString();
        if (forbiddenPattern.hasMatch(contents)) {
          violations.add(relative);
        }
      }

      expect(
        violations,
        isEmpty,
        reason: violations.isEmpty
            ? null
            : 'Unexpected direct databaseProvider write-like usage in:\n'
                  '${violations.join('\n')}',
      );
    },
  );
}

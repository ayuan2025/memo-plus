import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'direct AppDatabase write-like calls stay inside the allowlist',
    () async {
      const allowlist = <String>{
        'lib/data/db/app_database.dart',
        'lib/data/db/app_database_write_dao.dart',
        'lib/data/ai/ai_analysis_repository.dart',
        'lib/state/tags/tag_repository.dart',
      };

      final directWritePattern = RegExp(
        r'\b(?:db|database|_database)\.'
        r'(?:upsert|update|delete|replace|enqueue|mark|claim|clear|rewrite|insert|remove|retry|complete|rebuild|save|invalidate|create|discard)'
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
        if (allowlist.contains(relative) ||
            relative.endsWith('_mutation_service.dart')) {
          continue;
        }

        final contents = await entry.readAsString();
        if (directWritePattern.hasMatch(contents)) {
          violations.add(relative);
        }
      }

      expect(
        violations,
        isEmpty,
        reason: violations.isEmpty
            ? null
            : 'Unexpected direct AppDatabase write-like calls in:\n'
                  '${violations.join('\n')}',
      );
    },
  );
}

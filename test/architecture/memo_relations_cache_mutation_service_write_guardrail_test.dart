import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'memo relations cache mutation service does not issue writes via direct databaseProvider reads',
    () async {
      final file = File(
        'lib/state/memos/memo_relations_cache_mutation_service.dart',
      );
      final contents = await file.readAsString();

      const forbiddenPatterns = <String>[
        'read(databaseProvider).upsertMemoRelationsCache(',
      ];

      final violations = forbiddenPatterns
          .where((pattern) => contents.contains(pattern))
          .toList(growable: false);

      expect(
        violations,
        isEmpty,
        reason: violations.isEmpty
            ? null
            : 'Unexpected direct databaseProvider write calls in '
                  'memo_relations_cache_mutation_service.dart:\n'
                  '${violations.join('\n')}',
      );
    },
  );
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'memo relations provider delegates cache writes to mutation service',
    () async {
      final file = File('lib/state/memos/memos_relations_provider.part.dart');
      final contents = await file.readAsString();

      const forbiddenPatterns = <String>['db.upsertMemoRelationsCache('];

      final violations = forbiddenPatterns
          .where((pattern) => contents.contains(pattern))
          .toList(growable: false);

      expect(
        violations,
        isEmpty,
        reason: violations.isEmpty
            ? null
            : 'Unexpected direct memo relations cache write calls in '
                  'memos_relations_provider.part.dart:\n${violations.join('\n')}',
      );
    },
  );
}

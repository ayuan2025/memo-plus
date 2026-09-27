import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'memo delete service delegates memo writes to mutation service',
    () async {
      final file = File('lib/state/memos/memo_delete_service.dart');
      final contents = await file.readAsString();

      const forbiddenPatterns = <String>[
        'db.upsertMemoDeleteTombstone(',
        'db.deleteOutboxForMemo(',
        'db.enqueueOutbox(',
        'db.deleteMemoByUid(',
      ];

      final violations = forbiddenPatterns
          .where((pattern) => contents.contains(pattern))
          .toList(growable: false);

      expect(
        violations,
        isEmpty,
        reason: violations.isEmpty
            ? null
            : 'Unexpected direct memo delete write calls in '
                  'memo_delete_service.dart:\n${violations.join('\n')}',
      );
    },
  );
}

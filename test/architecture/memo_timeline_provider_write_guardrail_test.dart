import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'memo timeline provider delegates DB writes to mutation service',
    () async {
      final file = File('lib/state/memos/memo_timeline_provider.dart');
      final contents = await file.readAsString();

      const forbiddenPatterns = <String>[
        'db.insertMemoVersion(',
        'db.deleteOutboxForMemo(',
        'db.upsertMemo(',
        'db.enqueueOutbox(',
        'db.insertRecycleBinItem(',
        'db.deleteRecycleBinItemById(',
        'db.clearRecycleBinItems(',
        'db.deleteMemoDeleteTombstone(',
        'db.deleteMemoVersionById(',
      ];

      final violations = forbiddenPatterns
          .where((pattern) => contents.contains(pattern))
          .toList(growable: false);

      expect(
        violations,
        isEmpty,
        reason: violations.isEmpty
            ? null
            : 'Unexpected direct memo timeline write calls in '
                  'memo_timeline_provider.dart:\n${violations.join('\n')}',
      );
    },
  );
}

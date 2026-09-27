import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'sync queue controller delegates DB writes to mutation service',
    () async {
      final file = File('lib/state/memos/sync_queue_controller.dart');
      final contents = await file.readAsString();

      const forbiddenPatterns = <String>[
        'db.deleteOutboxForMemo(',
        'db.upsertMemoDeleteTombstone(',
        'db.deleteOutbox(',
        'db.removePendingAttachmentPlaceholder(',
        'db.retryOutboxErrors(',
        'db.retryOutboxItem(',
        'db.enqueueOutbox(',
        'db.updateMemoSyncState(',
      ];

      final violations = forbiddenPatterns
          .where((pattern) => contents.contains(pattern))
          .toList(growable: false);

      expect(
        violations,
        isEmpty,
        reason: violations.isEmpty
            ? null
            : 'Unexpected direct sync queue write calls in '
                  'sync_queue_controller.dart:\n${violations.join('\n')}',
      );
    },
  );
}

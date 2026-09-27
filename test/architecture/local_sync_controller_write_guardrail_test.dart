import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'local sync controller delegates DB writes to mutation service',
    () async {
      final file = File('lib/state/sync/local_sync_controller.dart');
      final contents = await file.readAsString();

      const forbiddenPatterns = <String>[
        'db.recoverOutboxRunningTasks(',
        'db.claimOutboxTaskById(',
        'db.markOutboxError(',
        'db.markOutboxDone(',
        'db.deleteOutbox(',
        'db.markOutboxRetryScheduled(',
        'db.updateMemoSyncState(',
        'db.removePendingAttachmentPlaceholder(',
        'db.updateMemoAttachmentsJson(',
      ];

      final violations = forbiddenPatterns
          .where((pattern) => contents.contains(pattern))
          .toList(growable: false);

      expect(
        violations,
        isEmpty,
        reason: violations.isEmpty
            ? null
            : 'Unexpected direct local sync write calls in '
                  'local_sync_controller.dart:\n${violations.join('\n')}',
      );
    },
  );
}

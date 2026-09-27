import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('remote sync parts delegate DB writes to mutation service', () async {
    const guardedFiles = <String, List<String>>{
      'lib/state/memos/memos_remote_sync_controller.part.dart': <String>[
        'db.recoverOutboxRunningTasks(',
      ],
      'lib/state/memos/memos_remote_sync_outbox.part.dart': <String>[
        'db.recoverOutboxRunningTasks(',
        'db.claimOutboxTaskById(',
        'db.markOutboxQuarantined(',
        'db.markOutboxDone(',
        'db.deleteOutbox(',
        'db.updateMemoSyncState(',
        'db.deleteMemoDeleteTombstone(',
        'db.markOutboxRetryScheduled(',
        'db.upsertMemoDeleteTombstone(',
        'db.removePendingAttachmentPlaceholder(',
        'db.renameMemoUid(',
        'db.rewriteOutboxMemoUids(',
      ],
      'lib/state/memos/memos_remote_sync_state_sync.part.dart': <String>[
        'db.upsertMemo(',
        'db.rewriteOutboxMemoUids(',
        'db.enqueueOutbox(',
        'db.upsertMemoRelationsCache(',
        'db.deleteMemoByUid(',
      ],
      'lib/state/memos/memos_remote_sync_attachments.part.dart': <String>[
        'db.enqueueOutbox(',
        'db.upsertMemo(',
        'db.updateMemoAttachmentsJson(',
      ],
    };

    final violations = <String>[];
    for (final entry in guardedFiles.entries) {
      final contents = await File(entry.key).readAsString();
      for (final pattern in entry.value) {
        if (contents.contains(pattern)) {
          violations.add('${entry.key}: $pattern');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: violations.isEmpty
          ? null
          : 'Unexpected direct remote sync write calls:\n'
                '${violations.join('\n')}',
    );
  });
}

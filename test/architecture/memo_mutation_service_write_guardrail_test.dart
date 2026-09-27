import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'memo mutation service does not issue writes via direct databaseProvider reads',
    () async {
      final file = File('lib/state/memos/memo_mutation_service.dart');
      final contents = await file.readAsString();

      const forbiddenPatterns = <String>[
        'read(databaseProvider).upsertMemo(',
        'read(databaseProvider).enqueueOutbox(',
        'read(databaseProvider).deleteOutbox(',
        'read(databaseProvider).deleteOutboxForMemo(',
        'read(databaseProvider).upsertMemoDeleteTombstone(',
        'read(databaseProvider).deleteMemoByUid(',
        'read(databaseProvider).retryOutboxErrors(',
        'read(databaseProvider).retryOutboxItem(',
        'read(databaseProvider).updateMemoSyncState(',
        'read(databaseProvider).removePendingAttachmentPlaceholder(',
        'read(databaseProvider).upsertMemoRelationsCache(',
        'read(databaseProvider).deleteMemoRelationsCache(',
        'read(databaseProvider).upsertMemoInlineImageSource(',
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
                  'memo_mutation_service.dart:\n${violations.join('\n')}',
      );
    },
  );
}

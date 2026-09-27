import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'memo editor controller delegates memo writes to mutation service',
    () async {
      final file = File('lib/state/memos/memo_editor_controller.dart');
      final contents = await file.readAsString();

      const forbiddenPatterns = <String>[
        'db.upsertMemo(',
        'db.deleteMemoRelationsCache(',
        'db.upsertMemoRelationsCache(',
        'db.enqueueOutbox(',
        'enqueueCreateMemoWithAttachmentUploads(',
        'buildCreateMemoOutboxPayload(',
      ];

      final violations = forbiddenPatterns
          .where((pattern) => contents.contains(pattern))
          .toList(growable: false);

      expect(
        violations,
        isEmpty,
        reason: violations.isEmpty
            ? null
            : 'Unexpected direct memo editor write calls in '
                  'memo_editor_controller.dart:\n${violations.join('\n')}',
      );
    },
  );
}

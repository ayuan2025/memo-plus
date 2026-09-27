import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'swashbuckler diary import controller delegates DB writes to mutation service',
    () async {
      final file = File(
        'lib/state/memos/swashbuckler_diary_import_controller.dart',
      );
      final contents = await file.readAsString();

      const forbiddenPatterns = <String>[
        'db.upsertImportHistory(',
        'db.updateImportHistory(',
        'db.upsertMemo(',
        'db.upsertMemoRelationsCache(',
        'db.enqueueOutbox(',
      ];

      final violations = forbiddenPatterns
          .where((pattern) => contents.contains(pattern))
          .toList(growable: false);

      expect(
        violations,
        isEmpty,
        reason: violations.isEmpty
            ? null
            : 'Unexpected direct swashbuckler diary import write calls in '
                  'swashbuckler_diary_import_controller.dart:\n'
                  '${violations.join('\n')}',
      );
    },
  );
}

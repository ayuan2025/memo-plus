import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'local library scan service delegates DB writes to mutation service',
    () async {
      final file = File('lib/application/sync/local_library_scan_service.dart');
      final contents = await file.readAsString();

      const forbiddenPatterns = <String>[
        'db.deleteOutboxForMemo(',
        'db.deleteMemoByUid(',
        'db.upsertMemo(',
        'db.deleteMemoRelationsCache(',
        'db.upsertMemoRelationsCache(',
      ];

      final violations = forbiddenPatterns
          .where((pattern) => contents.contains(pattern))
          .toList(growable: false);

      expect(
        violations,
        isEmpty,
        reason: violations.isEmpty
            ? null
            : 'Unexpected direct local library scan write calls in '
                  'local_library_scan_service.dart:\n${violations.join('\n')}',
      );
    },
  );
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'memo detail controller delegates memo writes to mutation service',
    () async {
      final file = File('lib/state/memos/memo_detail_controller.dart');
      final contents = await file.readAsString();

      const forbiddenPatterns = <String>['db.upsertMemo(', 'db.enqueueOutbox('];

      final violations = forbiddenPatterns
          .where((pattern) => contents.contains(pattern))
          .toList(growable: false);

      expect(
        violations,
        isEmpty,
        reason: violations.isEmpty
            ? null
            : 'Unexpected direct memo detail write calls in '
                  'memo_detail_controller.dart:\n${violations.join('\n')}',
      );
    },
  );
}

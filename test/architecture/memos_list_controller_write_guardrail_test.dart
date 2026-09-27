import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('memos list controller delegates memo writes to service', () async {
    final file = File('lib/state/memos/memos_list_controller.dart');
    final contents = await file.readAsString();

    const forbiddenPatterns = <String>[
      'db.upsertMemo(',
      'db.enqueueOutbox(',
      'db.retryOutboxErrors(',
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
          : 'Unexpected direct memo write calls in memos_list_controller.dart:\n'
                '${violations.join('\n')}',
    );
  });
}

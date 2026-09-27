import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('note input controller delegates memo writes to service', () async {
    final file = File('lib/state/memos/note_input_controller.dart');
    final contents = await file.readAsString();

    const forbiddenPatterns = <String>[
      'db.upsertMemo(',
      'db.enqueueOutbox(',
      'db.upsertMemoRelationsCache(',
      'db.deleteMemoRelationsCache(',
      'db.upsertMemoInlineImageSource(',
    ];

    final violations = forbiddenPatterns
        .where((pattern) => contents.contains(pattern))
        .toList(growable: false);

    expect(
      violations,
      isEmpty,
      reason: violations.isEmpty
          ? null
          : 'Unexpected direct memo write calls in note_input_controller.dart:\n'
                '${violations.join('\n')}',
    );
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('quick input service delegates DB writes to mutation service', () async {
    final file = File('lib/application/quick_input/quick_input_service.dart');
    final contents = await file.readAsString();

    const forbiddenPatterns = <String>[
      'db.upsertMemo(',
      'db.deleteMemoRelationsCache(',
      'db.upsertMemoRelationsCache(',
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
          : 'Unexpected direct quick input write calls in '
                'quick_input_service.dart:\n${violations.join('\n')}',
    );
  });
}

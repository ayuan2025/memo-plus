import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reminder scheduler delegates DB writes to mutation service', () async {
    final file = File('lib/state/system/reminder_scheduler.dart');
    final contents = await file.readAsString();

    const forbiddenPatterns = <String>[
      'db.upsertMemoReminder(',
      'db.deleteMemoReminder(',
    ];

    final violations = forbiddenPatterns
        .where((pattern) => contents.contains(pattern))
        .toList(growable: false);

    expect(
      violations,
      isEmpty,
      reason: violations.isEmpty
          ? null
          : 'Unexpected direct reminder write calls in '
                'reminder_scheduler.dart:\n${violations.join('\n')}',
    );
  });
}

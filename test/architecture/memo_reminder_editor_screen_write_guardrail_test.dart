import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'memo reminder editor delegates DB writes to mutation service',
    () async {
      final file = File(
        'lib/features/reminders/memo_reminder_editor_screen.dart',
      );
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
                  'memo_reminder_editor_screen.dart:\n${violations.join('\n')}',
      );
    },
  );
}

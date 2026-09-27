import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'reminder mutation service does not issue writes via direct databaseProvider reads',
    () async {
      final file = File('lib/state/system/reminder_mutation_service.dart');
      final contents = await file.readAsString();

      const forbiddenPatterns = <String>[
        'read(databaseProvider).upsertMemoReminder(',
        'read(databaseProvider).deleteMemoReminder(',
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
                  'reminder_mutation_service.dart:\n${violations.join('\n')}',
      );
    },
  );
}

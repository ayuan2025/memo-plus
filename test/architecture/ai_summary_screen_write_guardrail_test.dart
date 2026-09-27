import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'AI summary screen delegates memo writes to mutation services',
    () async {
      final file = File('lib/features/review/ai_summary_screen.dart');
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
            : 'Unexpected direct AI summary write calls in '
                  'ai_summary_screen.dart:\n${violations.join('\n')}',
      );
    },
  );
}

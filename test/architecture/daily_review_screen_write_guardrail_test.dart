import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'daily review screen delegates memo writes to mutation services',
    () async {
      final file = File('lib/features/review/daily_review_screen.dart');
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
            : 'Unexpected direct daily review write calls in '
                  'daily_review_screen.dart:\n${violations.join('\n')}',
      );
    },
  );
}

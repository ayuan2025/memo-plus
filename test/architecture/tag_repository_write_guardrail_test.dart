import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tag repository delegates tag writes to owner-only DAO', () async {
    final file = File('lib/state/tags/tag_repository.dart');
    final contents = await file.readAsString();

    const forbiddenPatterns = <String>['.transaction('];

    final violations = forbiddenPatterns
        .where((pattern) => contents.contains(pattern))
        .toList(growable: false);

    expect(
      violations,
      isEmpty,
      reason: violations.isEmpty
          ? null
          : 'Unexpected direct tag write transaction usage in '
                'tag_repository.dart:\n${violations.join('\n')}',
    );
  });

  test(
    'tag repository delegates tag table reads to persistence owner',
    () async {
      final file = File('lib/state/tags/tag_repository.dart');
      final contents = await file.readAsString();

      const forbiddenPatterns = <String>{
        ".query('tags'",
        ".query('tag_aliases'",
        ".rawQuery('SELECT",
      };

      final violations = forbiddenPatterns
          .where((pattern) => contents.contains(pattern))
          .toList(growable: false);

      expect(
        violations,
        isEmpty,
        reason: violations.isEmpty
            ? null
            : 'Tag repository should use TagDbPersistence for tag table reads:\n'
                  '${violations.join('\n')}',
      );
    },
  );
}

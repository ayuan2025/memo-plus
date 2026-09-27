import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('webdav backup import delegates DB writes to mutation service', () async {
    final file =
        File('lib/application/sync/webdav_backup/webdav_backup_import.dart');
    final contents = await file.readAsString();

    const forbiddenPatterns = <String>[
      '_db.clearOutbox(',
    ];

    final violations = forbiddenPatterns
        .where((pattern) => contents.contains(pattern))
        .toList(growable: false);

    expect(
      violations,
      isEmpty,
      reason: violations.isEmpty
          ? null
          : 'Unexpected direct WebDAV backup import write calls in '
                'webdav_backup_import.dart:\n${violations.join('\n')}',
    );
  });
}

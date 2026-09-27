import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'desktop settings and quick input runtimes do not call write-like databaseProvider methods',
    () async {
      const guardedFiles = <String>[
        'lib/features/settings/desktop_settings_window_app.dart',
        'lib/features/settings/webdav_sync_screen.dart',
        'lib/features/settings/vault_security_status_screen.dart',
        'lib/features/desktop/quick_input/desktop_quick_input_window.dart',
      ];

      final writeLikeMethodPattern = RegExp(
        r'(read|watch)\(databaseProvider\)\.'
        r'(insert|update|delete|upsert|replace|enqueue|mark|claim|clear|rewrite|save|invalidate|create|discard)[A-Za-z0-9_]*\s*\(',
      );

      final violations = <String>[];
      for (final path in guardedFiles) {
        final contents = await File(path).readAsString();
        if (writeLikeMethodPattern.hasMatch(contents)) {
          violations.add(path);
        }
      }

      expect(
        violations,
        isEmpty,
        reason: violations.isEmpty
            ? null
            : 'Unexpected direct write-like databaseProvider usage in desktop '
                  'subwindow runtime files:\n${violations.join('\n')}',
      );
    },
  );
}

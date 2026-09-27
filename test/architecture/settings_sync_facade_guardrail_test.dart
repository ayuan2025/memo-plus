import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'settings desktop runtime uses desktop sync facade instead of coordinator notifier',
    () async {
      const guardedFiles = <String>[
        'lib/features/settings/desktop_settings_window_app.dart',
        'lib/features/settings/webdav_sync_screen.dart',
        'lib/features/settings/vault_security_status_screen.dart',
      ];

      final violations = <String>[];
      for (final path in guardedFiles) {
        final contents = await File(path).readAsString();
        if (contents.contains('syncCoordinatorProvider.notifier')) {
          violations.add(path);
        }
      }

      expect(
        violations,
        isEmpty,
        reason: violations.isEmpty
            ? null
            : 'Unexpected direct coordinator notifier usage in settings '
                  'runtime files:\n${violations.join('\n')}',
      );
    },
  );
}

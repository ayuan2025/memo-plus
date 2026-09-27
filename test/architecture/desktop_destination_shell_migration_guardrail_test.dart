import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'migrated desktop destination pages use the unified destination shell',
    () async {
      const migratedPages = <String>[
        'lib/features/review/daily_review_screen.dart',
        'lib/features/explore/explore_screen.dart',
        'lib/features/review/ai_summary_screen.dart',
        'lib/features/tags/tags_screen.dart',
        'lib/features/resources/resources_screen.dart',
        'lib/features/notifications/notifications_screen.dart',
        'lib/features/about/about_screen.dart',
        'lib/features/collections/collections_screen.dart',
        'lib/features/memos/recycle_bin_screen.dart',
        'lib/features/settings/settings_screen.dart',
      ];

      final violations = <String>[];
      for (final relativePath in migratedPages) {
        final file = File(relativePath);
        if (!file.existsSync()) {
          violations.add('$relativePath: missing');
          continue;
        }

        final contents = await file.readAsString();
        if (!contents.contains('DesktopDestinationShell(')) {
          violations.add('$relativePath: missing DesktopDestinationShell');
        }
        if (contents.contains('DesktopShellHost(')) {
          violations.add(
            '$relativePath: still imports or builds DesktopShellHost',
          );
        }
        if (contents.contains('leadingTitle:')) {
          violations.add(
            '$relativePath: still defines a page-local leadingTitle',
          );
        }
        if (contents.contains('? DesktopShellHost(')) {
          violations.add('$relativePath: still branches on DesktopShellHost');
        }
      }

      expect(
        violations,
        isEmpty,
        reason: violations.isEmpty
            ? null
            : 'migrated top-level desktop destination pages must route through '
                  'the unified destination shell and keep title controls out of '
                  'page-local shell branches:\n${violations.join('\n')}',
      );
    },
  );
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'runtime appPreferences bridge usage stays confined to legacy adapter files',
    () async {
      final dartFiles = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList(growable: false);

      final providerAllowedFiles = <String>{
        'lib/state/settings/preferences_provider.dart',
      };
      final providerViolations = <String>[];

      final themeResolverAllowedFiles = <String>{
        'lib/data/models/app_preferences.dart',
      };
      final themeResolverViolations = <String>[];

      for (final file in dartFiles) {
        final normalizedPath = file.path.replaceAll('\\', '/');
        final contents = await file.readAsString();

        if (contents.contains('appPreferencesProvider') &&
            !providerAllowedFiles.contains(normalizedPath)) {
          providerViolations.add(normalizedPath);
        }

        final usesLegacyThemeResolver =
            contents.contains('resolveThemeColor(') ||
            contents.contains('resolveCustomTheme(');
        if (usesLegacyThemeResolver &&
            !themeResolverAllowedFiles.contains(normalizedPath)) {
          themeResolverViolations.add(normalizedPath);
        }
      }

      expect(
        providerViolations,
        isEmpty,
        reason: providerViolations.isEmpty
            ? null
            : 'Unexpected appPreferencesProvider runtime usage:\n'
                  '${providerViolations.join('\n')}',
      );

      expect(
        themeResolverViolations,
        isEmpty,
        reason: themeResolverViolations.isEmpty
            ? null
            : 'Unexpected legacy theme resolver usage:\n'
                  '${themeResolverViolations.join('\n')}',
      );
    },
  );
}

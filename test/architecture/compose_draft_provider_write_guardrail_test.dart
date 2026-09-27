import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'compose draft repository delegates DB writes to mutation service',
    () async {
      final file = File('lib/state/memos/compose_draft_provider.dart');
      final contents = await file.readAsString();

      const forbiddenPatterns = <String>[
        '_database.upsertComposeDraftRow(',
        '_database.deleteComposeDraft(',
        '_database.deleteComposeDraftsByWorkspace(',
        '_database.replaceComposeDraftRows(',
      ];

      final violations = forbiddenPatterns
          .where((pattern) => contents.contains(pattern))
          .toList(growable: false);

      expect(
        violations,
        isEmpty,
        reason: violations.isEmpty
            ? null
            : 'Unexpected direct compose draft DB write calls in '
                  'compose_draft_provider.dart:\n${violations.join('\n')}',
      );
    },
  );

  test('compose draft DB persistence stays in the data layer', () async {
    final files = <File>[File('lib/data/db/compose_draft_db_persistence.dart')];

    final violations = <String>[];
    for (final file in files) {
      final contents = await file.readAsString();
      for (final match in RegExp(
        r"^import '([^']+)';",
        multiLine: true,
      ).allMatches(contents)) {
        final importPath = match.group(1)!;
        if (importPath.startsWith('dart:')) {
          continue;
        }
        final normalized = importPath.replaceAll('\\', '/');
        if (normalized.startsWith('package:memos_flutter_app/features/') ||
            normalized.startsWith('package:memos_flutter_app/state/') ||
            normalized.startsWith('package:memos_flutter_app/application/') ||
            normalized.startsWith('../features/') ||
            normalized.startsWith('../../features/') ||
            normalized.startsWith('../state/') ||
            normalized.startsWith('../../state/') ||
            normalized.startsWith('../application/') ||
            normalized.startsWith('../../application/')) {
          violations.add('${file.path}: $importPath');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: violations.isEmpty
          ? null
          : 'Compose draft DB persistence must not import higher layers:\n'
                '${violations.join('\n')}',
    );
  });

  test(
    'feature and non-owner state/application code does not bypass draft mutations',
    () async {
      const ownerAllowlist = <String>{
        'lib/state/memos/compose_draft_mutation_service.dart',
      };
      const forbiddenMethods = <String>{
        'upsertComposeDraftRow',
        'replaceComposeDraftRows',
        'deleteComposeDraft',
        'deleteComposeDraftsByWorkspace',
      };

      final violations = <String>[];
      for (final root in const [
        'lib/features',
        'lib/state',
        'lib/application',
      ]) {
        final dir = Directory(root);
        if (!dir.existsSync()) continue;
        await for (final entry in dir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entry is! File || p.extension(entry.path) != '.dart') continue;
          final relative = p
              .relative(entry.path, from: Directory.current.path)
              .replaceAll('\\', '/');
          if (ownerAllowlist.contains(relative)) continue;

          final contents = await entry.readAsString();
          for (final method in forbiddenMethods) {
            if (contents.contains('.$method(')) {
              violations.add('$relative: $method');
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: violations.isEmpty
            ? null
            : 'Unexpected direct compose draft DB write calls outside '
                  'ComposeDraftMutationService:\n${violations.join('\n')}',
      );
    },
  );
}

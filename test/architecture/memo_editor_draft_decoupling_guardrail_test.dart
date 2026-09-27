import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'lower layers do not import memo editor or Draft Box presentation',
    () async {
      const forbiddenTargets = <String>{
        'lib/features/memos/memo_editor_screen.dart',
        'lib/features/memos/draft_box_screen.dart',
        'lib/features/memos/draft_box_navigation_screen.dart',
        'lib/features/memos/widgets/draft_box_memo_card.dart',
      };

      final violations = <String>[];
      for (final layer in const ['state', 'application', 'core']) {
        violations.addAll(
          await _findForbiddenImports(
            sourceLayer: layer,
            forbiddenTargets: forbiddenTargets,
          ),
        );
      }

      expect(
        violations,
        isEmpty,
        reason: violations.isEmpty
            ? null
            : 'Unexpected lower-layer imports of memo editor/Draft Box presentation:\n'
                  '${violations.join('\n')}',
      );
    },
  );

  test('memo editor edit-draft mapping stays in the state helper', () async {
    final helper = File('lib/state/memos/memo_editor_draft_session.dart');
    expect(await helper.exists(), isTrue);

    final screen = File('lib/features/memos/memo_editor_screen.dart');
    final contents = await screen.readAsString();
    const forbiddenPatterns = <String, String>{
      '_buildEditDraftSnapshot':
          'edit draft snapshot construction belongs to MemoEditorDraftSessionHelper',
      '_restoreEditDraftState':
          'edit draft restoration mapping belongs to MemoEditorDraftSessionHelper',
    };

    final violations = forbiddenPatterns.entries
        .where((entry) => contents.contains(entry.key))
        .map((entry) => '${entry.key}: ${entry.value}')
        .toList(growable: false);

    expect(
      violations,
      isEmpty,
      reason: violations.isEmpty
          ? null
          : 'Extracted edit draft responsibilities returned to memo_editor_screen.dart:\n'
                '${violations.join('\n')}',
    );
  });
}

Future<List<String>> _findForbiddenImports({
  required String sourceLayer,
  required Set<String> forbiddenTargets,
}) async {
  final libDir = Directory('lib');
  final violations = <String>[];

  await for (final entry in libDir.list(recursive: true, followLinks: false)) {
    if (entry is! File || p.extension(entry.path) != '.dart') continue;

    final source = p
        .relative(entry.path, from: Directory.current.path)
        .replaceAll('\\', '/');
    if (!source.startsWith('lib/$sourceLayer/')) continue;

    final contents = await entry.readAsString();
    for (final match in RegExp(
      r"^import '([^']+)';",
      multiLine: true,
    ).allMatches(contents)) {
      final target = _resolveLocalImport(source, match.group(1)!);
      if (target != null && forbiddenTargets.contains(target)) {
        violations.add('$source -> $target');
      }
    }
  }

  violations.sort();
  return violations;
}

String? _resolveLocalImport(String source, String importPath) {
  if (importPath.startsWith('package:memos_flutter_app/')) {
    return 'lib/${importPath.substring('package:memos_flutter_app/'.length)}';
  }
  if (importPath.startsWith('dart:') || importPath.startsWith('package:')) {
    return null;
  }
  if (importPath.startsWith('./') || importPath.startsWith('../')) {
    final resolved = p
        .normalize(p.join(p.dirname(source), importPath))
        .replaceAll('\\', '/');
    return resolved.startsWith('lib/') ? resolved : null;
  }

  const localRoots = <String>{
    'access_boundary',
    'application',
    'core',
    'data',
    'features',
    'i18n',
    'module_boundary',
    'platform_capabilities',
    'presentation',
    'private_hooks',
    'state',
  };
  for (final root in localRoots) {
    if (importPath.startsWith('$root/')) {
      return 'lib/$importPath';
    }
  }

  return null;
}

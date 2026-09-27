import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('lower layers do not import note input presentation internals', () async {
    const forbiddenTargets = <String>{
      'lib/features/memos/note_input_sheet.dart',
      'lib/features/memos/widgets/note_input_attachment_preview.dart',
      'lib/features/memos/widgets/note_input_compact_widgets.dart',
      'lib/features/memos/widgets/note_input_fullscreen_compose.dart',
      'lib/features/memos/widgets/memo_compose_fullscreen_surface.dart',
    };
    const allowedLegacyImports = <String>{
      'lib/application/startup/startup_coordinator.dart -> lib/features/memos/note_input_sheet.dart',
    };

    final violations = <String>[];
    for (final layer in const ['state', 'application', 'core']) {
      violations.addAll(
        await _findForbiddenImports(
          sourceLayer: layer,
          forbiddenTargets: forbiddenTargets,
          allowed: allowedLegacyImports,
        ),
      );
    }

    expect(
      violations,
      isEmpty,
      reason: violations.isEmpty
          ? null
          : 'Unexpected lower-layer imports of note input presentation:\n'
                '${violations.join('\n')}',
    );
  });

  test('note input sheet does not re-own extracted shared responsibilities', () async {
    final file = File('lib/features/memos/note_input_sheet.dart');
    final contents = await file.readAsString();

    const forbiddenPatterns = <String, String>{
      '_buildCurrentDraftSnapshot':
          'draft snapshot construction belongs to NoteInputDraftSessionHelper',
      '_linkedMemosFromRelations':
          'relation restore mapping belongs to NoteInputDraftSessionHelper',
      '_requestSyncBestEffort':
          'best-effort sync belongs to NoteInputSubmitCoordinator',
      'extractTags(':
          'submit tag extraction belongs to note input submit preparation',
      'downloadDeferredInlineImageAttachment(':
          'deferred inline downloads belong to ShareDeferredInlineImageCoordinator',
      '_DeferredShareVideoTask':
          'deferred video state belongs to ShareDeferredVideoCoordinator',
      '_DeferredShareVideoPhase':
          'deferred video state belongs to ShareDeferredVideoCoordinator',
      '_DeferredShareVideoFailure':
          'deferred video failure state belongs to ShareDeferredVideoCoordinator',
      '_guessMimeType':
          'MIME guessing belongs to core/attachment_mime_type.dart',
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
          : 'Extracted shared responsibilities returned to note_input_sheet.dart:\n'
                '${violations.join('\n')}',
    );
  });
}

Future<List<String>> _findForbiddenImports({
  required String sourceLayer,
  required Set<String> forbiddenTargets,
  required Set<String> allowed,
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
      if (target == null || !forbiddenTargets.contains(target)) continue;

      final violation = '$source -> $target';
      if (!allowed.contains(violation)) {
        violations.add(violation);
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

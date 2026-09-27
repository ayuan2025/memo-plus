import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'desktop memo editor opening stays behind the memos feature seam',
    () async {
      final appSource = await File('lib/app.dart').readAsString();
      expect(
        appSource,
        isNot(contains("features/memos/memo_editor_screen.dart")),
      );
      expect(appSource, isNot(contains('MemoEditorScreen(')));
      expect(
        appSource,
        contains('MemosListScreen.openNewMemoInCurrentDesktopHome'),
      );

      final memosListSource = await File(
        'lib/features/memos/memos_list_screen.dart',
      ).readAsString();
      expect(memosListSource, contains('DesktopMemoEditorIntent'));
      expect(memosListSource, contains('bool _openDesktopMemoEditor'));
      expect(memosListSource, contains('openEditor: _openMemoEditor'));

      final desktopPresentationSource = await File(
        'lib/features/memos/memos_list_desktop_presentation.dart',
      ).readAsString();
      expect(desktopPresentationSource, contains('isWindows || isMacos'));
    },
  );

  test(
    'lower layers do not own desktop memo editor UI opening policy',
    () async {
      final violations = <String>[];
      for (final layer in const <String>['core', 'application', 'state']) {
        final root = Directory('lib/$layer');
        if (!root.existsSync()) continue;
        for (final entity in root.listSync(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.dart')) continue;
          final source = await entity.readAsString();
          if (source.contains('desktop_memo_editor_intent.dart') ||
              source.contains('memo_editor_screen.dart') ||
              source.contains('MemoEditorScreen(')) {
            violations.add(entity.path.replaceAll('\\', '/'));
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: violations.isEmpty
            ? null
            : 'Desktop memo editor opening policy must stay out of lower '
                  'layers:\n${violations.join('\n')}',
      );
    },
  );
}

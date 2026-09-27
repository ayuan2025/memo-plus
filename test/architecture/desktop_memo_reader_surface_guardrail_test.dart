import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'desktop memo reader opening stays behind the memos feature seam',
    () async {
      final memosListSource = await File(
        'lib/features/memos/memos_list_screen.dart',
      ).readAsString();
      final previewPaneSource = await File(
        'lib/features/memos/widgets/memos_list_desktop_preview_pane.dart',
      ).readAsString();

      expect(memosListSource, contains('DesktopMemoReaderIntent'));
      expect(memosListSource, contains('bool _openDesktopMemoReader'));
      expect(memosListSource, contains('DesktopMemoReaderSurface'));
      expect(previewPaneSource, contains('onOpenMemo'));
      expect(previewPaneSource, isNot(contains('Navigator.push')));
      expect(previewPaneSource, isNot(contains('MemoDetailScreen(')));
    },
  );

  test(
    'lower layers do not own desktop memo reader UI opening policy',
    () async {
      final violations = <String>[];
      for (final layer in const <String>['core', 'application', 'state']) {
        final root = Directory('lib/$layer');
        if (!root.existsSync()) continue;
        for (final entity in root.listSync(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.dart')) continue;
          final source = await entity.readAsString();
          if (source.contains('desktop_memo_reader_intent.dart') ||
              source.contains('desktop_memo_reader_surface.dart') ||
              source.contains('DesktopMemoReaderSurface(')) {
            violations.add(entity.path.replaceAll('\\', '/'));
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: violations.isEmpty
            ? null
            : 'Desktop memo reader opening policy must stay out of lower '
                  'layers:\n${violations.join('\n')}',
      );
    },
  );

  test(
    'memo reader and fallback detail use shared chrome safe-area seam',
    () async {
      final readerSurface = await File(
        'lib/features/memos/desktop_memo_reader_surface.dart',
      ).readAsString();
      final detailView = await File(
        'lib/features/memos/memo_detail_view.dart',
      ).readAsString();

      expect(readerSurface, contains('window_chrome_safe_area.dart'));
      expect(readerSurface, contains('resolveDesktopWindowChromeInsets'));
      expect(readerSurface, isNot(contains('kMacosTrafficLightReservedWidth')));

      expect(detailView, contains('window_chrome_safe_area.dart'));
      expect(detailView, contains('DesktopWindowChromeSafeArea'));
      expect(detailView, contains('resolveDesktopWindowChromeInsets'));
      expect(detailView, isNot(contains('kMacosTrafficLightReservedWidth')));
    },
  );
}

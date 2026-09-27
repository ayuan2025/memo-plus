import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/memo_clip_markdown.dart';

void main() {
  group('parseMemoClipMarkdown', () {
    test('extracts first markdown heading as title', () {
      final parts = parseMemoClipMarkdown('# 标题\n\n正文第一段\n\n正文第二段');

      expect(parts.hasExplicitTitle, isTrue);
      expect(parts.title, '标题');
      expect(parts.body, '正文第一段\n\n正文第二段');
    });

    test('does not treat later heading as clip title', () {
      final parts = parseMemoClipMarkdown('普通正文\n\n# 后续标题\n\n更多内容');

      expect(parts.hasExplicitTitle, isFalse);
      expect(parts.title, isNull);
      expect(parts.body, '普通正文\n\n# 后续标题\n\n更多内容');
    });

    test('removes only the first heading block when stripping', () {
      final stripped = stripMemoClipTitle('# Title\n\nBody\n\n# Inner Heading');

      expect(stripped, 'Body\n\n# Inner Heading');
    });
  });
}

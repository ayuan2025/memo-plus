import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/features/memos/memo_markdown.dart';

void main() {
  test('stripTaskListToggleHint keeps title and removes hint suffix', () {
    const content =
        '\u4efb\u52a1\u5217\u8868\uff08\u53ef\u70b9\u51fb\u5207\u6362\uff09\n- [ ] \u672a\u5b8c\u6210\u4efb\u52a1\n- [x] \u5df2\u5b8c\u6210\u4efb\u52a1';

    expect(
      stripTaskListToggleHint(content),
      '\u4efb\u52a1\u5217\u8868\n- [ ] \u672a\u5b8c\u6210\u4efb\u52a1\n- [x] \u5df2\u5b8c\u6210\u4efb\u52a1',
    );
  });

  test('stripTaskListToggleHint keeps unrelated lines unchanged', () {
    const content =
        '\u4efb\u52a1\u5217\u8868\n- [ ] \u672a\u5b8c\u6210\u4efb\u52a1';

    expect(stripTaskListToggleHint(content), content);
  });

  testWidgets('MemoMarkdown renders task list title without hint suffix', (
    WidgetTester tester,
  ) async {
    const content =
        '\u4efb\u52a1\u5217\u8868\uff08\u53ef\u70b9\u51fb\u5207\u6362\uff09\n- [ ] \u672a\u5b8c\u6210\u4efb\u52a1\n- [x] \u5df2\u5b8c\u6210\u4efb\u52a1';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MemoMarkdown(data: content)),
      ),
    );
    await tester.pumpAndSettle();

    final rendered = _collectRenderedText(tester);

    expect(
      rendered,
      isNot(
        contains(
          '\u4efb\u52a1\u5217\u8868\uff08\u53ef\u70b9\u51fb\u5207\u6362\uff09',
        ),
      ),
    );
    expect(rendered, contains('\u4efb\u52a1\u5217\u8868'));
    expect(rendered, contains('\u672a\u5b8c\u6210\u4efb\u52a1'));
    expect(rendered, contains('\u5df2\u5b8c\u6210\u4efb\u52a1'));
  });
}

String _collectRenderedText(WidgetTester tester) {
  final buffer = StringBuffer();
  for (final richText in tester.widgetList<RichText>(find.byType(RichText))) {
    final value = richText.text.toPlainText();
    if (value.isNotEmpty) {
      buffer.writeln(value);
    }
  }
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    final span = text.textSpan;
    final value = span?.toPlainText() ?? text.data;
    if (value != null && value.isNotEmpty) {
      buffer.writeln(value);
    }
  }
  return buffer.toString();
}

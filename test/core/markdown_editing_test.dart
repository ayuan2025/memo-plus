import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/markdown_editing.dart';

TextEditingValue _value(String text, {required TextSelection selection}) {
  return TextEditingValue(text: text, selection: selection);
}

TextEditingValue _collapsedValue(String text, {int? offset}) {
  return _value(
    text,
    selection: TextSelection.collapsed(offset: offset ?? text.length),
  );
}

void main() {
  group('SmartEnterController.applySmartEnterKeyPress', () {
    test('continues unordered list items', () {
      final result = SmartEnterController.applySmartEnterKeyPress(
        _collapsedValue('- item'),
      );

      expect(result, isNotNull);
      expect(result!.text, '- item\n- ');
      expect(result.selection, const TextSelection.collapsed(offset: 9));
    });

    test('increments ordered list items', () {
      final result = SmartEnterController.applySmartEnterKeyPress(
        _collapsedValue('1. item'),
      );

      expect(result, isNotNull);
      expect(result!.text, '1. item\n2. ');
      expect(result.selection, const TextSelection.collapsed(offset: 11));
    });

    test('increments multi-digit ordered list items', () {
      final result = SmartEnterController.applySmartEnterKeyPress(
        _collapsedValue('9. item'),
      );

      expect(result, isNotNull);
      expect(result!.text, '9. item\n10. ');
      expect(result.selection, const TextSelection.collapsed(offset: 12));
    });

    test('preserves indentation while incrementing ordered list items', () {
      final result = SmartEnterController.applySmartEnterKeyPress(
        _collapsedValue('  3. item'),
      );

      expect(result, isNotNull);
      expect(result!.text, '  3. item\n  4. ');
      expect(result.selection, const TextSelection.collapsed(offset: 15));
    });

    test('continues unchecked task list items', () {
      final result = SmartEnterController.applySmartEnterKeyPress(
        _collapsedValue('- [ ] item'),
      );

      expect(result, isNotNull);
      expect(result!.text, '- [ ] item\n- [ ] ');
      expect(result.selection, const TextSelection.collapsed(offset: 17));
    });

    test('resets checked task list items to unchecked', () {
      final result = SmartEnterController.applySmartEnterKeyPress(
        _collapsedValue('- [x] done'),
      );

      expect(result, isNotNull);
      expect(result!.text, '- [x] done\n- [ ] ');
      expect(result.selection, const TextSelection.collapsed(offset: 17));
    });

    test('exits empty ordered list items', () {
      final result = SmartEnterController.applySmartEnterKeyPress(
        _collapsedValue('2. '),
      );

      expect(result, isNotNull);
      expect(result!.text, '\n');
      expect(result.selection, const TextSelection.collapsed(offset: 1));
    });

    test('exits empty unchecked task list items', () {
      final result = SmartEnterController.applySmartEnterKeyPress(
        _collapsedValue('- [ ] '),
      );

      expect(result, isNotNull);
      expect(result!.text, '\n');
      expect(result.selection, const TextSelection.collapsed(offset: 1));
    });

    test('exits empty checked task list items', () {
      final result = SmartEnterController.applySmartEnterKeyPress(
        _collapsedValue('- [x] '),
      );

      expect(result, isNotNull);
      expect(result!.text, '\n');
      expect(result.selection, const TextSelection.collapsed(offset: 1));
    });

    test('increments ordered list items with CRLF line breaks', () {
      final result = SmartEnterController.applySmartEnterKeyPress(
        _collapsedValue('9. item'),
        lineBreak: '\r\n',
      );

      expect(result, isNotNull);
      expect(result!.text, '9. item\r\n10. ');
      expect(result.selection, const TextSelection.collapsed(offset: 13));
    });
  });

  group('wrapMarkdownSelection', () {
    test(
      'unwraps when the selected content is already wrapped by matching markers',
      () {
        final value = wrapMarkdownSelection(
          _value(
            '**hello**',
            selection: const TextSelection(baseOffset: 2, extentOffset: 7),
          ),
          prefix: '**',
          suffix: '**',
        );

        expect(value.text, 'hello');
        expect(
          value.selection,
          const TextSelection(baseOffset: 0, extentOffset: 5),
        );
      },
    );

    test('unwraps when the full wrapped range is selected', () {
      final value = wrapMarkdownSelection(
        _value(
          '~~hello~~',
          selection: const TextSelection(baseOffset: 0, extentOffset: 9),
        ),
        prefix: '~~',
        suffix: '~~',
      );

      expect(value.text, 'hello');
      expect(
        value.selection,
        const TextSelection(baseOffset: 0, extentOffset: 5),
      );
    });

    test('unwraps when the cursor is inside matching wrapped content', () {
      final value = wrapMarkdownSelection(
        _value(
          '<u>hello</u>',
          selection: const TextSelection.collapsed(offset: 5),
        ),
        prefix: '<u>',
        suffix: '</u>',
      );

      expect(value.text, 'hello');
      expect(value.selection, const TextSelection.collapsed(offset: 2));
    });

    test(
      'unwraps an empty wrapper when the cursor is between inserted markers',
      () {
        final value = wrapMarkdownSelection(
          _value('====', selection: const TextSelection.collapsed(offset: 2)),
          prefix: '==',
          suffix: '==',
        );

        expect(value.text, '');
        expect(value.selection, const TextSelection.collapsed(offset: 0));
      },
    );

    test('does not confuse bold markers as italic wrappers', () {
      final value = wrapMarkdownSelection(
        _value(
          '**hello**',
          selection: const TextSelection(baseOffset: 2, extentOffset: 7),
        ),
        prefix: '*',
        suffix: '*',
      );

      expect(value.text, '***hello***');
      expect(
        value.selection,
        const TextSelection(baseOffset: 2, extentOffset: 9),
      );
    });

    test(
      'unwraps an empty bold wrapper when the cursor is between inserted markers',
      () {
        final value = wrapMarkdownSelection(
          _value('****', selection: const TextSelection.collapsed(offset: 2)),
          prefix: '**',
          suffix: '**',
        );

        expect(value.text, '');
        expect(value.selection, const TextSelection.collapsed(offset: 0));
      },
    );
  });

  group('selectedLogicalParagraphs', () {
    test('finds the logical paragraph for a collapsed cursor', () {
      const text = 'first line\nsecond line\n\nthird';

      final paragraphs = selectedLogicalParagraphs(
        text,
        const TextSelection.collapsed(offset: 8),
      );

      expect(paragraphs, hasLength(1));
      expect(
        text.substring(paragraphs.single.start, paragraphs.single.end),
        'first line\nsecond line',
      );
    });

    test('collects every paragraph intersecting an expanded selection', () {
      const text = 'first\n\nsecond\n\nthird';

      final paragraphs = selectedLogicalParagraphs(
        text,
        const TextSelection(baseOffset: 1, extentOffset: 13),
      );

      expect(
        paragraphs
            .map((paragraph) => text.substring(paragraph.start, paragraph.end))
            .toList(),
        <String>['first', 'second'],
      );
    });
  });

  group('toggleBlockStyle', () {
    test(
      'inserts heading prefix at a blank new line instead of restyling the previous paragraph',
      () {
        const text = '==abc==\n';

        final value = toggleBlockStyle(
          _value(text, selection: TextSelection.collapsed(offset: text.length)),
          MarkdownBlockStyle.heading1,
        );

        expect(value.text, '==abc==\n# ');
        expect(value.selection, const TextSelection.collapsed(offset: 10));
      },
    );

    test(
      'toggles unordered lists from a cursor in the middle of a paragraph',
      () {
        const text = 'first line\nsecond line\n\nthird';

        final listed = toggleBlockStyle(
          _value(text, selection: const TextSelection.collapsed(offset: 7)),
          MarkdownBlockStyle.unorderedList,
        );
        expect(listed.text, '- first line\nsecond line\n\nthird');

        final plain = toggleBlockStyle(
          listed,
          MarkdownBlockStyle.unorderedList,
        );
        expect(plain.text, text);
      },
    );

    test(
      'toggles unordered lists on the current line for a collapsed cursor',
      () {
        const text = '11111\n2222';

        final listed = toggleBlockStyle(
          _value(
            text,
            selection: const TextSelection.collapsed(offset: text.length),
          ),
          MarkdownBlockStyle.unorderedList,
        );
        expect(listed.text, '11111\n- 2222');

        final plain = toggleBlockStyle(
          listed,
          MarkdownBlockStyle.unorderedList,
        );
        expect(plain.text, text);
      },
    );

    test(
      'toggles ordered lists on the current line for a collapsed cursor',
      () {
        const text = '11111\n2222';

        final listed = toggleBlockStyle(
          _value(
            text,
            selection: const TextSelection.collapsed(offset: text.length),
          ),
          MarkdownBlockStyle.orderedList,
        );
        expect(listed.text, '11111\n1. 2222');

        final plain = toggleBlockStyle(listed, MarkdownBlockStyle.orderedList);
        expect(plain.text, text);
      },
    );

    test('toggles task lists on the current line for a collapsed cursor', () {
      const text = '11111\n2222';

      final listed = toggleBlockStyle(
        _value(
          text,
          selection: const TextSelection.collapsed(offset: text.length),
        ),
        MarkdownBlockStyle.taskList,
      );
      expect(listed.text, '11111\n- [ ] 2222');

      final plain = toggleBlockStyle(listed, MarkdownBlockStyle.taskList);
      expect(plain.text, text);
    });

    test('replaces headings instead of stacking them', () {
      final converted = toggleBlockStyle(
        _value('# Title', selection: const TextSelection.collapsed(offset: 3)),
        MarkdownBlockStyle.heading2,
      );
      expect(converted.text, '## Title');

      final plain = toggleBlockStyle(converted, MarkdownBlockStyle.heading2);
      expect(plain.text, 'Title');
    });

    test('toggles headings on the current line for a collapsed cursor', () {
      const text = '11111\n2222';
      final cases = <MarkdownBlockStyle, String>{
        MarkdownBlockStyle.heading1: '# ',
        MarkdownBlockStyle.heading2: '## ',
        MarkdownBlockStyle.heading3: '### ',
      };

      for (final entry in cases.entries) {
        final styled = toggleBlockStyle(
          _value(
            text,
            selection: const TextSelection.collapsed(offset: text.length),
          ),
          entry.key,
        );
        expect(
          styled.text,
          '11111\n${entry.value}2222',
          reason: 'expected ${entry.key} to affect only the current line',
        );

        final plain = toggleBlockStyle(styled, entry.key);
        expect(plain.text, text, reason: 'expected ${entry.key} to toggle off');
      }
    });

    test('toggles quotes on the current line for a collapsed cursor', () {
      const text = '11111\n2222';

      final quoted = toggleBlockStyle(
        _value(
          text,
          selection: const TextSelection.collapsed(offset: text.length),
        ),
        MarkdownBlockStyle.quote,
      );
      expect(quoted.text, '11111\n> 2222');

      final plain = toggleBlockStyle(quoted, MarkdownBlockStyle.quote);
      expect(plain.text, text);
    });

    test('quotes and unquotes every line in selected logical paragraphs', () {
      const text = 'line 1\nline 2\n\nnext';

      final quoted = toggleBlockStyle(
        _value(
          text,
          selection: const TextSelection(baseOffset: 0, extentOffset: 10),
        ),
        MarkdownBlockStyle.quote,
      );
      expect(quoted.text, '> line 1\n> line 2\n\nnext');

      final plain = toggleBlockStyle(quoted, MarkdownBlockStyle.quote);
      expect(plain.text, text);
    });

    test(
      'still uses logical paragraph toggling when there is text before the cursor',
      () {
        const text = 'abc';

        final value = toggleBlockStyle(
          _value(text, selection: const TextSelection.collapsed(offset: 2)),
          MarkdownBlockStyle.heading2,
        );

        expect(value.text, '## abc');
      },
    );
  });

  test(
    'insertBlockSnippet preserves block boundaries around inserted content',
    () {
      final inserted = insertBlockSnippet(
        _value(
          'before\nafter',
          selection: const TextSelection.collapsed(offset: 6),
        ),
        '---',
        caretOffset: 3,
      );

      expect(inserted.text, 'before\n\n---\n\nafter');
      expect(inserted.selection, const TextSelection.collapsed(offset: 11));
    },
  );

  group('cutParagraphs', () {
    test('cuts the current line when cursor is on a later line', () {
      const text = '11111\n2222\n\n3333';

      final result = cutParagraphs(
        _value(text, selection: const TextSelection.collapsed(offset: 8)),
      );

      expect(result, isNotNull);
      expect(result!.copiedText, '2222');
      expect(result.value.text, '11111\n\n3333');
      expect(result.value.selection, const TextSelection.collapsed(offset: 6));
    });

    test(
      'cuts a middle paragraph and leaves one blank line between neighbors',
      () {
        const text = 'first\n\nsecond line\nsecond 2\n\nthird';

        final result = cutParagraphs(
          _value(
            text,
            selection: const TextSelection(baseOffset: 8, extentOffset: 28),
          ),
        );

        expect(result, isNotNull);
        expect(result!.copiedText, 'second line\nsecond 2');
        expect(result.value.text, 'first\n\nthird');
        expect(
          result.value.selection,
          const TextSelection.collapsed(offset: 5),
        );
      },
    );

    test('cuts multiple selected paragraphs and preserves copied spacing', () {
      const text = 'first\n\nsecond\n\nthird';

      final result = cutParagraphs(
        _value(
          text,
          selection: const TextSelection(baseOffset: 1, extentOffset: 13),
        ),
      );

      expect(result, isNotNull);
      expect(result!.copiedText, 'first\n\nsecond');
      expect(result.value.text, 'third');
      expect(result.value.selection, const TextSelection.collapsed(offset: 0));
    });
  });
}

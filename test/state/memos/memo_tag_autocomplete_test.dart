import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/state/memos/memo_tag_autocomplete.dart';
import 'package:memos_flutter_app/state/memos/memos_providers.dart';

void main() {
  group('memo tag autocomplete', () {
    test('detects active tag query at collapsed selection', () {
      const value = TextEditingValue(
        text: 'See #work',
        selection: TextSelection.collapsed(offset: 9),
      );

      final query = detectActiveTagQuery(value);

      expect(query, isNotNull);
      expect(query!.start, 4);
      expect(query.end, 9);
      expect(query.query, 'work');
    });

    test('ignores non-collapsed selection and invalid partial tags', () {
      const selected = TextEditingValue(
        text: 'See #work',
        selection: TextSelection(baseOffset: 5, extentOffset: 9),
      );
      const invalid = TextEditingValue(
        text: 'See #bad#tag',
        selection: TextSelection.collapsed(offset: 12),
      );

      expect(detectActiveTagQuery(selected), isNull);
      expect(detectActiveTagQuery(invalid), isNull);
    });

    test(
      'ranks suggestions by match quality, pinned flag, count, and path',
      () {
        const tags = <TagStat>[
          TagStat(tag: 'personal', path: 'personal', count: 8),
          TagStat(tag: 'work', path: 'work', count: 3),
          TagStat(tag: 'world', path: 'world', count: 6),
          TagStat(tag: 'alpha', path: 'team/work', count: 20),
          TagStat(tag: 'work', path: 'archive/work', count: 1, pinned: true),
        ];

        final suggestions = buildTagSuggestions(tags, query: 'wo');

        expect(suggestions.map((tag) => tag.path).toList(), <String>[
          'archive/work',
          'team/work',
          'world',
          'work',
        ]);
      },
    );

    test('deduplicates paths and honors limit', () {
      const tags = <TagStat>[
        TagStat(tag: 'work', path: 'work', count: 1),
        TagStat(tag: 'work duplicate', path: 'work', count: 99),
        TagStat(tag: 'world', path: 'world', count: 2),
      ];

      final suggestions = buildTagSuggestions(tags, query: 'wo', limit: 1);

      expect(suggestions.map((tag) => tag.path).toList(), <String>['world']);
    });
  });
}

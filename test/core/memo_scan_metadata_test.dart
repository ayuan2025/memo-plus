import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/memo_scan_metadata.dart';

void main() {
  group('sanitizeScanTitle', () {
    test('collapses whitespace so a title can never span two lines', () {
      expect(sanitizeScanTitle('  购物\n清单  '), '购物 清单');
      expect(sanitizeScanTitle('a\t\tb'), 'a b');
    });

    test('strips the decoration a model tends to wrap a title in', () {
      expect(sanitizeScanTitle('# 购物清单'), '购物清单');
      expect(sanitizeScanTitle('## Shopping List'), 'Shopping List');
      expect(sanitizeScanTitle('`Receipt`'), 'Receipt');
      expect(sanitizeScanTitle('"Report"'), 'Report');
      expect(sanitizeScanTitle('- Note'), 'Note');
    });

    test('truncates past the cap by rune, not by UTF-16 unit', () {
      final long = '字' * (kScanMetadataMaxTitleChars + 10);
      expect(sanitizeScanTitle(long).runes.length, kScanMetadataMaxTitleChars);

      // An emoji is two UTF-16 units; counting units would cut this short.
      final emoji = '😀' * (kScanMetadataMaxTitleChars + 5);
      expect(sanitizeScanTitle(emoji).runes.length, kScanMetadataMaxTitleChars);
    });

    test('returns empty for values that carry no title', () {
      expect(sanitizeScanTitle(null), '');
      expect(sanitizeScanTitle(''), '');
      expect(sanitizeScanTitle('#'), '');
      expect(sanitizeScanTitle('   '), '');
      expect(sanitizeScanTitle(const <String>['a']), '');
    });

    test('accepts numbers rather than discarding a usable answer', () {
      expect(sanitizeScanTitle(2026), '2026');
    });
  });

  group('sanitizeScanTags', () {
    test('drops the # the model volunteered', () {
      expect(sanitizeScanTags(<String>['#发票', '##收据']), <String>['发票', '收据']);
    });

    test(
      'removes whitespace and Markdown punctuation that would break tags',
      () {
        expect(sanitizeScanTags(<String>['购物 清单', 'a*b', 'c_d-e/f']), <String>[
          '购物清单',
          'ab',
          'c_d-e/f',
        ]);
      },
    );

    test('deduplicates case-insensitively and keeps the first spelling', () {
      expect(
        sanitizeScanTags(<String>['Receipt', 'receipt', 'RECEIPT']),
        <String>['Receipt'],
      );
    });

    test('caps the count', () {
      final tags = sanitizeScanTags(List<String>.generate(12, (i) => 'tag$i'));
      expect(tags, hasLength(kScanMetadataMaxTags));
      expect(tags.first, 'tag0');
    });

    test('caps each tag by rune', () {
      final tags = sanitizeScanTags(<String>['标' * 60]);
      expect(tags.single.runes.length, kScanMetadataMaxTagChars);
    });

    test('splits a string answer the model separated itself', () {
      expect(sanitizeScanTags('发票, 报销 2026'), <String>['发票', '报销', '2026']);
    });

    test('returns empty for unsupported shapes', () {
      expect(sanitizeScanTags(null), isEmpty);
      expect(sanitizeScanTags(42), isEmpty);
      expect(sanitizeScanTags(<String>['   ', '###']), isEmpty);
      expect(
        sanitizeScanTags(<String>['/']),
        isEmpty,
        reason: 'a lone slash is not a tag',
      );
    });
  });

  group('parseScanMetadataResponse', () {
    test('reads a plain JSON object', () {
      final draft = parseScanMetadataResponse(
        '{"title": "购物清单", "tags": ["购物", "清单"]}',
      );
      expect(draft, isNotNull);
      expect(draft!.title, '购物清单');
      expect(draft.tags, <String>['购物', '清单']);
    });

    test('reads through the prose and fences a model wraps it in', () {
      final draft = parseScanMetadataResponse(
        '好的，这是结果：\n```json\n{"title": "发票", "tags": ["报销"]}\n```\n'
        '希望对你有帮助。',
      );
      expect(draft?.title, '发票');
      expect(draft?.tags, <String>['报销']);
    });

    test('keeps a usable half rather than discarding the whole answer', () {
      final draft = parseScanMetadataResponse('{"title": "发票"}');
      expect(draft?.title, '发票');
      expect(draft?.tags, isEmpty);
    });

    test('returns null when nothing usable came back', () {
      expect(parseScanMetadataResponse(''), isNull);
      expect(parseScanMetadataResponse('抱歉，我无法识别这张图片。'), isNull);
      expect(parseScanMetadataResponse('{"title": "'), isNull);
      expect(parseScanMetadataResponse('{"title": "  ", "tags": []}'), isNull);
      expect(parseScanMetadataResponse('[1, 2, 3]'), isNull);
    });
  });

  group('applyScanMetadataToContent', () {
    test('writes the title as a Markdown H1, then tags, and a 扫描件 tag', () {
      expect(
        applyScanMetadataToContent(
          content: '',
          title: '购物清单',
          tags: <String>['购物', '清单'],
        ),
        '# 购物清单\n\n#购物 #清单 #扫描件',
      );
    });

    test('keeps what the user already typed underneath', () {
      expect(
        applyScanMetadataToContent(
          content: '  记得买牛奶  ',
          title: '购物清单',
          tags: <String>['购物'],
        ),
        '# 购物清单\n\n#购物 #扫描件\n\n记得买牛奶',
      );
    });

    test('handles a title or a tag list on its own', () {
      expect(
        applyScanMetadataToContent(content: '', title: '标题', tags: const []),
        '# 标题\n\n#扫描件',
      );
      expect(
        applyScanMetadataToContent(content: '', title: '', tags: <String>['a']),
        '#a #扫描件',
      );
    });

    test('appends 扫描件 even when no other tag or title is present', () {
      expect(
        applyScanMetadataToContent(content: '原文', title: '', tags: const []),
        '#扫描件\n\n原文',
      );
    });

    test('does not duplicate an existing 扫描件 tag', () {
      expect(
        applyScanMetadataToContent(
          content: '',
          title: '',
          tags: <String>['扫描件'],
        ),
        '#扫描件',
      );
    });

    test('leaves the content untouched when there is nothing to add', () {
      expect(
        applyScanMetadataToContent(content: '原文', title: '', tags: const []),
        '#扫描件\n\n原文',
      );
    });
  });

  group('hidden scan OCR block', () {
    test('wrap and extract round-trips, and strip removes it', () {
      const ocr = '发票金额 ￥128.00\n谢谢惠顾';
      final wrapped = wrapHiddenScanOcr(ocr);
      expect(wrapped, '<!--scan-ocr\n$ocr\n-->');
      expect(hasHiddenScanOcr(wrapped), isTrue);
      expect(extractHiddenScanOcr(wrapped), ocr);
      expect(stripHiddenScanOcr(wrapped), '');
    });

    test('extract and strip are no-ops without the marker', () {
      expect(extractHiddenScanOcr('普通笔记内容'), '');
      expect(stripHiddenScanOcr('普通笔记内容'), '普通笔记内容');
      expect(hasHiddenScanOcr('普通笔记内容'), isFalse);
    });

    test('withHiddenScanOcr appends only when ocr is non-empty', () {
      expect(withHiddenScanOcr('可见正文', ''), '可见正文');
      expect(
        withHiddenScanOcr('可见正文', '隐藏文字'),
        '可见正文\n\n<!--scan-ocr\n隐藏文字\n-->',
      );
    });
  });
}

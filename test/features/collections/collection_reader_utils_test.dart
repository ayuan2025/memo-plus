import 'package:flutter_test/flutter_test.dart';

import 'package:memos_flutter_app/data/models/collection_reader.dart';
import 'package:memos_flutter_app/data/models/local_memo.dart';
import 'package:memos_flutter_app/features/collections/collection_reader_page_models.dart';
import 'package:memos_flutter_app/features/collections/collection_reader_utils.dart';

void main() {
  LocalMemo buildMemo({
    required String uid,
    required String content,
    DateTime? createTime,
    DateTime? displayTime,
    DateTime? updateTime,
  }) {
    final created = createTime ?? DateTime(2026, 4, 12, 9, 30);
    return LocalMemo(
      uid: uid,
      content: content,
      contentFingerprint: 'fingerprint-$uid',
      visibility: 'PRIVATE',
      pinned: false,
      state: 'NORMAL',
      createTime: created,
      displayTime: displayTime,
      updateTime: updateTime ?? created.add(const Duration(hours: 2)),
      tags: const <String>[],
      attachments: const [],
      relationCount: 0,
      location: null,
      syncState: SyncState.synced,
      lastError: null,
    );
  }

  test('toc title prefers first non-empty line and truncates to 32 runes', () {
    final memo = buildMemo(
      uid: 'memo-1',
      content: '\n\n这是一个很长很长很长很长很长很长很长很长很长很长很长很长很长很长的标题行，需要被截断\nSecond line',
    );

    final title = buildCollectionReaderTocTitle(memo, 0);

    expect(title, endsWith('\u2026'));
    expect(title.runes.length, lessThanOrEqualTo(33));
  });

  test('toc title falls back to display time then memo index', () {
    final memoWithTime = buildMemo(
      uid: 'memo-2',
      content: '   ',
      displayTime: DateTime(2026, 4, 12, 8, 0),
    );
    final memoWithoutTime = buildMemo(
      uid: 'memo-3',
      content: '',
      createTime: DateTime.fromMillisecondsSinceEpoch(0),
      updateTime: DateTime.fromMillisecondsSinceEpoch(0),
    );

    expect(buildCollectionReaderTocTitle(memoWithTime, 1), '2026-04-12 08:00');
    expect(buildCollectionReaderTocTitle(memoWithoutTime, 2), 'Memo 3');
  });

  test('search results count matches and build excerpt', () {
    final items = <LocalMemo>[
      buildMemo(uid: 'memo-a', content: 'alpha beta alpha gamma'),
      buildMemo(uid: 'memo-b', content: 'delta epsilon'),
    ];

    final results = buildCollectionReaderSearchResults(
      items: items,
      query: 'alpha',
    );

    expect(results, hasLength(1));
    expect(results.single.memoUid, 'memo-a');
    expect(results.single.matchCount, 2);
    expect(results.single.excerpt, contains('alpha beta alpha'));
    expect(results.single.firstMatchOffset, 0);
  });

  test('search result offset stays aligned with parsed reader text', () {
    final memo = buildMemo(
      uid: 'memo-offset',
      content:
          'Opening paragraph.\n\nSecond paragraph with target phrase inside.\n\nFinal paragraph.',
    );

    final results = buildCollectionReaderSearchResults(
      items: <LocalMemo>[memo],
      query: 'target phrase',
    );
    final parsedText = parseCollectionReaderContent(memo.content).text;

    expect(results, hasLength(1));
    expect(
      results.single.firstMatchOffset,
      parsedText.toLowerCase().indexOf('target phrase'),
    );
    expect(results.single.excerpt, contains('target phrase'));
  });

  test('content parser preserves paragraph blocks and blank spacing', () {
    final parsed = parseCollectionReaderContent(
      'Paragraph one.\n\nParagraph two.\n\nParagraph three.',
    );

    expect(parsed.text, contains('Paragraph one.'));
    expect(parsed.text, contains('Paragraph two.'));
    expect(parsed.text, contains('Paragraph three.'));
    expect(
      parsed.blocks.where(
        (block) => block.kind == CollectionReaderContentBlockKind.text,
      ),
      hasLength(3),
    );
    expect(
      parsed.blocks.where(
        (block) => block.kind == CollectionReaderContentBlockKind.spacer,
      ),
      isNotEmpty,
    );
  });

  test('content parser extracts markdown image blocks in reading order', () {
    final parsed = parseCollectionReaderContent(
      'Before image.\n\n![diagram](https://example.com/demo.png)\n\nAfter image.',
    );

    expect(
      parsed.blocks.any(
        (block) =>
            block.kind == CollectionReaderContentBlockKind.image &&
            block.sourceUrl == 'https://example.com/demo.png',
      ),
      isTrue,
    );
    expect(parsed.text, contains('Before image.'));
    expect(parsed.text, contains('After image.'));
  });

  test('content parser extracts inline html video blocks in reading order', () {
    final parsed = parseCollectionReaderContent(
      'Before video.\n\n<video controls title="demo clip"><source src="https://example.com/demo.mp4" type="video/mp4"></video>\n\nAfter video.',
    );

    expect(
      parsed.blocks.any(
        (block) =>
            block.kind == CollectionReaderContentBlockKind.video &&
            block.sourceUrl == 'https://example.com/demo.mp4' &&
            block.text == 'demo clip',
      ),
      isTrue,
    );
    expect(parsed.text, contains('Before video.'));
    expect(parsed.text, contains('After video.'));
  });

  test('content parser assigns roles for list quote code and table blocks', () {
    final parsed = parseCollectionReaderContent(
      '# Heading\n\n- first item\n- second item\n\n> quoted text\n\n```dart\nprint(1);\n```\n\n| A | B |\n| - | - |\n| 1 | 2 |',
    );

    expect(
      parsed.blocks.any(
        (block) =>
            block.kind == CollectionReaderContentBlockKind.text &&
            block.textRole == ReaderTextRole.heading &&
            (block.text ?? '').contains('Heading'),
      ),
      isTrue,
    );
    expect(
      parsed.blocks.any(
        (block) =>
            block.kind == CollectionReaderContentBlockKind.text &&
            block.textRole == ReaderTextRole.listItem &&
            (block.text ?? '').startsWith('- '),
      ),
      isTrue,
    );
    expect(
      parsed.blocks.any(
        (block) =>
            block.kind == CollectionReaderContentBlockKind.text &&
            block.textRole == ReaderTextRole.quote &&
            (block.text ?? '').startsWith('> '),
      ),
      isTrue,
    );
    expect(
      parsed.blocks.any(
        (block) =>
            block.kind == CollectionReaderContentBlockKind.text &&
            block.textRole == ReaderTextRole.code &&
            (block.text ?? '').contains('print(1);'),
      ),
      isTrue,
    );
    expect(
      parsed.blocks.any(
        (block) =>
            block.kind == CollectionReaderContentBlockKind.text &&
            block.textRole == ReaderTextRole.tableRow &&
            (block.text ?? '').contains('A | B'),
      ),
      isTrue,
    );
  });

  test('restore index prefers uid then falls back to index and first item', () {
    final items = <LocalMemo>[
      buildMemo(uid: 'memo-a', content: 'First'),
      buildMemo(uid: 'memo-b', content: 'Second'),
      buildMemo(uid: 'memo-c', content: 'Third'),
    ];

    expect(
      resolveCollectionReaderRestoreIndex(
        items: items,
        progress: CollectionReaderProgress(
          collectionId: 'collection-1',
          readerMode: CollectionReaderMode.vertical,
          pageAnimation: CollectionReaderPageAnimation.simulation,
          currentMemoUid: 'memo-c',
          currentMemoIndex: 0,
          currentChapterPageIndex: 0,
          listScrollOffset: 0,
          currentMatchCharOffset: null,
          updatedAt: DateTime(2026, 4, 12),
        ),
      ),
      2,
    );

    expect(
      resolveCollectionReaderRestoreIndex(
        items: items,
        progress: CollectionReaderProgress(
          collectionId: 'collection-1',
          readerMode: CollectionReaderMode.vertical,
          pageAnimation: CollectionReaderPageAnimation.simulation,
          currentMemoUid: 'missing',
          currentMemoIndex: 1,
          currentChapterPageIndex: 0,
          listScrollOffset: 0,
          currentMatchCharOffset: null,
          updatedAt: DateTime(2026, 4, 12),
        ),
      ),
      1,
    );

    expect(
      resolveCollectionReaderRestoreIndex(
        items: items,
        progress: CollectionReaderProgress(
          collectionId: 'collection-1',
          readerMode: CollectionReaderMode.vertical,
          pageAnimation: CollectionReaderPageAnimation.simulation,
          currentMemoUid: 'missing',
          currentMemoIndex: 99,
          currentChapterPageIndex: 0,
          listScrollOffset: 0,
          currentMatchCharOffset: null,
          updatedAt: DateTime(2026, 4, 12),
        ),
      ),
      0,
    );
  });

  test('normalize progress follows reordered uid and keeps stored mode', () {
    final items = <LocalMemo>[
      buildMemo(uid: 'memo-c', content: 'Third'),
      buildMemo(uid: 'memo-a', content: 'First'),
      buildMemo(uid: 'memo-b', content: 'Second'),
    ];

    final normalized = normalizeCollectionReaderProgress(
      collectionId: 'collection-1',
      items: items,
      fallbackPreferences: CollectionReaderPreferences.defaults,
      progress: CollectionReaderProgress(
        collectionId: 'collection-1',
        readerMode: CollectionReaderMode.paged,
        pageAnimation: CollectionReaderPageAnimation.slide,
        currentMemoUid: 'memo-b',
        currentMemoIndex: 0,
        currentChapterPageIndex: 3,
        listScrollOffset: 12,
        currentMatchCharOffset: 42,
        updatedAt: DateTime(2026, 4, 12),
      ),
    );

    expect(normalized.currentMemoUid, 'memo-b');
    expect(normalized.currentMemoIndex, 2);
    expect(normalized.readerMode, CollectionReaderMode.paged);
    expect(normalized.pageAnimation, CollectionReaderPageAnimation.slide);
    expect(normalized.currentChapterPageIndex, 3);
    expect(normalized.currentMatchCharOffset, 42);
  });
}

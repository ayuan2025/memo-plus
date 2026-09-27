import 'package:flutter_test/flutter_test.dart';

import 'package:memos_flutter_app/core/memo_scan_metadata.dart';
import 'package:memos_flutter_app/data/db/app_database.dart';

import '../../test_support.dart';

void main() {
  late TestSupport support;

  setUpAll(() async {
    support = await initializeTestSupport();
  });

  tearDownAll(() async {
    await support.dispose();
  });

  test('hidden scan OCR is searchable', () async {
    final dbName = uniqueDbName('scan_ocr_search');
    final db = AppDatabase(dbName: dbName);
    final nowSec = DateTime.utc(2026, 9, 25, 12, 0).millisecondsSinceEpoch ~/ 1000;

    // Exactly what a finished scan leaves in the composer: a visible headline
    // plus tags, with the recognised page hidden in an HTML comment.
    const ocr =
        '\u53d1\u7968\u53f7\u7801 04412836 \u5f00\u7968\u65e5\u671f 2026-09-25 '
        '\u5408\u8ba1\u91d1\u989d \u4eba\u6c11\u5e01\u4e8c\u767e\u4e09\u5341\u5143'
        '\nTotal 230.00 CNY';
    final content = withHiddenScanOcr(
      applyScanMetadataToContent(
        content: '',
        title: 'Receipt',
        tags: const ['ticket'],
      ),
      ocr,
    );

    // Sanity: what we persisted really does carry the hidden block.
    expect(hasHiddenScanOcr(content), isTrue);
    expect(extractHiddenScanOcr(content), ocr.trim());

    await db.upsertMemo(
      uid: 'memo-scan',
      content: content,
      visibility: 'PRIVATE',
      pinned: false,
      state: 'NORMAL',
      createTimeSec: nowSec,
      updateTimeSec: nowSec,
      tags: const ['ticket', 'scan'],
      attachments: const <Map<String, dynamic>>[],
      location: null,
      relationCount: 0,
      syncState: 0,
      lastError: null,
    );

    Future<List<String>> search(String q) async =>
        (await db.listMemos(searchQuery: q)).map((r) => r['uid'] as String).toList();

    // 2+ rune queries go through the gram index; single runes through LIKE.
    expect(await search('\u53d1\u7968'), contains('memo-scan'));
    expect(await search('04412836'), contains('memo-scan'));
    expect(await search('Total'), contains('memo-scan'));
    expect(await search('230.00'), contains('memo-scan'));
    expect(await search('\u4e8c\u767e\u4e09\u5341'), contains('memo-scan'));

    await db.close();
    await deleteTestDatabase(dbName);
  });
}

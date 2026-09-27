import 'package:flutter_test/flutter_test.dart';

import 'package:memos_flutter_app/data/db/app_database.dart';
import 'package:memos_flutter_app/data/models/memo_clip_card_metadata.dart';

import '../../test_support.dart';

void main() {
  late TestSupport support;

  setUpAll(() async {
    support = await initializeTestSupport();
  });

  tearDownAll(() async {
    await support.dispose();
  });

  test('clip metadata is stored and participates in search', () async {
    final dbName = uniqueDbName('clip_card_search');
    final db = AppDatabase(dbName: dbName);
    final now = DateTime.utc(2026, 4, 18, 2, 30);
    final nowSec = now.millisecondsSinceEpoch ~/ 1000;

    await db.upsertMemo(
      uid: 'memo-clip-1',
      content: '# 标题\n\n正文内容',
      visibility: 'PRIVATE',
      pinned: false,
      state: 'NORMAL',
      createTimeSec: nowSec,
      updateTimeSec: nowSec,
      tags: const [],
      attachments: const [],
      location: null,
      relationCount: 0,
      syncState: 0,
      lastError: null,
    );

    await db.upsertMemoClipCard(
      MemoClipCardMetadata(
        memoUid: 'memo-clip-1',
        clipKind: MemoClipKind.article,
        platform: MemoClipPlatform.wechat,
        sourceName: '中国民兵',
        sourceAvatarUrl: '',
        authorName: '编辑部',
        authorAvatarUrl: '',
        sourceUrl: 'https://mp.weixin.qq.com/s/example',
        leadImageUrl: '',
        parserTag: 'wechat',
        createdTime: now,
        updatedTime: now,
      ),
    );

    final stored = await db.getMemoClipCardByUid('memo-clip-1');
    expect(stored, isNotNull);
    expect(stored!['source_name'], '中国民兵');

    final bySource = await db.listMemos(searchQuery: '中国民兵');
    expect(bySource.map((row) => row['uid']), contains('memo-clip-1'));

    final byAuthor = await db.listMemos(searchQuery: '编辑部');
    expect(byAuthor.map((row) => row['uid']), contains('memo-clip-1'));

    final byHost = await db.listMemos(searchQuery: 'mp.weixin.qq.com');
    expect(byHost.map((row) => row['uid']), contains('memo-clip-1'));

    await db.deleteMemoClipCard('memo-clip-1');

    final removed = await db.getMemoClipCardByUid('memo-clip-1');
    expect(removed, isNull);

    final sourceAfterDelete = await db.listMemos(searchQuery: '中国民兵');
    expect(sourceAfterDelete.map((row) => row['uid']), isNot(contains('memo-clip-1')));

    await db.deleteMemoByUid('memo-clip-1');
    await db.close();
    await deleteTestDatabase(dbName);
  });
}

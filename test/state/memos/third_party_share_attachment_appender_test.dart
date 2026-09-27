import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/db/app_database.dart';
import 'package:memos_flutter_app/state/memos/third_party_share_attachment_appender.dart';
import 'package:memos_flutter_app/state/system/database_provider.dart';

import '../../test_support.dart';

void main() {
  late TestSupport support;

  setUpAll(() async {
    support = await initializeTestSupport();
  });

  tearDownAll(() async {
    await support.dispose();
  });

  test(
    'appends inline image with source mapping and outbox payloads',
    () async {
      final harness = await _AppenderHarness.create(
        support,
        'share_appender_inline_image',
      );
      addTearDown(harness.dispose);
      const sourceUrl = 'https://example.com/image.png';
      final sourceFile = await harness.createFile('image.png', 'image-bytes');
      await harness.upsertMemo(
        uid: 'memo-1',
        content: '<img src="$sourceUrl">',
      );

      final result = await harness.appender.append(
        ThirdPartyShareAttachmentAppendRequest(
          memoUid: 'memo-1',
          attachmentUid: 'att-1',
          filePath: sourceFile.path,
          filename: 'image.png',
          mimeType: 'image/png',
          size: await sourceFile.length(),
          kind: ThirdPartyShareAttachmentKind.inlineImage,
          shareInlineImage: true,
          fromThirdPartyShare: true,
          sourceUrl: sourceUrl,
          replaceSourceUrl: sourceUrl,
        ),
      );

      expect(result.appended, isTrue);
      final memo = await harness.db.getMemoByUid('memo-1');
      expect(memo, isNotNull);
      expect(memo!['content'], contains(result.localUrl));
      expect(memo['content'], isNot(contains(sourceUrl)));
      expect(_attachments(memo), hasLength(1));

      final sources = await harness.db.listMemoInlineImageSources('memo-1');
      expect(sources[result.localUrl], sourceUrl);

      final outbox = await harness.db.listOutboxByMemoUid('memo-1');
      expect(outbox.map((row) => row['type']), <Object?>[
        'update_memo',
        'upload_attachment',
      ]);
      final uploadPayload =
          jsonDecode(outbox.last['payload'] as String) as Map<String, dynamic>;
      expect(uploadPayload['uid'], 'att-1');
      expect(uploadPayload['memo_uid'], 'memo-1');
      expect(uploadPayload['share_inline_image'], isTrue);
      expect(uploadPayload['from_third_party_share'], isTrue);
      expect(uploadPayload['share_inline_local_url'], result.localUrl);
    },
  );

  test(
    'appends video as third-party attachment without content rewrite',
    () async {
      final harness = await _AppenderHarness.create(
        support,
        'share_appender_video',
      );
      addTearDown(harness.dispose);
      final sourceFile = await harness.createFile('video.mp4', 'video-bytes');
      await harness.upsertMemo(uid: 'memo-1', content: 'captured text');

      final result = await harness.appender.append(
        ThirdPartyShareAttachmentAppendRequest(
          memoUid: 'memo-1',
          attachmentUid: 'video-1',
          filePath: sourceFile.path,
          filename: 'video.mp4',
          mimeType: 'video/mp4',
          size: await sourceFile.length(),
          kind: ThirdPartyShareAttachmentKind.video,
          skipCompression: true,
        ),
      );

      expect(result.appended, isTrue);
      final memo = await harness.db.getMemoByUid('memo-1');
      expect(memo, isNotNull);
      expect(memo!['content'], 'captured text');
      final attachments = _attachments(memo);
      expect(attachments, hasLength(1));
      expect(attachments.single['type'], 'video/mp4');
      expect(attachments.single['externalLink'], result.localUrl);

      final outbox = await harness.db.listOutboxByMemoUid('memo-1');
      expect(outbox.map((row) => row['type']), <Object?>[
        'update_memo',
        'upload_attachment',
      ]);
      final uploadPayload =
          jsonDecode(outbox.last['payload'] as String) as Map<String, dynamic>;
      expect(uploadPayload['uid'], 'video-1');
      expect(uploadPayload['share_inline_image'], isFalse);
      expect(uploadPayload['from_third_party_share'], isTrue);
      expect(uploadPayload['skip_compression'], isTrue);
    },
  );

  test('skips duplicate attachment uid without adding outbox items', () async {
    final harness = await _AppenderHarness.create(
      support,
      'share_appender_duplicate',
    );
    addTearDown(harness.dispose);
    final sourceFile = await harness.createFile('video.mp4', 'video-bytes');
    await harness.upsertMemo(uid: 'memo-1', content: 'captured text');

    final request = ThirdPartyShareAttachmentAppendRequest(
      memoUid: 'memo-1',
      attachmentUid: 'video-1',
      filePath: sourceFile.path,
      filename: 'video.mp4',
      mimeType: 'video/mp4',
      size: await sourceFile.length(),
      kind: ThirdPartyShareAttachmentKind.video,
    );

    final first = await harness.appender.append(request);
    final second = await harness.appender.append(request);

    expect(first.appended, isTrue);
    expect(
      second.status,
      ThirdPartyShareAttachmentAppendStatus.skippedDuplicate,
    );
    final memo = await harness.db.getMemoByUid('memo-1');
    expect(_attachments(memo!), hasLength(1));
    expect(await harness.db.listOutboxByMemoUid('memo-1'), hasLength(2));
  });

  test('throws when target memo is missing', () async {
    final harness = await _AppenderHarness.create(
      support,
      'share_appender_missing_memo',
    );
    addTearDown(harness.dispose);
    final sourceFile = await harness.createFile('video.mp4', 'video-bytes');

    await expectLater(
      harness.appender.append(
        ThirdPartyShareAttachmentAppendRequest(
          memoUid: 'missing',
          attachmentUid: 'video-1',
          filePath: sourceFile.path,
          filename: 'video.mp4',
          mimeType: 'video/mp4',
          size: await sourceFile.length(),
          kind: ThirdPartyShareAttachmentKind.video,
        ),
      ),
      throwsA(isA<StateError>()),
    );
  });
}

List<dynamic> _attachments(Map<String, dynamic> memo) {
  return jsonDecode(memo['attachments_json'] as String) as List<dynamic>;
}

class _AppenderHarness {
  _AppenderHarness({
    required this.db,
    required this.container,
    required this.tempDir,
  });

  final AppDatabase db;
  final ProviderContainer container;
  final Directory tempDir;

  ThirdPartyShareAttachmentAppender get appender =>
      container.read(thirdPartyShareAttachmentAppenderProvider);

  static Future<_AppenderHarness> create(
    TestSupport support,
    String prefix,
  ) async {
    final dbName = uniqueDbName(prefix);
    final db = AppDatabase(dbName: dbName);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    final tempDir = await support.createTempDir(prefix);
    return _AppenderHarness(db: db, container: container, tempDir: tempDir);
  }

  Future<File> createFile(String filename, String content) async {
    final file = File('${tempDir.path}${Platform.pathSeparator}$filename');
    await file.writeAsString(content);
    return file;
  }

  Future<void> upsertMemo({required String uid, required String content}) {
    return db.upsertMemo(
      uid: uid,
      content: content,
      visibility: 'PRIVATE',
      pinned: false,
      state: 'NORMAL',
      createTimeSec: 1,
      updateTimeSec: 1,
      tags: const <String>[],
      attachments: const <Map<String, dynamic>>[],
      location: null,
      relationCount: 0,
      syncState: 1,
      lastError: null,
    );
  }

  Future<void> dispose() async {
    container.dispose();
    final dbName = db.dbName;
    await db.close();
    await deleteTestDatabase(dbName);
  }
}

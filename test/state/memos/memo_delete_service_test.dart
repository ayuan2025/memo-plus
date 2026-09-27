import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memos_flutter_app/data/db/app_database.dart';
import 'package:memos_flutter_app/data/models/local_memo.dart';
import 'package:memos_flutter_app/data/models/recycle_bin_item.dart';
import 'package:memos_flutter_app/state/memos/memo_delete_service.dart';
import 'package:memos_flutter_app/state/memos/memo_timeline_provider.dart';
import 'package:memos_flutter_app/state/memos/sync_queue_controller.dart';
import 'package:memos_flutter_app/state/memos/sync_queue_models.dart';
import 'package:memos_flutter_app/state/system/database_provider.dart';
import 'package:memos_flutter_app/state/system/reminder_scheduler.dart';

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
    'delete memo folds old tasks into one delete task and writes tombstone',
    () async {
      final dbName = uniqueDbName('memo_delete_service_delete');
      final db = AppDatabase(dbName: dbName);
      late _TestReminderScheduler reminderScheduler;
      final timelineService = MemoTimelineService(
        db: db,
        account: null,
        triggerSync: () async {},
      );
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          memoTimelineServiceProvider.overrideWithValue(timelineService),
          reminderSchedulerProvider.overrideWith((ref) {
            reminderScheduler = _TestReminderScheduler(ref);
            return reminderScheduler;
          }),
        ],
      );

      addTearDown(() async {
        container.dispose();
        await db.close();
        await deleteTestDatabase(dbName);
      });

      await db.upsertMemo(
        uid: 'memo-1',
        content: 'delete me',
        visibility: 'PRIVATE',
        pinned: false,
        state: 'NORMAL',
        createTimeSec: 1735689600,
        updateTimeSec: 1735689600,
        tags: const ['delete'],
        attachments: const [],
        location: null,
        relationCount: 0,
        syncState: 1,
        lastError: null,
      );
      await db.enqueueOutbox(
        type: 'update_memo',
        payload: {'uid': 'memo-1', 'content': 'stale change'},
      );
      await db.enqueueOutbox(
        type: 'upload_attachment',
        payload: {
          'uid': 'att-1',
          'memo_uid': 'memo-1',
          'file_path': '/tmp/sample.png',
          'filename': 'sample.png',
        },
      );

      final row = await db.getMemoByUid('memo-1');
      final memo = LocalMemo.fromDb(row!);

      await container.read(memoDeleteServiceProvider).deleteMemo(memo);

      expect(await db.getMemoByUid('memo-1'), isNull);
      expect(
        await db.getMemoDeleteTombstoneState('memo-1'),
        AppDatabase.memoDeleteTombstoneStatePendingRemoteDelete,
      );

      final pending = await db.listOutboxPending(limit: 20);
      expect(pending, hasLength(1));
      expect(pending.single['type'], 'delete_memo');
      final payload =
          jsonDecode(pending.single['payload'] as String)
              as Map<String, dynamic>;
      expect(payload['uid'], 'memo-1');

      final recycleItems = await db.listRecycleBinItems();
      expect(recycleItems, hasLength(1));
      expect(recycleItems.single['memo_uid'], 'memo-1');
      expect(reminderScheduler.rescheduleCalls, 1);
    },
  );

  test(
    'delete memo preserves attachment cleanup for pending create draft',
    () async {
      final dbName = uniqueDbName('memo_delete_service_delete_create_draft');
      final db = AppDatabase(dbName: dbName);
      late _TestReminderScheduler reminderScheduler;
      final timelineService = MemoTimelineService(
        db: db,
        account: null,
        triggerSync: () async {},
      );
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          memoTimelineServiceProvider.overrideWithValue(timelineService),
          reminderSchedulerProvider.overrideWith((ref) {
            reminderScheduler = _TestReminderScheduler(ref);
            return reminderScheduler;
          }),
        ],
      );

      addTearDown(() async {
        container.dispose();
        await db.close();
        await deleteTestDatabase(dbName);
      });

      await db.upsertMemo(
        uid: 'memo-create-draft',
        content: 'draft with uploaded attachment',
        visibility: 'PRIVATE',
        pinned: false,
        state: 'NORMAL',
        createTimeSec: 1735689600,
        updateTimeSec: 1735689600,
        tags: const ['draft'],
        attachments: const [
          {
            'name': 'resources/att-1',
            'filename': 'sample.png',
            'type': 'image/png',
            'size': 42,
            'externalLink': '/file/resources/att-1/sample.png',
          },
        ],
        location: null,
        relationCount: 0,
        syncState: 1,
        lastError: null,
      );
      await db.enqueueOutbox(
        type: 'create_memo',
        payload: {
          'uid': 'memo-create-draft',
          'content': 'draft with uploaded attachment',
          'visibility': 'PRIVATE',
          'pinned': false,
          'has_attachments': true,
          'create_time': 1735689600,
          'display_time': 1735689600,
        },
      );

      final memo = LocalMemo.fromDb(
        (await db.getMemoByUid('memo-create-draft'))!,
      );

      await container.read(memoDeleteServiceProvider).deleteMemo(memo);

      final pending = await db.listOutboxPending(limit: 20);
      expect(pending.map((row) => row['type']).toList(growable: false), [
        'delete_attachment',
        'delete_memo',
      ]);
      final deleteAttachmentPayload =
          jsonDecode(pending.first['payload'] as String)
              as Map<String, dynamic>;
      expect(deleteAttachmentPayload['attachment_name'], 'resources/att-1');
      expect(deleteAttachmentPayload['memo_uid'], 'memo-create-draft');
      expect(reminderScheduler.rescheduleCalls, 1);
    },
  );

  test('restore memo clears delete tombstone and stale delete task', () async {
    final dbName = uniqueDbName('memo_delete_service_restore');
    final db = AppDatabase(dbName: dbName);
    late _TestReminderScheduler reminderScheduler;
    final timelineService = MemoTimelineService(
      db: db,
      account: null,
      triggerSync: () async {},
    );
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        memoTimelineServiceProvider.overrideWithValue(timelineService),
        reminderSchedulerProvider.overrideWith((ref) {
          reminderScheduler = _TestReminderScheduler(ref);
          return reminderScheduler;
        }),
      ],
    );

    addTearDown(() async {
      container.dispose();
      await db.close();
      await deleteTestDatabase(dbName);
    });

    await db.upsertMemo(
      uid: 'memo-restore',
      content: 'restore me',
      visibility: 'PRIVATE',
      pinned: false,
      state: 'NORMAL',
      createTimeSec: 1735689600,
      updateTimeSec: 1735689600,
      tags: const ['restore'],
      attachments: const [],
      location: null,
      relationCount: 0,
      syncState: 1,
      lastError: null,
    );
    final memo = LocalMemo.fromDb((await db.getMemoByUid('memo-restore'))!);

    await container.read(memoDeleteServiceProvider).deleteMemo(memo);

    final recycleItem = RecycleBinItem.fromDb(
      (await db.listRecycleBinItems()).single,
    );
    await timelineService.restoreRecycleBinItem(recycleItem);

    expect(await db.getMemoDeleteTombstoneState('memo-restore'), isNull);
    final restored = await db.getMemoByUid('memo-restore');
    expect(restored, isNotNull);

    final pending = await db.listOutboxPending(limit: 20);
    expect(pending.where((row) => row['type'] == 'delete_memo'), isEmpty);
    expect(pending.where((row) => row['type'] == 'create_memo'), isNotEmpty);
    expect(reminderScheduler.rescheduleCalls, 1);
  });

  test(
    'deleting failed delete task keeps memo hidden as local-only tombstone',
    () async {
      final dbName = uniqueDbName('memo_delete_service_sync_queue');
      final db = AppDatabase(dbName: dbName);
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );

      addTearDown(() async {
        container.dispose();
        await db.close();
        await deleteTestDatabase(dbName);
      });

      final outboxId = await db.enqueueOutbox(
        type: 'delete_memo',
        payload: {'uid': 'memo-queue', 'force': false},
      );
      await db.upsertMemoDeleteTombstone(
        memoUid: 'memo-queue',
        state: AppDatabase.memoDeleteTombstoneStatePendingRemoteDelete,
      );

      final item = SyncQueueItem(
        id: outboxId,
        type: 'delete_memo',
        state: SyncQueueOutboxState.error,
        attempts: 1,
        createdAt: DateTime.now(),
        preview: null,
        filename: null,
        lastError: '404',
        memoUid: 'memo-queue',
        attachmentUid: null,
        retryAt: null,
      );

      await container.read(syncQueueControllerProvider).deleteItem(item);

      expect(await db.listOutboxPending(limit: 10), isEmpty);
      expect(
        await db.getMemoDeleteTombstoneState('memo-queue'),
        AppDatabase.memoDeleteTombstoneStateLocalOnly,
      );
    },
  );

  test(
    'delete memo still succeeds when attachment snapshot is unavailable',
    () async {
      final dbName = uniqueDbName('memo_delete_service_missing_attachment');
      final db = AppDatabase(dbName: dbName);
      late _TestReminderScheduler reminderScheduler;
      final timelineService = MemoTimelineService(
        db: db,
        account: null,
        triggerSync: () async {},
      );
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          memoTimelineServiceProvider.overrideWithValue(timelineService),
          reminderSchedulerProvider.overrideWith((ref) {
            reminderScheduler = _TestReminderScheduler(ref);
            return reminderScheduler;
          }),
        ],
      );

      addTearDown(() async {
        container.dispose();
        await db.close();
        await deleteTestDatabase(dbName);
      });

      await db.upsertMemo(
        uid: 'memo-missing-attachment',
        content: 'delete me with broken attachment',
        visibility: 'PRIVATE',
        pinned: false,
        state: 'NORMAL',
        createTimeSec: 1735689600,
        updateTimeSec: 1735689600,
        tags: const ['broken'],
        attachments: const [
          {
            'name': 'attachments/att-missing',
            'filename': 'missing.png',
            'type': 'image/png',
            'size': 123,
            'externalLink': 'file:///definitely-missing/missing.png',
          },
        ],
        location: null,
        relationCount: 0,
        syncState: 0,
        lastError: null,
      );

      final memo = LocalMemo.fromDb(
        (await db.getMemoByUid('memo-missing-attachment'))!,
      );

      await container.read(memoDeleteServiceProvider).deleteMemo(memo);

      expect(await db.getMemoByUid('memo-missing-attachment'), isNull);
      expect(
        await db.getMemoDeleteTombstoneState('memo-missing-attachment'),
        AppDatabase.memoDeleteTombstoneStatePendingRemoteDelete,
      );
      expect(await db.listRecycleBinItems(), hasLength(1));
      expect(reminderScheduler.rescheduleCalls, 1);
    },
  );
}

class _TestReminderScheduler extends ReminderScheduler {
  _TestReminderScheduler(super.ref);

  int rescheduleCalls = 0;

  @override
  Future<void> rescheduleAll({bool force = false, String? caller}) async {
    rescheduleCalls += 1;
  }
}

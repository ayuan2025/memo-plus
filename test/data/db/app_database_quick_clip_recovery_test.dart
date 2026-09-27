import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:memos_flutter_app/core/debug_ephemeral_storage.dart';
import 'package:memos_flutter_app/data/db/app_database.dart';
import 'package:memos_flutter_app/data/models/quick_clip_recovery_job.dart';

import '../../test_support.dart';

void main() {
  late TestSupport support;

  setUpAll(() async {
    support = await initializeTestSupport();
  });

  tearDownAll(() async {
    await support.dispose();
  });

  test('persists and updates quick clip recovery job state', () async {
    final dbName = uniqueDbName('quick_clip_recovery_persistence');
    final db = AppDatabase(dbName: dbName);
    addTearDown(() async {
      await db.close();
      await AppDatabase.deleteDatabaseFile(dbName: dbName);
    });

    await db.upsertMemo(
      uid: 'memo-recovery-1',
      content: 'placeholder',
      visibility: 'PRIVATE',
      pinned: false,
      state: 'NORMAL',
      createTimeSec: 1770000000,
      updateTimeSec: 1770000000,
      tags: const <String>[],
      attachments: const <Map<String, dynamic>>[],
      location: null,
      syncState: 1,
    );

    final createdAt = DateTime.utc(2026, 1, 1, 1);
    await db.upsertQuickClipRecoveryJob(
      QuickClipRecoveryJob.pending(
        memoUid: 'memo-recovery-1',
        sourceUrl: 'https://example.com/a',
        payloadType: 'text',
        payloadText: 'Read https://example.com/a',
        payloadTitle: 'Example',
        textOnly: false,
        titleAndLinkOnly: false,
        tags: const <String>['#clip', 'reading'],
        localeLanguageCode: 'en',
        placeholderMarker: '<!-- memoflow_quick_clip:memo-recovery-1 -->',
        placeholderLookupContent: 'placeholder',
        now: createdAt,
      ),
    );

    final saved = await db.getQuickClipRecoveryJobByMemoUid('memo-recovery-1');
    expect(saved, isNotNull);
    expect(saved?.status, QuickClipRecoveryJobStatus.pending);
    expect(saved?.tags, <String>['#clip', 'reading']);

    final recoverable = await db.listRecoverableQuickClipRecoveryJobs();
    expect(recoverable.map((job) => job.memoUid), contains('memo-recovery-1'));

    final stale = await db.listStaleQuickClipRecoveryJobs(
      staleBefore: createdAt.add(const Duration(minutes: 1)),
    );
    expect(stale.map((job) => job.memoUid), contains('memo-recovery-1'));

    final attemptAt = createdAt.add(const Duration(minutes: 2));
    expect(
      await db.markQuickClipRecoveryJobRunning(
        memoUid: 'memo-recovery-1',
        now: attemptAt,
      ),
      1,
    );
    final running = await db.getQuickClipRecoveryJobByMemoUid(
      'memo-recovery-1',
    );
    expect(running?.status, QuickClipRecoveryJobStatus.running);
    expect(running?.attemptCount, 1);
    expect(running?.lastAttemptTime, isNotNull);

    final completedAt = createdAt.add(const Duration(minutes: 3));
    expect(
      await db.markQuickClipRecoveryJobCompleted(
        memoUid: 'memo-recovery-1',
        now: completedAt,
      ),
      1,
    );
    expect(await db.listRecoverableQuickClipRecoveryJobs(), isEmpty);

    expect(
      await db.deleteTerminalQuickClipRecoveryJobs(
        completedBefore: completedAt.add(const Duration(milliseconds: 1)),
      ),
      1,
    );
    expect(
      await db.getQuickClipRecoveryJobByMemoUid('memo-recovery-1'),
      isNull,
    );
  });

  test('upgrade from v28 creates quick clip recovery jobs table', () async {
    final dbName = uniqueDbName('quick_clip_recovery_v28_to_v29');
    addTearDown(() async {
      await AppDatabase.deleteDatabaseFile(dbName: dbName);
    });

    final dbDir = await resolveDatabasesDirectoryPath();
    final path = p.join(dbDir, dbName);
    final legacyDb = await openDatabase(
      path,
      version: 28,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE IF NOT EXISTS memos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uid TEXT NOT NULL UNIQUE,
  content TEXT NOT NULL,
  visibility TEXT NOT NULL,
  pinned INTEGER NOT NULL DEFAULT 0,
  state TEXT NOT NULL DEFAULT 'NORMAL',
  create_time INTEGER NOT NULL,
  display_time INTEGER,
  update_time INTEGER NOT NULL,
  tags TEXT NOT NULL DEFAULT '',
  attachments_json TEXT NOT NULL DEFAULT '[]',
  location_placeholder TEXT,
  location_lat REAL,
  location_lng REAL,
  relation_count INTEGER NOT NULL DEFAULT 0,
  sync_state INTEGER NOT NULL DEFAULT 0,
  last_error TEXT
);
''');
      },
    );
    await legacyDb.close();

    final appDb = AppDatabase(dbName: dbName);
    addTearDown(appDb.close);

    final upgradedDb = await appDb.db;
    final columns = await upgradedDb.rawQuery(
      'PRAGMA table_info("quick_clip_recovery_jobs");',
    );

    expect(columns.any((row) => row['name'] == 'memo_uid'), isTrue);
    expect(columns.any((row) => row['name'] == 'source_url'), isTrue);
    expect(columns.any((row) => row['name'] == 'attempt_count'), isTrue);
    expect(columns.any((row) => row['name'] == 'placeholder_marker'), isTrue);
    expect(columns.any((row) => row['name'] == 'completed_time'), isTrue);
  });
}

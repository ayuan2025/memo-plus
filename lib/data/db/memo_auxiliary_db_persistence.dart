import 'package:sqflite/sqflite.dart';

import '../models/memo_clip_card_metadata.dart';

final class MemoAuxiliaryDbPersistence {
  const MemoAuxiliaryDbPersistence._();

  static Future<void> ensureTables(Database db) async {
    await ensureMemoReminderTable(db);
    await ensureImportHistoryTable(db);
    await ensureMemoClipCardsTable(db);
  }

  static Future<void> ensureMemoReminderTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS memo_reminders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  memo_uid TEXT NOT NULL UNIQUE,
  mode TEXT NOT NULL,
  times_json TEXT NOT NULL,
  created_time INTEGER NOT NULL,
  updated_time INTEGER NOT NULL,
  FOREIGN KEY (memo_uid) REFERENCES memos(uid) ON DELETE CASCADE ON UPDATE CASCADE
);
''');
  }

  static Future<void> ensureImportHistoryTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS import_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  source TEXT NOT NULL,
  file_md5 TEXT NOT NULL,
  file_name TEXT NOT NULL,
  memo_count INTEGER NOT NULL DEFAULT 0,
  attachment_count INTEGER NOT NULL DEFAULT 0,
  failed_count INTEGER NOT NULL DEFAULT 0,
  status INTEGER NOT NULL DEFAULT 0,
  created_time INTEGER NOT NULL,
  updated_time INTEGER NOT NULL,
  error TEXT,
  UNIQUE(source, file_md5)
);
''');
  }

  static Future<void> ensureMemoClipCardsTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS memo_clip_cards (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  memo_uid TEXT NOT NULL UNIQUE,
  clip_kind TEXT NOT NULL,
  platform TEXT NOT NULL,
  source_name TEXT NOT NULL DEFAULT '',
  source_avatar_url TEXT NOT NULL DEFAULT '',
  author_name TEXT NOT NULL DEFAULT '',
  author_avatar_url TEXT NOT NULL DEFAULT '',
  source_url TEXT NOT NULL DEFAULT '',
  lead_image_url TEXT NOT NULL DEFAULT '',
  parser_tag TEXT NOT NULL DEFAULT '',
  created_time INTEGER NOT NULL,
  updated_time INTEGER NOT NULL,
  FOREIGN KEY (memo_uid) REFERENCES memos(uid) ON DELETE CASCADE ON UPDATE CASCADE
);
''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_memo_clip_cards_platform ON memo_clip_cards(platform);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_memo_clip_cards_updated_time ON memo_clip_cards(updated_time DESC);',
    );
  }

  static Future<Map<String, dynamic>?> getMemoClipCardByUid(
    DatabaseExecutor executor,
    String memoUid,
  ) async {
    final rows = await executor.query(
      'memo_clip_cards',
      where: 'memo_uid = ?',
      whereArgs: [memoUid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  static Future<List<Map<String, dynamic>>> listMemoClipCards(
    DatabaseExecutor executor,
  ) {
    return executor.query(
      'memo_clip_cards',
      orderBy: 'updated_time DESC, id DESC',
    );
  }

  static Future<Map<String, dynamic>?> getImportHistory(
    DatabaseExecutor executor, {
    required String source,
    required String fileMd5,
  }) async {
    final rows = await executor.query(
      'import_history',
      where: 'source = ? AND file_md5 = ?',
      whereArgs: [source, fileMd5],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  static Future<int> upsertImportHistory(
    DatabaseExecutor executor, {
    required String source,
    required String fileMd5,
    required String fileName,
    required int status,
    required int memoCount,
    required int attachmentCount,
    required int failedCount,
    String? error,
  }) {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    return executor.insert('import_history', {
      'source': source,
      'file_md5': fileMd5,
      'file_name': fileName,
      'memo_count': memoCount,
      'attachment_count': attachmentCount,
      'failed_count': failedCount,
      'status': status,
      'created_time': now,
      'updated_time': now,
      'error': error,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateImportHistory(
    DatabaseExecutor executor, {
    required int id,
    required int status,
    required int memoCount,
    required int attachmentCount,
    required int failedCount,
    String? error,
  }) async {
    await executor.update(
      'import_history',
      {
        'status': status,
        'memo_count': memoCount,
        'attachment_count': attachmentCount,
        'failed_count': failedCount,
        'updated_time': DateTime.now().toUtc().millisecondsSinceEpoch,
        'error': error,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<Map<String, dynamic>?> getMemoReminderByUid(
    DatabaseExecutor executor,
    String memoUid,
  ) async {
    final rows = await executor.query(
      'memo_reminders',
      where: 'memo_uid = ?',
      whereArgs: [memoUid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  static Future<List<Map<String, dynamic>>> listMemoReminders(
    DatabaseExecutor executor,
  ) {
    return executor.query('memo_reminders', orderBy: 'updated_time DESC');
  }

  static Future<void> upsertMemoReminder(
    DatabaseExecutor executor, {
    required String memoUid,
    required String mode,
    required String timesJson,
  }) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final updated = await executor.update(
      'memo_reminders',
      {'mode': mode, 'times_json': timesJson, 'updated_time': now},
      where: 'memo_uid = ?',
      whereArgs: [memoUid],
    );
    if (updated == 0) {
      await executor.insert('memo_reminders', {
        'memo_uid': memoUid,
        'mode': mode,
        'times_json': timesJson,
        'created_time': now,
        'updated_time': now,
      }, conflictAlgorithm: ConflictAlgorithm.abort);
    }
  }

  static Future<void> deleteMemoReminder(
    DatabaseExecutor executor,
    String memoUid,
  ) async {
    await executor.delete(
      'memo_reminders',
      where: 'memo_uid = ?',
      whereArgs: [memoUid],
    );
  }

  static Future<void> renameMemoReminderUid(
    DatabaseExecutor executor, {
    required String oldUid,
    required String newUid,
  }) async {
    await executor.update(
      'memo_reminders',
      {'memo_uid': newUid},
      where: 'memo_uid = ?',
      whereArgs: [oldUid],
    );
  }

  static Future<void> upsertMemoClipCard(
    DatabaseExecutor executor,
    MemoClipCardMetadata metadata,
  ) async {
    await executor.insert(
      'memo_clip_cards',
      metadata.toDbRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteMemoClipCard(
    DatabaseExecutor executor,
    String memoUid,
  ) async {
    await executor.delete(
      'memo_clip_cards',
      where: 'memo_uid = ?',
      whereArgs: [memoUid],
    );
  }
}

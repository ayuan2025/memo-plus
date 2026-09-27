import 'package:sqflite/sqflite.dart';

import '../models/quick_clip_recovery_job.dart';

final class QuickClipRecoveryDbPersistence {
  const QuickClipRecoveryDbPersistence._();

  static const tableName = 'quick_clip_recovery_jobs';

  static const _recoverableStatuses = <QuickClipRecoveryJobStatus>{
    QuickClipRecoveryJobStatus.pending,
    QuickClipRecoveryJobStatus.running,
  };

  static const _terminalStatuses = <QuickClipRecoveryJobStatus>{
    QuickClipRecoveryJobStatus.completed,
    QuickClipRecoveryJobStatus.failed,
    QuickClipRecoveryJobStatus.abandoned,
  };

  static Future<void> ensureTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS quick_clip_recovery_jobs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  memo_uid TEXT NOT NULL UNIQUE,
  source_url TEXT NOT NULL,
  payload_type TEXT NOT NULL,
  payload_text TEXT NOT NULL DEFAULT '',
  payload_title TEXT,
  payload_paths_json TEXT NOT NULL DEFAULT '[]',
  text_only INTEGER NOT NULL DEFAULT 0,
  title_and_link_only INTEGER NOT NULL DEFAULT 0,
  tags_json TEXT NOT NULL DEFAULT '[]',
  locale_language_code TEXT NOT NULL DEFAULT '',
  placeholder_marker TEXT NOT NULL DEFAULT '',
  placeholder_lookup_content TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL,
  attempt_count INTEGER NOT NULL DEFAULT 0,
  last_error TEXT,
  created_time INTEGER NOT NULL,
  updated_time INTEGER NOT NULL,
  last_attempt_time INTEGER,
  completed_time INTEGER,
  FOREIGN KEY (memo_uid) REFERENCES memos(uid) ON DELETE CASCADE ON UPDATE CASCADE
);
''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_quick_clip_recovery_status_updated ON quick_clip_recovery_jobs(status, updated_time ASC);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_quick_clip_recovery_created ON quick_clip_recovery_jobs(created_time ASC);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_quick_clip_recovery_completed ON quick_clip_recovery_jobs(completed_time ASC);',
    );
  }

  static Future<void> upsertJob(
    DatabaseExecutor executor,
    QuickClipRecoveryJob job,
  ) async {
    final row = job.toDbRow();
    final memoUid = (row['memo_uid'] as String? ?? '').trim();
    final sourceUrl = (row['source_url'] as String? ?? '').trim();
    if (memoUid.isEmpty || sourceUrl.isEmpty) return;
    await executor.insert(
      tableName,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<QuickClipRecoveryJob?> getJobByMemoUid(
    DatabaseExecutor executor,
    String memoUid,
  ) async {
    final normalizedUid = memoUid.trim();
    if (normalizedUid.isEmpty) return null;
    final rows = await executor.query(
      tableName,
      where: 'memo_uid = ?',
      whereArgs: <Object?>[normalizedUid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return QuickClipRecoveryJob.fromDb(rows.first);
  }

  static Future<List<QuickClipRecoveryJob>> listRecoverableJobs(
    DatabaseExecutor executor, {
    int limit = 20,
  }) async {
    final statuses = _recoverableStatuses
        .map(quickClipRecoveryJobStatusValue)
        .toList(growable: false);
    final rows = await executor.query(
      tableName,
      where: 'status IN (${_placeholders(statuses.length)})',
      whereArgs: statuses,
      orderBy: 'updated_time ASC, id ASC',
      limit: limit,
    );
    return rows.map(QuickClipRecoveryJob.fromDb).toList(growable: false);
  }

  static Future<List<QuickClipRecoveryJob>> listStaleJobs(
    DatabaseExecutor executor, {
    required DateTime staleBefore,
    int limit = 20,
  }) async {
    final statuses = _recoverableStatuses
        .map(quickClipRecoveryJobStatusValue)
        .toList(growable: false);
    final rows = await executor.query(
      tableName,
      where:
          'status IN (${_placeholders(statuses.length)}) AND created_time <= ?',
      whereArgs: <Object?>[
        ...statuses,
        staleBefore.toUtc().millisecondsSinceEpoch,
      ],
      orderBy: 'created_time ASC, id ASC',
      limit: limit,
    );
    return rows.map(QuickClipRecoveryJob.fromDb).toList(growable: false);
  }

  static Future<int> markRunning(
    DatabaseExecutor executor, {
    required String memoUid,
    required DateTime now,
    String? lastError,
  }) async {
    final normalizedUid = memoUid.trim();
    if (normalizedUid.isEmpty) return 0;
    final recoverableValues = _recoverableStatuses
        .map(quickClipRecoveryJobStatusValue)
        .toList(growable: false);
    return executor.rawUpdate(
      '''
UPDATE quick_clip_recovery_jobs
SET status = ?,
    attempt_count = attempt_count + 1,
    last_attempt_time = ?,
    updated_time = ?,
    last_error = ?
WHERE memo_uid = ?
  AND status IN (${_placeholders(recoverableValues.length)});
''',
      <Object?>[
        quickClipRecoveryJobStatusValue(QuickClipRecoveryJobStatus.running),
        now.toUtc().millisecondsSinceEpoch,
        now.toUtc().millisecondsSinceEpoch,
        _normalizeNullableText(lastError),
        normalizedUid,
        ...recoverableValues,
      ],
    );
  }

  static Future<int> markCompleted(
    DatabaseExecutor executor, {
    required String memoUid,
    required DateTime now,
  }) {
    return _markTerminal(
      executor,
      memoUid: memoUid,
      status: QuickClipRecoveryJobStatus.completed,
      now: now,
      lastError: null,
    );
  }

  static Future<int> markAbandoned(
    DatabaseExecutor executor, {
    required String memoUid,
    required DateTime now,
    String? lastError,
  }) {
    return _markTerminal(
      executor,
      memoUid: memoUid,
      status: QuickClipRecoveryJobStatus.abandoned,
      now: now,
      lastError: lastError,
    );
  }

  static Future<int> markFailed(
    DatabaseExecutor executor, {
    required String memoUid,
    required DateTime now,
    String? lastError,
  }) {
    return _markTerminal(
      executor,
      memoUid: memoUid,
      status: QuickClipRecoveryJobStatus.failed,
      now: now,
      lastError: lastError,
    );
  }

  static Future<int> deleteTerminalJobsOlderThan(
    DatabaseExecutor executor, {
    required DateTime completedBefore,
    int limit = 100,
  }) async {
    final statuses = _terminalStatuses
        .map(quickClipRecoveryJobStatusValue)
        .toList(growable: false);
    final ids = await executor.query(
      tableName,
      columns: const <String>['id'],
      where:
          'status IN (${_placeholders(statuses.length)}) AND completed_time IS NOT NULL AND completed_time < ?',
      whereArgs: <Object?>[
        ...statuses,
        completedBefore.toUtc().millisecondsSinceEpoch,
      ],
      orderBy: 'completed_time ASC, id ASC',
      limit: limit,
    );
    final idValues = ids
        .map((row) => row['id'])
        .whereType<int>()
        .toList(growable: false);
    if (idValues.isEmpty) return 0;
    return executor.delete(
      tableName,
      where: 'id IN (${_placeholders(idValues.length)})',
      whereArgs: idValues,
    );
  }

  static Future<int> _markTerminal(
    DatabaseExecutor executor, {
    required String memoUid,
    required QuickClipRecoveryJobStatus status,
    required DateTime now,
    String? lastError,
  }) async {
    final normalizedUid = memoUid.trim();
    if (normalizedUid.isEmpty) return 0;
    return executor.update(
      tableName,
      <String, Object?>{
        'status': quickClipRecoveryJobStatusValue(status),
        'updated_time': now.toUtc().millisecondsSinceEpoch,
        'completed_time': now.toUtc().millisecondsSinceEpoch,
        'last_error': _normalizeNullableText(lastError),
      },
      where: 'memo_uid = ?',
      whereArgs: <Object?>[normalizedUid],
    );
  }

  static String _placeholders(int count) {
    return List<String>.filled(count, '?').join(', ');
  }

  static String? _normalizeNullableText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }
}

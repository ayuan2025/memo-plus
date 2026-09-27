import 'package:sqflite/sqflite.dart';

final class MemoQueryDbPersistence {
  const MemoQueryDbPersistence._();

  static Future<Map<String, dynamic>?> getMemoByUid(
    DatabaseExecutor executor,
    String uid,
  ) async {
    final rows = await executor.query(
      'memos',
      where: 'uid = ?',
      whereArgs: [uid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  static Future<List<Map<String, dynamic>>> listMemoUidTagRows(
    DatabaseExecutor executor,
  ) {
    return executor.query('memos', columns: const ['uid', 'tags']);
  }

  static Future<int?> getMemoIdByUid(
    DatabaseExecutor executor,
    String uid,
  ) async {
    final rows = await executor.query(
      'memos',
      columns: const ['id'],
      where: 'uid = ?',
      whereArgs: [uid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _readInt(rows.first['id']);
  }

  static Future<List<Map<String, dynamic>>> listMemoTagNormalizationRows(
    DatabaseExecutor executor, {
    required int afterId,
    required int limit,
  }) {
    return executor.query(
      'memos',
      columns: const ['id', 'uid', 'tags'],
      where: 'id > ?',
      whereArgs: [afterId],
      orderBy: 'id ASC',
      limit: limit,
    );
  }

  static Future<List<Map<String, dynamic>>> listMemoTagBackfillRows(
    DatabaseExecutor executor, {
    required int afterId,
    required int limit,
  }) {
    return executor.query(
      'memos',
      columns: const ['id', 'uid', 'content', 'tags'],
      where: 'id > ?',
      whereArgs: [afterId],
      orderBy: 'id ASC',
      limit: limit,
    );
  }

  static Future<List<String>> listTagStrings(
    DatabaseExecutor executor, {
    String? state,
  }) async {
    final normalizedState = (state ?? '').trim();
    final rows = await executor.query(
      'memos',
      columns: const ['tags'],
      where: normalizedState.isEmpty ? null : 'state = ?',
      whereArgs: normalizedState.isEmpty ? null : [normalizedState],
    );
    return rows
        .map((r) => (r['tags'] as String?) ?? '')
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
  }

  static Future<List<Map<String, dynamic>>> listMemoAttachmentRows(
    DatabaseExecutor executor, {
    String? state,
  }) {
    final normalizedState = (state ?? '').trim();
    return executor.query(
      'memos',
      columns: const ['uid', 'update_time', 'attachments_json'],
      where: [
        if (normalizedState.isNotEmpty) 'state = ?',
        "attachments_json <> '[]'",
      ].join(' AND '),
      whereArgs: [if (normalizedState.isNotEmpty) normalizedState],
      orderBy: 'update_time DESC',
      limit: 2000,
    );
  }

  static Future<List<Map<String, dynamic>>> listMemoStorageSummaryRows(
    DatabaseExecutor executor, {
    String? state,
  }) {
    final normalizedState = (state ?? '').trim();
    return executor.query(
      'memos',
      columns: const ['uid', 'content', 'attachments_json'],
      where: normalizedState.isEmpty ? null : 'state = ?',
      whereArgs: normalizedState.isEmpty ? null : [normalizedState],
      orderBy: 'id ASC',
    );
  }

  static Future<List<Map<String, dynamic>>> listMemoUidSyncStates(
    DatabaseExecutor executor, {
    String? state,
  }) {
    final normalizedState = (state ?? '').trim();
    return executor.query(
      'memos',
      columns: const ['uid', 'sync_state', 'visibility'],
      where: normalizedState.isEmpty ? null : 'state = ?',
      whereArgs: normalizedState.isEmpty ? null : [normalizedState],
    );
  }

  static Future<List<Map<String, dynamic>>> listMemosForExport(
    DatabaseExecutor executor, {
    int? startTimeSec,
    int? endTimeSecExclusive,
    bool includeArchived = false,
  }) {
    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    if (!includeArchived) {
      whereClauses.add("state = 'NORMAL'");
    }
    if (startTimeSec != null) {
      whereClauses.add('COALESCE(display_time, create_time) >= ?');
      whereArgs.add(startTimeSec);
    }
    if (endTimeSecExclusive != null) {
      whereClauses.add('COALESCE(display_time, create_time) < ?');
      whereArgs.add(endTimeSecExclusive);
    }

    return executor.query(
      'memos',
      where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'COALESCE(display_time, create_time) ASC',
      limit: 20000,
    );
  }

  static Future<List<Map<String, dynamic>>> listMemosForLosslessExport(
    DatabaseExecutor executor, {
    int? startTimeSec,
    int? endTimeSecExclusive,
    bool includeArchived = false,
  }) {
    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    if (!includeArchived) {
      whereClauses.add("m.state = 'NORMAL'");
    }
    if (startTimeSec != null) {
      whereClauses.add('COALESCE(m.display_time, m.create_time) >= ?');
      whereArgs.add(startTimeSec);
    }
    if (endTimeSecExclusive != null) {
      whereClauses.add('COALESCE(m.display_time, m.create_time) < ?');
      whereArgs.add(endTimeSecExclusive);
    }

    final whereClause = whereClauses.isEmpty
        ? ''
        : 'WHERE ${whereClauses.join(' AND ')}';
    return executor.rawQuery('''
SELECT m.*, r.relations_json
FROM memos m
LEFT JOIN memo_relations_cache r ON r.memo_uid = m.uid
$whereClause
ORDER BY COALESCE(m.display_time, m.create_time) ASC
LIMIT 20000;
''', whereArgs);
  }

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}

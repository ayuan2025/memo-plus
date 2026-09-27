import 'dart:convert';

import 'package:sqflite/sqflite.dart';

final class OutboxDbPersistence {
  const OutboxDbPersistence._();

  static const int statePending = 0;
  static const int stateRunning = 1;
  static const int stateRetry = 2;
  static const int stateError = 3;
  static const int stateDone = 4;
  static const int stateQuarantined = 5;

  static const List<int> activeStates = <int>[
    statePending,
    stateRunning,
    stateRetry,
    stateError,
    stateQuarantined,
  ];

  static const List<int> runnableStates = <int>[
    statePending,
    stateRunning,
    stateRetry,
  ];

  static const List<int> attentionStates = <int>[stateQuarantined, stateError];

  static Future<void> ensureTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS outbox (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL,
  payload TEXT NOT NULL,
  state INTEGER NOT NULL DEFAULT 0,
  attempts INTEGER NOT NULL DEFAULT 0,
  last_error TEXT,
  failure_code TEXT,
  failure_kind TEXT,
  retry_at INTEGER,
  quarantined_at INTEGER,
  created_time INTEGER NOT NULL
);
''');
  }

  static Future<void> ensureRetryColumnAndNormalizeLegacyStates(
    Database db,
  ) async {
    await _ensureColumnExists(
      db,
      table: 'outbox',
      column: 'retry_at',
      definition: 'retry_at INTEGER',
    );
    await db.execute('UPDATE outbox SET state = $stateError WHERE state = 2;');
    await db.execute(
      'UPDATE outbox SET state = $statePending WHERE state = 1;',
    );
    await db.execute(
      'UPDATE outbox SET state = $statePending WHERE state NOT IN ($statePending, $stateRetry, $stateError, $stateDone);',
    );
  }

  static Future<void> ensureFailureMetadataColumns(Database db) async {
    await ensureTable(db);
    await _ensureColumnExists(
      db,
      table: 'outbox',
      column: 'failure_code',
      definition: 'failure_code TEXT',
    );
    await _ensureColumnExists(
      db,
      table: 'outbox',
      column: 'failure_kind',
      definition: 'failure_kind TEXT',
    );
    await _ensureColumnExists(
      db,
      table: 'outbox',
      column: 'quarantined_at',
      definition: 'quarantined_at INTEGER',
    );
  }

  static Future<void> migrateLegacyErrorChains(Database db) async {
    final rows = await db.query(
      'outbox',
      columns: const ['id', 'type', 'payload', 'state'],
      orderBy: 'id ASC',
    );
    if (rows.isEmpty) return;

    final legacyErrorIds = <int>[];
    final dependentIds = <int>[];
    final blockedMemoUids = <String>{};

    for (final row in rows) {
      final id = _readInt(row['id']);
      if (id == null || id <= 0) continue;

      final state = _readInt(row['state']);
      if (state == null) continue;

      final memoUid = extractMemoUidFromRow(row['type'], row['payload']);
      if (state == stateError) {
        legacyErrorIds.add(id);
        if (memoUid != null && memoUid.isNotEmpty) {
          blockedMemoUids.add(memoUid);
        }
        continue;
      }

      if (memoUid == null ||
          memoUid.isEmpty ||
          !blockedMemoUids.contains(memoUid)) {
        continue;
      }
      if (state == statePending ||
          state == stateRunning ||
          state == stateRetry) {
        dependentIds.add(id);
      }
    }

    for (final id in legacyErrorIds) {
      await db.rawUpdate(
        'UPDATE outbox SET state = ?, retry_at = NULL, failure_code = COALESCE(NULLIF(TRIM(failure_code), \'\'), ?), failure_kind = COALESCE(NULLIF(TRIM(failure_kind), \'\'), ?), quarantined_at = COALESCE(quarantined_at, created_time) WHERE id = ?',
        [stateQuarantined, 'legacy_error_migrated', 'fatal_immediate', id],
      );
    }

    for (final id in dependentIds) {
      await db.rawUpdate(
        'UPDATE outbox SET state = ?, retry_at = NULL, last_error = COALESCE(NULLIF(TRIM(last_error), \'\'), ?), failure_code = COALESCE(NULLIF(TRIM(failure_code), \'\'), ?), failure_kind = COALESCE(NULLIF(TRIM(failure_kind), \'\'), ?), quarantined_at = COALESCE(quarantined_at, created_time) WHERE id = ?',
        [
          stateQuarantined,
          'Blocked by quarantined memo root task',
          'blocked_by_quarantined_memo_root',
          'fatal_immediate',
          id,
        ],
      );
    }
  }

  static Future<List<Map<String, dynamic>>> listPending(
    DatabaseExecutor executor, {
    int limit = 50,
  }) {
    return executor.query(
      'outbox',
      where: 'state IN (?, ?, ?)',
      whereArgs: runnableStates,
      orderBy: 'id ASC',
      limit: limit,
    );
  }

  static Future<List<Map<String, dynamic>>> listAttention(
    DatabaseExecutor executor, {
    int limit = 50,
  }) async {
    final rows = await executor.query(
      'outbox',
      where: 'state IN (?, ?)',
      whereArgs: attentionStates,
      orderBy: 'COALESCE(quarantined_at, created_time) DESC, id DESC',
      limit: limit,
    );
    return rows.map(withDerivedAttentionFields).toList(growable: false);
  }

  static Future<int> countAttention(DatabaseExecutor executor) {
    return _countWhere(executor, 'state IN ($stateQuarantined, $stateError)');
  }

  static Future<int> countPending(DatabaseExecutor executor) {
    return _countWhere(
      executor,
      'state IN ($statePending, $stateRunning, $stateRetry)',
    );
  }

  static Future<int> countRetryable(DatabaseExecutor executor) {
    return _countWhere(
      executor,
      'state IN ($statePending, $stateRunning, $stateRetry)',
    );
  }

  static Future<int> countFailed(DatabaseExecutor executor) {
    return _countWhere(executor, 'state = $stateError');
  }

  static Future<int> countQuarantined(DatabaseExecutor executor) {
    return _countWhere(executor, 'state = $stateQuarantined');
  }

  static Future<List<Map<String, dynamic>>> listPendingByType(
    DatabaseExecutor executor,
    String type,
  ) {
    return executor.query(
      'outbox',
      columns: const ['id', 'payload'],
      where: 'state IN (?, ?, ?, ?, ?) AND type = ?',
      whereArgs: <Object?>[...activeStates, type],
      orderBy: 'id ASC',
    );
  }

  static Future<List<Map<String, dynamic>>> listByMemoUid(
    DatabaseExecutor executor,
    String memoUid, {
    Set<String>? types,
    Set<int>? states,
  }) async {
    final trimmed = memoUid.trim();
    if (trimmed.isEmpty) return const [];
    final rows = await executor.query(
      'outbox',
      columns: const [
        'id',
        'type',
        'payload',
        'state',
        'attempts',
        'last_error',
        'failure_code',
        'failure_kind',
        'retry_at',
        'quarantined_at',
        'created_time',
      ],
      orderBy: 'id ASC',
    );
    final matched = <Map<String, dynamic>>[];
    for (final row in rows) {
      final type = row['type'];
      final payloadRaw = row['payload'];
      final state = row['state'];
      if (type is! String || payloadRaw is! String) continue;
      if (types != null && !types.contains(type)) continue;
      if (states != null) {
        final normalizedState = _readInt(state);
        if (normalizedState == null || !states.contains(normalizedState)) {
          continue;
        }
      }
      final payload = decodePayload(payloadRaw);
      if (payload == null) continue;
      final targetUid = extractMemoUid(type, payload);
      if (targetUid == null || targetUid.trim() != trimmed) continue;
      matched.add(row.map((key, value) => MapEntry(key, value)));
    }
    return matched;
  }

  static Future<bool> hasPendingTaskForMemo(
    DatabaseExecutor executor,
    String memoUid, {
    Set<String>? types,
  }) async {
    final trimmed = memoUid.trim();
    if (trimmed.isEmpty) return false;
    final rows = await executor.query(
      'outbox',
      columns: const ['type', 'payload'],
      where: 'state IN (?, ?, ?, ?, ?)',
      whereArgs: activeStates,
    );

    for (final row in rows) {
      final type = row['type'];
      final payloadRaw = row['payload'];
      if (type is! String || payloadRaw is! String) continue;
      if (types != null && !types.contains(type)) continue;
      final payload = decodePayload(payloadRaw);
      if (payload == null) continue;
      final targetUid = extractMemoUid(type, payload);
      if (targetUid is String && targetUid.trim() == trimmed) {
        return true;
      }
    }

    return false;
  }

  static Future<Set<String>> listPendingMemoUids(
    DatabaseExecutor executor,
  ) async {
    final rows = await executor.query(
      'outbox',
      columns: const ['type', 'payload'],
      where: 'state IN (?, ?, ?, ?, ?)',
      whereArgs: activeStates,
    );

    final uids = <String>{};
    for (final row in rows) {
      final type = row['type'];
      final payloadRaw = row['payload'];
      if (type is! String || payloadRaw is! String) continue;
      final payload = decodePayload(payloadRaw);
      if (payload == null) continue;
      final uid = extractMemoUid(type, payload);
      if (uid is String && uid.trim().isNotEmpty) {
        uids.add(uid.trim());
      }
    }
    return uids;
  }

  static Future<int> insertItem(
    DatabaseExecutor executor, {
    required String type,
    required Map<Object?, Object?> payload,
    required int createdTimeMs,
  }) {
    return executor.insert('outbox', {
      'type': type,
      'payload': jsonEncode(
        payload.map<String, Object?>(
          (mapKey, mapValue) => MapEntry(mapKey.toString(), mapValue),
        ),
      ),
      'state': statePending,
      'attempts': 0,
      'last_error': null,
      'failure_code': null,
      'failure_kind': null,
      'retry_at': null,
      'quarantined_at': null,
      'created_time': createdTimeMs,
    });
  }

  static Future<int> enqueueBatch(
    DatabaseExecutor executor, {
    required List<Map<String, Object?>> items,
    required int createdTimeMs,
  }) async {
    var insertedCount = 0;
    for (final item in items) {
      final type = (item['type'] as String? ?? '').trim();
      final payload = item['payload'];
      if (type.isEmpty || payload is! Map) continue;
      await insertItem(
        executor,
        type: type,
        payload: Map<Object?, Object?>.from(payload),
        createdTimeMs: createdTimeMs,
      );
      insertedCount++;
    }
    return insertedCount;
  }

  static Future<Map<String, dynamic>?> claimNextRunnable(
    DatabaseExecutor executor, {
    required int nowMs,
  }) async {
    final rows = await executor.query(
      'outbox',
      where: '(state = ? OR state = ?) AND (retry_at IS NULL OR retry_at <= ?)',
      whereArgs: [statePending, stateRetry, nowMs],
      orderBy: 'id ASC',
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final id = _readInt(rows.first['id']);
    if (id == null) return null;

    final updated = await executor.update(
      'outbox',
      {'state': stateRunning},
      where: 'id = ? AND (state = ? OR state = ?)',
      whereArgs: [id, statePending, stateRetry],
    );
    if (updated <= 0) return null;

    final claimedRows = await executor.query(
      'outbox',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (claimedRows.isEmpty) return null;
    return Map<String, dynamic>.from(claimedRows.first);
  }

  static Future<Map<String, dynamic>?> claimTaskById(
    DatabaseExecutor executor,
    int id, {
    required int nowMs,
  }) async {
    final updated = await executor.rawUpdate(
      '''
UPDATE outbox
SET state = ?
WHERE id = ?
  AND (
    state = ?
    OR (state = ? AND (retry_at IS NULL OR retry_at <= ?))
  );
''',
      [stateRunning, id, statePending, stateRetry, nowMs],
    );
    if (updated <= 0) return null;
    final rows = await executor.query(
      'outbox',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first);
  }

  static Future<int> recoverRunningTasks(DatabaseExecutor executor) {
    return executor.rawUpdate(
      'UPDATE outbox SET state = ?, retry_at = NULL WHERE state = ?',
      [statePending, stateRunning],
    );
  }

  static Future<void> markDone(DatabaseExecutor executor, int id) {
    return executor.rawUpdate(
      'UPDATE outbox SET state = ?, retry_at = NULL, last_error = NULL, failure_code = NULL, failure_kind = NULL, quarantined_at = NULL WHERE id = ?',
      [stateDone, id],
    );
  }

  static Future<void> completeTask(DatabaseExecutor executor, int id) async {
    await markDone(executor, id);
    await executor.delete('outbox', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> markError(
    DatabaseExecutor executor,
    int id, {
    required String error,
  }) {
    return executor.rawUpdate(
      'UPDATE outbox SET state = ?, attempts = attempts + 1, retry_at = NULL, last_error = ?, failure_code = NULL, failure_kind = NULL, quarantined_at = NULL WHERE id = ?',
      [stateError, error, id],
    );
  }

  static Future<void> markRetryScheduled(
    DatabaseExecutor executor,
    int id, {
    required String error,
    required int retryAtMs,
  }) {
    return executor.rawUpdate(
      'UPDATE outbox SET state = ?, attempts = attempts + 1, retry_at = ?, last_error = ?, failure_code = NULL, failure_kind = ?, quarantined_at = NULL WHERE id = ?',
      [stateRetry, retryAtMs, error, 'retryable', id],
    );
  }

  static Future<void> markQuarantined(
    DatabaseExecutor executor,
    int id, {
    required String error,
    required String failureCode,
    required String failureKind,
    required int quarantinedAtMs,
    bool incrementAttempts = true,
  }) {
    if (incrementAttempts) {
      return executor.rawUpdate(
        'UPDATE outbox SET state = ?, attempts = attempts + 1, retry_at = NULL, last_error = ?, failure_code = ?, failure_kind = ?, quarantined_at = ? WHERE id = ?',
        [
          stateQuarantined,
          error,
          failureCode,
          failureKind,
          quarantinedAtMs,
          id,
        ],
      );
    }
    return executor.rawUpdate(
      'UPDATE outbox SET state = ?, retry_at = NULL, last_error = ?, failure_code = ?, failure_kind = ?, quarantined_at = ? WHERE id = ?',
      [stateQuarantined, error, failureCode, failureKind, quarantinedAtMs, id],
    );
  }

  static Future<void> retryItem(DatabaseExecutor executor, int id) {
    return executor.rawUpdate(
      'UPDATE outbox SET state = ?, retry_at = NULL, last_error = NULL, failure_code = NULL, failure_kind = NULL, quarantined_at = NULL WHERE id = ?',
      [statePending, id],
    );
  }

  static Future<int> retryErrors(
    DatabaseExecutor executor, {
    String? memoUid,
  }) async {
    final normalizedMemoUid = (memoUid ?? '').trim();
    final rows = await executor.query(
      'outbox',
      columns: const ['id', 'type', 'payload'],
      where: 'state IN (?, ?)',
      whereArgs: attentionStates.reversed.toList(growable: false),
      orderBy: 'id ASC',
    );

    final ids = <int>[];
    for (final row in rows) {
      final id = _readInt(row['id']);
      if (id == null) continue;
      if (normalizedMemoUid.isEmpty) {
        ids.add(id);
        continue;
      }
      final type = row['type'];
      final payloadRaw = row['payload'];
      if (type is! String || payloadRaw is! String) continue;
      final payload = decodePayload(payloadRaw);
      if (payload == null) continue;
      final targetUid = extractMemoUid(type, payload);
      if (targetUid == null || targetUid.trim() != normalizedMemoUid) {
        continue;
      }
      ids.add(id);
    }

    if (ids.isEmpty) return 0;
    for (final id in ids) {
      await retryItem(executor, id);
    }
    return ids.length;
  }

  static Future<void> deleteById(DatabaseExecutor executor, int id) {
    return executor.delete('outbox', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteItems(
    DatabaseExecutor executor,
    List<int> ids,
  ) async {
    if (ids.isEmpty) return 0;
    final normalizedIds = ids.where((id) => id > 0).toList(growable: false);
    if (normalizedIds.isEmpty) return 0;
    final placeholders = List.filled(normalizedIds.length, '?').join(', ');
    return executor.delete(
      'outbox',
      where: 'id IN ($placeholders)',
      whereArgs: normalizedIds,
    );
  }

  static Future<void> clear(DatabaseExecutor executor) {
    return executor.delete('outbox');
  }

  static Future<int> deleteForMemo(
    DatabaseExecutor executor,
    String memoUid,
  ) async {
    final trimmed = memoUid.trim();
    if (trimmed.isEmpty) return 0;

    final rows = await executor.query(
      'outbox',
      columns: const ['id', 'type', 'payload'],
      where: 'state IN (?, ?, ?, ?, ?)',
      whereArgs: activeStates,
    );
    final ids = <int>[];
    for (final row in rows) {
      final id = _readInt(row['id']);
      final type = row['type'];
      final payloadRaw = row['payload'];
      if (id == null || type is! String || payloadRaw is! String) continue;
      final payload = decodePayload(payloadRaw);
      if (payload == null) continue;
      final target = extractMemoUid(type, payload);
      if (target is String && target.trim() == trimmed) {
        ids.add(id);
      }
    }
    if (ids.isEmpty) return 0;
    for (final id in ids) {
      await deleteById(executor, id);
    }
    return ids.length;
  }

  static Future<int> rewriteMemoUids(
    DatabaseExecutor executor, {
    required String oldUid,
    required String newUid,
  }) async {
    var changedCount = 0;
    final rows = await executor.query(
      'outbox',
      columns: const ['id', 'type', 'payload'],
    );
    for (final row in rows) {
      final id = _readInt(row['id']);
      final type = row['type'];
      final payloadRaw = row['payload'];
      if (id == null || type is! String || payloadRaw is! String) continue;

      final payload = decodePayload(payloadRaw);
      if (payload == null) continue;

      var changed = false;
      switch (type) {
        case 'create_memo':
        case 'update_memo':
        case 'delete_memo':
          if (payload['uid'] == oldUid) {
            payload['uid'] = newUid;
            changed = true;
          }
          break;
        case 'upload_attachment':
        case 'delete_attachment':
          if (payload['memo_uid'] == oldUid) {
            payload['memo_uid'] = newUid;
            changed = true;
          }
          break;
      }
      if (!changed) continue;

      await executor.update(
        'outbox',
        {'payload': jsonEncode(payload)},
        where: 'id = ?',
        whereArgs: [id],
      );
      changedCount++;
    }
    return changedCount;
  }

  static Future<int> updatePendingCreateMemoContent(
    DatabaseExecutor executor, {
    required String memoUid,
    required String content,
    String? visibility,
  }) async {
    final trimmedMemoUid = memoUid.trim();
    if (trimmedMemoUid.isEmpty) return 0;

    final rows = await executor.query(
      'outbox',
      columns: const ['id', 'payload'],
      where: 'type = ? AND state IN (?, ?, ?, ?, ?)',
      whereArgs: const [
        'create_memo',
        statePending,
        stateRunning,
        stateRetry,
        stateError,
        stateQuarantined,
      ],
    );

    var updatedCount = 0;
    for (final row in rows) {
      final id = _readInt(row['id']);
      final payloadRaw = row['payload'];
      if (id == null || payloadRaw is! String) continue;

      final payload = decodePayload(payloadRaw);
      if (payload == null) continue;
      final payloadUid = (payload['uid'] as String? ?? '').trim();
      if (payloadUid != trimmedMemoUid) continue;

      var changed = false;
      if (payload['content'] != content) {
        payload['content'] = content;
        changed = true;
      }
      if (visibility != null && payload['visibility'] != visibility) {
        payload['visibility'] = visibility;
        changed = true;
      }
      if (!changed) continue;

      await executor.update(
        'outbox',
        {'payload': jsonEncode(payload)},
        where: 'id = ?',
        whereArgs: [id],
      );
      updatedCount++;
    }
    return updatedCount;
  }

  static Map<String, dynamic>? decodePayload(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return decoded.cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> withDerivedAttentionFields(
    Map<String, Object?> row,
  ) {
    final copy = row.map((key, value) => MapEntry(key, value));
    final type = copy['type'] as String?;
    final payloadRaw = copy['payload'] as String?;
    if (type != null && payloadRaw != null) {
      final payload = decodePayload(payloadRaw);
      if (payload != null) {
        copy['memo_uid'] = extractMemoUid(type, payload);
      }
    }
    copy['occurred_at'] = copy['quarantined_at'] ?? copy['created_time'];
    return copy;
  }

  static String? extractMemoUid(String type, Map<String, dynamic> payload) {
    return switch (type) {
      'create_memo' ||
      'update_memo' ||
      'delete_memo' => payload['uid'] as String?,
      'upload_attachment' ||
      'delete_attachment' => payload['memo_uid'] as String?,
      _ => null,
    };
  }

  static String? extractMemoUidFromRow(Object? type, Object? payloadRaw) {
    if (type is! String || payloadRaw is! String) return null;
    final payload = decodePayload(payloadRaw);
    if (payload == null) return null;
    final uid = extractMemoUid(type, payload);
    final trimmed = uid?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  static Future<int> _countWhere(
    DatabaseExecutor executor,
    String where,
  ) async {
    final rows = await executor.rawQuery(
      'SELECT COUNT(*) AS count FROM outbox WHERE $where',
    );
    if (rows.isEmpty) return 0;
    return _readInt(rows.first['count']) ?? 0;
  }

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static Future<void> _ensureColumnExists(
    Database db, {
    required String table,
    required String column,
    required String definition,
  }) async {
    if (await _tableHasColumn(db, table, column)) {
      return;
    }
    await db.execute(
      'ALTER TABLE ${_quoteIdentifier(table)} ADD COLUMN $definition;',
    );
  }

  static Future<bool> _tableHasColumn(
    Database db,
    String table,
    String column,
  ) async {
    final rows = await db.rawQuery(
      'PRAGMA table_info(${_quoteIdentifier(table)});',
    );
    return rows.any((row) => row['name'] == column);
  }

  static String _quoteIdentifier(String identifier) {
    final escaped = identifier.replaceAll('"', '""');
    return '"$escaped"';
  }
}

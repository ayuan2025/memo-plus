import 'package:sqflite/sqflite.dart';

final class MemoLifecycleDbPersistence {
  const MemoLifecycleDbPersistence._();

  static Future<void> ensureTables(Database db) async {
    await ensureMemoRelationsCacheTable(db);
    await ensureMemoVersionsTable(db);
    await ensureRecycleBinTable(db);
    await ensureMemoDeleteTombstoneTable(db);
    await ensureMemoInlineImageSourceTable(db);
  }

  static Future<void> ensureMemoRelationsCacheTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS memo_relations_cache (
  memo_uid TEXT NOT NULL PRIMARY KEY,
  relations_json TEXT NOT NULL DEFAULT '[]',
  updated_time INTEGER NOT NULL
);
''');
  }

  static Future<void> ensureMemoVersionsTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS memo_versions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  memo_uid TEXT NOT NULL,
  snapshot_time INTEGER NOT NULL,
  summary TEXT NOT NULL DEFAULT '',
  payload_json TEXT NOT NULL DEFAULT '{}',
  created_time INTEGER NOT NULL
);
''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_memo_versions_memo_time ON memo_versions(memo_uid, snapshot_time DESC);',
    );
  }

  static Future<void> ensureRecycleBinTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS recycle_bin_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  item_type TEXT NOT NULL,
  memo_uid TEXT NOT NULL DEFAULT '',
  summary TEXT NOT NULL DEFAULT '',
  payload_json TEXT NOT NULL DEFAULT '{}',
  deleted_time INTEGER NOT NULL,
  expire_time INTEGER NOT NULL
);
''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_recycle_bin_items_deleted_time ON recycle_bin_items(deleted_time DESC);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_recycle_bin_items_expire_time ON recycle_bin_items(expire_time ASC);',
    );
  }

  static Future<void> ensureMemoDeleteTombstoneTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS memo_delete_tombstones (
  memo_uid TEXT NOT NULL PRIMARY KEY,
  state TEXT NOT NULL,
  deleted_time INTEGER NOT NULL,
  updated_time INTEGER NOT NULL,
  last_error TEXT
);
''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_memo_delete_tombstones_state_updated ON memo_delete_tombstones(state, updated_time DESC);',
    );
  }

  static Future<void> ensureMemoInlineImageSourceTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS memo_inline_image_sources (
  memo_uid TEXT NOT NULL,
  local_url TEXT NOT NULL,
  source_url TEXT NOT NULL,
  updated_time INTEGER NOT NULL,
  PRIMARY KEY (memo_uid, local_url)
);
''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_memo_inline_image_sources_memo ON memo_inline_image_sources(memo_uid, updated_time DESC);',
    );
  }

  static Future<String?> getMemoRelationsCacheJson(
    DatabaseExecutor executor,
    String memoUid,
  ) async {
    final normalized = memoUid.trim();
    if (normalized.isEmpty) return null;
    final rows = await executor.query(
      'memo_relations_cache',
      columns: const ['relations_json'],
      where: 'memo_uid = ?',
      whereArgs: [normalized],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final raw = rows.first['relations_json'];
    return raw is String ? raw : null;
  }

  static Future<void> upsertMemoRelationsCache(
    DatabaseExecutor executor,
    String memoUid, {
    required String relationsJson,
  }) async {
    final normalized = memoUid.trim();
    if (normalized.isEmpty) return;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final updated = await executor.update(
      'memo_relations_cache',
      {'relations_json': relationsJson, 'updated_time': now},
      where: 'memo_uid = ?',
      whereArgs: [normalized],
    );
    if (updated == 0) {
      await executor.insert('memo_relations_cache', {
        'memo_uid': normalized,
        'relations_json': relationsJson,
        'updated_time': now,
      }, conflictAlgorithm: ConflictAlgorithm.abort);
    }
  }

  static Future<void> deleteMemoRelationsCache(
    DatabaseExecutor executor,
    String memoUid,
  ) async {
    final normalized = memoUid.trim();
    if (normalized.isEmpty) return;
    await executor.delete(
      'memo_relations_cache',
      where: 'memo_uid = ?',
      whereArgs: [normalized],
    );
  }

  static Future<int> insertMemoVersion(
    DatabaseExecutor executor, {
    required String memoUid,
    required int snapshotTime,
    required String summary,
    required String payloadJson,
  }) async {
    final normalizedUid = memoUid.trim();
    if (normalizedUid.isEmpty) {
      throw const FormatException('memo_uid is required');
    }
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    return executor.insert('memo_versions', {
      'memo_uid': normalizedUid,
      'snapshot_time': snapshotTime,
      'summary': summary,
      'payload_json': payloadJson,
      'created_time': now,
    });
  }

  static Future<List<Map<String, dynamic>>> listMemoVersionsByUid(
    DatabaseExecutor executor,
    String memoUid, {
    int? limit,
  }) async {
    final normalizedUid = memoUid.trim();
    if (normalizedUid.isEmpty) return const [];
    return executor.query(
      'memo_versions',
      where: 'memo_uid = ?',
      whereArgs: [normalizedUid],
      orderBy: 'snapshot_time DESC, id DESC',
      limit: (limit != null && limit > 0) ? limit : null,
    );
  }

  static Future<List<int>> listMemoVersionIdsExceedLimit(
    DatabaseExecutor executor,
    String memoUid, {
    required int keep,
  }) async {
    final normalizedUid = memoUid.trim();
    if (normalizedUid.isEmpty) return const [];
    if (keep < 0) return const [];
    final rows = await executor.query(
      'memo_versions',
      columns: const ['id'],
      where: 'memo_uid = ?',
      whereArgs: [normalizedUid],
      orderBy: 'snapshot_time DESC, id DESC',
      offset: keep,
    );
    final ids = <int>[];
    for (final row in rows) {
      final id = _readInt(row['id']);
      if (id != null) ids.add(id);
    }
    return ids;
  }

  static Future<Map<String, dynamic>?> getMemoVersionById(
    DatabaseExecutor executor,
    int id,
  ) async {
    final rows = await executor.query(
      'memo_versions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  static Future<void> deleteMemoVersionById(
    DatabaseExecutor executor,
    int id,
  ) async {
    await executor.delete('memo_versions', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteMemoVersionsByMemoUid(
    DatabaseExecutor executor,
    String memoUid,
  ) async {
    final normalizedUid = memoUid.trim();
    if (normalizedUid.isEmpty) return;
    await executor.delete(
      'memo_versions',
      where: 'memo_uid = ?',
      whereArgs: [normalizedUid],
    );
  }

  static Future<int> insertRecycleBinItem(
    DatabaseExecutor executor, {
    required String itemType,
    required String memoUid,
    required String summary,
    required String payloadJson,
    required int deletedTime,
    required int expireTime,
  }) {
    return executor.insert('recycle_bin_items', {
      'item_type': itemType,
      'memo_uid': memoUid.trim(),
      'summary': summary,
      'payload_json': payloadJson,
      'deleted_time': deletedTime,
      'expire_time': expireTime,
    });
  }

  static Future<Set<String>> listRecycleBinMemoUids(
    DatabaseExecutor executor,
  ) async {
    final rows = await executor.query(
      'recycle_bin_items',
      columns: const ['memo_uid'],
      where: 'item_type = ? AND memo_uid <> ?',
      whereArgs: const ['memo', ''],
    );
    final uids = <String>{};
    for (final row in rows) {
      final raw = row['memo_uid'];
      final uid = raw is String ? raw.trim() : '';
      if (uid.isNotEmpty) {
        uids.add(uid);
      }
    }
    return uids;
  }

  static Future<bool> hasRecycleBinMemoItem(
    DatabaseExecutor executor,
    String memoUid,
  ) async {
    final normalizedUid = memoUid.trim();
    if (normalizedUid.isEmpty) return false;
    final rows = await executor.query(
      'recycle_bin_items',
      columns: const ['id'],
      where: 'item_type = ? AND memo_uid = ?',
      whereArgs: ['memo', normalizedUid],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  static Future<List<Map<String, dynamic>>> listRecycleBinItems(
    DatabaseExecutor executor,
  ) {
    return executor.query(
      'recycle_bin_items',
      orderBy: 'deleted_time DESC, id DESC',
    );
  }

  static Future<Map<String, dynamic>?> getRecycleBinItemById(
    DatabaseExecutor executor,
    int id,
  ) async {
    final rows = await executor.query(
      'recycle_bin_items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  static Future<List<int>> listExpiredRecycleBinItemIds(
    DatabaseExecutor executor, {
    required int nowMs,
  }) async {
    final rows = await executor.query(
      'recycle_bin_items',
      columns: const ['id'],
      where: 'expire_time <= ?',
      whereArgs: [nowMs],
      orderBy: 'expire_time ASC, id ASC',
    );
    final ids = <int>[];
    for (final row in rows) {
      final id = _readInt(row['id']);
      if (id != null) ids.add(id);
    }
    return ids;
  }

  static Future<void> deleteRecycleBinItemById(
    DatabaseExecutor executor,
    int id,
  ) async {
    await executor.delete(
      'recycle_bin_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> clearRecycleBinItems(DatabaseExecutor executor) async {
    await executor.delete('recycle_bin_items');
  }

  static Future<void> upsertMemoDeleteTombstone(
    DatabaseExecutor executor, {
    required String memoUid,
    required String state,
    String? lastError,
    int? deletedTime,
  }) async {
    final normalizedUid = memoUid.trim();
    if (normalizedUid.isEmpty) return;
    final existing = await executor.query(
      'memo_delete_tombstones',
      columns: const ['deleted_time'],
      where: 'memo_uid = ?',
      whereArgs: [normalizedUid],
      limit: 1,
    );
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final deletedTimeValue = switch (existing.isEmpty
        ? null
        : existing.first['deleted_time']) {
      int value when deletedTime == null => value,
      num value when deletedTime == null => value.toInt(),
      String value when deletedTime == null =>
        int.tryParse(value.trim()) ?? now,
      _ => deletedTime ?? now,
    };
    await executor.insert('memo_delete_tombstones', {
      'memo_uid': normalizedUid,
      'state': state,
      'deleted_time': deletedTimeValue,
      'updated_time': now,
      'last_error': lastError,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Map<String, dynamic>?> getMemoDeleteTombstone(
    DatabaseExecutor executor,
    String memoUid,
  ) async {
    final normalizedUid = memoUid.trim();
    if (normalizedUid.isEmpty) return null;
    final rows = await executor.query(
      'memo_delete_tombstones',
      where: 'memo_uid = ?',
      whereArgs: [normalizedUid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  static Future<String?> getMemoDeleteTombstoneState(
    DatabaseExecutor executor,
    String memoUid,
  ) async {
    final row = await getMemoDeleteTombstone(executor, memoUid);
    final state = row?['state'];
    return state is String && state.trim().isNotEmpty ? state.trim() : null;
  }

  static Future<Set<String>> listMemoDeleteTombstoneUids(
    DatabaseExecutor executor,
  ) async {
    final rows = await executor.query(
      'memo_delete_tombstones',
      columns: const ['memo_uid'],
    );
    final uids = <String>{};
    for (final row in rows) {
      final raw = row['memo_uid'];
      final uid = raw is String ? raw.trim() : '';
      if (uid.isNotEmpty) {
        uids.add(uid);
      }
    }
    return uids;
  }

  static Future<void> deleteMemoDeleteTombstone(
    DatabaseExecutor executor,
    String memoUid,
  ) async {
    final normalizedUid = memoUid.trim();
    if (normalizedUid.isEmpty) return;
    await executor.delete(
      'memo_delete_tombstones',
      where: 'memo_uid = ?',
      whereArgs: [normalizedUid],
    );
  }

  static Future<void> upsertMemoInlineImageSource(
    DatabaseExecutor executor, {
    required String memoUid,
    required String localUrl,
    required String sourceUrl,
  }) async {
    final normalizedUid = memoUid.trim();
    final normalizedLocalUrl = localUrl.trim();
    final normalizedSourceUrl = sourceUrl.trim();
    if (normalizedUid.isEmpty ||
        normalizedLocalUrl.isEmpty ||
        normalizedSourceUrl.isEmpty) {
      return;
    }
    await executor.insert('memo_inline_image_sources', {
      'memo_uid': normalizedUid,
      'local_url': normalizedLocalUrl,
      'source_url': normalizedSourceUrl,
      'updated_time': DateTime.now().toUtc().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Map<String, String>> listMemoInlineImageSources(
    DatabaseExecutor executor,
    String memoUid,
  ) async {
    final normalizedUid = memoUid.trim();
    if (normalizedUid.isEmpty) return const <String, String>{};
    final rows = await executor.query(
      'memo_inline_image_sources',
      columns: const ['local_url', 'source_url'],
      where: 'memo_uid = ?',
      whereArgs: [normalizedUid],
      orderBy: 'updated_time DESC',
    );
    final mappings = <String, String>{};
    for (final row in rows) {
      final localUrl = (row['local_url'] as String? ?? '').trim();
      final sourceUrl = (row['source_url'] as String? ?? '').trim();
      if (localUrl.isEmpty || sourceUrl.isEmpty) continue;
      mappings.putIfAbsent(localUrl, () => sourceUrl);
    }
    return mappings;
  }

  static Future<void> deleteMemoInlineImageSources(
    DatabaseExecutor executor,
    String memoUid,
  ) async {
    final normalizedUid = memoUid.trim();
    if (normalizedUid.isEmpty) return;
    await executor.delete(
      'memo_inline_image_sources',
      where: 'memo_uid = ?',
      whereArgs: [normalizedUid],
    );
  }

  static Future<void> deleteMemoLifecycleRowsForMemo(
    DatabaseExecutor executor,
    String memoUid,
  ) async {
    await deleteMemoRelationsCache(executor, memoUid);
    await deleteMemoVersionsByMemoUid(executor, memoUid);
  }

  static Future<void> renameMemoUid(
    DatabaseExecutor executor, {
    required String oldUid,
    required String newUid,
  }) async {
    await executor.update(
      'memo_relations_cache',
      {'memo_uid': newUid},
      where: 'memo_uid = ?',
      whereArgs: [oldUid],
    );
    await executor.update(
      'memo_versions',
      {'memo_uid': newUid},
      where: 'memo_uid = ?',
      whereArgs: [oldUid],
    );
    await executor.update(
      'recycle_bin_items',
      {'memo_uid': newUid},
      where: 'memo_uid = ?',
      whereArgs: [oldUid],
    );
    await executor.update(
      'memo_inline_image_sources',
      {'memo_uid': newUid},
      where: 'memo_uid = ?',
      whereArgs: [oldUid],
    );
  }

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}

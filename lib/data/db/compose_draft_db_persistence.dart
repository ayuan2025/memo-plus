import 'package:sqflite/sqflite.dart';

class ComposeDraftDbPersistence {
  const ComposeDraftDbPersistence._();

  static Future<void> ensureTable(Database sqlite) async {
    await sqlite.execute('''
CREATE TABLE IF NOT EXISTS compose_drafts (
  uid TEXT NOT NULL PRIMARY KEY,
  workspace_key TEXT NOT NULL,
  content TEXT NOT NULL,
  visibility TEXT NOT NULL,
  draft_kind TEXT NOT NULL DEFAULT 'create_memo',
  target_memo_uid TEXT,
  target_memo_content_fingerprint TEXT,
  target_memo_update_time INTEGER,
  relations_json TEXT NOT NULL DEFAULT '[]',
  attachments_json TEXT NOT NULL DEFAULT '[]',
  existing_attachments_json TEXT NOT NULL DEFAULT '[]',
  location_placeholder TEXT,
  location_lat REAL,
  location_lng REAL,
  created_time INTEGER NOT NULL,
  updated_time INTEGER NOT NULL
);
''');
    await ensureIndexes(sqlite);
  }

  static Future<void> ensureIndexes(Database sqlite) async {
    await sqlite.execute(
      'CREATE INDEX IF NOT EXISTS idx_compose_drafts_workspace_updated ON compose_drafts(workspace_key, updated_time DESC);',
    );
    await sqlite.execute(
      "CREATE UNIQUE INDEX IF NOT EXISTS idx_compose_drafts_workspace_edit_target ON compose_drafts(workspace_key, target_memo_uid) WHERE draft_kind = 'edit_memo' AND target_memo_uid IS NOT NULL AND target_memo_uid <> '';",
    );
  }

  static Future<void> ensureEditDraftColumns(Database sqlite) async {
    if (!await _tableExists(sqlite, 'compose_drafts')) {
      return;
    }
    await _ensureColumnExists(
      sqlite,
      table: 'compose_drafts',
      column: 'draft_kind',
      definition: "draft_kind TEXT NOT NULL DEFAULT 'create_memo'",
    );
    await _ensureColumnExists(
      sqlite,
      table: 'compose_drafts',
      column: 'target_memo_uid',
      definition: 'target_memo_uid TEXT',
    );
    await _ensureColumnExists(
      sqlite,
      table: 'compose_drafts',
      column: 'target_memo_content_fingerprint',
      definition: 'target_memo_content_fingerprint TEXT',
    );
    await _ensureColumnExists(
      sqlite,
      table: 'compose_drafts',
      column: 'target_memo_update_time',
      definition: 'target_memo_update_time INTEGER',
    );
    await _ensureColumnExists(
      sqlite,
      table: 'compose_drafts',
      column: 'existing_attachments_json',
      definition: "existing_attachments_json TEXT NOT NULL DEFAULT '[]'",
    );
    await ensureIndexes(sqlite);
  }

  static Future<List<Map<String, dynamic>>> listRows(
    DatabaseExecutor executor, {
    required String workspaceKey,
    int? limit,
  }) {
    return executor.query(
      'compose_drafts',
      where: 'workspace_key = ?',
      whereArgs: [workspaceKey],
      orderBy: 'updated_time DESC',
      limit: limit,
    );
  }

  static Future<Map<String, dynamic>?> getRow(
    DatabaseExecutor executor, {
    required String uid,
    String? workspaceKey,
  }) async {
    final whereParts = <String>['uid = ?'];
    final whereArgs = <Object?>[uid];
    final normalizedWorkspaceKey = workspaceKey?.trim();
    if (normalizedWorkspaceKey != null && normalizedWorkspaceKey.isNotEmpty) {
      whereParts.add('workspace_key = ?');
      whereArgs.add(normalizedWorkspaceKey);
    }
    final rows = await executor.query(
      'compose_drafts',
      where: whereParts.join(' AND '),
      whereArgs: whereArgs,
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  static Future<Map<String, dynamic>?> getEditDraftRowForMemo(
    DatabaseExecutor executor, {
    required String workspaceKey,
    required String targetMemoUid,
  }) async {
    final normalizedWorkspaceKey = workspaceKey.trim();
    final normalizedTargetMemoUid = targetMemoUid.trim();
    if (normalizedWorkspaceKey.isEmpty || normalizedTargetMemoUid.isEmpty) {
      return null;
    }
    final rows = await executor.query(
      'compose_drafts',
      where:
          "workspace_key = ? AND draft_kind = 'edit_memo' AND target_memo_uid = ?",
      whereArgs: [normalizedWorkspaceKey, normalizedTargetMemoUid],
      orderBy: 'updated_time DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  static Future<Map<String, dynamic>?> getLatestRow(
    DatabaseExecutor executor, {
    required String workspaceKey,
  }) async {
    final rows = await listRows(executor, workspaceKey: workspaceKey, limit: 1);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  static Future<void> upsertRow(
    DatabaseExecutor executor,
    Map<String, Object?> row,
  ) async {
    await executor.insert(
      'compose_drafts',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> replaceRowsInExecutor(
    DatabaseExecutor executor, {
    required String workspaceKey,
    required List<Map<String, Object?>> rows,
  }) async {
    await executor.delete(
      'compose_drafts',
      where: 'workspace_key = ?',
      whereArgs: [workspaceKey],
    );
    for (final row in rows) {
      await executor.insert(
        'compose_drafts',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  static Future<void> deleteRow(DatabaseExecutor executor, String uid) async {
    await executor.delete('compose_drafts', where: 'uid = ?', whereArgs: [uid]);
  }

  static Future<void> deleteRowsByWorkspace(
    DatabaseExecutor executor,
    String workspaceKey,
  ) async {
    await executor.delete(
      'compose_drafts',
      where: 'workspace_key = ?',
      whereArgs: [workspaceKey],
    );
  }

  static Future<bool> _tableExists(Database sqlite, String table) async {
    final rows = await sqlite.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ? LIMIT 1;",
      [table],
    );
    return rows.isNotEmpty;
  }

  static Future<void> _ensureColumnExists(
    Database sqlite, {
    required String table,
    required String column,
    required String definition,
  }) async {
    if (await _tableHasColumn(sqlite, table, column)) {
      return;
    }
    await sqlite.execute(
      'ALTER TABLE ${_quoteIdentifier(table)} ADD COLUMN $definition;',
    );
  }

  static Future<bool> _tableHasColumn(
    Database sqlite,
    String table,
    String column,
  ) async {
    final rows = await sqlite.rawQuery(
      'PRAGMA table_info(${_quoteIdentifier(table)});',
    );
    return rows.any((row) => row['name'] == column);
  }

  static String _quoteIdentifier(String identifier) {
    final escaped = identifier.replaceAll('"', '""');
    return '"$escaped"';
  }
}

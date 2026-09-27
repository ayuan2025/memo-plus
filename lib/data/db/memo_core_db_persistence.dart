import 'package:sqflite/sqflite.dart';

final class MemoCoreDbPersistence {
  const MemoCoreDbPersistence._();

  static Future<void> ensureMemoTable(Database db) {
    return db.execute('''
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
  }

  static Future<void> ensureAttachmentTable(Database db) {
    return db.execute('''
CREATE TABLE IF NOT EXISTS attachments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uid TEXT NOT NULL UNIQUE,
  memo_uid TEXT,
  filename TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  size INTEGER NOT NULL,
  external_link TEXT,
  create_time INTEGER NOT NULL,
  local_path TEXT,
  downloaded INTEGER NOT NULL DEFAULT 0,
  pending_upload INTEGER NOT NULL DEFAULT 0
);
''');
  }

  static Future<void> ensureRelationCountColumn(Database db) {
    return _ensureColumnExists(
      db,
      table: 'memos',
      column: 'relation_count',
      definition: 'relation_count INTEGER NOT NULL DEFAULT 0',
    );
  }

  static Future<void> ensureLocationColumns(Database db) async {
    await _ensureColumnExists(
      db,
      table: 'memos',
      column: 'location_placeholder',
      definition: 'location_placeholder TEXT',
    );
    await _ensureColumnExists(
      db,
      table: 'memos',
      column: 'location_lat',
      definition: 'location_lat REAL',
    );
    await _ensureColumnExists(
      db,
      table: 'memos',
      column: 'location_lng',
      definition: 'location_lng REAL',
    );
  }

  static Future<void> ensureDisplayTimeColumnAndBackfill(Database db) async {
    await _ensureColumnExists(
      db,
      table: 'memos',
      column: 'display_time',
      definition: 'display_time INTEGER',
    );
    await db.execute(
      'UPDATE memos SET display_time = create_time WHERE display_time IS NULL;',
    );
  }

  static Future<int> countMemos(DatabaseExecutor executor) async {
    final rows = await executor.rawQuery('SELECT COUNT(*) AS count FROM memos');
    if (rows.isEmpty) return 0;
    return _readInt(rows.first['count']) ?? 0;
  }

  static Future<void> renameAttachmentMemoUid(
    DatabaseExecutor executor, {
    required String oldUid,
    required String newUid,
  }) {
    return executor.update(
      'attachments',
      {'memo_uid': newUid},
      where: 'memo_uid = ?',
      whereArgs: [oldUid],
    );
  }

  static String _quoteIdentifier(String identifier) {
    final escaped = identifier.replaceAll('"', '""');
    return '"$escaped"';
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

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}

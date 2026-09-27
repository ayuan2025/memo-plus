import 'dart:convert';

import 'package:sqflite/sqflite.dart';

final class MemoWriteDbPersistence {
  const MemoWriteDbPersistence._();

  static Future<void> updateMemoSyncState(
    DatabaseExecutor executor,
    String uid, {
    required int syncState,
    String? lastError,
  }) {
    return executor.update(
      'memos',
      {'sync_state': syncState, 'last_error': lastError},
      where: 'uid = ?',
      whereArgs: [uid],
    );
  }

  static Future<void> updateMemoAttachmentsJson(
    DatabaseExecutor executor,
    String uid, {
    required String attachmentsJson,
  }) {
    return executor.update(
      'memos',
      {'attachments_json': attachmentsJson},
      where: 'uid = ?',
      whereArgs: [uid],
    );
  }

  static Future<void> updateMemoTagsTextByUid(
    DatabaseExecutor executor,
    String uid, {
    required String tagsText,
  }) {
    return executor.update(
      'memos',
      {'tags': tagsText},
      where: 'uid = ?',
      whereArgs: [uid],
    );
  }

  static Future<void> updateMemoTagsTextById(
    DatabaseExecutor executor,
    int id, {
    required String tagsText,
  }) {
    return executor.update(
      'memos',
      {'tags': tagsText},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> renameMemoUidRow(
    DatabaseExecutor executor, {
    required String oldUid,
    required String newUid,
  }) {
    return executor.update(
      'memos',
      {'uid': newUid},
      where: 'uid = ?',
      whereArgs: [oldUid],
    );
  }

  static Future<bool> removePendingAttachmentPlaceholder(
    DatabaseExecutor executor, {
    required String memoUid,
    required String attachmentUid,
  }) async {
    final rows = await executor.query(
      'memos',
      columns: const ['attachments_json'],
      where: 'uid = ?',
      whereArgs: [memoUid],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    final raw = rows.first['attachments_json'];
    if (raw is! String || raw.trim().isEmpty) return false;

    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return false;
    }
    if (decoded is! List) return false;

    final expectedNames = <String>{
      'attachments/$attachmentUid',
      'resources/$attachmentUid',
    };
    var changed = false;
    final next = <Map<String, dynamic>>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final map = item.cast<String, dynamic>();
      final name = (map['name'] as String?)?.trim() ?? '';
      if (expectedNames.contains(name)) {
        changed = true;
        continue;
      }
      next.add(map);
    }
    if (!changed) return false;

    await updateMemoAttachmentsJson(
      executor,
      memoUid,
      attachmentsJson: jsonEncode(next),
    );
    return true;
  }

  static Future<int> upsertMemoRow(
    DatabaseExecutor executor,
    MemoWriteRowDraft draft,
  ) async {
    final attachmentsJson = jsonEncode(draft.attachments);
    final values = <String, Object?>{
      'content': draft.content,
      'visibility': draft.visibility,
      'pinned': draft.pinned ? 1 : 0,
      'state': draft.state,
      'create_time': draft.createTimeSec,
      'update_time': draft.updateTimeSec,
      'tags': draft.tagsText,
      'attachments_json': attachmentsJson,
      'location_placeholder': draft.locationPlaceholder,
      'location_lat': draft.locationLat,
      'location_lng': draft.locationLng,
      'relation_count': draft.relationCount,
      'sync_state': draft.syncState,
      'last_error': draft.lastError,
    };
    if (!draft.preserveDisplayTime) {
      values['display_time'] = draft.displayTimeSec;
    }

    final updated = await executor.update(
      'memos',
      values,
      where: 'uid = ?',
      whereArgs: [draft.uid],
    );
    if (updated > 0) {
      return await getMemoRowIdByUid(executor, draft.uid) ?? 0;
    }

    return executor.insert('memos', {
      'uid': draft.uid,
      'content': draft.content,
      'visibility': draft.visibility,
      'pinned': draft.pinned ? 1 : 0,
      'state': draft.state,
      'create_time': draft.createTimeSec,
      'display_time': draft.displayTimeSec,
      'update_time': draft.updateTimeSec,
      'tags': draft.tagsText,
      'attachments_json': attachmentsJson,
      'location_placeholder': draft.locationPlaceholder,
      'location_lat': draft.locationLat,
      'location_lng': draft.locationLng,
      'relation_count': draft.relationCount,
      'sync_state': draft.syncState,
      'last_error': draft.lastError,
    }, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  static Future<int?> deleteMemoRowByUid(
    DatabaseExecutor executor,
    String uid,
  ) async {
    final rowId = await getMemoRowIdByUid(executor, uid);
    await executor.delete('memos', where: 'uid = ?', whereArgs: [uid]);
    return rowId;
  }

  static Future<int?> getMemoRowIdByUid(
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

  static Future<MemoWriteSearchRefreshRow?> getMemoSearchRefreshRow(
    DatabaseExecutor executor,
    String uid,
  ) async {
    final rows = await executor.query(
      'memos',
      columns: const ['id', 'content', 'tags'],
      where: 'uid = ?',
      whereArgs: [uid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final rowId = _readInt(rows.first['id']) ?? 0;
    if (rowId <= 0) return null;
    return MemoWriteSearchRefreshRow(
      rowId: rowId,
      content: (rows.first['content'] as String?) ?? '',
      tags: (rows.first['tags'] as String?) ?? '',
    );
  }

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}

final class MemoWriteRowDraft {
  const MemoWriteRowDraft({
    required this.uid,
    required this.content,
    required this.visibility,
    required this.pinned,
    required this.state,
    required this.createTimeSec,
    required this.displayTimeSec,
    required this.preserveDisplayTime,
    required this.updateTimeSec,
    required this.tagsText,
    required this.attachments,
    required this.locationPlaceholder,
    required this.locationLat,
    required this.locationLng,
    required this.relationCount,
    required this.syncState,
    required this.lastError,
  });

  final String uid;
  final String content;
  final String visibility;
  final bool pinned;
  final String state;
  final int createTimeSec;
  final int? displayTimeSec;
  final bool preserveDisplayTime;
  final int updateTimeSec;
  final String tagsText;
  final List<Map<String, dynamic>> attachments;
  final String? locationPlaceholder;
  final double? locationLat;
  final double? locationLng;
  final int relationCount;
  final int syncState;
  final String? lastError;
}

final class MemoWriteSearchRefreshRow {
  const MemoWriteSearchRefreshRow({
    required this.rowId,
    required this.content,
    required this.tags,
  });

  final int rowId;
  final String content;
  final String tags;
}

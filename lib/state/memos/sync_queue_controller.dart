import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/sync/sync_request.dart';
import '../../application/sync/sync_error.dart';
import '../../application/sync/sync_types.dart';
import '../../data/db/app_database.dart';
import '../../data/models/local_memo.dart';
import '../system/database_provider.dart';
import '../sync/sync_coordinator_provider.dart';
import 'memo_mutation_service.dart';
import 'sync_queue_models.dart';

final syncQueueControllerProvider = Provider<SyncQueueController>((ref) {
  return SyncQueueController(ref);
});

class SyncQueueController {
  SyncQueueController(this._ref);

  final Ref _ref;

  Future<void> deleteItem(SyncQueueItem item) async {
    final db = _ref.read(databaseProvider);
    final memoUid = item.memoUid?.trim();
    if (memoUid != null && memoUid.isNotEmpty) {
      final memoRow = await db.getMemoByUid(memoUid);
      final currentLastError = memoRow?['last_error'] as String?;
      final shouldPreserveLocalOnlyMemo =
          item.type == 'create_memo' ||
          isLocalOnlySyncPausedError(currentLastError);
      if (shouldPreserveLocalOnlyMemo) {
        await _ref
            .read(memoMutationServiceProvider)
            .deleteMemoSyncTasksPreservingLocalOnly(
              memoUid: memoUid,
              existingRow: memoRow,
            );
        return;
      }
      final tombstoneState = await db.getMemoDeleteTombstoneState(memoUid);
      await _ref
          .read(memoMutationServiceProvider)
          .deleteSyncQueueItem(
            outboxId: item.id,
            memoUid: memoUid,
            attachmentUid: item.type == 'upload_attachment'
                ? item.attachmentUid
                : null,
            keepDeleteTombstoneLocalOnly:
                item.type == 'delete_memo' && tombstoneState != null,
          );
      return;
    }

    await _ref
        .read(memoMutationServiceProvider)
        .deleteSyncQueueItem(outboxId: item.id);
  }

  Future<void> retryItem(SyncQueueItem item) async {
    final memoUid = item.memoUid?.trim();
    if (item.needsAttention) {
      if (memoUid != null && memoUid.isNotEmpty) {
        final rebuilt = await retryQuarantinedMemoItem(item);
        if (rebuilt) {
          return;
        }
        final retried = await _ref
            .read(memoMutationServiceProvider)
            .retryOutboxErrors(memoUid: memoUid);
        if (retried > 0) {
          return;
        }
      }
      await _ref
          .read(memoMutationServiceProvider)
          .retryOutboxItem(outboxId: item.id);
      return;
    }
    if (memoUid != null && memoUid.isNotEmpty) {
      await _ref
          .read(memoMutationServiceProvider)
          .retryOutboxErrors(memoUid: memoUid);
      return;
    }
    await _ref
        .read(memoMutationServiceProvider)
        .retryOutboxItem(outboxId: item.id);
  }

  Future<bool> retryQuarantinedMemoItem(SyncQueueItem item) async {
    final memoUid = item.memoUid?.trim();
    if (memoUid == null || memoUid.isEmpty) return false;
    return rebuildMemoSyncTasks(
      memoUid,
      preferredRootType:
          item.type == 'create_memo' ||
              item.failureCode?.trim() == 'remote_missing_memo'
          ? 'create_memo'
          : null,
    );
  }

  Future<bool> rebuildMemoSyncTasks(
    String memoUid, {
    String? preferredRootType,
  }) async {
    final db = _ref.read(databaseProvider);
    final normalizedMemoUid = memoUid.trim();
    if (normalizedMemoUid.isEmpty) return false;

    final row = await db.getMemoByUid(normalizedMemoUid);
    if (row == null) {
      return false;
    }
    final memo = LocalMemo.fromDb(row);
    final existingItems = await db.listOutboxByMemoUid(normalizedMemoUid);
    final attentionIds = existingItems
        .where((row) => _isAttentionState(_stateFromOutboxRow(row)))
        .map((row) => row['id'])
        .whereType<int>()
        .toList(growable: false);
    if (attentionIds.isEmpty) {
      return false;
    }
    final hasActiveItems = existingItems.any(
      (row) => _isActiveState(_stateFromOutboxRow(row)),
    );
    final rootType = _resolveRebuildRootType(
      existingItems: existingItems,
      preferredRootType: preferredRootType,
    );
    final uploadPayloads = _collectUploadAttachmentPayloads(existingItems);
    final deletePayloads = _collectDeleteAttachmentPayloads(existingItems);
    final relations = await _loadMemoRelationsPayload(db, normalizedMemoUid);
    final shouldSyncAttachments =
        memo.attachments.isNotEmpty || _hasAttachmentTaskChanges(existingItems);

    return _ref
        .read(memoMutationServiceProvider)
        .rebuildMemoSyncQueue(
          memo: memo,
          attentionIds: attentionIds,
          hasActiveItems: hasActiveItems,
          rootType: rootType,
          uploadPayloads: uploadPayloads,
          deletePayloads: deletePayloads,
          relations: relations,
          shouldSyncAttachments: shouldSyncAttachments,
        );
  }

  Future<SyncRunResult> requestSync() async {
    return _ref
        .read(syncCoordinatorProvider.notifier)
        .requestSync(
          const SyncRequest(
            kind: SyncRequestKind.memos,
            reason: SyncRequestReason.manual,
          ),
        );
  }

  String _resolveRebuildRootType({
    required List<Map<String, dynamic>> existingItems,
    String? preferredRootType,
  }) {
    if (preferredRootType == 'create_memo') {
      return 'create_memo';
    }
    for (final row in existingItems) {
      final failureCode = (row['failure_code'] as String?)?.trim();
      if (failureCode == 'remote_missing_memo') {
        return 'create_memo';
      }
    }
    for (final row in existingItems) {
      final type = (row['type'] as String?)?.trim();
      if (type == 'create_memo') {
        return 'create_memo';
      }
    }
    return 'update_memo';
  }

  List<Map<String, dynamic>> _collectUploadAttachmentPayloads(
    List<Map<String, dynamic>> existingItems,
  ) {
    final uploads = <Map<String, dynamic>>[];
    final seenKeys = <String>{};
    for (final row in existingItems) {
      final type = (row['type'] as String?)?.trim();
      if (type != 'upload_attachment') continue;
      final payload = _decodePayload(row['payload']);
      if (payload == null) continue;
      final key =
          (payload['uid'] as String?)?.trim() ??
          (payload['file_path'] as String?)?.trim() ??
          '';
      if (key.isEmpty || seenKeys.contains(key)) continue;
      seenKeys.add(key);
      uploads.add(payload);
    }
    return uploads;
  }

  List<Map<String, dynamic>> _collectDeleteAttachmentPayloads(
    List<Map<String, dynamic>> existingItems,
  ) {
    final deletes = <Map<String, dynamic>>[];
    final seenKeys = <String>{};
    for (final row in existingItems) {
      final type = (row['type'] as String?)?.trim();
      if (type != 'delete_attachment') continue;
      final payload = _decodePayload(row['payload']);
      if (payload == null) continue;
      final key =
          (payload['attachment_name'] as String?)?.trim() ??
          (payload['attachmentName'] as String?)?.trim() ??
          (payload['name'] as String?)?.trim() ??
          '';
      if (key.isEmpty || seenKeys.contains(key)) continue;
      seenKeys.add(key);
      deletes.add(payload);
    }
    return deletes;
  }

  Future<List<Map<String, dynamic>>> _loadMemoRelationsPayload(
    AppDatabase db,
    String memoUid,
  ) async {
    final raw = await db.getMemoRelationsCacheJson(memoUid);
    if (raw == null || raw.trim().isEmpty) {
      return const <Map<String, dynamic>>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <Map<String, dynamic>>[];
      return decoded
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList(growable: false);
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  Map<String, dynamic>? _decodePayload(Object? raw) {
    if (raw is Map) {
      return raw.cast<String, dynamic>();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return decoded.cast<String, dynamic>();
        }
      } catch (_) {}
    }
    return null;
  }

  int? _stateFromOutboxRow(Map<String, dynamic> row) {
    final raw = row['state'];
    return switch (raw) {
      int value => value,
      num value => value.toInt(),
      String value => int.tryParse(value.trim()),
      _ => null,
    };
  }

  bool _isAttentionState(int? state) {
    return state == AppDatabase.outboxStateError ||
        state == AppDatabase.outboxStateQuarantined;
  }

  bool _isActiveState(int? state) {
    return state == AppDatabase.outboxStatePending ||
        state == AppDatabase.outboxStateRunning ||
        state == AppDatabase.outboxStateRetry;
  }

  bool _hasAttachmentTaskChanges(List<Map<String, dynamic>> existingItems) {
    for (final row in existingItems) {
      final type = (row['type'] as String?)?.trim();
      if (type == 'upload_attachment' || type == 'delete_attachment') {
        return true;
      }
    }
    return false;
  }
}

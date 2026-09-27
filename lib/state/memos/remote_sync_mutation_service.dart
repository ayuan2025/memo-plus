import '../../data/db/app_database.dart';
import '../../data/models/memo_location.dart';

class RemoteSyncMutationService {
  RemoteSyncMutationService({required this.db});

  final AppDatabase db;

  Future<int> recoverOutboxRunningTasks() {
    return db.recoverOutboxRunningTasks();
  }

  Future<Map<String, dynamic>?> claimOutboxTaskById(
    int outboxId, {
    required int nowMs,
  }) {
    return db.claimOutboxTaskById(outboxId, nowMs: nowMs);
  }

  Future<void> markOutboxQuarantined(
    int outboxId, {
    required String error,
    required String failureCode,
    required String failureKind,
    bool incrementAttempts = true,
  }) {
    return db.markOutboxQuarantined(
      outboxId,
      error: error,
      failureCode: failureCode,
      failureKind: failureKind,
      incrementAttempts: incrementAttempts,
    );
  }

  Future<void> markOutboxDone(int outboxId) {
    return db.markOutboxDone(outboxId);
  }

  Future<void> completeOutboxTask(int outboxId) {
    return db.completeOutboxTask(outboxId);
  }

  Future<void> deleteOutbox(int outboxId) {
    return db.deleteOutbox(outboxId);
  }

  Future<void> updateMemoSyncState(
    String memoUid, {
    required int syncState,
    String? lastError,
  }) {
    return db.updateMemoSyncState(
      memoUid,
      syncState: syncState,
      lastError: lastError,
    );
  }

  Future<void> deleteMemoDeleteTombstone(String memoUid) {
    return db.deleteMemoDeleteTombstone(memoUid);
  }

  Future<void> markOutboxRetryScheduled(
    int outboxId, {
    required String error,
    required int retryAtMs,
  }) {
    return db.markOutboxRetryScheduled(
      outboxId,
      error: error,
      retryAtMs: retryAtMs,
    );
  }

  Future<void> upsertMemoDeleteTombstone({
    required String memoUid,
    required String state,
    String? lastError,
    int? deletedTime,
  }) {
    return db.upsertMemoDeleteTombstone(
      memoUid: memoUid,
      state: state,
      lastError: lastError,
      deletedTime: deletedTime,
    );
  }

  Future<void> removePendingAttachmentPlaceholder({
    required String memoUid,
    required String attachmentUid,
  }) {
    return db.removePendingAttachmentPlaceholder(
      memoUid: memoUid,
      attachmentUid: attachmentUid,
    );
  }

  Future<void> upsertMemo({
    required String uid,
    required String content,
    required String visibility,
    required bool pinned,
    required String state,
    required int createTimeSec,
    Object? displayTimeSec,
    bool displayTimeSpecified = false,
    required int updateTimeSec,
    required List<String> tags,
    required List<Map<String, dynamic>> attachments,
    required MemoLocation? location,
    int relationCount = 0,
    required int syncState,
    String? lastError,
  }) {
    if (displayTimeSpecified) {
      return db.upsertMemo(
        uid: uid,
        content: content,
        visibility: visibility,
        pinned: pinned,
        state: state,
        createTimeSec: createTimeSec,
        displayTimeSec: displayTimeSec,
        updateTimeSec: updateTimeSec,
        tags: tags,
        attachments: attachments,
        location: location,
        relationCount: relationCount,
        syncState: syncState,
        lastError: lastError,
      );
    }
    return db.upsertMemo(
      uid: uid,
      content: content,
      visibility: visibility,
      pinned: pinned,
      state: state,
      createTimeSec: createTimeSec,
      updateTimeSec: updateTimeSec,
      tags: tags,
      attachments: attachments,
      location: location,
      relationCount: relationCount,
      syncState: syncState,
      lastError: lastError,
    );
  }

  Future<int> enqueueOutbox({
    required String type,
    required Map<String, dynamic> payload,
  }) {
    return db.enqueueOutbox(type: type, payload: payload);
  }

  Future<void> upsertMemoRelationsCache(
    String memoUid, {
    required String relationsJson,
  }) {
    return db.upsertMemoRelationsCache(memoUid, relationsJson: relationsJson);
  }

  Future<void> deleteMemoByUid(String memoUid) {
    return db.deleteMemoByUid(memoUid);
  }

  Future<void> updateMemoAttachmentsJson(
    String memoUid, {
    required String attachmentsJson,
  }) {
    return db.updateMemoAttachmentsJson(
      memoUid,
      attachmentsJson: attachmentsJson,
    );
  }

  Future<void> renameMemoUid({required String oldUid, required String newUid}) {
    return db.renameMemoUid(oldUid: oldUid, newUid: newUid);
  }

  Future<int> renameMemoUidAndRewriteOutboxMemoUids({
    required String oldUid,
    required String newUid,
  }) {
    return db.renameMemoUidAndRewriteOutboxMemoUids(
      oldUid: oldUid,
      newUid: newUid,
    );
  }

  Future<int> rewriteOutboxMemoUids({
    required String oldUid,
    required String newUid,
  }) {
    return db.rewriteOutboxMemoUids(oldUid: oldUid, newUid: newUid);
  }
}

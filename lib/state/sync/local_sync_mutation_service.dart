import '../../data/db/app_database.dart';
import '../../data/models/memo_location.dart';

class LocalSyncMutationService {
  LocalSyncMutationService({required this.db});

  final AppDatabase db;

  Future<void> recoverOutboxRunningTasks() {
    return db.recoverOutboxRunningTasks();
  }

  Future<Map<String, dynamic>?> claimOutboxTaskById(
    int outboxId, {
    required int nowMs,
  }) {
    return db.claimOutboxTaskById(outboxId, nowMs: nowMs);
  }

  Future<void> markOutboxError(int outboxId, {required String error}) {
    return db.markOutboxError(outboxId, error: error);
  }

  Future<void> scheduleOutboxRetry(
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

  Future<void> completeOutboxTask(int outboxId) async {
    await db.completeOutboxTask(outboxId);
  }

  Future<void> markMemoSynchronized(String memoUid) {
    return db.updateMemoSyncState(memoUid, syncState: 0, lastError: null);
  }

  Future<void> markMemoPendingSync(String memoUid) {
    return db.updateMemoSyncState(memoUid, syncState: 1, lastError: null);
  }

  Future<void> markMemoSyncError(String memoUid, {required String lastError}) {
    return db.updateMemoSyncState(memoUid, syncState: 2, lastError: lastError);
  }

  Future<void> discardMissingSourceUploadTask({
    required int outboxId,
    required String memoUid,
    required String attachmentUid,
  }) async {
    await db.discardMissingSourceUploadTask(
      outboxId: outboxId,
      memoUid: memoUid,
      attachmentUid: attachmentUid,
    );
  }

  Future<void> updateMemoAttachmentsJson({
    required String memoUid,
    required String attachmentsJson,
  }) {
    return db.updateMemoAttachmentsJson(
      memoUid,
      attachmentsJson: attachmentsJson,
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
    required int updateTimeSec,
    required List<String> tags,
    required List<Map<String, dynamic>> attachments,
    required MemoLocation? location,
    int relationCount = 0,
    required int syncState,
    String? lastError,
  }) {
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
}

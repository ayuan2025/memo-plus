import '../../data/db/app_database.dart';
import '../../data/models/memo_location.dart';
import 'create_memo_outbox_payload.dart';

class FlomoImportMutationService {
  const FlomoImportMutationService({required this.db});

  final AppDatabase db;

  Future<int> beginImportHistory({
    required String source,
    required String fileMd5,
    required String fileName,
  }) {
    return db.upsertImportHistory(
      source: source,
      fileMd5: fileMd5,
      fileName: fileName,
      status: 0,
      memoCount: 0,
      attachmentCount: 0,
      failedCount: 0,
      error: null,
    );
  }

  Future<void> completeImportHistory({
    required int historyId,
    required int memoCount,
    required int attachmentCount,
    required int failedCount,
  }) {
    return db.updateImportHistory(
      id: historyId,
      status: 1,
      memoCount: memoCount,
      attachmentCount: attachmentCount,
      failedCount: failedCount,
      error: null,
    );
  }

  Future<void> failImportHistory({
    required int historyId,
    required int memoCount,
    required int attachmentCount,
    required int failedCount,
    required String error,
  }) {
    return db.updateImportHistory(
      id: historyId,
      status: 2,
      memoCount: memoCount,
      attachmentCount: attachmentCount,
      failedCount: failedCount,
      error: error,
    );
  }

  Future<int> persistImportedMemo({
    required String memoUid,
    required String content,
    required String visibility,
    required bool pinned,
    required String state,
    required int createTimeSec,
    int? displayTimeSec,
    required int updateTimeSec,
    required List<String> tags,
    required List<Map<String, dynamic>> attachments,
    required MemoLocation? location,
    required int relationCount,
    String? relationsJson,
    List<Map<String, dynamic>> createRelations = const <Map<String, dynamic>>[],
    required bool allowRemoteSync,
    required bool uploadBeforeCreate,
    required List<Map<String, dynamic>> attachmentPayloads,
  }) async {
    await db.upsertMemo(
      uid: memoUid,
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
      syncState: 1,
    );

    if (relationsJson != null && relationsJson.trim().isNotEmpty) {
      await db.upsertMemoRelationsCache(memoUid, relationsJson: relationsJson);
    }

    if (!allowRemoteSync) return 0;

    final outboxItems = <Map<String, Object?>>[];
    var queuedAttachmentCount = 0;
    if (uploadBeforeCreate) {
      for (final payload in attachmentPayloads) {
        outboxItems.add(<String, Object?>{
          'type': 'upload_attachment',
          'payload': payload,
        });
        queuedAttachmentCount += 1;
      }
    }

    outboxItems.add(<String, Object?>{
      'type': 'create_memo',
      'payload': buildCreateMemoOutboxPayload(
        uid: memoUid,
        content: content,
        visibility: visibility,
        pinned: pinned,
        createTimeSec: createTimeSec,
        displayTimeSec: displayTimeSec,
        hasAttachments: attachments.isNotEmpty,
        location: location,
        relations: createRelations,
      ),
    });

    if (state.trim().isNotEmpty && state.trim().toUpperCase() != 'NORMAL') {
      outboxItems.add(<String, Object?>{
        'type': 'update_memo',
        'payload': <String, Object?>{'uid': memoUid, 'state': state},
      });
    }

    if (!uploadBeforeCreate) {
      for (final payload in attachmentPayloads) {
        outboxItems.add(<String, Object?>{
          'type': 'upload_attachment',
          'payload': payload,
        });
        queuedAttachmentCount += 1;
      }
    }

    await db.enqueueOutboxBatch(items: outboxItems);

    return queuedAttachmentCount;
  }
}

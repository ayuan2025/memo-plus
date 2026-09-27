import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/models/memo_location.dart';
import '../system/database_provider.dart';

final memoTimelineMutationServiceProvider =
    Provider<MemoTimelineMutationService>((ref) {
      return MemoTimelineMutationService(db: ref.watch(databaseProvider));
    });

class MemoTimelineMutationService {
  MemoTimelineMutationService({required this.db});

  final AppDatabase db;

  Future<int> insertMemoVersion({
    required String memoUid,
    required int snapshotTime,
    required String summary,
    required String payloadJson,
  }) {
    return db.insertMemoVersion(
      memoUid: memoUid,
      snapshotTime: snapshotTime,
      summary: summary,
      payloadJson: payloadJson,
    );
  }

  Future<void> deleteOutboxForMemo(String memoUid) {
    return db.deleteOutboxForMemo(memoUid);
  }

  Future<void> upsertMemo({
    required String uid,
    required String content,
    required String visibility,
    required bool pinned,
    required String state,
    required int createTimeSec,
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

  Future<int> insertRecycleBinItem({
    required String itemType,
    required String memoUid,
    required String summary,
    required String payloadJson,
    required int deletedTime,
    required int expireTime,
  }) {
    return db.insertRecycleBinItem(
      itemType: itemType,
      memoUid: memoUid,
      summary: summary,
      payloadJson: payloadJson,
      deletedTime: deletedTime,
      expireTime: expireTime,
    );
  }

  Future<void> deleteRecycleBinItemById(int id) {
    return db.deleteRecycleBinItemById(id);
  }

  Future<void> clearRecycleBinItems() {
    return db.clearRecycleBinItems();
  }

  Future<void> deleteMemoDeleteTombstone(String memoUid) {
    return db.deleteMemoDeleteTombstone(memoUid);
  }

  Future<void> deleteMemoVersionById(int id) {
    return db.deleteMemoVersionById(id);
  }
}

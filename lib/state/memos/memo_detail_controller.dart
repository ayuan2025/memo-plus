import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/attachment.dart';
import '../../data/models/local_memo.dart';
import '../../data/models/memo.dart';
import '../../data/models/reaction.dart';
import '../../data/models/user.dart';
import '../system/database_provider.dart';
import 'memo_delete_service.dart';
import 'memo_mutation_service.dart';
import 'memos_providers.dart';

class MemoDetailController {
  MemoDetailController(this._ref);

  final Ref _ref;

  Future<LocalMemo?> loadMemoByUid(String uid) async {
    final row = await _ref.read(databaseProvider).getMemoByUid(uid);
    if (row == null) return null;
    return LocalMemo.fromDb(row);
  }

  Future<void> updateLocalAndEnqueue({
    required LocalMemo memo,
    bool? pinned,
    String? state,
  }) async {
    await _ref
        .read(memoMutationServiceProvider)
        .updateMemo(memo, pinned: pinned, state: state);
  }

  Future<void> adjustMemoTime({
    required LocalMemo memo,
    required DateTime selectedTime,
  }) async {
    await _ref
        .read(memoMutationServiceProvider)
        .adjustMemoTime(memo: memo, selectedTime: selectedTime);
  }

  Future<void> deleteMemo(LocalMemo memo) async {
    await _ref.read(memoDeleteServiceProvider).deleteMemo(memo);
  }

  Future<void> updateMemoContentForTaskToggle({
    required LocalMemo memo,
    required String content,
    required DateTime updateTime,
    required List<String> tags,
  }) async {
    await _ref
        .read(memoMutationServiceProvider)
        .updateMemoContentForTaskToggle(
          memo: memo,
          content: content,
          updateTime: updateTime,
          tags: tags,
        );
  }

  Future<void> replaceMemoAttachment({
    required LocalMemo memo,
    required Attachment oldAttachment,
    required List<Attachment> updatedAttachments,
    required int index,
    required String newUid,
    required String filePath,
    required String filename,
    required String mimeType,
    required int size,
    required DateTime now,
  }) async {
    await _ref
        .read(memoMutationServiceProvider)
        .replaceMemoAttachment(
          memo: memo,
          oldAttachment: oldAttachment,
          updatedAttachments: updatedAttachments,
          index: index,
          newUid: newUid,
          filePath: filePath,
          filename: filename,
          mimeType: mimeType,
          size: size,
          now: now,
        );
  }

  Future<({List<Reaction> reactions, String nextPageToken, int totalSize})>
  listMemoReactions({required String memoUid, int pageSize = 50}) async {
    final api = _ref.read(memosApiProvider);
    return api.listMemoReactions(memoUid: memoUid, pageSize: pageSize);
  }

  Future<({List<Memo> memos, String nextPageToken, int totalSize})>
  listMemoComments({required String memoUid, int pageSize = 50}) async {
    final api = _ref.read(memosApiProvider);
    return api.listMemoComments(memoUid: memoUid, pageSize: pageSize);
  }

  Future<Memo> createMemoComment({
    required String memoUid,
    required String content,
    required String visibility,
  }) async {
    final api = _ref.read(memosApiProvider);
    return api.createMemoComment(
      memoUid: memoUid,
      content: content,
      visibility: visibility,
    );
  }

  Future<User?> fetchUser({required String name}) async {
    try {
      return await _ref.read(memosApiProvider).getUser(name: name);
    } catch (_) {
      return null;
    }
  }

  Future<LocalMemo?> resolveMemoForOpen({required String uid}) async {
    final db = _ref.read(databaseProvider);
    if (await db.hasMemoDeleteMarker(uid)) {
      return null;
    }
    final row = await db.getMemoByUid(uid);
    LocalMemo? memo = row == null ? null : LocalMemo.fromDb(row);

    if (memo == null) {
      final api = _ref.read(memosApiProvider);
      final remote = await api.getMemo(memoUid: uid);
      final remoteUid = remote.uid.isNotEmpty ? remote.uid : uid;
      await _ref
          .read(memoMutationServiceProvider)
          .cacheRemoteMemoForOpen(remoteMemo: remote, fallbackUid: uid);
      final refreshed = await db.getMemoByUid(remoteUid);
      if (refreshed != null) {
        memo = LocalMemo.fromDb(refreshed);
      }
    }

    return memo;
  }
}

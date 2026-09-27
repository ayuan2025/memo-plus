import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/attachment.dart';
import '../../data/models/local_memo.dart';
import '../../data/models/memo_relation.dart';
import '../../data/models/memo_location.dart';
import 'memo_composer_state.dart';
import 'memo_mutation_service.dart';
import 'memos_providers.dart';

class MemoEditorPendingAttachment {
  const MemoEditorPendingAttachment({
    required this.uid,
    required this.filePath,
    required this.filename,
    required this.mimeType,
    required this.size,
    this.skipCompression = false,
  });

  final String uid;
  final String filePath;
  final String filename;
  final String mimeType;
  final int size;
  final bool skipCompression;
}

class MemoEditorController {
  MemoEditorController(this._ref);

  final Ref _ref;

  Future<List<MemoRelation>> listMemoRelationsAll({
    required String memoUid,
  }) async {
    final api = _ref.read(memosApiProvider);
    final items = <MemoRelation>[];
    String? pageToken;
    do {
      final (relations, nextToken) = await api.listMemoRelations(
        memoUid: memoUid,
        pageSize: 200,
        pageToken: pageToken,
      );
      items.addAll(relations);
      pageToken = nextToken.trim().isEmpty ? null : nextToken;
    } while (pageToken != null);
    return items;
  }

  Future<void> saveMemo({
    required LocalMemo? existing,
    required String uid,
    required String content,
    required String visibility,
    required bool pinned,
    required String state,
    required DateTime createTime,
    required DateTime now,
    required List<String> tags,
    required List<Map<String, dynamic>> attachments,
    required MemoLocation? location,
    required bool locationChanged,
    required int relationCount,
    required bool hasPrimaryChanges,
    required List<Attachment> attachmentsToDelete,
    required bool includeRelations,
    required List<Map<String, dynamic>> relations,
    required bool shouldSyncAttachments,
    required bool hasPendingAttachments,
    required List<MemoEditorPendingAttachment> pendingAttachments,
  }) async {
    await _ref
        .read(memoMutationServiceProvider)
        .saveEditedMemo(
          existing: existing,
          uid: uid,
          content: content,
          visibility: visibility,
          pinned: pinned,
          state: state,
          createTime: createTime,
          now: now,
          tags: tags,
          attachments: attachments,
          location: location,
          locationChanged: locationChanged,
          relationCount: relationCount,
          hasPrimaryChanges: hasPrimaryChanges,
          attachmentsToDelete: attachmentsToDelete,
          includeRelations: includeRelations,
          relations: relations,
          shouldSyncAttachments: shouldSyncAttachments,
          hasPendingAttachments: hasPendingAttachments,
          pendingAttachments: pendingAttachments
              .map(
                (attachment) => MemoComposerPendingAttachment(
                  uid: attachment.uid,
                  filePath: attachment.filePath,
                  filename: attachment.filename,
                  mimeType: attachment.mimeType,
                  size: attachment.size,
                  skipCompression: attachment.skipCompression,
                ),
              )
              .toList(growable: false),
        );
  }
}

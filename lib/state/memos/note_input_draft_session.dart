import '../../core/share_inline_image_content.dart';
import '../../data/models/compose_draft.dart';
import '../../data/models/memo_location.dart';
import 'memo_composer_state.dart';

class NoteInputDraftSessionHelper {
  const NoteInputDraftSessionHelper();

  ComposeDraftSnapshot buildSnapshot({
    required String content,
    required String visibility,
    required List<MemoComposerLinkedMemo> linkedMemos,
    required List<MemoComposerPendingAttachment> pendingAttachments,
    required MemoLocation? location,
  }) {
    return ComposeDraftSnapshot(
      content: content,
      visibility: visibility,
      relations: linkedMemos
          .map((memo) => memo.toRelationJson())
          .toList(growable: false),
      attachments: pendingAttachments
          .map(ComposeDraftAttachment.fromPendingAttachment)
          .toList(growable: false),
      location: location,
    );
  }

  NoteInputDraftRestoreState restoreState(
    ComposeDraftRecord draft, {
    required String defaultVisibility,
  }) {
    final snapshot = draft.snapshot;
    final visibility = snapshot.visibility.trim().isEmpty
        ? defaultVisibility
        : snapshot.visibility.trim();
    final pendingAttachments = snapshot.attachments
        .map((attachment) => attachment.toPendingAttachment())
        .toList(growable: false);

    return NoteInputDraftRestoreState(
      draftUid: draft.uid,
      content: snapshot.content,
      visibility: visibility,
      location: snapshot.location,
      linkedMemos: linkedMemosFromRelations(snapshot.relations),
      pendingAttachments: pendingAttachments,
      pickedImagePaths: pendingAttachments
          .where((attachment) => isImageMimeType(attachment.mimeType))
          .map((attachment) => attachment.filePath)
          .toList(growable: false),
      inlineSourceByLocalUrl: inlineSourceMapFromAttachments(
        snapshot.attachments,
      ),
    );
  }

  List<MemoComposerLinkedMemo> linkedMemosFromRelations(
    List<Map<String, dynamic>> relations,
  ) {
    final linked = <MemoComposerLinkedMemo>[];
    final seenNames = <String>{};
    for (final relation in relations) {
      final relatedMemoRaw = relation['relatedMemo'];
      if (relatedMemoRaw is! Map) continue;
      final name = (relatedMemoRaw['name'] as String? ?? '').trim();
      if (name.isEmpty || !seenNames.add(name)) continue;
      final label = name.startsWith('memos/') ? name.substring(6) : name;
      linked.add(MemoComposerLinkedMemo(name: name, label: label));
    }
    return linked;
  }

  Map<String, String> inlineSourceMapFromAttachments(
    List<ComposeDraftAttachment> attachments,
  ) {
    final inlineSourceByLocalUrl = <String, String>{};
    for (final attachment in attachments) {
      final sourceUrl = attachment.sourceUrl?.trim();
      if (!attachment.shareInlineImage ||
          sourceUrl == null ||
          sourceUrl.isEmpty) {
        continue;
      }
      final localUrl = shareInlineLocalUrlFromPath(attachment.filePath);
      if (localUrl.isNotEmpty) {
        inlineSourceByLocalUrl[localUrl] = sourceUrl;
      }
    }
    return inlineSourceByLocalUrl;
  }

  Set<String> keepPathsForSubmittedDraft(Iterable<String> attachmentPaths) {
    return attachmentPaths
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toSet();
  }
}

class NoteInputDraftRestoreState {
  const NoteInputDraftRestoreState({
    required this.draftUid,
    required this.content,
    required this.visibility,
    required this.location,
    required this.linkedMemos,
    required this.pendingAttachments,
    required this.pickedImagePaths,
    required this.inlineSourceByLocalUrl,
  });

  final String draftUid;
  final String content;
  final String visibility;
  final MemoLocation? location;
  final List<MemoComposerLinkedMemo> linkedMemos;
  final List<MemoComposerPendingAttachment> pendingAttachments;
  final List<String> pickedImagePaths;
  final Map<String, String> inlineSourceByLocalUrl;
}

bool isImageMimeType(String mimeType) {
  return mimeType.trim().toLowerCase().startsWith('image/');
}

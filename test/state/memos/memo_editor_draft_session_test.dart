import 'package:flutter_test/flutter_test.dart';

import 'package:memos_flutter_app/data/models/attachment.dart';
import 'package:memos_flutter_app/data/models/compose_draft.dart';
import 'package:memos_flutter_app/data/models/local_memo.dart';
import 'package:memos_flutter_app/data/models/memo_location.dart';
import 'package:memos_flutter_app/state/memos/memo_composer_state.dart';
import 'package:memos_flutter_app/state/memos/memo_editor_draft_session.dart';

void main() {
  const helper = MemoEditorDraftSessionHelper();

  test('builds edit draft snapshot from editor state', () {
    final attachment = _attachment('remote-1', filename: 'remote.png');
    final pending = MemoComposerPendingAttachment(
      uid: 'pending-1',
      filePath: '/tmp/pending.png',
      filename: 'pending.png',
      mimeType: 'image/png',
      size: 12,
      skipCompression: true,
      shareInlineImage: true,
      sourceUrl: 'https://example.com/source.png',
    );

    final snapshot = helper.buildEditDraftSnapshot(
      content: 'edited content',
      visibility: 'PUBLIC',
      linkedMemos: const <MemoComposerLinkedMemo>[
        MemoComposerLinkedMemo(name: 'memos/memo-2', label: 'Memo 2'),
      ],
      existingAttachments: <Attachment>[attachment],
      pendingAttachments: <MemoComposerPendingAttachment>[pending],
      location: const MemoLocation(
        placeholder: 'Shanghai',
        latitude: 31.2304,
        longitude: 121.4737,
      ),
    );

    expect(snapshot.content, 'edited content');
    expect(snapshot.visibility, 'PUBLIC');
    expect(snapshot.relations.single['relatedMemo']['name'], 'memos/memo-2');
    expect(snapshot.existingAttachments.single.name, 'attachments/remote-1');
    expect(snapshot.attachments.single.uid, 'pending-1');
    expect(snapshot.attachments.single.skipCompression, isTrue);
    expect(snapshot.attachments.single.shareInlineImage, isTrue);
    expect(
      snapshot.attachments.single.sourceUrl,
      'https://example.com/source.png',
    );
    expect(snapshot.location?.placeholder, 'Shanghai');
  });

  test(
    'restores edit draft state and derives removed existing attachments',
    () {
      final keptAttachment = _attachment('remote-kept');
      final removedAttachment = _attachment('remote-removed');
      final target = _memo(
        attachments: <Attachment>[keptAttachment, removedAttachment],
      );
      final targetUpdateTime = DateTime.utc(2025, 1, 2, 3, 4, 5);
      final draft = ComposeDraftRecord(
        uid: 'draft-edit',
        workspaceKey: 'workspace-1',
        kind: ComposeDraftKind.editMemo,
        targetMemoUid: 'memo-1',
        targetMemoContentFingerprint: 'base-fingerprint',
        targetMemoUpdateTime: targetUpdateTime,
        snapshot: ComposeDraftSnapshot(
          content: 'restored edit',
          visibility: 'PROTECTED',
          relations: const <Map<String, dynamic>>[
            <String, dynamic>{
              'relatedMemo': <String, dynamic>{'name': 'memos/memo-2'},
              'type': 'REFERENCE',
            },
          ],
          existingAttachments: <Attachment>[keptAttachment],
          attachments: const <ComposeDraftAttachment>[
            ComposeDraftAttachment(
              uid: 'pending-1',
              filePath: '/tmp/pending.txt',
              filename: 'pending.txt',
              mimeType: 'text/plain',
              size: 7,
            ),
          ],
          location: const MemoLocation(
            placeholder: 'Hangzhou',
            latitude: 30.2741,
            longitude: 120.1551,
          ),
        ),
        createdTime: DateTime.utc(2025),
        updatedTime: DateTime.utc(2025, 1, 2),
      );

      final restored = helper.restoreEditDraft(draft, targetMemo: target);

      expect(restored.draftUid, 'draft-edit');
      expect(restored.targetMemoUid, 'memo-1');
      expect(restored.targetMemoContentFingerprint, 'base-fingerprint');
      expect(restored.targetMemoUpdateTime, targetUpdateTime);
      expect(restored.content, 'restored edit');
      expect(restored.visibility, 'PROTECTED');
      expect(restored.location?.placeholder, 'Hangzhou');
      expect(restored.linkedMemos.single.name, 'memos/memo-2');
      expect(restored.existingAttachments.single.name, keptAttachment.name);
      expect(restored.pendingAttachments.single.uid, 'pending-1');
      expect(restored.attachmentsToDelete.single.name, removedAttachment.name);
    },
  );

  test(
    'restore uses target defaults when optional draft metadata is absent',
    () {
      final target = _memo(visibility: 'PUBLIC');
      final draft = ComposeDraftRecord(
        uid: 'draft-edit',
        workspaceKey: 'workspace-1',
        kind: ComposeDraftKind.editMemo,
        snapshot: const ComposeDraftSnapshot(content: '', visibility: ''),
        createdTime: DateTime.utc(2025),
        updatedTime: DateTime.utc(2025, 1, 2),
      );

      final restored = helper.restoreEditDraft(draft, targetMemo: target);

      expect(restored.targetMemoUid, target.uid);
      expect(restored.targetMemoContentFingerprint, target.contentFingerprint);
      expect(restored.targetMemoUpdateTime, target.updateTime);
      expect(restored.visibility, 'PUBLIC');
      expect(restored.linkedMemos, isEmpty);
      expect(restored.existingAttachments, isEmpty);
      expect(restored.pendingAttachments, isEmpty);
    },
  );
}

Attachment _attachment(String uid, {String filename = 'file.txt'}) {
  return Attachment(
    name: 'attachments/$uid',
    filename: filename,
    type: filename.endsWith('.png') ? 'image/png' : 'text/plain',
    size: 10,
    externalLink: '',
  );
}

LocalMemo _memo({
  String uid = 'memo-1',
  String content = 'original content',
  String visibility = 'PRIVATE',
  List<Attachment> attachments = const <Attachment>[],
}) {
  return LocalMemo(
    uid: uid,
    content: content,
    contentFingerprint: 'fingerprint-$uid',
    visibility: visibility,
    pinned: false,
    state: 'NORMAL',
    createTime: DateTime.utc(2025),
    updateTime: DateTime.utc(2025, 1, 1, 12),
    tags: const <String>[],
    attachments: attachments,
    relationCount: 0,
    syncState: SyncState.synced,
    lastError: null,
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/models/compose_draft.dart';
import 'package:memos_flutter_app/data/models/memo_location.dart';
import 'package:memos_flutter_app/state/memos/memo_composer_state.dart';
import 'package:memos_flutter_app/state/memos/note_input_draft_session.dart';

void main() {
  const helper = NoteInputDraftSessionHelper();

  test(
    'buildSnapshot preserves content relations attachments and location',
    () {
      const location = MemoLocation(
        placeholder: 'Office',
        latitude: 1.23,
        longitude: 4.56,
      );

      final snapshot = helper.buildSnapshot(
        content: 'draft body',
        visibility: 'PROTECTED',
        linkedMemos: const [
          MemoComposerLinkedMemo(name: 'memos/related', label: 'Related'),
        ],
        pendingAttachments: const [
          MemoComposerPendingAttachment(
            uid: 'att-1',
            filePath: 'C:/tmp/image.png',
            filename: 'image.png',
            mimeType: 'image/png',
            size: 12,
            skipCompression: true,
            shareInlineImage: true,
            fromThirdPartyShare: true,
            sourceUrl: 'https://example.com/image.png',
          ),
        ],
        location: location,
      );

      expect(snapshot.content, 'draft body');
      expect(snapshot.visibility, 'PROTECTED');
      expect(snapshot.relations, hasLength(1));
      expect(snapshot.relations.single, containsPair('type', 'REFERENCE'));
      expect(snapshot.attachments.single.uid, 'att-1');
      expect(snapshot.attachments.single.shareInlineImage, isTrue);
      expect(snapshot.location, location);
    },
  );

  test('restoreState maps relations attachments images and inline sources', () {
    final draft = ComposeDraftRecord(
      uid: 'draft-1',
      workspaceKey: 'workspace',
      snapshot: ComposeDraftSnapshot(
        content: 'restored',
        visibility: '',
        relations: const [
          {
            'type': 'REFERENCE',
            'relatedMemo': {'name': 'memos/abc'},
          },
          {
            'type': 'REFERENCE',
            'relatedMemo': {'name': 'memos/abc'},
          },
        ],
        attachments: const [
          ComposeDraftAttachment(
            uid: 'img-1',
            filePath: 'C:/tmp/inline.png',
            filename: 'inline.png',
            mimeType: 'image/png',
            size: 3,
            shareInlineImage: true,
            sourceUrl: 'https://example.com/inline.png',
          ),
          ComposeDraftAttachment(
            uid: 'doc-1',
            filePath: 'C:/tmp/doc.pdf',
            filename: 'doc.pdf',
            mimeType: 'application/pdf',
            size: 5,
          ),
        ],
      ),
      createdTime: DateTime.utc(2025),
      updatedTime: DateTime.utc(2025, 1, 2),
    );

    final restored = helper.restoreState(draft, defaultVisibility: 'PRIVATE');

    expect(restored.draftUid, 'draft-1');
    expect(restored.content, 'restored');
    expect(restored.visibility, 'PRIVATE');
    expect(restored.linkedMemos, hasLength(1));
    expect(restored.linkedMemos.single.name, 'memos/abc');
    expect(restored.linkedMemos.single.label, 'abc');
    expect(restored.pendingAttachments, hasLength(2));
    expect(restored.pickedImagePaths, ['C:/tmp/inline.png']);
    expect(
      restored.inlineSourceByLocalUrl[Uri.file('C:/tmp/inline.png').toString()],
      'https://example.com/inline.png',
    );
  });

  test('keepPathsForSubmittedDraft drops blank paths', () {
    expect(helper.keepPathsForSubmittedDraft([' C:/tmp/a.png ', '', '   ']), {
      'C:/tmp/a.png',
    });
  });
}

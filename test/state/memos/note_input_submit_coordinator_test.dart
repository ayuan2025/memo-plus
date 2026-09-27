import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/models/memo_location.dart';
import 'package:memos_flutter_app/features/share/share_clip_models.dart';
import 'package:memos_flutter_app/state/memos/memo_composer_state.dart';
import 'package:memos_flutter_app/state/memos/note_input_controller.dart';

void main() {
  test('prepareNoteInputSubmitDraft builds payload and filters inline media', () {
    final captureResult = ShareCaptureResult.success(
      finalUrl: Uri.parse('https://example.com/article'),
    );
    const normalPath = 'C:/tmp/manual.pdf';
    const keptInlinePath = 'C:/tmp/kept-inline.png';
    const skippedInlinePath = 'C:/tmp/skipped-inline.png';
    final keptLocalUrl = Uri.file(keptInlinePath).toString();
    final draft = NoteInputSubmitDraft(
      content:
          '#work\n\nHello ![]($keptLocalUrl) ![](https://example.com/keep.png)   ',
      visibility: 'PUBLIC',
      location: const MemoLocation(
        placeholder: 'Desk',
        latitude: 1,
        longitude: 2,
      ),
      relations: const [
        {
          'type': 'REFERENCE',
          'relatedMemo': {'name': 'memos/related'},
        },
      ],
      pendingAttachments: const [
        MemoComposerPendingAttachment(
          uid: 'inline-skipped',
          filePath: skippedInlinePath,
          filename: 'skipped-inline.png',
          mimeType: 'image/png',
          size: 7,
          shareInlineImage: true,
          fromThirdPartyShare: true,
          sourceUrl: 'https://example.com/skip.png',
        ),
        MemoComposerPendingAttachment(
          uid: 'manual',
          filePath: normalPath,
          filename: 'manual.pdf',
          mimeType: 'application/pdf',
          size: 10,
        ),
        MemoComposerPendingAttachment(
          uid: 'inline-kept',
          filePath: keptInlinePath,
          filename: 'kept-inline.png',
          mimeType: 'image/png',
          size: 8,
          shareInlineImage: true,
          fromThirdPartyShare: true,
          sourceUrl: 'https://example.com/keep.png',
        ),
      ],
      deferredInlineImageRequests: [
        ShareDeferredInlineImageAttachmentRequest(
          captureResult: captureResult,
          sourceUrl: 'https://example.com/keep.png',
          index: 0,
        ),
        ShareDeferredInlineImageAttachmentRequest(
          captureResult: captureResult,
          sourceUrl: 'https://example.com/skip.png',
          index: 1,
        ),
      ],
    );

    final prepared = prepareNoteInputSubmitDraft(
      draft,
      memoUid: 'memo-1',
      now: DateTime.utc(2025, 1, 2, 3, 4, 5),
    );

    expect(prepared.memoUid, 'memo-1');
    expect(prepared.content.endsWith('   '), isFalse);
    expect(prepared.tags, ['work']);
    expect(prepared.visibility, 'PUBLIC');
    expect(prepared.location?.placeholder, 'Desk');
    expect(prepared.relations, draft.relations);
    expect(prepared.hasAttachments, isTrue);
    expect(prepared.pendingUploads.map((a) => a.uid), [
      'manual',
      'inline-kept',
    ]);
    expect(prepared.pendingUploads.last.shareInlineImage, isTrue);
    expect(prepared.attachments.map((a) => a['name']), [
      'attachments/manual',
      'attachments/inline-kept',
    ]);
    expect(
      prepared.attachments.first,
      containsPair('externalLink', Uri.file(normalPath).toString()),
    );
    expect(prepared.deferredInlineImageRequests, hasLength(1));
    expect(
      prepared.deferredInlineImageRequests.single.sourceUrl,
      'https://example.com/keep.png',
    );
  });

  test(
    'submit forwards prepared draft and requests sync best effort',
    () async {
      final controller = _RecordingNoteInputController();
      var syncCallCount = 0;
      final infoMessages = <String>[];
      final coordinator = NoteInputSubmitCoordinator(
        controller: controller,
        requestSync: () async {
          syncCallCount += 1;
        },
        logInfo: (message, {context}) {
          infoMessages.add(message);
        },
        uidFactory: () => 'memo-submit-1',
        now: () => DateTime.utc(2025, 2, 3, 4, 5, 6),
      );

      final result = await coordinator.submit(
        const NoteInputSubmitDraft(
          content: '#tag\n\nSubmit',
          visibility: 'PRIVATE',
          location: null,
          relations: <Map<String, dynamic>>[],
          pendingAttachments: <MemoComposerPendingAttachment>[],
          deferredInlineImageRequests:
              <ShareDeferredInlineImageAttachmentRequest>[],
        ),
        logShareSaveFlow: true,
      );
      await Future<void>.delayed(Duration.zero);

      expect(result.memoUid, 'memo-submit-1');
      expect(controller.createCallCount, 1);
      expect(controller.lastUid, 'memo-submit-1');
      expect(controller.lastContent, '#tag\n\nSubmit');
      expect(controller.lastTags, ['tag']);
      expect(controller.lastNow, DateTime.utc(2025, 2, 3, 4, 5, 6));
      expect(syncCallCount, 1);
      expect(infoMessages, contains('ShareCompose: local_save_committed'));
      expect(infoMessages, contains('ShareCompose: background_sync_requested'));
    },
  );
}

class _RecordingNoteInputController implements NoteInputController {
  int createCallCount = 0;
  String? lastUid;
  String? lastContent;
  DateTime? lastNow;
  List<String>? lastTags;

  @override
  Future<void> createMemo({
    required String uid,
    required String content,
    String? syncContent,
    required String visibility,
    required DateTime now,
    required List<String> tags,
    required List<Map<String, dynamic>> attachments,
    required MemoLocation? location,
    required bool hasAttachments,
    required List<Map<String, dynamic>> relations,
    required List<NoteInputPendingAttachment> pendingAttachments,
    ShareClipMetadataDraft? clipMetadataDraft,
  }) async {
    createCallCount += 1;
    lastUid = uid;
    lastContent = content;
    lastNow = now;
    lastTags = tags;
  }

  @override
  Future<void> appendDeferredThirdPartyShareInlineImage({
    required String memoUid,
    required String sourceUrl,
    required NoteInputPendingAttachment attachment,
  }) async {}
}

import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/features/share/share_capture_engine.dart';
import 'package:memos_flutter_app/features/share/share_clip_controller.dart';
import 'package:memos_flutter_app/features/share/share_clip_models.dart';
import 'package:memos_flutter_app/features/share/share_handler.dart';
import 'package:memos_flutter_app/features/share/share_inline_image_content.dart';
import 'package:memos_flutter_app/features/share/share_inline_image_download_service.dart';

void main() {
  test(
    'attachVideo returns compose request with deferred video download',
    () async {
      const payload = SharePayload(
        type: SharePayloadType.text,
        text: 'Interesting Article https://example.com/articles/1',
        title: 'Interesting Article',
      );
      final engine = _FakeShareCaptureEngine(
        ShareCaptureResult.success(
          finalUrl: Uri.parse('https://www.bilibili.com/video/BV1xx'),
          articleTitle: 'Bilibili Video',
          pageKind: SharePageKind.video,
          videoCandidates: const [
            ShareVideoCandidate(
              id: 'video-1',
              url: 'https://cdn.example.com/video.mp4',
              title: 'Candidate Video',
              source: ShareVideoSource.parser,
              isDirectDownloadable: true,
              parserTag: 'bilibili',
            ),
          ],
        ),
      );
      final controller = ShareClipController(payload: payload, engine: engine);
      addTearDown(controller.dispose);

      await controller.start();
      final request = controller.attachVideo(
        controller.state.result!.videoCandidates.first,
      );

      expect(request, isNotNull);
      expect(request!.attachmentPaths, isEmpty);
      expect(request.deferredVideoAttachments, hasLength(1));
      expect(
        request.deferredVideoAttachments.first.candidate.url,
        'https://cdn.example.com/video.mp4',
      );
      expect(request.text, contains('# Bilibili Video'));
    },
  );

  test('xiaohongshu video result uses generic video candidate flow', () async {
    const payload = SharePayload(
      type: SharePayloadType.text,
      text: 'https://xhslink.com/a/example',
      title: 'Shared XHS Video',
    );
    final engine = _FakeShareCaptureEngine(
      ShareCaptureResult.success(
        finalUrl: Uri.parse(
          'https://www.xiaohongshu.com/discovery/item/note-123?type=video',
        ),
        articleTitle: 'XHS Video Gifts',
        pageKind: SharePageKind.video,
        siteParserTag: 'xiaohongshu',
        videoCandidates: const [
          ShareVideoCandidate(
            id: 'xiaohongshu-h264',
            url: 'http://sns-video-qc.xhscdn.com/stream/h264.mp4',
            title: 'h264.mp4',
            source: ShareVideoSource.parser,
            isDirectDownloadable: true,
            parserTag: 'xiaohongshu',
          ),
        ],
      ),
    );
    final controller = ShareClipController(payload: payload, engine: engine);
    addTearDown(controller.dispose);

    await controller.start();

    expect(controller.state.phase, ShareClipPhase.success);
    expect(controller.state.result!.isVideoPage, isTrue);
    expect(controller.state.result!.hasDirectVideoCandidates, isTrue);
    expect(controller.state.autoComposeRequest, isNull);

    final request = controller.attachVideo(
      controller.state.result!.videoCandidates.first,
    );

    expect(request, isNotNull);
    expect(request!.deferredVideoAttachments, hasLength(1));
    expect(
      request.deferredVideoAttachments.single.candidate.parserTag,
      'xiaohongshu',
    );
    expect(request.text, contains('# XHS Video Gifts'));
    expect(request.text, isNot(contains('xhsdiscover://')));
  });

  test(
    'saveArticle defers inline image downloads into compose request',
    () async {
      const payload = SharePayload(
        type: SharePayloadType.text,
        text: 'Interesting Article https://example.com/articles/1',
        title: 'Interesting Article',
      );
      final engine = _FakeShareCaptureEngine(
        ShareCaptureResult.success(
          finalUrl: Uri.parse('https://example.com/articles/1'),
          articleTitle: 'Interesting Article',
          contentHtml:
              '<p>Hello</p><img src="https://cdn.example.com/cover.jpg">',
          pageKind: SharePageKind.article,
        ),
      );
      final deferredRequest = ShareDeferredInlineImageAttachmentRequest(
        captureResult: ShareCaptureResult.success(
          finalUrl: Uri.parse('https://example.com/articles/1'),
          articleTitle: 'Interesting Article',
        ),
        sourceUrl: 'https://cdn.example.com/cover.jpg',
        index: 0,
      );
      final controller = ShareClipController(
        payload: payload,
        engine: engine,
        inlineImageDownloadService: _FakeInlineImageDownloadService([
          deferredRequest,
        ]),
      );
      addTearDown(controller.dispose);

      await controller.start();
      final request = await controller.saveArticle();

      expect(request, isNotNull);
      expect(request!.initialAttachmentSeeds, isEmpty);
      expect(request.deferredInlineImageAttachments, hasLength(1));
      expect(
        request.deferredInlineImageAttachments.single.sourceUrl,
        'https://cdn.example.com/cover.jpg',
      );
      expect(request.text, contains('https://cdn.example.com/cover.jpg'));
      expect(request.text, contains(buildThirdPartyShareMemoMarker()));
    },
  );
}

class _FakeShareCaptureEngine implements ShareCaptureEngine {
  _FakeShareCaptureEngine(this.result);

  final ShareCaptureResult result;

  @override
  Future<ShareCaptureResult> capture(
    ShareCaptureRequest request, {
    void Function(ShareCaptureStage stage)? onStageChanged,
  }) async {
    onStageChanged?.call(ShareCaptureStage.loadingPage);
    onStageChanged?.call(ShareCaptureStage.buildingPreview);
    return result;
  }
}

class _FakeInlineImageDownloadService extends ShareInlineImageDownloadService {
  _FakeInlineImageDownloadService(this.result);

  final List<ShareDeferredInlineImageAttachmentRequest> result;

  @override
  Future<List<ShareDeferredInlineImageAttachmentRequest>>
  discoverDeferredInlineImageAttachments(ShareCaptureResult result) async {
    return this.result;
  }
}

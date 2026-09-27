import 'package:flutter/foundation.dart';

import 'share_capture_engine.dart';
import 'share_capture_formatter.dart';
import 'share_clip_models.dart';
import 'share_handler.dart';
import 'share_inline_image_download_service.dart';

class ShareClipController extends ChangeNotifier {
  ShareClipController({
    required SharePayload payload,
    required ShareCaptureEngine engine,
    ShareInlineImageDownloadService? inlineImageDownloadService,
    ShareCaptureRequest? request,
  }) : _payload = payload,
       _engine = engine,
       _inlineImageDownloadService =
           inlineImageDownloadService ?? ShareInlineImageDownloadService(),
       _request = request ?? buildShareCaptureRequest(payload)!,
       _state = ShareClipViewState.loading(
         linkOnlyRequest: buildLinkOnlyComposeRequest(payload),
       );

  final SharePayload _payload;
  final ShareCaptureEngine _engine;
  final ShareInlineImageDownloadService _inlineImageDownloadService;
  final ShareCaptureRequest _request;

  ShareClipViewState _state;

  ShareClipViewState get state => _state;

  Future<void> start() => _capture();

  Future<void> retry() => _capture();

  ShareComposeRequest useLinkOnly() => _state.linkOnlyRequest;

  Future<ShareComposeRequest?> saveArticle() async {
    final result = _state.result;
    if (result == null || !result.isSuccess) return null;
    _state = _state.copyWith(phase: ShareClipPhase.composing);
    notifyListeners();
    try {
      final inlineImages = await _inlineImageDownloadService
          .discoverDeferredInlineImageAttachments(result);
      return buildShareComposeRequestFromCapture(
        result: result,
        payload: _payload,
      ).copyWith(deferredInlineImageAttachments: inlineImages);
    } catch (_) {
      return buildShareComposeRequestFromCapture(
        result: result,
        payload: _payload,
      );
    }
  }

  ShareComposeRequest? takeAutoComposeRequest() {
    final request = _state.autoComposeRequest;
    if (request == null) return null;
    _state = _state.copyWith(clearAutoComposeRequest: true);
    notifyListeners();
    return request;
  }

  ShareComposeRequest? attachVideo(ShareVideoCandidate candidate) {
    final result = _state.result;
    if (result == null || !result.isSuccess) {
      return null;
    }

    final request =
        buildShareComposeRequestFromCapture(
          result: result,
          payload: _payload,
        ).copyWith(
          deferredVideoAttachments: [
            ShareDeferredVideoAttachmentRequest(
              captureResult: result,
              candidate: candidate,
            ),
          ],
        );
    _state = _state.copyWith(phase: ShareClipPhase.composing);
    notifyListeners();
    return request;
  }

  Future<void> _capture() async {
    _state = ShareClipViewState.loading(
      linkOnlyRequest: _state.linkOnlyRequest,
    );
    notifyListeners();
    final result = await _engine.capture(
      _request,
      onStageChanged: (stage) {
        _state = _state.copyWith(stage: stage);
        notifyListeners();
      },
    );
    if (result.isSuccess) {
      final previewText = buildShareCaptureMemoText(
        result: result,
        payload: _payload,
      );
      final shouldAutoFallback =
          result.isVideoPage && !result.hasDirectVideoCandidates;
      _state = _state.copyWith(
        phase: ShareClipPhase.success,
        stage: ShareCaptureStage.buildingPreview,
        result: result,
        previewText: previewText,
        autoComposeRequest: shouldAutoFallback ? _state.linkOnlyRequest : null,
      );
      notifyListeners();
      return;
    }

    _state = _state.copyWith(
      phase: ShareClipPhase.failure,
      result: result,
      clearPreviewText: true,
    );
    notifyListeners();
  }
}

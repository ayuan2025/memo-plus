import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/features/share/share_clip_models.dart';
import 'package:memos_flutter_app/features/share/share_deferred_inline_image_coordinator.dart';
import 'package:memos_flutter_app/features/share/share_inline_image_download_service.dart';

void main() {
  test('skips requests no longer referenced by content', () async {
    final service = _FakeInlineImageDownloadService();
    final skipped = <String>[];
    final coordinator = ShareDeferredInlineImageCoordinator(
      downloadService: service,
    );

    await coordinator.processRequests(
      requests: [_request('https://example.com/skipped.png')],
      shouldProcess: (_) => false,
      onSkipped: (request) => skipped.add(request.sourceUrl),
      handleSeed: (_, _) async => true,
    );

    expect(skipped, ['https://example.com/skipped.png']);
    expect(service.downloadCallCount, 0);
  });

  test('downloads and applies seed with progress', () async {
    final service = _FakeInlineImageDownloadService(
      seed: const ShareAttachmentSeed(
        uid: 'seed-1',
        filePath: 'C:/tmp/seed.png',
        filename: 'seed.png',
        mimeType: 'image/png',
        size: 3,
      ),
    );
    final progressValues = <double?>[];
    final applied = <String>[];
    final cleanupPaths = <String?>[];
    final coordinator = ShareDeferredInlineImageCoordinator(
      downloadService: service,
      cleanupFile: (path) async => cleanupPaths.add(path),
      onProgressChanged: (progress) {
        progressValues.add(progress.overallProgress);
      },
    );

    await coordinator.processRequests(
      requests: [_request('https://example.com/applied.png')],
      shouldProcess: (_) => true,
      handleSeed: (request, seed) async {
        applied.add('${request.sourceUrl}:${seed.uid}');
        return true;
      },
    );

    expect(applied, ['https://example.com/applied.png:seed-1']);
    expect(cleanupPaths, isEmpty);
    expect(progressValues, contains(0.5));
    expect(progressValues.last, isNull);
  });

  test('cleans downloaded seed when apply fails', () async {
    final service = _FakeInlineImageDownloadService(
      seed: const ShareAttachmentSeed(
        uid: 'seed-1',
        filePath: 'C:/tmp/failed.png',
        filename: 'failed.png',
        mimeType: 'image/png',
        size: 3,
      ),
    );
    final cleanupPaths = <String?>[];
    final coordinator = ShareDeferredInlineImageCoordinator(
      downloadService: service,
      cleanupFile: (path) async => cleanupPaths.add(path),
    );

    await coordinator.processRequests(
      requests: [_request('https://example.com/failed.png')],
      shouldProcess: (_) => true,
      handleSeed: (_, _) async => false,
    );

    expect(cleanupPaths, ['C:/tmp/failed.png']);
  });

  test('handles failed downloads and returns to idle progress', () async {
    final service = _FakeInlineImageDownloadService()
      ..error = StateError('download failed');
    final progressValues = <double?>[];
    final coordinator = ShareDeferredInlineImageCoordinator(
      downloadService: service,
      onProgressChanged: (progress) {
        progressValues.add(progress.overallProgress);
      },
    );

    await coordinator.processRequests(
      requests: [_request('https://example.com/error.png')],
      shouldProcess: (_) => true,
      handleSeed: (_, _) async => true,
    );

    expect(service.downloadCallCount, 1);
    expect(progressValues.last, isNull);
  });
}

ShareDeferredInlineImageAttachmentRequest _request(String sourceUrl) {
  return ShareDeferredInlineImageAttachmentRequest(
    captureResult: ShareCaptureResult.success(
      finalUrl: Uri.parse('https://example.com/article'),
    ),
    sourceUrl: sourceUrl,
    index: 0,
  );
}

class _FakeInlineImageDownloadService extends ShareInlineImageDownloadService {
  _FakeInlineImageDownloadService({this.seed});

  final ShareAttachmentSeed? seed;
  Object? error;
  int downloadCallCount = 0;

  @override
  Future<ShareAttachmentSeed?> downloadDeferredInlineImageAttachment(
    ShareDeferredInlineImageAttachmentRequest request, {
    void Function(double progress)? onProgress,
    bool shareInlineImage = true,
  }) async {
    downloadCallCount += 1;
    onProgress?.call(0.5);
    if (error != null) {
      throw error!;
    }
    return seed;
  }
}

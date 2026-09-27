import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/api/memos_api.dart';
import 'package:memos_flutter_app/features/share/share_clip_models.dart';
import 'package:memos_flutter_app/features/share/share_deferred_video_coordinator.dart';
import 'package:memos_flutter_app/features/share/share_video_attachment_preparer.dart';
import 'package:memos_flutter_app/features/share/share_video_download_service.dart';

void main() {
  test(
    'successful processing admits staged attachment and removes task',
    () async {
      final admitted = <String>[];
      final coordinator = ShareDeferredVideoCoordinator(
        resolveUploadSizeLimit: () async => _knownLimit(),
        confirmCompression: (_, _) async => true,
        admitPreparedAttachment: (prepared) async {
          admitted.add(prepared.filePath);
        },
        prepare:
            ({
              required result,
              required candidate,
              required uploadSizeLimit,
              onProbeComplete,
              onDownloadProgress,
              onCompressionProgress,
              confirmCompression,
              isCancelled,
            }) async {
              onProbeComplete?.call(
                const ShareVideoProbeResult(headers: {'referer': 'test'}),
              );
              onDownloadProgress?.call(0.5);
              return const SharePreparedVideoAttachment(
                filePath: 'C:/tmp/video.mp4',
                filename: 'video.mp4',
                mimeType: 'video/mp4',
                size: 10,
                wasCompressed: false,
              );
            },
      );

      coordinator.addRequests([_request()]);
      await _drainMicrotasks();

      expect(admitted, ['C:/tmp/video.mp4']);
      expect(coordinator.visibleTasks, isEmpty);
      expect(coordinator.progress, isNull);
    },
  );

  test('compression declined removes task without failure', () async {
    final failures = <ShareDeferredVideoFailure>[];
    final coordinator = ShareDeferredVideoCoordinator(
      resolveUploadSizeLimit: () async => _knownLimit(),
      confirmCompression: (_, _) async => false,
      admitPreparedAttachment: (_) async {},
      onFailure: (event) => failures.add(event.failure),
      prepare:
          ({
            required result,
            required candidate,
            required uploadSizeLimit,
            onProbeComplete,
            onDownloadProgress,
            onCompressionProgress,
            confirmCompression,
            isCancelled,
          }) async {
            final shouldCompress =
                await confirmCompression?.call(100, 50) ?? false;
            if (!shouldCompress) {
              throw const ShareVideoAttachmentCompressionDeclined();
            }
            throw StateError('unexpected compression approval');
          },
    );

    coordinator.addRequests([_request()]);
    await _drainMicrotasks();

    expect(coordinator.visibleTasks, isEmpty);
    expect(failures, isEmpty);
  });

  test('compression failure reports failure', () async {
    final failures = <ShareDeferredVideoFailure>[];
    final coordinator = ShareDeferredVideoCoordinator(
      resolveUploadSizeLimit: () async => _knownLimit(),
      confirmCompression: (_, _) async => true,
      admitPreparedAttachment: (_) async {},
      onFailure: (event) => failures.add(event.failure),
      prepare:
          ({
            required result,
            required candidate,
            required uploadSizeLimit,
            onProbeComplete,
            onDownloadProgress,
            onCompressionProgress,
            confirmCompression,
            isCancelled,
          }) async {
            throw const ShareVideoAttachmentCompressionFailed();
          },
    );

    coordinator.addRequests([_request()]);
    await _drainMicrotasks();

    expect(failures, [ShareDeferredVideoFailure.compressionFailed]);
    expect(coordinator.visibleTasks, isEmpty);
  });

  test('cancellation removes task and cleans prepared file', () async {
    final cleanupPaths = <String?>[];
    final prepareCompleter = Completer<void>();
    late ShareDeferredVideoCoordinator coordinator;
    coordinator = ShareDeferredVideoCoordinator(
      resolveUploadSizeLimit: () async => _knownLimit(),
      confirmCompression: (_, _) async => true,
      admitPreparedAttachment: (_) async {},
      cleanupFile: (path) async => cleanupPaths.add(path),
      prepare:
          ({
            required result,
            required candidate,
            required uploadSizeLimit,
            onProbeComplete,
            onDownloadProgress,
            onCompressionProgress,
            confirmCompression,
            isCancelled,
          }) async {
            await prepareCompleter.future;
            return const SharePreparedVideoAttachment(
              filePath: 'C:/tmp/cancelled.mp4',
              filename: 'cancelled.mp4',
              mimeType: 'video/mp4',
              size: 10,
              wasCompressed: false,
            );
          },
    );

    coordinator.addRequests([_request()]);
    await Future<void>.delayed(Duration.zero);
    await coordinator.removeTask('video-1');
    prepareCompleter.complete();
    await _drainMicrotasks();

    expect(cleanupPaths, ['C:/tmp/cancelled.mp4']);
    expect(coordinator.visibleTasks, isEmpty);
  });
}

AttachmentUploadSizeLimit _knownLimit() {
  return const AttachmentUploadSizeLimit.known(
    bytes: 1024,
    source: AttachmentUploadSizeLimitSource.systemStatus,
  );
}

ShareDeferredVideoAttachmentRequest _request() {
  return ShareDeferredVideoAttachmentRequest(
    captureResult: ShareCaptureResult.success(
      finalUrl: Uri.parse('https://example.com/article'),
    ),
    candidate: const ShareVideoCandidate(
      id: 'video-1',
      url: 'https://example.com/video.mp4',
      source: ShareVideoSource.parser,
      title: 'Video',
    ),
  );
}

Future<void> _drainMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

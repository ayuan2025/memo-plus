import 'package:flutter/foundation.dart';

import 'share_clip_models.dart';
import 'share_inline_image_download_service.dart';

typedef ShareDeferredInlineImageShouldProcess =
    bool Function(ShareDeferredInlineImageAttachmentRequest request);
typedef ShareDeferredInlineImageSeedHandler =
    Future<bool> Function(
      ShareDeferredInlineImageAttachmentRequest request,
      ShareAttachmentSeed seed,
    );
typedef ShareDeferredInlineImageRequestCallback =
    void Function(ShareDeferredInlineImageAttachmentRequest request);
typedef ShareDeferredInlineImageCleanup = Future<void> Function(String? path);

@immutable
class ShareDeferredInlineImageProgress {
  const ShareDeferredInlineImageProgress({
    required this.active,
    required this.total,
    required this.completed,
    required this.activeProgress,
  });

  const ShareDeferredInlineImageProgress.idle()
    : active = false,
      total = 0,
      completed = 0,
      activeProgress = 0;

  final bool active;
  final int total;
  final int completed;
  final double activeProgress;

  double? get overallProgress {
    if (!active || total <= 0) return null;
    return ((completed + activeProgress.clamp(0, 1)) / total).clamp(0, 1);
  }
}

class ShareDeferredInlineImageCoordinator {
  ShareDeferredInlineImageCoordinator({
    required ShareInlineImageDownloadService downloadService,
    ShareDeferredInlineImageCleanup? cleanupFile,
    ValueChanged<ShareDeferredInlineImageProgress>? onProgressChanged,
    bool Function()? isCancelled,
  }) : _downloadService = downloadService,
       _cleanupFile = cleanupFile,
       _onProgressChanged = onProgressChanged,
       _isCancelled = isCancelled;

  final ShareInlineImageDownloadService _downloadService;
  final ShareDeferredInlineImageCleanup? _cleanupFile;
  final ValueChanged<ShareDeferredInlineImageProgress>? _onProgressChanged;
  final bool Function()? _isCancelled;

  Future<void> processRequests({
    required List<ShareDeferredInlineImageAttachmentRequest> requests,
    required ShareDeferredInlineImageShouldProcess shouldProcess,
    required ShareDeferredInlineImageSeedHandler handleSeed,
    ShareDeferredInlineImageRequestCallback? onSkipped,
  }) async {
    if (requests.isEmpty) return;

    var completed = 0;
    void emit(double activeProgress) {
      _onProgressChanged?.call(
        ShareDeferredInlineImageProgress(
          active: true,
          total: requests.length,
          completed: completed,
          activeProgress: activeProgress.clamp(0, 1),
        ),
      );
    }

    emit(0);
    try {
      for (final request in requests) {
        if (_isCancelled?.call() == true) break;

        ShareAttachmentSeed? seed;
        try {
          if (!shouldProcess(request)) {
            onSkipped?.call(request);
            continue;
          }

          seed = await _downloadService.downloadDeferredInlineImageAttachment(
            request,
            onProgress: emit,
          );
          if (seed == null) continue;

          if (_isCancelled?.call() == true) {
            await _cleanupFile?.call(seed.filePath);
            break;
          }

          final handled = await handleSeed(request, seed);
          if (!handled) {
            await _cleanupFile?.call(seed.filePath);
          }
        } catch (_) {
          if (seed != null) {
            await _cleanupFile?.call(seed.filePath);
          }
        } finally {
          completed += 1;
          emit(0);
        }
      }
    } finally {
      _onProgressChanged?.call(const ShareDeferredInlineImageProgress.idle());
    }
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/api/memos_api.dart';
import 'share_clip_models.dart';
import 'share_video_attachment_preparer.dart';
import 'share_video_download_service.dart';

enum ShareDeferredVideoPhase {
  preparing,
  downloading,
  awaitingCompression,
  compressing,
  completed,
  removed,
}

enum ShareDeferredVideoFailure {
  downloadFailed,
  compressionFailed,
  compressionStillTooLarge,
}

class ShareDeferredVideoTask {
  ShareDeferredVideoTask({required this.request});

  final ShareDeferredVideoAttachmentRequest request;
  Map<String, String> headers = const <String, String>{};
  int? remoteSize;
  int? uploadSizeLimitBytes;
  double progress = 0;
  ShareDeferredVideoPhase phase = ShareDeferredVideoPhase.preparing;
  bool cancelled = false;

  String get id => request.id;
  String get title => request.title;
  String? get thumbnailUrl => request.thumbnailUrl;

  bool get isPending =>
      !cancelled &&
      phase != ShareDeferredVideoPhase.completed &&
      phase != ShareDeferredVideoPhase.removed;

  bool get isRemovable => phase != ShareDeferredVideoPhase.completed;

  double get overallProgress {
    return switch (phase) {
      ShareDeferredVideoPhase.preparing => 0,
      ShareDeferredVideoPhase.downloading => progress.clamp(0, 1) * 0.72,
      ShareDeferredVideoPhase.awaitingCompression => 0.72,
      ShareDeferredVideoPhase.compressing => 0.72 + progress.clamp(0, 1) * 0.28,
      ShareDeferredVideoPhase.completed || ShareDeferredVideoPhase.removed => 1,
    };
  }
}

@immutable
class ShareDeferredVideoFailureEvent {
  const ShareDeferredVideoFailureEvent({
    required this.failure,
    this.uploadSizeLimitBytes,
  });

  final ShareDeferredVideoFailure failure;
  final int? uploadSizeLimitBytes;
}

typedef ShareDeferredVideoPrepare =
    Future<SharePreparedVideoAttachment> Function({
      required ShareCaptureResult result,
      required ShareVideoCandidate candidate,
      required AttachmentUploadSizeLimit uploadSizeLimit,
      ValueChanged<ShareVideoProbeResult>? onProbeComplete,
      ValueChanged<double>? onDownloadProgress,
      ValueChanged<double>? onCompressionProgress,
      ShareVideoCompressionConfirmation? confirmCompression,
      bool Function()? isCancelled,
    });
typedef ShareDeferredVideoUploadLimitResolver =
    Future<AttachmentUploadSizeLimit> Function();
typedef ShareDeferredVideoPreparedAttachmentHandler =
    Future<void> Function(SharePreparedVideoAttachment prepared);
typedef ShareDeferredVideoCleanup = Future<void> Function(String? path);
typedef ShareDeferredVideoFailureHandler =
    void Function(ShareDeferredVideoFailureEvent event);

class ShareDeferredVideoCoordinator {
  ShareDeferredVideoCoordinator({
    required ShareDeferredVideoUploadLimitResolver resolveUploadSizeLimit,
    required ShareVideoCompressionConfirmation confirmCompression,
    required ShareDeferredVideoPreparedAttachmentHandler
    admitPreparedAttachment,
    ShareVideoAttachmentPreparer? preparer,
    ShareDeferredVideoPrepare? prepare,
    ShareDeferredVideoCleanup? cleanupFile,
    ShareDeferredVideoFailureHandler? onFailure,
    VoidCallback? onChanged,
  }) : _resolveUploadSizeLimit = resolveUploadSizeLimit,
       _confirmCompression = confirmCompression,
       _admitPreparedAttachment = admitPreparedAttachment,
       _preparer = preparer ?? ShareVideoAttachmentPreparer(),
       _prepareOverride = prepare,
       _cleanupFile = cleanupFile,
       _onFailure = onFailure,
       _onChanged = onChanged;

  final ShareDeferredVideoUploadLimitResolver _resolveUploadSizeLimit;
  final ShareVideoCompressionConfirmation _confirmCompression;
  final ShareDeferredVideoPreparedAttachmentHandler _admitPreparedAttachment;
  final ShareVideoAttachmentPreparer _preparer;
  final ShareDeferredVideoPrepare? _prepareOverride;
  final ShareDeferredVideoCleanup? _cleanupFile;
  final ShareDeferredVideoFailureHandler? _onFailure;
  final VoidCallback? _onChanged;
  final List<ShareDeferredVideoTask> _tasks = [];

  List<ShareDeferredVideoTask> get tasks => List.unmodifiable(_tasks);

  List<ShareDeferredVideoTask> get visibleTasks => _tasks
      .where((task) => task.phase != ShareDeferredVideoPhase.removed)
      .toList(growable: false);

  bool get hasPendingTasks => _tasks.any((task) => task.isPending);

  double? get progress {
    final active = _tasks
        .where((task) => task.isPending)
        .toList(growable: false);
    if (active.isEmpty) return null;
    final total = active.fold<double>(
      0,
      (sum, task) => sum + task.overallProgress,
    );
    return (total / active.length).clamp(0, 1);
  }

  void addRequests(List<ShareDeferredVideoAttachmentRequest> requests) {
    if (requests.isEmpty) return;
    final tasks = requests
        .map((request) => ShareDeferredVideoTask(request: request))
        .toList(growable: false);
    _tasks.addAll(tasks);
    _notifyChanged();
    for (final task in tasks) {
      unawaited(process(task.id));
    }
  }

  ShareDeferredVideoTask? findTask(String id) {
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  Future<void> process(String id) async {
    final task = findTask(id);
    if (task == null || task.cancelled) return;

    try {
      final uploadSizeLimit = await _resolveUploadSizeLimit();
      task.uploadSizeLimitBytes = uploadSizeLimit.bytes;
      _notifyChanged();

      final prepared = await _prepareVideo(
        result: task.request.captureResult,
        candidate: task.request.candidate,
        uploadSizeLimit: uploadSizeLimit,
        onProbeComplete: (probe) {
          final activeTask = findTask(id);
          if (activeTask == null || activeTask.cancelled) return;
          activeTask.headers = probe.headers;
          activeTask.remoteSize = probe.contentLength;
          activeTask.phase = ShareDeferredVideoPhase.downloading;
          activeTask.progress = 0;
          _notifyChanged();
        },
        onDownloadProgress: (progress) {
          final activeTask = findTask(id);
          if (activeTask == null || activeTask.cancelled) return;
          activeTask.phase = ShareDeferredVideoPhase.downloading;
          activeTask.progress = progress.clamp(0, 1);
          _notifyChanged();
        },
        confirmCompression: (fileSize, maxBytes) async {
          final activeTask = findTask(id);
          if (activeTask == null || activeTask.cancelled) return false;
          activeTask.phase = ShareDeferredVideoPhase.awaitingCompression;
          activeTask.progress = 1;
          _notifyChanged();

          final shouldCompress = await _confirmCompression(fileSize, maxBytes);
          final compressionTask = findTask(id);
          if (compressionTask == null || compressionTask.cancelled) {
            return false;
          }
          if (shouldCompress) {
            compressionTask.phase = ShareDeferredVideoPhase.compressing;
            compressionTask.progress = 0;
            _notifyChanged();
          }
          return shouldCompress;
        },
        onCompressionProgress: (progress) {
          final activeTask = findTask(id);
          if (activeTask == null || activeTask.cancelled) return;
          activeTask.phase = ShareDeferredVideoPhase.compressing;
          activeTask.progress = progress.clamp(0, 1);
          _notifyChanged();
        },
        isCancelled: () {
          final activeTask = findTask(id);
          return activeTask == null || activeTask.cancelled;
        },
      );

      final completionTask = findTask(id);
      if (completionTask == null || completionTask.cancelled) {
        await _cleanupFile?.call(prepared.filePath);
        return;
      }

      completionTask.phase = ShareDeferredVideoPhase.completed;
      completionTask.progress = 1;
      _notifyChanged();
      await _admitPreparedAttachment(prepared);
      completionTask.phase = ShareDeferredVideoPhase.removed;
      _notifyChanged();
    } on ShareVideoAttachmentCancelled {
      await removeTask(id);
    } on ShareVideoAttachmentCompressionDeclined {
      await removeTask(id);
    } on ShareVideoAttachmentCompressionFailed {
      await removeTask(id);
      _onFailure?.call(
        const ShareDeferredVideoFailureEvent(
          failure: ShareDeferredVideoFailure.compressionFailed,
        ),
      );
    } on ShareVideoAttachmentStillTooLarge {
      await removeTask(id);
      _onFailure?.call(
        ShareDeferredVideoFailureEvent(
          failure: ShareDeferredVideoFailure.compressionStillTooLarge,
          uploadSizeLimitBytes: task.uploadSizeLimitBytes,
        ),
      );
    } catch (_) {
      final failedTask = findTask(id);
      await removeTask(id);
      if (failedTask?.cancelled == true) return;
      _onFailure?.call(
        const ShareDeferredVideoFailureEvent(
          failure: ShareDeferredVideoFailure.downloadFailed,
        ),
      );
    }
  }

  Future<void> removeTask(String id) async {
    final task = findTask(id);
    if (task == null) return;
    task.cancelled = true;
    task.phase = ShareDeferredVideoPhase.removed;
    _notifyChanged();
  }

  void clear() {
    for (final task in _tasks) {
      task.cancelled = true;
      task.phase = ShareDeferredVideoPhase.removed;
    }
    _tasks.clear();
    _notifyChanged();
  }

  Future<SharePreparedVideoAttachment> _prepareVideo({
    required ShareCaptureResult result,
    required ShareVideoCandidate candidate,
    required AttachmentUploadSizeLimit uploadSizeLimit,
    ValueChanged<ShareVideoProbeResult>? onProbeComplete,
    ValueChanged<double>? onDownloadProgress,
    ValueChanged<double>? onCompressionProgress,
    ShareVideoCompressionConfirmation? confirmCompression,
    bool Function()? isCancelled,
  }) {
    final prepare = _prepareOverride;
    if (prepare != null) {
      return prepare(
        result: result,
        candidate: candidate,
        uploadSizeLimit: uploadSizeLimit,
        onProbeComplete: onProbeComplete,
        onDownloadProgress: onDownloadProgress,
        onCompressionProgress: onCompressionProgress,
        confirmCompression: confirmCompression,
        isCancelled: isCancelled,
      );
    }
    return _preparer.prepare(
      result: result,
      candidate: candidate,
      uploadSizeLimit: uploadSizeLimit,
      onProbeComplete: onProbeComplete,
      onDownloadProgress: onDownloadProgress,
      onCompressionProgress: onCompressionProgress,
      confirmCompression: confirmCompression,
      isCancelled: isCancelled,
    );
  }

  void _notifyChanged() {
    _onChanged?.call();
  }
}

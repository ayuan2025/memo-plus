import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../core/attachment_mime_type.dart';
import '../../data/api/memos_api.dart';
import 'share_clip_models.dart';
import 'share_video_compression_service.dart';
import 'share_video_download_service.dart';

typedef ShareVideoCompressionConfirmation =
    Future<bool> Function(int fileSize, int maxBytes);

@immutable
class SharePreparedVideoAttachment {
  const SharePreparedVideoAttachment({
    required this.filePath,
    required this.filename,
    required this.mimeType,
    required this.size,
    required this.wasCompressed,
  });

  final String filePath;
  final String filename;
  final String mimeType;
  final int size;
  final bool wasCompressed;
}

class ShareVideoAttachmentCancelled implements Exception {
  const ShareVideoAttachmentCancelled();
}

class ShareVideoAttachmentCompressionDeclined implements Exception {
  const ShareVideoAttachmentCompressionDeclined();
}

class ShareVideoAttachmentCompressionFailed implements Exception {
  const ShareVideoAttachmentCompressionFailed();
}

class ShareVideoAttachmentStillTooLarge implements Exception {
  const ShareVideoAttachmentStillTooLarge();
}

class ShareVideoAttachmentPreparer {
  ShareVideoAttachmentPreparer({
    ShareVideoDownloadService? downloadService,
    ShareVideoCompressionService? compressionService,
  }) : _downloadService = downloadService ?? ShareVideoDownloadService(),
       _compressionService =
           compressionService ?? ShareVideoCompressionService();

  final ShareVideoDownloadService _downloadService;
  final ShareVideoCompressionService _compressionService;

  Future<SharePreparedVideoAttachment> prepare({
    required ShareCaptureResult result,
    required ShareVideoCandidate candidate,
    required AttachmentUploadSizeLimit uploadSizeLimit,
    ValueChanged<ShareVideoProbeResult>? onProbeComplete,
    ValueChanged<double>? onDownloadProgress,
    ValueChanged<double>? onCompressionProgress,
    ShareVideoCompressionConfirmation? confirmCompression,
    bool Function()? isCancelled,
  }) async {
    String? downloadedPath;
    String? compressedPath;
    try {
      final probe = await _downloadService.probe(
        result: result,
        candidate: candidate,
      );
      _throwIfCancelled(isCancelled);
      onProbeComplete?.call(probe);

      final download = await _downloadService.download(
        result: result,
        candidate: candidate,
        onProgress: onDownloadProgress,
      );
      downloadedPath = download.filePath;
      _throwIfCancelled(isCancelled);

      var resolvedPath = download.filePath;
      var resolvedSize = download.fileSize;
      var wasCompressed = false;
      final maxBytes = uploadSizeLimit.bytes;
      if (uploadSizeLimit.isKnown &&
          maxBytes != null &&
          resolvedSize > maxBytes) {
        final shouldCompress =
            await confirmCompression?.call(resolvedSize, maxBytes) ?? true;
        _throwIfCancelled(isCancelled);
        if (!shouldCompress) {
          throw const ShareVideoAttachmentCompressionDeclined();
        }
        final compression = await _compressionService.compressToFit(
          inputPath: download.filePath,
          maxBytes: maxBytes,
          targetBytes: shareVideoCompressionTargetBytesForLimit(maxBytes),
          onProgress: onCompressionProgress,
        );
        _throwIfCancelled(isCancelled);
        if (compression == null) {
          throw const ShareVideoAttachmentCompressionFailed();
        }
        compressedPath = compression.filePath;
        resolvedPath = compression.filePath;
        resolvedSize = compression.fileSize;
        wasCompressed = compression.wasCompressed;
        if (compression.wasCompressed && compressedPath != downloadedPath) {
          await _deleteFile(downloadedPath);
          downloadedPath = null;
        }
        if (resolvedSize > maxBytes) {
          throw const ShareVideoAttachmentStillTooLarge();
        }
      }

      return SharePreparedVideoAttachment(
        filePath: resolvedPath,
        filename: p.basename(resolvedPath),
        mimeType: guessAttachmentMimeType(resolvedPath, fallback: 'video/mp4'),
        size: resolvedSize,
        wasCompressed: wasCompressed,
      );
    } catch (_) {
      await _deleteFile(compressedPath);
      await _deleteFile(downloadedPath);
      rethrow;
    }
  }
}

int shareVideoCompressionTargetBytesForLimit(int maxBytes) {
  if (maxBytes <= 1) return maxBytes;
  final margin = (maxBytes * 0.05)
      .round()
      .clamp(512 * 1024, 4 * 1024 * 1024)
      .toInt();
  final target = maxBytes - margin;
  return target > 0 ? target : maxBytes - 1;
}

void _throwIfCancelled(bool Function()? isCancelled) {
  if (isCancelled?.call() == true) {
    throw const ShareVideoAttachmentCancelled();
  }
}

Future<void> _deleteFile(String? path) async {
  if (path == null || path.trim().isEmpty) return;
  final file = File(path);
  if (!await file.exists()) return;
  try {
    await file.delete();
  } catch (_) {}
}

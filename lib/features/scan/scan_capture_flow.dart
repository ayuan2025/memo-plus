import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/uid.dart';
import '../../data/logs/log_manager.dart';
import 'scan_review_screen.dart';

/// Picks up a photo for the scan flow to work on, returning its path or null
/// when the user backed out.
///
/// Supplied by the caller because how a photo is taken is a platform and
/// feature concern — the camera screen on Windows, `image_picker` everywhere
/// else — and the scanner itself only ever needs the resulting image.
typedef ScanPhotoSource = Future<String?> Function();

/// A scanned page on disk, plus whatever a model said about it.
class ScannedDocument {
  const ScannedDocument({
    required this.filePath,
    required this.filename,
    this.title = '',
    this.tags = const <String>[],
    this.body = '',
  });

  /// Where the finished page was written, as a JPEG.
  final String filePath;

  /// A human-readable name that survives into the upload, so a scanned page can
  /// be told apart from camera photos once it is on the server.
  final String filename;

  final String title;
  final List<String> tags;

  /// The full recognised text of the page, or empty when none was read.
  ///
  /// Surfaces the on-device OCR result so the caller can drop it into the
  /// note's hidden body instead of discarding it.
  final String body;

  bool get hasMetadata => title.isNotEmpty || tags.isNotEmpty;
}

/// Takes a photo, lets the user correct it, and writes the result to a file.
///
/// This is the whole scan feature as one call, so every composer surface gets
/// identical behaviour from a single place. Returns null whenever the user
/// cancels at any point — in which case, deliberately, nothing has been written
/// to disk yet, so there is no temp file left behind to clean up.
Future<ScannedDocument?> captureAndReviewDocument({
  required BuildContext context,
  required ScanPhotoSource capturePhoto,
  bool askForMetadata = true,
}) async {
  final sourcePath = await capturePhoto();
  if (sourcePath == null || sourcePath.trim().isEmpty) return null;

  final sourceFile = File(sourcePath);
  if (!sourceFile.existsSync()) return null;

  final Uint8List encoded;
  try {
    encoded = await sourceFile.readAsBytes();
  } on FileSystemException {
    return null;
  }
  if (encoded.isEmpty) return null;

  if (!context.mounted) return null;
  final reviewed = await ScanReviewScreen.open(
    context,
    encoded: encoded,
    askForMetadata: askForMetadata,
  );
  if (reviewed == null) return null;

  final filename = buildScanFilename();
  try {
    final directory = await getTemporaryDirectory();
    final target = File('${directory.path}${Platform.pathSeparator}$filename');
    await target.writeAsBytes(reviewed.bytes, flush: true);
    return ScannedDocument(
      filePath: target.path,
      filename: filename,
      title: reviewed.title,
      tags: reviewed.tags,
      body: reviewed.body,
    );
  } catch (error, stackTrace) {
    // A device that will not hand out a temp directory, or that has run out of
    // space, cannot hold a scan. Fail here rather than returning a path to a
    // file that was never written, so the caller never builds an attachment on
    // top of a missing page.
    LogManager.instance.warn(
      'ScanCaptureFlow: write_failed',
      error: error,
      stackTrace: stackTrace,
      context: {'bytes': reviewed.bytes.length},
    );
    return null;
  }
}

/// `scan-20260916-210345-a3f901.jpg`.
///
/// Carries the moment it was taken so a downloaded scan is identifiable by
/// name, and a short random tail so two scans in the same second cannot land on
/// the same file.
String buildScanFilename({DateTime? now}) {
  final at = now ?? DateTime.now();
  String two(int value) => value.toString().padLeft(2, '0');
  final stamp =
      '${at.year}${two(at.month)}${two(at.day)}'
      '-${two(at.hour)}${two(at.minute)}${two(at.second)}';
  return 'scan-$stamp-${generateUid(length: 6)}.jpg';
}

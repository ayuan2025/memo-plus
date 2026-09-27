// Re-reads pages this app has already scanned, so old notes pick up whatever
// the current recogniser can get off them.
//
// Nothing here decides *what* to recognise — that stays with
// LocalScanMetadataService — and nothing here knows how a memo reaches the
// server: the caller hands in a `save` callback. That keeps the batch testable
// on a desk, where there is no camera and no Memos instance.
//
// The one policy worth stating plainly: a page is only rewritten when the new
// read is *longer* than what is already stored. Re-running the same engine on
// the same page returns a slightly different answer every time, and writing
// whichever came back last would let a worse read replace a better one. Only a
// read that found more is evidence the old one was missing something.

import 'dart:typed_data';

import '../../core/memo_scan_metadata.dart';
import '../../data/models/attachment.dart';
import '../../data/models/local_memo.dart';
import '../../data/scan/local_scan_metadata_service.dart';

/// Filename prefix every page this app has ever scanned is saved under.
///
/// Fixed by [buildScanFilename] and unchanged since, so it is how a page is
/// recognised as ours rather than a photo the user attached themselves.
const String kScanFilenamePrefix = 'scan-';

/// Why one memo came out of a batch the way it did.
enum ScanReindexOutcome {
  /// The new read was longer than the stored one, and replaced it.
  improved,

  /// A read came back but was not better than what was already there.
  unchanged,

  /// The memo has no page image left to read.
  noImage,

  /// Downloading or recognising the page threw.
  failed,
}

/// Where a batch has got to, for a progress indicator.
class ScanReindexProgress {
  const ScanReindexProgress({
    required this.completed,
    required this.total,
    required this.improved,
    this.currentMemoUid,
  });

  final int completed;
  final int total;
  final int improved;
  final String? currentMemoUid;
}

/// What a batch achieved, for a summary line.
class ScanReindexReport {
  const ScanReindexReport({
    this.improved = 0,
    this.unchanged = 0,
    this.noImage = 0,
    this.failed = 0,
    this.cancelled = false,
  });

  /// Memos whose stored text grew.
  final int improved;

  /// Memos read again but left alone.
  final int unchanged;

  /// Memos whose page image is gone or unreachable.
  final int noImage;

  /// Memos that threw while being read.
  final int failed;

  /// True when the caller stopped the batch before it finished.
  final bool cancelled;

  int get considered => improved + unchanged + noImage + failed;

  ScanReindexReport operator +(ScanReindexOutcome outcome) {
    return ScanReindexReport(
      improved: improved + (outcome == ScanReindexOutcome.improved ? 1 : 0),
      unchanged: unchanged + (outcome == ScanReindexOutcome.unchanged ? 1 : 0),
      noImage: noImage + (outcome == ScanReindexOutcome.noImage ? 1 : 0),
      failed: failed + (outcome == ScanReindexOutcome.failed ? 1 : 0),
      cancelled: cancelled,
    );
  }
}

class ScanReindexService {
  const ScanReindexService({
    required LocalScanMetadataService ocr,
    required Future<Uint8List?> Function(Attachment attachment) readBytes,
  }) : _ocr = ocr,
       _readBytes = readBytes;

  final LocalScanMetadataService _ocr;
  final Future<Uint8List?> Function(Attachment attachment) _readBytes;

  /// Whether this build can read pages at all.
  bool get isSupported => _ocr.isSupported;

  /// Whether [memo] is a page this app scanned.
  ///
  /// Two shapes count: anything carrying hidden OCR, and anything holding a
  /// page image filed under the scan prefix. The second is what catches pages
  /// scanned before the hidden block existed — those have no marker in the
  /// content to find them by.
  static bool isScanMemo(LocalMemo memo) {
    if (hasHiddenScanOcr(memo.content)) return true;
    return scanAttachmentOf(memo) != null;
  }

  /// The page image a scanned memo carries, or null when it has none left.
  ///
  /// A memo with hidden OCR but no `scan-` image still counts — the page may
  /// have been renamed or re-attached — so any image will do as a fallback
  /// there. Without that marker only a page filed under the scan prefix is
  /// ours, otherwise every photo the user ever attached would be read.
  static Attachment? scanAttachmentOf(LocalMemo memo) {
    Attachment? fallback;
    for (final attachment in memo.attachments) {
      if (!attachment.isImage) continue;
      if (attachment.filename
          .trim()
          .toLowerCase()
          .startsWith(kScanFilenamePrefix)) {
        return attachment;
      }
      fallback ??= attachment;
    }
    return hasHiddenScanOcr(memo.content) ? fallback : null;
  }

  /// Re-reads every scan in [memos], saving through [save] only when the new
  /// read is longer than the text already stored.
  ///
  /// [shouldStop] is polled between memos, never mid-page: a page already
  /// handed to the recogniser finishes, so stopping never leaves a memo
  /// half-written.
  Future<ScanReindexReport> reindex({
    required List<LocalMemo> memos,
    required Future<void> Function(LocalMemo memo, String content) save,
    void Function(ScanReindexProgress progress)? onProgress,
    bool Function()? shouldStop,
  }) async {
    final targets = memos.where(isScanMemo).toList(growable: false);
    var report = const ScanReindexReport();

    for (var index = 0; index < targets.length; index++) {
      if (shouldStop?.call() ?? false) {
        return ScanReindexReport(
          improved: report.improved,
          unchanged: report.unchanged,
          noImage: report.noImage,
          failed: report.failed,
          cancelled: true,
        );
      }

      final memo = targets[index];
      onProgress?.call(
        ScanReindexProgress(
          completed: index,
          total: targets.length,
          improved: report.improved,
          currentMemoUid: memo.uid,
        ),
      );

      report = report + await _reindexOne(memo, save);
    }

    onProgress?.call(
      ScanReindexProgress(
        completed: targets.length,
        total: targets.length,
        improved: report.improved,
      ),
    );
    return report;
  }

  Future<ScanReindexOutcome> _reindexOne(
    LocalMemo memo,
    Future<void> Function(LocalMemo memo, String content) save,
  ) async {
    final attachment = scanAttachmentOf(memo);
    if (attachment == null) return ScanReindexOutcome.noImage;

    final Uint8List bytes;
    try {
      final read = await _readBytes(attachment);
      if (read == null || read.isEmpty) return ScanReindexOutcome.noImage;
      bytes = read;
    } catch (_) {
      return ScanReindexOutcome.noImage;
    }

    final String text;
    try {
      final draft = await _ocr.generate(
        imageBytes: bytes,
        scannedAt: memo.createTime,
      );
      text = draft?.text.trim() ?? '';
    } catch (_) {
      return ScanReindexOutcome.failed;
    }

    // An empty read is not an improvement over anything, and overwriting a
    // page that currently reads well with nothing would be the worst outcome
    // this batch could produce.
    if (text.isEmpty) return ScanReindexOutcome.unchanged;

    final previous = extractHiddenScanOcr(memo.content).trim();
    if (text.runes.length <= previous.runes.length) {
      return ScanReindexOutcome.unchanged;
    }

    try {
      await save(
        memo,
        withHiddenScanOcr(stripHiddenScanOcr(memo.content), text),
      );
    } catch (_) {
      return ScanReindexOutcome.failed;
    }
    return ScanReindexOutcome.improved;
  }
}

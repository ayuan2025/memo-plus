import 'dart:typed_data';

import '../../core/memo_scan_metadata.dart';
import '../../core/scan_document_outline.dart';
import '../../core/scan/src/ocr_preprocess.dart';
import './local_document_text_service.dart';
import './ocr_page_preprocessor.dart';

/// Proposes a memo title and tags for a scan using only what is on the device.
///
/// This is the default reader for the document scanner. It costs nothing to
/// run, works with no account and no network, and never sends a page anywhere —
/// which matters when the pages being scanned are contracts and invoices.
///
/// It deliberately reports failure as `null` rather than as an error: a page
/// with no readable headline is an ordinary outcome, and the caller decides
/// whether a configured model is worth trying instead.
class LocalScanMetadataService {
  const LocalScanMetadataService({
    required LocalDocumentTextService textService,
    required OcrPagePreprocessor preprocessor,
  }) : _textService = textService,
       _preprocessor = preprocessor;

  final LocalDocumentTextService _textService;
  final OcrPagePreprocessor _preprocessor;

  /// Whether this build can read a page at all, without asking a model.
  bool get isSupported => _textService.isSupported;

  /// The order the page is handed to the recogniser in.
  ///
  /// A page is read more than once before giving up, because the distance
  /// between "nothing came back" and "everything came back" is often nothing
  /// more than how hard the levels were pushed. A further local pass costs a
  /// few hundred milliseconds, which is far cheaper than either telling the
  /// user their page came out blank or paying for a model call because the page
  /// happened to be grey and unevenly lit.
  ///
  /// The trailing `null` is the page exactly as it was captured, read last.
  /// Preprocessing is a bet that a page reads better without the room's
  /// lighting on it; that bet has to be settled rather than assumed, or a page
  /// that read fine as it was would come out worse for having been "improved".
  static const List<OcrPreprocessLevel?> _attempts = [
    OcrPreprocessLevel.balanced,
    OcrPreprocessLevel.flat,
    OcrPreprocessLevel.aggressive,
    null,
  ];

  /// How much text a single pass has to read for it to be trusted outright.
  ///
  /// Below this the pass is treated as having caught only a fragment of the
  /// page — a stray line, a letterhead — and the remaining attempts are run to
  /// see whether they read more. At or above it the page was genuinely read,
  /// and making the user wait for further passes would buy nothing.
  ///
  /// The bar has to be high enough that "read something" is not mistaken for
  /// "read the page". A dense Chinese page runs to several hundred characters;
  /// a pass that came back with forty of them has lost most of the page, and
  /// stopping there would bake that loss into the hidden body the memo is
  /// searched by. Only a genuinely short page — a business card, a one-line
  /// note — is meant to fall below this and pay for all four passes.
  static const int _kConfidentReadRunes = 120;

  /// A suggestion derived from the text recognised on the page, or null when
  /// the page yielded nothing the rules could turn into a title or a tag.
  ///
  /// [scannedAt] dates the fallback title, and [fallbackPrefix] is what that
  /// title is called; the caller passes a localised one.
  Future<ScanMetadataDraft?> generate({
    required Uint8List imageBytes,
    required DateTime scannedAt,
    String fallbackPrefix = '扫描件',
  }) async {
    if (!isSupported || imageBytes.isEmpty) return null;

    // The recognised text is kept as the memo's hidden body and is what makes
    // a scan searchable, so the pass that read the most off the page is the one
    // worth keeping — not the first one that read anything at all. Taking the
    // first non-empty answer instead would let a pass that caught a single line
    // stand in for the whole page, and everything else on it would then be
    // missing from search.
    ScanMetadataDraft? best;
    var bestRunes = -1;

    for (final level in _attempts) {
      final page = level == null
          ? imageBytes
          : await _preprocessor.prepare(imageBytes, level: level);
      final text = await _textService.readText(page);
      if (text == null || text.trim().isEmpty) continue;

      final draft = outlineScannedText(
        text,
        scannedAt: scannedAt,
        fallbackPrefix: fallbackPrefix,
      );
      if (draft == null || draft.isEmpty) continue;

      final runes = draft.text.trim().runes.length;
      if (runes <= bestRunes) continue;
      best = draft;
      bestRunes = runes;
      if (runes >= _kConfidentReadRunes) break;
    }
    return best;
  }
}

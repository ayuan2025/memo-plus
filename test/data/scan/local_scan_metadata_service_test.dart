import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:memos_flutter_app/core/scan/src/ocr_preprocess.dart';
import 'package:memos_flutter_app/data/scan/local_document_text_service.dart';
import 'package:memos_flutter_app/data/scan/local_scan_metadata_service.dart';
import 'package:memos_flutter_app/data/scan/ocr_page_preprocessor.dart';

/// Hands the recogniser a different answer per page, so a test can decide what
/// each preprocessing level "reads".
///
/// The marker byte distinguishes the pages: the preprocessor rewrites the page
/// to a one-byte stand-in named after the level it was asked for, and the
/// untouched page keeps the original bytes.
class _FakeTextService extends LocalDocumentTextService {
  _FakeTextService(this._answers);

  final Map<int, String?> _answers;
  final List<int> readPages = [];

  @override
  bool get isSupported => true;

  @override
  Future<String?> readText(Uint8List imageBytes) async {
    readPages.add(imageBytes.isEmpty ? -1 : imageBytes.first);
    return _answers[imageBytes.isEmpty ? -1 : imageBytes.first];
  }
}

class _FakePreprocessor extends OcrPagePreprocessor {
  final List<OcrPreprocessLevel> prepared = [];

  @override
  Future<Uint8List> prepare(
    Uint8List encoded, {
    OcrPreprocessLevel level = OcrPreprocessLevel.balanced,
  }) async {
    prepared.add(level);
    return Uint8List.fromList([level.index + 1]);
  }
}

LocalScanMetadataService _service({
  required _FakeTextService text,
  required _FakePreprocessor preprocessor,
}) {
  return LocalScanMetadataService(
    textService: text,
    preprocessor: preprocessor,
  );
}

void main() {
  final scannedAt = DateTime(2026, 9, 25);

  // Long enough to clear the "this pass read the page" bar on its own.
  final fullPage = List.filled(30, '发票号码04412836').join('\n');

  test('keeps the pass that read the most, not the first that read anything',
      () async {
    final text = _FakeTextService({
      1: '发票', // balanced: one stray line
      2: fullPage, // aggressive: the whole page
      9: null, // the untouched page
    });
    final preprocessor = _FakePreprocessor();

    final draft = await _service(text: text, preprocessor: preprocessor)
        .generate(imageBytes: Uint8List.fromList([9]), scannedAt: scannedAt);

    expect(draft, isNotNull);
    // The hidden body is what makes a scan searchable. A one-line read that
    // happened to come first must not be allowed to stand in for the page.
    expect(draft!.text, fullPage);
    expect(preprocessor.prepared, [
      OcrPreprocessLevel.balanced,
      OcrPreprocessLevel.flat,
      OcrPreprocessLevel.aggressive,
    ]);
    // The aggressive pass read the page properly, so the untouched page is
    // never reached — the fallback exists for a page nothing else could read,
    // not as a further opinion on one that was already read.
    expect(text.readPages, [1, 3, 2]);
  });

  test('a pass that caught only a fragment does not end the search', () async {
    // Three lines of an invoice: recognisably text, comfortably under the bar,
    // and nowhere near the several hundred characters a dense page holds.
    final fragment = List.filled(3, '发票号码04412836').join('\n');
    expect(fragment.runes.length, lessThan(120));

    final text = _FakeTextService({
      1: fragment, // balanced: lost most of the page
      3: fullPage, // flat: read it properly
      2: 'something else entirely, never asked for',
      9: null,
    });
    final preprocessor = _FakePreprocessor();

    final draft = await _service(text: text, preprocessor: preprocessor)
        .generate(imageBytes: Uint8List.fromList([9]), scannedAt: scannedAt);

    // Trusting the first pass here would have hidden nine tenths of the page
    // from search, which is exactly the regression this guards against.
    expect(draft!.text, fullPage);
    expect(preprocessor.prepared, [
      OcrPreprocessLevel.balanced,
      OcrPreprocessLevel.flat,
    ]);
    expect(text.readPages, [1, 3]);
  });

  test('stops early once a pass has genuinely read the page', () async {
    final text = _FakeTextService({
      1: fullPage,
      2: 'something else entirely, never asked for',
      9: null,
    });
    final preprocessor = _FakePreprocessor();

    final draft = await _service(text: text, preprocessor: preprocessor)
        .generate(imageBytes: Uint8List.fromList([9]), scannedAt: scannedAt);

    expect(draft!.text, fullPage);
    // A confident first read is used outright rather than making the user wait
    // through two more passes.
    expect(preprocessor.prepared, [OcrPreprocessLevel.balanced]);
    expect(text.readPages, [1]);
  });

  test('falls back to the page as captured when preprocessing reads nothing',
      () async {
    final text = _FakeTextService({
      1: null,
      2: null,
      9: '发票号码 04412836',
    });
    final preprocessor = _FakePreprocessor();

    final draft = await _service(text: text, preprocessor: preprocessor)
        .generate(imageBytes: Uint8List.fromList([9]), scannedAt: scannedAt);

    // Preprocessing is a bet that the page reads better without the room's
    // lighting on it. When it loses, the page as it was must still be read.
    expect(draft, isNotNull);
    expect(draft!.text, '发票号码 04412836');
  });

  test('returns null when no pass reads anything', () async {
    final text = _FakeTextService(const {});
    final preprocessor = _FakePreprocessor();

    final draft = await _service(text: text, preprocessor: preprocessor)
        .generate(imageBytes: Uint8List.fromList([9]), scannedAt: scannedAt);

    expect(draft, isNull);
  });
}

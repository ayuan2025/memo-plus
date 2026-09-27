import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:memos_flutter_app/application/scan/scan_reindex_service.dart';
import 'package:memos_flutter_app/core/memo_scan_metadata.dart';
import 'package:memos_flutter_app/core/scan/src/ocr_preprocess.dart';
import 'package:memos_flutter_app/data/models/attachment.dart';
import 'package:memos_flutter_app/data/models/local_memo.dart';
import 'package:memos_flutter_app/data/scan/local_document_text_service.dart';
import 'package:memos_flutter_app/data/scan/local_scan_metadata_service.dart';
import 'package:memos_flutter_app/data/scan/ocr_page_preprocessor.dart';

/// Answers every preprocessing level with the same text.
///
/// The batch does not care which level read the page — that is the
/// recogniser's own business — only how much came back.
class _FakeTextService extends LocalDocumentTextService {
  _FakeTextService(this._text);

  final String? _text;
  int calls = 0;

  @override
  bool get isSupported => true;

  @override
  Future<String?> readText(Uint8List imageBytes) async {
    calls++;
    return _text;
  }
}

class _FakePreprocessor extends OcrPagePreprocessor {
  @override
  Future<Uint8List> prepare(
    Uint8List encoded, {
    OcrPreprocessLevel level = OcrPreprocessLevel.balanced,
  }) async {
    return Uint8List.fromList([level.index + 1]);
  }
}

LocalScanMetadataService _ocr(String? text) {
  return LocalScanMetadataService(
    textService: _FakeTextService(text),
    preprocessor: _FakePreprocessor(),
  );
}

Attachment _image(String filename) {
  return Attachment(
    name: 'attachments/$filename',
    filename: filename,
    type: 'image/jpeg',
    size: 1024,
    externalLink: '/file/attachments/$filename/$filename',
  );
}

const _scanFilename = 'scan-20260925-100000-a1b2c3.jpg';

LocalMemo _memo({
  required String uid,
  required String content,
  List<Attachment> attachments = const <Attachment>[],
}) {
  return LocalMemo(
    uid: uid,
    content: content,
    contentFingerprint: 'fp-$uid',
    visibility: 'PRIVATE',
    pinned: false,
    state: 'NORMAL',
    createTime: DateTime(2026, 9, 25),
    displayTime: null,
    updateTime: DateTime(2026, 9, 25),
    tags: const <String>[],
    attachments: attachments,
    relationCount: 0,
    location: null,
    syncState: SyncState.synced,
    lastError: null,
  );
}

void main() {
  final pageBytes = Uint8List.fromList([9, 9, 9]);

  test('recognises a scan by its hidden block and by its page filename', () {
    final byBlock = _memo(uid: 'a', content: withHiddenScanOcr('# T', '发票'));
    final byFilename = _memo(
      uid: 'b',
      content: 'no marker here',
      attachments: <Attachment>[_image(_scanFilename)],
    );
    final ordinaryPhoto = _memo(
      uid: 'c',
      content: 'no marker here',
      attachments: <Attachment>[_image('IMG_2041.jpg')],
    );

    expect(ScanReindexService.isScanMemo(byBlock), isTrue);
    expect(ScanReindexService.isScanMemo(byFilename), isTrue);
    expect(ScanReindexService.isScanMemo(ordinaryPhoto), isFalse);
  });

  test('a read that found more replaces the stored one', () async {
    final memo = _memo(
      uid: 'a',
      content: withHiddenScanOcr('# 发票', '发票'),
      attachments: <Attachment>[_image(_scanFilename)],
    );
    final saved = <String, String>{};

    final report = await ScanReindexService(
      ocr: _ocr('发票号码 04412836 金额 1200 元'),
      readBytes: (_) async => pageBytes,
    ).reindex(
      memos: <LocalMemo>[memo],
      save: (m, content) async => saved[m.uid] = content,
    );

    expect(report.improved, 1);
    expect(saved['a'], isNotNull);
    expect(extractHiddenScanOcr(saved['a']!), '发票号码 04412836 金额 1200 元');
  });

  test('a read that found less leaves the stored one alone', () async {
    final stored = '发票号码 04412836 金额 1200 元 税额 一百二十';
    final memo = _memo(
      uid: 'a',
      content: withHiddenScanOcr('# 发票', stored),
      attachments: <Attachment>[_image(_scanFilename)],
    );
    final saved = <String, String>{};

    final report = await ScanReindexService(
      // Same page, worse day: the engine returned a fragment this time.
      ocr: _ocr('发票'),
      readBytes: (_) async => pageBytes,
    ).reindex(
      memos: <LocalMemo>[memo],
      save: (m, content) async => saved[m.uid] = content,
    );

    expect(report.improved, 0);
    expect(report.unchanged, 1);
    expect(saved, isEmpty);
  });

  test('an empty read never blanks out a page that already reads', () async {
    final memo = _memo(
      uid: 'a',
      content: withHiddenScanOcr('# 发票', '发票号码 04412836'),
      attachments: <Attachment>[_image(_scanFilename)],
    );
    final saved = <String, String>{};

    final report = await ScanReindexService(
      ocr: _ocr(null),
      readBytes: (_) async => pageBytes,
    ).reindex(
      memos: <LocalMemo>[memo],
      save: (m, content) async => saved[m.uid] = content,
    );

    expect(report.unchanged, 1);
    expect(saved, isEmpty);
    expect(extractHiddenScanOcr(memo.content), '发票号码 04412836');
  });

  test('rewriting keeps the visible note and swaps only the hidden block',
      () async {
    final memo = _memo(
      uid: 'a',
      content: '# 发票\n\n#扫描件\n\n${withHiddenScanOcr('# 发票\n\n#扫描件', '旧的一次')}',
      attachments: <Attachment>[_image(_scanFilename)],
    );
    final saved = <String, String>{};

    await ScanReindexService(
      ocr: _ocr('发票号码 04412836 金额 1200 元 税额 一百二十元整'),
      readBytes: (_) async => pageBytes,
    ).reindex(
      memos: <LocalMemo>[memo],
      save: (m, content) async => saved[m.uid] = content,
    );

    final content = saved['a']!;
    expect(content, startsWith('# 发票'));
    expect(content, contains('#扫描件'));
    expect(content, isNot(contains('旧的一次')));
    expect(extractHiddenScanOcr(content), '发票号码 04412836 金额 1200 元 税额 一百二十元整');
  });

  test('a page whose image is gone is reported, not skipped silently',
      () async {
    final memo = _memo(
      uid: 'a',
      content: withHiddenScanOcr('# 发票', '发票'),
      attachments: <Attachment>[_image(_scanFilename)],
    );

    final report = await ScanReindexService(
      ocr: _ocr('发票号码'),
      readBytes: (_) async => null,
    ).reindex(memos: <LocalMemo>[memo], save: (_, __) async {});

    expect(report.noImage, 1);
    expect(report.improved, 0);
  });

  test('a memo with no image at all is not offered to the recogniser',
      () async {
    final memo = _memo(
      uid: 'a',
      content: withHiddenScanOcr('# 发票', '发票'),
    );
    final text = _FakeTextService('发票号码');
    final service = ScanReindexService(
      ocr: LocalScanMetadataService(
        textService: text,
        preprocessor: _FakePreprocessor(),
      ),
      readBytes: (_) async => pageBytes,
    );

    final report = await service.reindex(
      memos: <LocalMemo>[memo],
      save: (_, __) async {},
    );

    expect(report.noImage, 1);
    expect(text.calls, 0);
  });

  test('a download that throws counts as failed, not as no image', () async {
    final memo = _memo(
      uid: 'a',
      content: withHiddenScanOcr('# 发票', '发票'),
      attachments: <Attachment>[_image(_scanFilename)],
    );

    final report = await ScanReindexService(
      ocr: _ocr('发票号码'),
      readBytes: (_) async => throw StateError('socket closed'),
    ).reindex(memos: <LocalMemo>[memo], save: (_, __) async {});

    expect(report.failed, 0);
    expect(report.noImage, 1);
  });

  test('stopping between pages finishes the batch early and says so', () async {
    final memos = List.generate(
      5,
      (i) => _memo(
        uid: 'm$i',
        content: withHiddenScanOcr('# 发票 $i', '发票'),
        attachments: <Attachment>[_image(_scanFilename)],
      ),
    );
    var handled = 0;

    final report = await ScanReindexService(
      ocr: _ocr('发票号码 04412836 金额 1200 元'),
      readBytes: (_) async => pageBytes,
    ).reindex(
      memos: memos,
      save: (_, __) async {},
      shouldStop: () => handled++ >= 2,
    );

    expect(report.cancelled, isTrue);
    expect(report.considered, lessThan(5));
  });

  test('progress reports the total up front and finishes on it', () async {
    final memos = List.generate(
      3,
      (i) => _memo(
        uid: 'm$i',
        content: withHiddenScanOcr('# 发票 $i', '发票'),
        attachments: <Attachment>[_image(_scanFilename)],
      ),
    );
    final seen = <ScanReindexProgress>[];

    await ScanReindexService(
      ocr: _ocr('发票号码 04412836 金额 1200 元'),
      readBytes: (_) async => pageBytes,
    ).reindex(
      memos: memos,
      save: (_, __) async {},
      onProgress: seen.add,
    );

    expect(seen.first.total, 3);
    expect(seen.first.completed, 0);
    expect(seen.last.completed, 3);
    expect(seen.last.improved, 3);
  });

  test('a photo the user attached is never read', () async {
    final memo = _memo(
      uid: 'a',
      content: '假期照片',
      attachments: <Attachment>[_image('IMG_2041.jpg')],
    );
    final text = _FakeTextService('发票号码');

    final report = await ScanReindexService(
      ocr: LocalScanMetadataService(
        textService: text,
        preprocessor: _FakePreprocessor(),
      ),
      readBytes: (_) async => pageBytes,
    ).reindex(memos: <LocalMemo>[memo], save: (_, __) async {});

    expect(report.considered, 0);
    expect(text.calls, 0);
  });
}

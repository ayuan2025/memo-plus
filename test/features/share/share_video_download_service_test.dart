import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/features/share/share_clip_models.dart';
import 'package:memos_flutter_app/features/share/share_video_download_service.dart';

void main() {
  group('ShareVideoDownloadService', () {
    test('builds request headers and sanitized filename', () async {
      final tempDir = await Directory.systemTemp.createTemp('share-video-test');
      addTearDown(() => tempDir.delete(recursive: true));
      final client = _FakeShareVideoHttpClient(bytes: Uint8List.fromList(List<int>.filled(16, 1)));
      final service = ShareVideoDownloadService(
        client: client,
        resolveDirectory: () async => tempDir,
        readCookieHeader: (_) async => 'SESS=1',
      );
      final result = ShareCaptureResult.success(
        finalUrl: Uri.parse('https://example.com/post/1'),
        articleTitle: 'Unsafe:/Title?',
        pageUserAgent: 'UnitTest-UA',
      );
      const candidate = ShareVideoCandidate(
        id: 'c1',
        url: 'https://cdn.example.com/video.mp4',
        title: 'unsafe title',
        source: ShareVideoSource.parser,
        referer: 'https://example.com/post/1',
        headers: {'X-Test': '1'},
        isDirectDownloadable: true,
      );

      final download = await service.download(result: result, candidate: candidate);

      expect(File(download.filePath).existsSync(), isTrue);
      expect(download.headers['Referer'], 'https://example.com/post/1');
      expect(download.headers['User-Agent'], 'UnitTest-UA');
      expect(download.headers['Cookie'], 'SESS=1');
      expect(download.headers['X-Test'], '1');
      expect(download.filePath, contains('unsafe_title'));
    });

    test('probes remote content length with prepared headers', () async {
      final client = _FakeShareVideoHttpClient(
        bytes: Uint8List.fromList(List<int>.filled(16, 1)),
        probeResult: const ShareVideoHttpProbeResult(
          contentLength: 2097152,
          mimeType: 'video/mp4',
        ),
      );
      final service = ShareVideoDownloadService(
        client: client,
        readCookieHeader: (_) async => 'SESS=2',
      );
      final result = ShareCaptureResult.success(
        finalUrl: Uri.parse('https://example.com/post/1'),
        pageUserAgent: 'UnitTest-UA',
      );
      const candidate = ShareVideoCandidate(
        id: 'c2',
        url: 'https://cdn.example.com/video.mp4',
        source: ShareVideoSource.parser,
        referer: 'https://example.com/post/1',
        isDirectDownloadable: true,
      );

      final probe = await service.probe(result: result, candidate: candidate);

      expect(probe.contentLength, 2097152);
      expect(probe.mimeType, 'video/mp4');
      expect(probe.headers['Referer'], 'https://example.com/post/1');
      expect(probe.headers['User-Agent'], 'UnitTest-UA');
      expect(probe.headers['Cookie'], 'SESS=2');
    });
  });
}

class _FakeShareVideoHttpClient implements ShareVideoHttpClient {
  _FakeShareVideoHttpClient({
    required this.bytes,
    this.probeResult = const ShareVideoHttpProbeResult(),
  });

  final Uint8List bytes;
  final ShareVideoHttpProbeResult probeResult;

  @override
  Future<void> download(
    String url,
    String savePath, {
    required Map<String, String> headers,
    void Function(double progress)? onProgress,
  }) async {
    await File(savePath).writeAsBytes(bytes, flush: true);
    onProgress?.call(1);
  }

  @override
  Future<ShareVideoHttpProbeResult> probe(
    String url, {
    required Map<String, String> headers,
  }) async {
    return probeResult;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/features/share/parsers/share_page_parser.dart';
import 'package:memos_flutter_app/features/share/share_clip_models.dart';

void main() {
  group('mergeShareVideoCandidates', () {
    test('deduplicates same url and prefers direct parser candidate', () {
      final merged = mergeShareVideoCandidates([
        const ShareVideoCandidate(
          id: 'generic',
          url: 'https://cdn.example.com/video.mp4?token=1',
          source: ShareVideoSource.meta,
          isDirectDownloadable: true,
          priority: 50,
          parserTag: 'generic',
        ),
        const ShareVideoCandidate(
          id: 'parser',
          url: 'https://cdn.example.com/video.mp4?token=1#fragment',
          source: ShareVideoSource.parser,
          isDirectDownloadable: true,
          priority: 100,
          parserTag: 'bilibili',
        ),
      ]);

      expect(merged, hasLength(1));
      expect(merged.first.id, 'parser');
    });

    test('sorts direct candidates before unsupported streams', () {
      final merged = mergeShareVideoCandidates([
        const ShareVideoCandidate(
          id: 'stream',
          url: 'https://cdn.example.com/video.m3u8',
          source: ShareVideoSource.dom,
          isDirectDownloadable: false,
          priority: 10,
          parserTag: 'generic',
        ),
        const ShareVideoCandidate(
          id: 'direct',
          url: 'https://cdn.example.com/video.mp4',
          source: ShareVideoSource.dom,
          isDirectDownloadable: true,
          priority: 10,
          parserTag: 'generic',
        ),
      ]);

      expect(merged.map((item) => item.id), ['direct', 'stream']);
    });
  });
}

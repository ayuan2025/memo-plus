import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/features/share/share_clip_models.dart';
import 'package:memos_flutter_app/features/share/share_quick_clip_media_classifier.dart';

void main() {
  test('classifies Xiaohongshu video and prefers h264 direct candidate', () {
    final result = ShareCaptureResult.success(
      finalUrl: Uri.parse('https://www.xiaohongshu.com/explore/1'),
      pageKind: SharePageKind.video,
      siteParserTag: 'xiaohongshu',
      videoCandidates: const [
        ShareVideoCandidate(
          id: 'h265',
          url: 'https://sns-video.xhscdn.com/h265.mp4',
          source: ShareVideoSource.parser,
          isDirectDownloadable: true,
          priority: 200,
          parserTag: 'xiaohongshu',
        ),
        ShareVideoCandidate(
          id: 'h264',
          url: 'https://sns-video.xhscdn.com/h264.mp4',
          source: ShareVideoSource.parser,
          isDirectDownloadable: true,
          priority: 160,
          parserTag: 'xiaohongshu',
        ),
      ],
    );

    final classification = classifyQuickClipMedia(result);

    expect(classification.path, ShareQuickClipMediaPath.video);
    expect(classification.videoCandidate?.id, 'h264');
  });

  test('classifies non-video Xiaohongshu result as image article', () {
    final result = ShareCaptureResult.success(
      finalUrl: Uri.parse('https://www.xiaohongshu.com/explore/2'),
      pageKind: SharePageKind.article,
      siteParserTag: 'xiaohongshu',
    );

    final classification = classifyQuickClipMedia(result);

    expect(classification.path, ShareQuickClipMediaPath.imageArticle);
    expect(classification.videoCandidate, isNull);
  });

  test('ignores non-Xiaohongshu results', () {
    final result = ShareCaptureResult.success(
      finalUrl: Uri.parse('https://example.com/post'),
      pageKind: SharePageKind.article,
      siteParserTag: 'generic',
    );

    final classification = classifyQuickClipMedia(result);

    expect(classification.path, ShareQuickClipMediaPath.none);
  });
}

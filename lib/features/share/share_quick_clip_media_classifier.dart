import 'share_clip_models.dart';

enum ShareQuickClipMediaPath { none, imageArticle, video }

class ShareQuickClipMediaClassification {
  const ShareQuickClipMediaClassification({
    required this.path,
    this.videoCandidate,
  });

  final ShareQuickClipMediaPath path;
  final ShareVideoCandidate? videoCandidate;
}

ShareQuickClipMediaClassification classifyQuickClipMedia(
  ShareCaptureResult result,
) {
  if (!result.isSuccess || result.siteParserTag != 'xiaohongshu') {
    return const ShareQuickClipMediaClassification(
      path: ShareQuickClipMediaPath.none,
    );
  }
  if (result.pageKind == SharePageKind.video) {
    final candidate = selectQuickClipVideoCandidate(result.videoCandidates);
    if (candidate != null) {
      return ShareQuickClipMediaClassification(
        path: ShareQuickClipMediaPath.video,
        videoCandidate: candidate,
      );
    }
  }
  return const ShareQuickClipMediaClassification(
    path: ShareQuickClipMediaPath.imageArticle,
  );
}

ShareVideoCandidate? selectQuickClipVideoCandidate(
  Iterable<ShareVideoCandidate> candidates,
) {
  final direct = candidates
      .where((candidate) => candidate.isDirectDownloadable)
      .toList(growable: false);
  if (direct.isEmpty) return null;
  direct.sort(
    (left, right) => _candidateScore(right).compareTo(_candidateScore(left)),
  );
  return direct.first;
}

int _candidateScore(ShareVideoCandidate candidate) {
  var score = 0;
  if (candidate.isDirectDownloadable) score += 10000;
  final codecHint = [
    candidate.id,
    candidate.url,
    candidate.mimeType ?? '',
    candidate.title ?? '',
    candidate.reason ?? '',
  ].join(' ').toLowerCase();
  if (codecHint.contains('h264') || codecHint.contains('avc')) {
    score += 2000;
  } else if (codecHint.contains('h265') || codecHint.contains('hevc')) {
    score += 1000;
  }
  if (candidate.mimeType != null) score += 500;
  if (candidate.parserTag == 'xiaohongshu') score += 250;
  score += candidate.priority;
  return score;
}

import 'dart:convert';

import '../share_clip_models.dart';
import 'share_page_parser.dart';

const String xiaohongshuParserTag = 'xiaohongshu';

ShareCaptureResult? parseXiaohongshuDeepLinkCapture(
  Uri deepLink, {
  Uri? fallbackSourceUrl,
}) {
  if (!_isXiaohongshuVideoDeepLink(deepLink)) return null;
  final preloadInfo = tryDecodeJsonMap(
    _queryParameter(deepLink, const ['h5VideoPreloadInfo']),
  );
  if (preloadInfo == null) return null;

  final sourceUrl = _resolveSourceUrl(deepLink, fallbackSourceUrl);
  final title = firstStringAtPaths(preloadInfo, const [
    ['title'],
    ['note', 'title'],
    ['noteInfo', 'note', 'title'],
  ]);
  final excerpt = firstStringAtPaths(preloadInfo, const [
    ['desc'],
    ['description'],
    ['note', 'desc'],
    ['noteInfo', 'note', 'desc'],
  ]);
  final leadImageUrl = firstStringAtPaths(preloadInfo, const [
    ['video_info_v2', 'image', 'first_frame'],
    ['video_info_v2', 'image', 'firstFrame'],
    ['videoInfoV2', 'image', 'first_frame'],
    ['videoInfoV2', 'image', 'firstFrame'],
    ['image', 'first_frame'],
    ['image', 'firstFrame'],
    ['cover'],
    ['coverUrl'],
  ]);
  final candidates = mergeShareVideoCandidates(
    _collectStreamCandidates(
      preloadInfo,
      referer: sourceUrl.toString(),
      title: title,
      thumbnailUrl: leadImageUrl,
    ),
  );
  if (candidates.isEmpty) return null;

  return ShareCaptureResult.success(
    finalUrl: sourceUrl,
    articleTitle: title,
    pageTitle: title,
    siteName: 'Xiaohongshu',
    excerpt: excerpt,
    leadImageUrl: leadImageUrl,
    pageKind: SharePageKind.video,
    videoCandidates: candidates,
    siteParserTag: xiaohongshuParserTag,
  );
}

bool _isXiaohongshuVideoDeepLink(Uri uri) {
  return uri.scheme.toLowerCase() == 'xhsdiscover' &&
      uri.host.toLowerCase() == 'video_feed';
}

String? _queryParameter(Uri uri, List<String> names) {
  final lowerNames = names.map((name) => name.toLowerCase()).toSet();
  for (final entry in uri.queryParameters.entries) {
    if (lowerNames.contains(entry.key.toLowerCase())) {
      return normalizeShareText(entry.value);
    }
  }
  return null;
}

Uri _resolveSourceUrl(Uri deepLink, Uri? fallbackSourceUrl) {
  final openUrl = _queryParameter(deepLink, const ['open_url', 'openUrl']);
  final resolvedOpenUrl = _resolveOpenUrl(openUrl);
  if (resolvedOpenUrl != null) return resolvedOpenUrl;

  final noteId = _noteIdFromDeepLink(deepLink);
  if (noteId != null) {
    return Uri.https('www.xiaohongshu.com', '/explore/$noteId');
  }

  if (fallbackSourceUrl != null && _isHttpUrl(fallbackSourceUrl)) {
    return fallbackSourceUrl;
  }
  return Uri.https('www.xiaohongshu.com', '/');
}

Uri? _resolveOpenUrl(String? rawOpenUrl) {
  final normalized = normalizeShareText(rawOpenUrl);
  if (normalized == null) return null;
  final parsed = Uri.tryParse(normalized);
  if (parsed != null && _isHttpUrl(parsed)) return parsed;
  try {
    final resolved = Uri.https('www.xiaohongshu.com', '/').resolve(normalized);
    return _isHttpUrl(resolved) ? resolved : null;
  } catch (_) {
    return null;
  }
}

String? _noteIdFromDeepLink(Uri deepLink) {
  for (final segment in deepLink.pathSegments.reversed) {
    final normalized = normalizeShareText(segment);
    if (normalized != null) return normalized;
  }
  return null;
}

bool _isHttpUrl(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  return scheme == 'http' || scheme == 'https';
}

Iterable<ShareVideoCandidate> _collectStreamCandidates(
  Map<String, dynamic> preloadInfo, {
  required String referer,
  required String? title,
  required String? thumbnailUrl,
}) sync* {
  yield* _collectCodecCandidates(
    preloadInfo,
    referer: referer,
    title: title,
    thumbnailUrl: thumbnailUrl,
  );
  yield* _collectFallbackCandidates(
    preloadInfo,
    referer: referer,
    title: title,
    thumbnailUrl: thumbnailUrl,
  );
}

Iterable<ShareVideoCandidate> _collectCodecCandidates(
  Map<String, dynamic> preloadInfo, {
  required String referer,
  required String? title,
  required String? thumbnailUrl,
}) sync* {
  final stream =
      valueAtPath(preloadInfo, const ['video_info_v2', 'media', 'stream']) ??
      valueAtPath(preloadInfo, const ['videoInfoV2', 'media', 'stream']) ??
      valueAtPath(preloadInfo, const ['media', 'stream']) ??
      valueAtPath(preloadInfo, const ['stream']);
  if (stream is! Map) return;

  for (final codec in const ['h264', 'h265']) {
    final list = asDynamicList(stream[codec] ?? stream[codec.toUpperCase()]);
    for (var index = 0; index < list.length; index++) {
      final map = _normalizeMap(list[index]);
      if (map == null) continue;
      final candidate = _candidateFromMap(
        map,
        codec: codec,
        index: index,
        referer: referer,
        title: title,
        thumbnailUrl: thumbnailUrl,
      );
      if (candidate != null) yield candidate;
    }
  }
}

Iterable<ShareVideoCandidate> _collectFallbackCandidates(
  Map<String, dynamic> preloadInfo, {
  required String referer,
  required String? title,
  required String? thumbnailUrl,
}) sync* {
  var index = 0;
  for (final map in deepMaps(preloadInfo)) {
    final candidate = _candidateFromMap(
      map,
      codec: null,
      index: index,
      referer: referer,
      title: title,
      thumbnailUrl: thumbnailUrl,
    );
    index++;
    if (candidate != null) yield candidate;
  }
}

ShareVideoCandidate? _candidateFromMap(
  Map<String, dynamic> map, {
  required String? codec,
  required int index,
  required String referer,
  required String? title,
  required String? thumbnailUrl,
}) {
  final rawUrl = normalizeShareText(
    map['master_url']?.toString() ??
        map['masterUrl']?.toString() ??
        map['url']?.toString() ??
        map['play_url']?.toString() ??
        map['playUrl']?.toString(),
  );
  if (rawUrl == null || !isDirectVideoUrl(rawUrl)) return null;
  final normalizedUrl = normalizeShareVideoUrl(rawUrl);
  final codecLabel = codec ?? 'video';
  return ShareVideoCandidate(
    id: 'xiaohongshu_${codecLabel}_${index}_${normalizedUrl.hashCode.abs()}',
    url: normalizedUrl,
    title: fileNameFromUrl(normalizedUrl) ?? title,
    mimeType: 'video/mp4',
    thumbnailUrl: thumbnailUrl,
    source: ShareVideoSource.parser,
    referer: referer,
    cookieUrl: referer,
    isDirectDownloadable: true,
    priority: _codecPriority(codec),
    parserTag: xiaohongshuParserTag,
  );
}

int _codecPriority(String? codec) {
  return switch ((codec ?? '').toLowerCase()) {
    'h264' => 160,
    'h265' => 120,
    _ => 80,
  };
}

Map<String, dynamic>? _normalizeMap(Object? raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  if (raw is String) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {}
  }
  return null;
}

import '../share_clip_models.dart';
import 'share_page_parser.dart';

class BilibiliSharePageParser implements SharePageParser {
  @override
  bool canParse(SharePageSnapshot snapshot) {
    final host = snapshot.host.toLowerCase();
    return host == 'b23.tv' || host.endsWith('.bilibili.com') || host == 'bilibili.com';
  }

  @override
  SharePageParserResult parse(SharePageSnapshot snapshot) {
    final bridge = snapshot.bridgeData;
    final windowStates = tryDecodeJsonMap(bridge['windowStates']) ?? const <String, dynamic>{};
    final parserRoots = <Object?>[
      windowStates['__playinfo__'],
      windowStates['__INITIAL_STATE__'],
    ];
    for (final record in snapshot.networkRecords) {
      final lowerUrl = record.url.toLowerCase();
      if (lowerUrl.contains('playurl')) {
        parserRoots.add(tryDecodeJsonMap(record.responseBody) ?? record.responseBody);
      }
    }

    final directCandidates = <ShareVideoCandidate>[];
    final unsupportedCandidates = <ShareVideoCandidate>[];
    var foundPlayableData = false;

    for (final root in parserRoots) {
      if (root == null) continue;
      final durlList = valueAtPath(root, const ['data', 'durl']) ?? valueAtPath(root, const ['durl']);
      for (final item in asDynamicList(durlList)) {
        if (item is! Map) continue;
        final map = item.map((key, value) => MapEntry(key.toString(), value));
        final url = normalizeShareText(map['url']?.toString());
        if (url == null) continue;
        foundPlayableData = true;
        directCandidates.add(
          ShareVideoCandidate(
            id: 'bilibili_durl_${normalizeShareVideoUrl(url).hashCode.abs()}',
            url: normalizeShareVideoUrl(url),
            title: _resolveTitle(windowStates, bridge),
            mimeType: 'video/mp4',
            source: ShareVideoSource.parser,
            referer: snapshot.finalUrl.toString(),
            cookieUrl: snapshot.finalUrl.toString(),
            isDirectDownloadable: true,
            priority: 120,
            parserTag: 'bilibili',
          ),
        );
        for (final backup in asDynamicList(map['backup_url'] ?? map['backupUrl'])) {
          final backupUrl = normalizeShareText(backup?.toString());
          if (backupUrl == null || !isDirectVideoUrl(backupUrl)) continue;
          directCandidates.add(
            ShareVideoCandidate(
              id: 'bilibili_backup_${normalizeShareVideoUrl(backupUrl).hashCode.abs()}',
              url: normalizeShareVideoUrl(backupUrl),
              title: _resolveTitle(windowStates, bridge),
              mimeType: 'video/mp4',
              source: ShareVideoSource.parser,
              referer: snapshot.finalUrl.toString(),
              cookieUrl: snapshot.finalUrl.toString(),
              isDirectDownloadable: true,
              priority: 110,
              parserTag: 'bilibili',
            ),
          );
        }
      }

      for (final map in deepMaps(root)) {
        final baseUrl = normalizeShareText(
          map['baseUrl']?.toString() ?? map['base_url']?.toString(),
        );
        if (baseUrl != null) {
          foundPlayableData = true;
          final normalizedUrl = normalizeShareVideoUrl(baseUrl);
          unsupportedCandidates.add(
            ShareVideoCandidate(
              id: 'bilibili_dash_${normalizedUrl.hashCode.abs()}',
              url: normalizedUrl,
              title: _resolveTitle(windowStates, bridge),
              source: ShareVideoSource.parser,
              referer: snapshot.finalUrl.toString(),
              cookieUrl: snapshot.finalUrl.toString(),
              isDirectDownloadable: false,
              priority: 30,
              parserTag: 'bilibili',
              reason: 'separate_dash_not_supported',
            ),
          );
        }
        for (final backup in asDynamicList(map['backupUrl'] ?? map['backup_url'])) {
          final backupUrl = normalizeShareText(backup?.toString());
          if (backupUrl == null) continue;
          final normalizedUrl = normalizeShareVideoUrl(backupUrl);
          unsupportedCandidates.add(
            ShareVideoCandidate(
              id: 'bilibili_dash_backup_${normalizedUrl.hashCode.abs()}',
              url: normalizedUrl,
              title: _resolveTitle(windowStates, bridge),
              source: ShareVideoSource.parser,
              referer: snapshot.finalUrl.toString(),
              cookieUrl: snapshot.finalUrl.toString(),
              isDirectDownloadable: false,
              priority: 20,
              parserTag: 'bilibili',
              reason: 'separate_dash_not_supported',
            ),
          );
        }
      }
    }

    final mergedDirect = mergeShareVideoCandidates(directCandidates);
    final mergedUnsupported = mergeShareVideoCandidates(unsupportedCandidates);
    final pageKind = foundPlayableData ||
            mergedDirect.isNotEmpty ||
            mergedUnsupported.isNotEmpty ||
            snapshot.finalUrl.path.contains('/video/')
        ? SharePageKind.video
        : SharePageKind.unknown;

    return SharePageParserResult(
      pageKind: pageKind,
      videoCandidates: mergedDirect,
      unsupportedVideoCandidates: mergedUnsupported,
      title: _resolveTitle(windowStates, bridge),
      excerpt: _resolveExcerpt(windowStates, bridge),
      parserTag: 'bilibili',
    );
  }

  String? _resolveTitle(Map<String, dynamic> windowStates, Map<String, dynamic> bridge) {
    return firstStringAtPaths(windowStates, const [
          ['__INITIAL_STATE__', 'videoData', 'title'],
          ['__INITIAL_STATE__', 'h1Title'],
          ['__INITIAL_STATE__', 'title'],
        ]) ??
        normalizeShareText(bridge['articleTitle']?.toString()) ??
        normalizeShareText(bridge['pageTitle']?.toString());
  }

  String? _resolveExcerpt(Map<String, dynamic> windowStates, Map<String, dynamic> bridge) {
    return firstStringAtPaths(windowStates, const [
          ['__INITIAL_STATE__', 'videoData', 'desc'],
          ['__INITIAL_STATE__', 'videoData', 'dynamic'],
          ['__INITIAL_STATE__', 'desc'],
        ]) ??
        normalizeShareText(bridge['excerpt']?.toString());
  }
}

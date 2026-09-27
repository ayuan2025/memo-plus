import '../share_clip_models.dart';
import 'share_page_parser.dart';
import 'xiaohongshu_note_content_cleaner.dart';

class XiaohongshuSharePageParser implements SharePageParser {
  @override
  bool canParse(SharePageSnapshot snapshot) {
    final host = snapshot.host.toLowerCase();
    return host == 'xhslink.com' ||
        host.endsWith('.xiaohongshu.com') ||
        host == 'xiaohongshu.com';
  }

  @override
  SharePageParserResult parse(SharePageSnapshot snapshot) {
    final bridge = snapshot.bridgeData;
    final windowStates =
        tryDecodeJsonMap(bridge['windowStates']) ?? const <String, dynamic>{};
    final roots = <Object?>[
      windowStates['__INITIAL_STATE__'],
      windowStates['__INITIAL_SSR_STATE__'],
      ...asDynamicList(bridge['bootstrapStates']),
    ];
    for (final record in snapshot.networkRecords) {
      final lowerUrl = record.url.toLowerCase();
      if (lowerUrl.contains('note') ||
          lowerUrl.contains('feed') ||
          lowerUrl.contains('detail')) {
        roots.add(tryDecodeJsonMap(record.responseBody) ?? record.responseBody);
      }
    }

    final cleaned = cleanXiaohongshuNoteContent(
      roots: roots,
      bridge: bridge,
      finalUrl: snapshot.finalUrl,
    );

    final directCandidates = <ShareVideoCandidate>[];
    final unsupportedCandidates = <ShareVideoCandidate>[];

    for (final root in cleaned.targetNoteRoots) {
      for (final value in deepValuesForKey(root, const {'masterUrl', 'url'})) {
        final url = normalizeShareText(value?.toString());
        final candidate = _candidateFromUrl(url, snapshot);
        if (candidate == null) continue;
        if (candidate.isDirectDownloadable) {
          directCandidates.add(candidate);
        } else {
          unsupportedCandidates.add(candidate);
        }
      }

      for (final value in deepValuesForKey(root, const {'backupUrls'})) {
        for (final backup in asDynamicList(value)) {
          final candidate = _candidateFromUrl(backup?.toString(), snapshot);
          if (candidate == null) continue;
          if (candidate.isDirectDownloadable) {
            directCandidates.add(candidate);
          } else {
            unsupportedCandidates.add(candidate);
          }
        }
      }

      for (final value in deepValuesForKey(root, const {'stream'})) {
        for (final map in deepMaps(value)) {
          final url = normalizeShareText(
            map['masterUrl']?.toString() ?? map['url']?.toString(),
          );
          final candidate = _candidateFromUrl(url, snapshot);
          if (candidate == null) continue;
          if (candidate.isDirectDownloadable) {
            directCandidates.add(candidate);
          } else {
            unsupportedCandidates.add(candidate);
          }
        }
      }
    }

    final mergedDirect = mergeShareVideoCandidates(directCandidates);
    final mergedUnsupported = mergeShareVideoCandidates(unsupportedCandidates);
    final pageKind =
        cleaned.isVideoNote ||
            mergedDirect.isNotEmpty ||
            mergedUnsupported.isNotEmpty
        ? SharePageKind.video
        : cleaned.hasArticleBody || cleaned.imageAttachmentUrls.isNotEmpty
        ? SharePageKind.article
        : SharePageKind.unknown;

    return SharePageParserResult(
      pageKind: pageKind,
      videoCandidates: mergedDirect,
      unsupportedVideoCandidates: mergedUnsupported,
      imageAttachmentUrls: pageKind == SharePageKind.video
          ? const <String>[]
          : cleaned.imageAttachmentUrls,
      title: cleaned.title,
      excerpt: cleaned.excerpt,
      contentHtml: cleaned.contentHtml,
      textContent: cleaned.textContent,
      parserTag: 'xiaohongshu',
    );
  }

  ShareVideoCandidate? _candidateFromUrl(
    String? url,
    SharePageSnapshot snapshot,
  ) {
    final normalizedUrl = normalizeShareText(url);
    if (normalizedUrl == null) return null;
    final isDirect = isDirectVideoUrl(normalizedUrl);
    final isUnsupported = isUnsupportedStreamUrl(normalizedUrl);
    if (!isDirect && !isUnsupported) return null;
    return ShareVideoCandidate(
      id: 'xiaohongshu_${normalizeShareVideoUrl(normalizedUrl).hashCode.abs()}',
      url: normalizeShareVideoUrl(normalizedUrl),
      title: fileNameFromUrl(normalizedUrl),
      source: ShareVideoSource.parser,
      referer: snapshot.finalUrl.toString(),
      cookieUrl: snapshot.finalUrl.toString(),
      isDirectDownloadable: isDirect,
      priority: isDirect ? 120 : 20,
      parserTag: 'xiaohongshu',
      reason: isUnsupported ? 'stream_only_not_supported' : null,
    );
  }
}

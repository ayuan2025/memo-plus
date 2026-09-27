import '../share_clip_models.dart';
import 'share_page_parser.dart';

class GenericSharePageParser implements SharePageParser {
  @override
  bool canParse(SharePageSnapshot snapshot) => true;

  @override
  SharePageParserResult parse(SharePageSnapshot snapshot) {
    final bridge = snapshot.bridgeData;
    final finalUrl = snapshot.finalUrl.toString();
    final directCandidates = <ShareVideoCandidate>[];
    final unsupportedCandidates = <ShareVideoCandidate>[];

    for (final hint in asDynamicList(bridge['rawVideoHints'])) {
      final candidate = _candidateFromHint(
        hint,
        parserTag: 'generic',
        fallbackReferer: finalUrl,
      );
      if (candidate == null) continue;
      if (candidate.isDirectDownloadable) {
        directCandidates.add(candidate);
      } else {
        unsupportedCandidates.add(candidate);
      }
    }

    for (final jsonLd in asDynamicList(bridge['structuredData'])) {
      for (final map in deepMaps(jsonLd)) {
        final typeValue = (map['@type'] ?? map['type'])?.toString().toLowerCase();
        if (typeValue != null && typeValue.contains('videoobject')) {
          for (final key in const ['contentUrl', 'embedUrl', 'url']) {
            final rawUrl = normalizeShareText(map[key]?.toString());
            final candidate = _candidateFromUrl(
              rawUrl,
              parserTag: 'generic',
              title: normalizeShareText(map['name']?.toString()),
              source: ShareVideoSource.jsonLd,
              referer: finalUrl,
            );
            if (candidate == null) continue;
            if (candidate.isDirectDownloadable) {
              directCandidates.add(candidate);
            } else {
              unsupportedCandidates.add(candidate);
            }
          }
        }
      }
    }

    for (final record in snapshot.networkRecords) {
      final source = switch (record.kind) {
        ShareNetworkRecordKind.request => ShareVideoSource.request,
        ShareNetworkRecordKind.ajax => ShareVideoSource.ajax,
        ShareNetworkRecordKind.fetch => ShareVideoSource.fetch,
        ShareNetworkRecordKind.resource => ShareVideoSource.resource,
      };
      final candidate = _candidateFromUrl(
        record.url,
        parserTag: 'generic',
        mimeType: record.mimeType,
        source: source,
        referer: record.referer ?? finalUrl,
        headers: record.headers,
      );
      if (candidate == null) continue;
      if (candidate.isDirectDownloadable) {
        directCandidates.add(candidate);
      } else {
        unsupportedCandidates.add(candidate);
      }
    }

    final mergedDirect = mergeShareVideoCandidates(directCandidates);
    final mergedUnsupported = mergeShareVideoCandidates(unsupportedCandidates);

    final contentHtml = normalizeShareText(bridge['contentHtml']?.toString());
    final textContent = normalizeShareText(bridge['textContent']?.toString());
    final pageKind = mergedDirect.isNotEmpty || mergedUnsupported.isNotEmpty
        ? SharePageKind.video
        : ((contentHtml ?? '').isNotEmpty || (textContent ?? '').length >= 80)
        ? SharePageKind.article
        : SharePageKind.unknown;

    return SharePageParserResult(
      pageKind: pageKind,
      videoCandidates: mergedDirect,
      unsupportedVideoCandidates: mergedUnsupported,
      title:
          normalizeShareText(bridge['articleTitle']?.toString()) ??
          normalizeShareText(bridge['pageTitle']?.toString()),
      excerpt: normalizeShareText(bridge['excerpt']?.toString()),
      contentHtml: contentHtml,
      textContent: textContent,
      siteName: normalizeShareText(bridge['siteName']?.toString()),
      byline: normalizeShareText(bridge['byline']?.toString()),
      leadImageUrl: normalizeShareText(bridge['leadImageUrl']?.toString()),
      parserTag: 'generic',
    );
  }

  ShareVideoCandidate? _candidateFromHint(
    Object? raw, {
    required String parserTag,
    required String fallbackReferer,
  }) {
    if (raw is! Map) return null;
    final map = raw.map((key, value) => MapEntry(key.toString(), value));
    final url = normalizeShareText(map['url']?.toString());
    final source = shareVideoSourceFromLabel(map['source']?.toString());
    return _candidateFromUrl(
      url,
      parserTag: parserTag,
      title: normalizeShareText(map['title']?.toString()),
      mimeType: normalizeShareText(map['mimeType']?.toString()),
      source: source,
      referer:
          normalizeShareText(map['referer']?.toString()) ?? fallbackReferer,
      reason: normalizeShareText(map['reason']?.toString()),
    );
  }

  ShareVideoCandidate? _candidateFromUrl(
    String? url, {
    required String parserTag,
    required ShareVideoSource source,
    String? title,
    String? mimeType,
    String? referer,
    Map<String, String>? headers,
    String? reason,
  }) {
    if (url == null) return null;
    final normalizedUrl = normalizeShareVideoUrl(url);
    if (normalizedUrl.isEmpty) return null;
    final isDirect = isDirectVideoUrl(normalizedUrl, mimeType: mimeType);
    final isUnsupported = isUnsupportedStreamUrl(normalizedUrl);
    if (!isDirect && !isUnsupported) return null;
    return ShareVideoCandidate(
      id: '${parserTag}_${source.name}_${normalizedUrl.hashCode.abs()}',
      url: normalizedUrl,
      title: title ?? fileNameFromUrl(normalizedUrl),
      mimeType: mimeType,
      source: source,
      referer: referer,
      headers: headers,
      cookieUrl: referer,
      isDirectDownloadable: isDirect,
      priority: isDirect ? 80 : 10,
      parserTag: parserTag,
      reason: reason,
    );
  }
}

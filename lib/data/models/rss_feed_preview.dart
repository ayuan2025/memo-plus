class RssFeedPreview {
  const RssFeedPreview({
    required this.requestedUrl,
    required this.feedUrl,
    required this.siteUrl,
    required this.title,
    required this.description,
    required this.iconUrl,
    required this.articles,
    this.etag = '',
    this.lastModified = '',
    this.discoveredFromHtml = false,
  });

  final String requestedUrl;
  final String feedUrl;
  final String siteUrl;
  final String title;
  final String description;
  final String iconUrl;
  final List<RssArticlePreview> articles;
  final String etag;
  final String lastModified;
  final bool discoveredFromHtml;

  String get displayTitle {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isNotEmpty) return trimmedTitle;
    final host = Uri.tryParse(siteUrl.trim())?.host;
    if (host != null && host.isNotEmpty) return host;
    final feedHost = Uri.tryParse(feedUrl.trim())?.host;
    return feedHost?.isNotEmpty == true ? feedHost! : feedUrl.trim();
  }

  RssFeedPreview copyWith({
    String? requestedUrl,
    String? feedUrl,
    String? siteUrl,
    String? title,
    String? description,
    String? iconUrl,
    List<RssArticlePreview>? articles,
    String? etag,
    String? lastModified,
    bool? discoveredFromHtml,
  }) {
    return RssFeedPreview(
      requestedUrl: requestedUrl ?? this.requestedUrl,
      feedUrl: feedUrl ?? this.feedUrl,
      siteUrl: siteUrl ?? this.siteUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      articles: articles ?? this.articles,
      etag: etag ?? this.etag,
      lastModified: lastModified ?? this.lastModified,
      discoveredFromHtml: discoveredFromHtml ?? this.discoveredFromHtml,
    );
  }
}

class RssArticlePreview {
  const RssArticlePreview({
    required this.guid,
    required this.link,
    required this.title,
    required this.author,
    required this.summaryHtml,
    required this.contentHtml,
    required this.leadImageUrl,
    required this.publishedTime,
  });

  final String guid;
  final String link;
  final String title;
  final String author;
  final String summaryHtml;
  final String contentHtml;
  final String leadImageUrl;
  final DateTime? publishedTime;

  String get stableIdentity {
    final normalizedGuid = guid.trim();
    if (normalizedGuid.isNotEmpty) return normalizedGuid;
    final normalizedLink = link.trim();
    if (normalizedLink.isNotEmpty) return normalizedLink;
    return title.trim();
  }

  String get readableHtml {
    final content = contentHtml.trim();
    return content.isNotEmpty ? content : summaryHtml.trim();
  }
}

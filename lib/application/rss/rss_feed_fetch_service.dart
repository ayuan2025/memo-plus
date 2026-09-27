import '../../data/models/rss_feed.dart';
import '../../data/models/rss_feed_preview.dart';
import '../../data/repositories/rss_repository.dart';
import 'rss_full_content_service.dart';
import 'rss_feed_discovery.dart';
import 'rss_feed_parser.dart';
import 'rss_http.dart';

export 'rss_http.dart' show RssHttpFetcher, RssHttpResponse;

enum RssFeedDiscoveryFailure { emptyInput, invalidUrl, noFeedDiscovered }

class RssFeedDiscoveryException implements Exception {
  const RssFeedDiscoveryException(this.message, {required this.failure});

  final String message;
  final RssFeedDiscoveryFailure failure;

  @override
  String toString() => message;
}

class RssCollectionRefreshSummary {
  const RssCollectionRefreshSummary({
    required this.successCount,
    required this.failureCount,
  });

  final int successCount;
  final int failureCount;
}

class RssFeedFetchService {
  RssFeedFetchService({
    required RssRepository repository,
    RssFeedParser parser = const RssFeedParser(),
    RssFeedDiscovery discovery = const RssFeedDiscovery(),
    RssHttpFetcher? fetcher,
    RssFullContentService? fullContentService,
  }) : _repository = repository,
       _parser = parser,
       _discovery = discovery,
       _fetcher = fetcher ?? defaultRssHttpFetch,
       _fullContentService = fullContentService;

  final RssRepository _repository;
  final RssFeedParser _parser;
  final RssFeedDiscovery _discovery;
  final RssHttpFetcher _fetcher;
  final RssFullContentService? _fullContentService;

  Future<RssFeedPreview> previewUrl(String inputUrl) async {
    final requestUri = _normalizeInputUrl(inputUrl);
    final directResponse = await _fetcher(requestUri);
    final directPreview = _tryParsePreview(
      directResponse,
      requestedUri: requestUri,
      feedUri: requestUri,
    );
    if (directPreview != null) {
      return directPreview;
    }

    final discovered = _discovery.discoverAlternateFeeds(
      directResponse.body,
      pageUri: requestUri,
    );
    for (final feedUri in discovered) {
      final response = await _fetcher(feedUri);
      final preview = _tryParsePreview(
        response,
        requestedUri: requestUri,
        feedUri: feedUri,
      );
      if (preview != null) {
        return preview.copyWith(discoveredFromHtml: true);
      }
    }
    throw const RssFeedDiscoveryException(
      'No supported RSS or Atom feed could be discovered.',
      failure: RssFeedDiscoveryFailure.noFeedDiscovered,
    );
  }

  Future<RssFeedPreview> refreshFeed(RssFeed feed) async {
    final feedUri = _normalizeInputUrl(feed.feedUrl);
    final headers = <String, String>{
      if (feed.etag.trim().isNotEmpty) 'If-None-Match': feed.etag.trim(),
      if (feed.lastModified.trim().isNotEmpty)
        'If-Modified-Since': feed.lastModified.trim(),
    };
    try {
      final response = await _fetcher(feedUri, headers: headers);
      if (response.statusCode == 304) {
        final preview = RssFeedPreview(
          requestedUrl: feed.feedUrl,
          feedUrl: feed.feedUrl,
          siteUrl: feed.siteUrl,
          title: feed.title,
          description: feed.description,
          iconUrl: feed.iconUrl,
          articles: const <RssArticlePreview>[],
          etag: feed.etag,
          lastModified: feed.lastModified,
        );
        await _repository.recordFeedSuccess(
          preview: preview,
          fetchedAt: DateTime.now(),
        );
        await _maybeRefreshFullContent(feed);
        return preview;
      }
      final preview = _parser
          .parse(response.body, sourceUri: feedUri)
          .copyWith(
            requestedUrl: feed.feedUrl,
            feedUrl: feed.feedUrl,
            etag: response.header('etag'),
            lastModified: response.header('last-modified'),
          );
      await _repository.upsertFeedFromPreview(preview);
      await _maybeRefreshFullContent(feed);
      return preview;
    } catch (error) {
      await _repository.recordFeedFailure(
        feedId: feed.id,
        error: error.toString(),
      );
      rethrow;
    }
  }

  Future<RssCollectionRefreshSummary> refreshCollection(
    String collectionId,
  ) async {
    final sources = await _repository.listCollectionRssSources(collectionId);
    var success = 0;
    var failure = 0;
    for (final source in sources) {
      try {
        await refreshFeed(source.feed);
        success += 1;
      } catch (_) {
        failure += 1;
      }
    }
    return RssCollectionRefreshSummary(
      successCount: success,
      failureCount: failure,
    );
  }

  Future<void> _maybeRefreshFullContent(RssFeed feed) async {
    if (_fullContentService == null || !feed.fullContentEnabled) return;
    try {
      await _fullContentService.fetchEligibleArticlesForFeed(feed.id);
    } catch (_) {
      // Full-content fetching is best-effort and must not fail feed refresh.
    }
  }

  RssFeedPreview? _tryParsePreview(
    RssHttpResponse response, {
    required Uri requestedUri,
    required Uri feedUri,
  }) {
    if (response.statusCode < 200 || response.statusCode >= 400) {
      return null;
    }
    try {
      return _parser
          .parse(response.body, sourceUri: feedUri)
          .copyWith(
            requestedUrl: requestedUri.toString(),
            feedUrl: feedUri.toString(),
            etag: response.header('etag'),
            lastModified: response.header('last-modified'),
          );
    } catch (_) {
      return null;
    }
  }

  Uri _normalizeInputUrl(String inputUrl) {
    final trimmed = inputUrl.trim();
    if (trimmed.isEmpty) {
      throw const RssFeedDiscoveryException(
        'Enter a feed or site URL.',
        failure: RssFeedDiscoveryFailure.emptyInput,
      );
    }
    final withScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(trimmed)
        ? trimmed
        : 'https://$trimmed';
    final parsed = Uri.tryParse(withScheme);
    if (parsed == null || parsed.host.trim().isEmpty) {
      throw RssFeedDiscoveryException(
        'Invalid URL: $inputUrl',
        failure: RssFeedDiscoveryFailure.invalidUrl,
      );
    }
    return parsed;
  }
}

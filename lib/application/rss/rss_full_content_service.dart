import 'package:html/parser.dart' as html_parser;

import '../../data/models/rss_article.dart';
import '../../data/repositories/rss_repository.dart';
import 'rss_full_content_extractor.dart';
import 'rss_html_sanitizer.dart';
import 'rss_http.dart';

enum RssFullContentFailure {
  articleMissing,
  missingLink,
  invalidUrl,
  unsupportedScheme,
  httpFailure,
  unsupportedContentType,
  oversizedResponse,
  extractionFailed,
  sanitizationFailed,
}

class RssFullContentFetchResult {
  const RssFullContentFetchResult({
    required this.articleId,
    required this.status,
    this.failure,
    this.error = '',
  });

  final String articleId;
  final RssArticleFullContentStatus status;
  final RssFullContentFailure? failure;
  final String error;

  bool get succeeded => status == RssArticleFullContentStatus.fetched;
}

class RssFullContentService {
  RssFullContentService({
    required RssRepository repository,
    RssHttpFetcher? fetcher,
    RssFullContentExtractor extractor = const RssFullContentExtractor(),
    RssHtmlSanitizer sanitizer = const RssHtmlSanitizer(),
    Duration timeout = const Duration(seconds: 15),
    this.maxResponseCharacters = 1500000,
  }) : _repository = repository,
       _fetcher =
           fetcher ??
           ((uri, {headers}) =>
               defaultRssHttpFetch(uri, headers: headers, timeout: timeout)),
       _extractor = extractor,
       _sanitizer = sanitizer;

  final RssRepository _repository;
  final RssHttpFetcher _fetcher;
  final RssFullContentExtractor _extractor;
  final RssHtmlSanitizer _sanitizer;
  final int maxResponseCharacters;

  Future<RssFullContentFetchResult> fetchArticle(String articleId) async {
    final normalizedArticleId = articleId.trim();
    if (normalizedArticleId.isEmpty) {
      return const RssFullContentFetchResult(
        articleId: '',
        status: RssArticleFullContentStatus.failed,
        failure: RssFullContentFailure.articleMissing,
        error: 'RSS article id is empty.',
      );
    }
    final article = await _repository.readArticleById(normalizedArticleId);
    if (article == null) {
      return RssFullContentFetchResult(
        articleId: normalizedArticleId,
        status: RssArticleFullContentStatus.failed,
        failure: RssFullContentFailure.articleMissing,
        error: 'RSS article was not found.',
      );
    }

    await _repository.markArticleFullContentFetching(articleId: article.id);
    try {
      final result = await _fetchAndExtract(article);
      await _repository.recordArticleFullContentFetched(
        articleId: article.id,
        fullContentHtml: result,
      );
      return RssFullContentFetchResult(
        articleId: article.id,
        status: RssArticleFullContentStatus.fetched,
      );
    } on _RssFullContentException catch (error) {
      await _repository.recordArticleFullContentFailure(
        articleId: article.id,
        error: error.message,
        skipped: error.skipped,
      );
      return RssFullContentFetchResult(
        articleId: article.id,
        status: error.skipped
            ? RssArticleFullContentStatus.skipped
            : RssArticleFullContentStatus.failed,
        failure: error.failure,
        error: error.message,
      );
    } catch (error) {
      final message = error.toString();
      await _repository.recordArticleFullContentFailure(
        articleId: article.id,
        error: message,
      );
      return RssFullContentFetchResult(
        articleId: article.id,
        status: RssArticleFullContentStatus.failed,
        failure: RssFullContentFailure.httpFailure,
        error: message,
      );
    }
  }

  Future<List<RssFullContentFetchResult>> fetchEligibleArticlesForFeed(
    String feedId, {
    int maxArticles = 10,
    int concurrency = 2,
  }) async {
    final articles = await _repository.listFullContentEligibleArticlesForFeed(
      feedId,
      limit: maxArticles,
    );
    if (articles.isEmpty) return const <RssFullContentFetchResult>[];
    final safeConcurrency = concurrency.clamp(1, 4).toInt();
    var nextIndex = 0;
    final results = List<RssFullContentFetchResult?>.filled(
      articles.length,
      null,
    );

    Future<void> worker() async {
      while (true) {
        final index = nextIndex;
        if (index >= articles.length) return;
        nextIndex += 1;
        results[index] = await fetchArticle(articles[index].id);
      }
    }

    await Future.wait(
      List<Future<void>>.generate(
        safeConcurrency > articles.length ? articles.length : safeConcurrency,
        (_) => worker(),
      ),
    );
    return results.whereType<RssFullContentFetchResult>().toList(
      growable: false,
    );
  }

  Future<String> _fetchAndExtract(RssArticle article) async {
    final uri = _articleUri(article);
    final response = await _fetcher(
      uri,
      headers: const <String, String>{
        'Accept': 'text/html,application/xhtml+xml;q=0.9,*/*;q=0.1',
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 400) {
      throw _RssFullContentException(
        RssFullContentFailure.httpFailure,
        'Full content request failed with HTTP ${response.statusCode}.',
      );
    }
    _validateContentType(response);
    _validateResponseSize(response);

    final extracted = _extractor.extract(response.body);
    if (extracted == null) {
      throw const _RssFullContentException(
        RssFullContentFailure.extractionFailed,
        'Could not extract readable content.',
      );
    }
    final sanitized = _sanitizer.sanitize(extracted.contentHtml, baseUri: uri);
    if (_readableTextLength(sanitized) < _extractor.minimumTextLength) {
      throw const _RssFullContentException(
        RssFullContentFailure.sanitizationFailed,
        'Sanitized content was empty.',
      );
    }
    return sanitized;
  }

  Uri _articleUri(RssArticle article) {
    final link = article.link.trim();
    if (link.isEmpty) {
      throw const _RssFullContentException(
        RssFullContentFailure.missingLink,
        'RSS article has no original link.',
        skipped: true,
      );
    }
    final uri = Uri.tryParse(link);
    if (uri == null || uri.host.trim().isEmpty) {
      throw _RssFullContentException(
        RssFullContentFailure.invalidUrl,
        'Invalid RSS article link: $link',
        skipped: true,
      );
    }
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      throw _RssFullContentException(
        RssFullContentFailure.unsupportedScheme,
        'Unsupported RSS article link scheme: $scheme',
        skipped: true,
      );
    }
    return uri;
  }

  void _validateContentType(RssHttpResponse response) {
    final contentType = response.header('content-type').trim().toLowerCase();
    if (contentType.isEmpty) return;
    final mediaType = contentType.split(';').first.trim();
    if (mediaType == 'text/html' || mediaType == 'application/xhtml+xml') {
      return;
    }
    throw _RssFullContentException(
      RssFullContentFailure.unsupportedContentType,
      'Unsupported full content type: $mediaType',
      skipped: true,
    );
  }

  void _validateResponseSize(RssHttpResponse response) {
    final lengthHeader = response.header('content-length').trim();
    final contentLength = int.tryParse(lengthHeader);
    if (contentLength != null && contentLength > maxResponseCharacters) {
      throw _RssFullContentException(
        RssFullContentFailure.oversizedResponse,
        'Full content response is larger than the configured limit.',
        skipped: true,
      );
    }
    if (response.body.length > maxResponseCharacters) {
      throw _RssFullContentException(
        RssFullContentFailure.oversizedResponse,
        'Full content response is larger than the configured limit.',
        skipped: true,
      );
    }
  }
}

int _readableTextLength(String html) {
  return html_parser
          .parseFragment(html)
          .text
          ?.replaceAll(RegExp(r'\s+'), ' ')
          .trim()
          .length ??
      0;
}

class _RssFullContentException implements Exception {
  const _RssFullContentException(
    this.failure,
    this.message, {
    this.skipped = false,
  });

  final RssFullContentFailure failure;
  final String message;
  final bool skipped;

  @override
  String toString() => message;
}

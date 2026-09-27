import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/application/rss/rss_feed_fetch_service.dart';
import 'package:memos_flutter_app/application/rss/rss_feed_parser.dart';
import 'package:memos_flutter_app/application/rss/rss_full_content_service.dart';
import 'package:memos_flutter_app/data/db/app_database.dart';
import 'package:memos_flutter_app/data/models/memo_collection.dart';
import 'package:memos_flutter_app/data/models/rss_article.dart';
import 'package:memos_flutter_app/data/models/rss_feed.dart';
import 'package:memos_flutter_app/data/models/rss_feed_preview.dart';
import 'package:memos_flutter_app/data/repositories/collections_repository.dart';
import 'package:memos_flutter_app/data/repositories/rss_repository.dart';

import '../../test_support.dart';

void main() {
  late TestSupport support;

  setUpAll(() async {
    support = await initializeTestSupport();
  });

  tearDownAll(() async {
    await support.dispose();
  });

  test(
    'fetchArticle stores sanitized full content without creating memos',
    () async {
      final harness = await _RssHarness.create('rss_full_content_success');
      addTearDown(harness.dispose);
      final article = await harness.subscribeOneArticle(
        link: 'https://example.com/articles/one',
        contentHtml: '<p>Feed excerpt only</p>',
      );
      final service = RssFullContentService(
        repository: harness.rss,
        fetcher: (uri, {headers}) async => const RssHttpResponse(
          statusCode: 200,
          headers: <String, String>{'content-type': 'text/html; charset=utf-8'},
          body: '''
<html><head><title>Ignored title</title><script>alert(1)</script></head>
<body>
  <nav>navigation noise</nav>
  <article>
    <h1>Readable article</h1>
    <p>Readable full article body with enough words to pass extraction.</p>
    <p><a href="/more">More context</a><img src="/lead.png" onerror="bad()"></p>
    <script>alert(2)</script>
  </article>
</body></html>
''',
        ),
      );

      final result = await service.fetchArticle(article.id);
      final stored = await harness.rss.readArticleById(article.id);
      final sqlite = await harness.db.db;
      final memos = await sqlite.query('memos');

      expect(result.succeeded, isTrue);
      expect(stored?.fullContentStatus, RssArticleFullContentStatus.fetched);
      expect(stored?.fullContentHtml, contains('Readable full article body'));
      expect(stored?.fullContentHtml, contains('https://example.com/more'));
      expect(stored?.fullContentHtml, isNot(contains('script')));
      expect(stored?.fullContentHtml, isNot(contains('onerror')));
      expect(stored?.readableHtml, contains('Readable full article body'));
      expect(stored?.readableHtml, isNot(contains('Feed excerpt only')));
      expect(memos, isEmpty);
    },
  );

  test(
    'unsupported pages are skipped and feed content remains readable',
    () async {
      final harness = await _RssHarness.create('rss_full_content_skipped');
      addTearDown(harness.dispose);
      final article = await harness.subscribeOneArticle(
        link: 'https://example.com/file.pdf',
        contentHtml: '<p>Feed body remains available</p>',
      );
      final service = RssFullContentService(
        repository: harness.rss,
        fetcher: (uri, {headers}) async => const RssHttpResponse(
          statusCode: 200,
          headers: <String, String>{'content-type': 'application/pdf'},
          body: '%PDF',
        ),
      );

      final result = await service.fetchArticle(article.id);
      final stored = await harness.rss.readArticleById(article.id);

      expect(result.status, RssArticleFullContentStatus.skipped);
      expect(result.failure, RssFullContentFailure.unsupportedContentType);
      expect(stored?.fullContentStatus, RssArticleFullContentStatus.skipped);
      expect(stored?.readableHtml, '<p>Feed body remains available</p>');
    },
  );

  test('fetchEligibleArticlesForFeed keeps article failures local', () async {
    final harness = await _RssHarness.create('rss_full_content_partial');
    addTearDown(harness.dispose);
    final feed = await harness.subscribePreview(
      RssFeedPreview(
        requestedUrl: 'https://example.com/feed.xml',
        feedUrl: 'https://example.com/feed.xml',
        siteUrl: 'https://example.com/',
        title: 'Example Feed',
        description: '',
        iconUrl: '',
        articles: <RssArticlePreview>[
          _articlePreview(
            guid: 'ok',
            link: 'https://example.com/ok',
            title: 'OK',
          ),
          _articlePreview(
            guid: 'bad',
            link: 'https://example.com/bad',
            title: 'Bad',
          ),
        ],
      ),
    );
    final service = RssFullContentService(
      repository: harness.rss,
      fetcher: (uri, {headers}) async {
        if (uri.path == '/bad') {
          return const RssHttpResponse(
            statusCode: 200,
            headers: <String, String>{'content-type': 'application/json'},
            body: '{}',
          );
        }
        return const RssHttpResponse(
          statusCode: 200,
          headers: <String, String>{'content-type': 'text/html'},
          body:
              '<article><p>Readable body for successful article with enough useful text.</p></article>',
        );
      },
    );

    final results = await service.fetchEligibleArticlesForFeed(
      feed.id,
      concurrency: 2,
    );
    final articles = await harness.rss.listFeedArticles(feed.id);

    expect(results, hasLength(2));
    expect(results.where((result) => result.succeeded), hasLength(1));
    expect(results.where((result) => !result.succeeded), hasLength(1));
    expect(
      articles.map((item) => item.fullContentStatus).toSet(),
      containsAll(<RssArticleFullContentStatus>{
        RssArticleFullContentStatus.fetched,
        RssArticleFullContentStatus.skipped,
      }),
    );
  });

  test(
    'manual feed refresh fetches full content when feed opt-in is enabled',
    () async {
      final harness = await _RssHarness.create('rss_full_content_feed_refresh');
      addTearDown(harness.dispose);
      final feed = await harness.subscribePreview(
        const RssFeedParser().parse(
          _rssFeed(articleTitle: 'Initial title'),
          sourceUri: Uri.parse('https://example.com/feed.xml'),
        ),
      );
      await harness.rss.setFeedFullContentEnabled(
        feedId: feed.id,
        enabled: true,
      );
      final enabledFeed = await harness.rss.readFeedById(feed.id);
      final fullContentService = RssFullContentService(
        repository: harness.rss,
        fetcher: (uri, {headers}) async => const RssHttpResponse(
          statusCode: 200,
          headers: <String, String>{'content-type': 'text/html'},
          body:
              '<article><p>Fetched full body during refresh with enough readable words.</p></article>',
        ),
      );
      final feedService = RssFeedFetchService(
        repository: harness.rss,
        fullContentService: fullContentService,
        fetcher: (uri, {headers}) async => RssHttpResponse(
          statusCode: 200,
          body: _rssFeed(articleTitle: 'Refreshed title'),
        ),
      );

      await feedService.refreshFeed(enabledFeed!);
      final articles = await harness.rss.listFeedArticles(feed.id);

      expect(articles.single.title, 'Refreshed title');
      expect(
        articles.single.fullContentHtml,
        contains('Fetched full body during refresh'),
      );
    },
  );
}

class _RssHarness {
  const _RssHarness({
    required this.db,
    required this.collections,
    required this.rss,
  });

  final AppDatabase db;
  final CollectionsRepository collections;
  final RssRepository rss;

  static Future<_RssHarness> create(String name) async {
    final dbName = uniqueDbName(name);
    final db = AppDatabase(dbName: dbName);
    final collections = CollectionsRepository(db: db);
    await collections.upsert(
      MemoCollection.createRss(id: 'collection-rss', title: 'RSS'),
    );
    return _RssHarness(
      db: db,
      collections: collections,
      rss: RssRepository(db: db),
    );
  }

  Future<RssFeed> subscribePreview(RssFeedPreview preview) {
    return rss.subscribeCollectionToPreview(
      collectionId: 'collection-rss',
      preview: preview,
    );
  }

  Future<RssArticle> subscribeOneArticle({
    required String link,
    required String contentHtml,
  }) async {
    final feed = await subscribePreview(
      RssFeedPreview(
        requestedUrl: 'https://example.com/feed.xml',
        feedUrl: 'https://example.com/feed.xml',
        siteUrl: 'https://example.com/',
        title: 'Example Feed',
        description: '',
        iconUrl: '',
        articles: <RssArticlePreview>[
          _articlePreview(
            guid: 'article-1',
            link: link,
            title: 'Article',
            contentHtml: contentHtml,
          ),
        ],
      ),
    );
    return (await rss.listFeedArticles(feed.id)).single;
  }

  Future<void> dispose() async {
    final dbName = db.dbName;
    await db.close();
    await deleteTestDatabase(dbName);
  }
}

RssArticlePreview _articlePreview({
  required String guid,
  required String link,
  required String title,
  String contentHtml = '<p>Feed body</p>',
}) {
  return RssArticlePreview(
    guid: guid,
    link: link,
    title: title,
    author: '',
    summaryHtml: '<p>Summary</p>',
    contentHtml: contentHtml,
    leadImageUrl: '',
    publishedTime: DateTime(2026, 5, 10),
  );
}

String _rssFeed({required String articleTitle}) {
  return '''
<rss version="2.0" xmlns:content="http://purl.org/rss/1.0/modules/content/">
  <channel>
    <title>Example Feed</title>
    <link>https://example.com/</link>
    <item>
      <guid>article-1</guid>
      <title>$articleTitle</title>
      <link>https://example.com/article-1</link>
      <description>Short summary</description>
      <content:encoded><p>Short feed body</p></content:encoded>
    </item>
  </channel>
</rss>
''';
}

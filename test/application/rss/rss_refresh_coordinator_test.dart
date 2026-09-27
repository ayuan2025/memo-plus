import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/application/rss/rss_feed_fetch_service.dart';
import 'package:memos_flutter_app/application/rss/rss_refresh_coordinator.dart';
import 'package:memos_flutter_app/data/db/app_database.dart';
import 'package:memos_flutter_app/data/models/memo_collection.dart';
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

  test('stale selection uses latest fetch or success timestamp', () {
    final now = DateTime(2026, 5, 15, 12);
    const interval = Duration(minutes: 30);

    expect(
      isRssFeedStaleForRefresh(
        _feed(lastFetchTime: null, lastSuccessTime: null),
        now: now,
        interval: interval,
      ),
      isTrue,
    );
    expect(
      isRssFeedStaleForRefresh(
        _feed(
          lastFetchTime: now.subtract(const Duration(minutes: 29)),
          lastSuccessTime: now.subtract(const Duration(hours: 2)),
        ),
        now: now,
        interval: interval,
      ),
      isFalse,
    );
    expect(
      isRssFeedStaleForRefresh(
        _feed(
          lastFetchTime: now.subtract(const Duration(hours: 2)),
          lastSuccessTime: now.subtract(const Duration(minutes: 31)),
        ),
        now: now,
        interval: interval,
      ),
      isTrue,
    );
    expect(
      isRssFeedStaleForRefresh(
        _feed(
          lastFetchTime: now.add(const Duration(minutes: 5)),
          lastSuccessTime: now.subtract(const Duration(days: 1)),
        ),
        now: now,
        interval: interval,
      ),
      isFalse,
    );
  });

  test(
    'collection-open refresh only refreshes stale collection feeds',
    () async {
      final context = await _buildContext('rss_open_refresh_stale');
      addTearDown(context.dispose);

      final now = DateTime(2026, 5, 15, 12);
      final stalePreview = _preview('stale');
      final freshPreview = _preview('fresh');
      await context.seedFeed(
        stalePreview,
        fetchedAt: now.subtract(const Duration(hours: 2)),
      );
      await context.seedFeed(
        freshPreview,
        fetchedAt: now.subtract(const Duration(minutes: 5)),
      );

      final fetched = <String>[];
      final coordinator = RssRefreshCoordinator(
        repository: context.rssRepository,
        fetchService: context.fetchService((uri, {headers}) async {
          fetched.add(uri.toString());
          return RssHttpResponse(
            statusCode: 200,
            body: _rssXml(
              title: 'Updated ${uri.pathSegments.first}',
              articleGuid: 'updated-${uri.pathSegments.first}',
            ),
          );
        }),
        now: () => now,
      );

      final result = await coordinator.refreshCollectionOnOpen(
        collectionId: _collectionId,
        preferences: const CollectionRssRefreshPreferences(
          enabled: true,
          intervalMinutes: 30,
        ),
      );

      expect(result.consideredFeedCount, 2);
      expect(result.staleFeedCount, 1);
      expect(result.successCount, 1);
      expect(result.failureCount, 0);
      expect(fetched, <String>[stalePreview.feedUrl]);
    },
  );

  test('collection-open refresh is single-flight per collection', () async {
    final context = await _buildContext('rss_open_refresh_single_flight');
    addTearDown(context.dispose);

    final now = DateTime(2026, 5, 15, 12);
    final preview = _preview('single');
    await context.seedFeed(
      preview,
      fetchedAt: now.subtract(const Duration(hours: 2)),
    );

    final fetchStarted = Completer<void>();
    final releaseFetch = Completer<void>();
    var fetchCount = 0;
    final coordinator = RssRefreshCoordinator(
      repository: context.rssRepository,
      fetchService: context.fetchService((uri, {headers}) async {
        fetchCount += 1;
        if (!fetchStarted.isCompleted) fetchStarted.complete();
        await releaseFetch.future;
        return RssHttpResponse(
          statusCode: 200,
          body: _rssXml(title: 'Single', articleGuid: 'single-updated'),
        );
      }),
      now: () => now,
    );

    final first = coordinator.refreshCollectionOnOpen(
      collectionId: _collectionId,
      preferences: CollectionRssRefreshPreferences.defaults,
    );
    await fetchStarted.future;
    final second = coordinator.refreshCollectionOnOpen(
      collectionId: _collectionId,
      preferences: CollectionRssRefreshPreferences.defaults,
    );
    await Future<void>.delayed(Duration.zero);
    expect(fetchCount, 1);

    releaseFetch.complete();
    final firstResult = await first;
    final secondResult = await second;

    expect(firstResult.coalesced, isFalse);
    expect(secondResult.coalesced, isTrue);
    expect(fetchCount, 1);
  });

  test('collection-open refresh keeps going after per-feed failure', () async {
    final context = await _buildContext('rss_open_refresh_partial_failure');
    addTearDown(context.dispose);

    final now = DateTime(2026, 5, 15, 12);
    final okPreview = _preview('ok');
    final failPreview = _preview('fail');
    await context.seedFeed(
      okPreview,
      fetchedAt: now.subtract(const Duration(hours: 2)),
    );
    await context.seedFeed(
      failPreview,
      fetchedAt: now.subtract(const Duration(hours: 2)),
    );

    final coordinator = RssRefreshCoordinator(
      repository: context.rssRepository,
      fetchService: context.fetchService((uri, {headers}) async {
        if (uri.toString() == failPreview.feedUrl) {
          throw StateError('network down');
        }
        return RssHttpResponse(
          statusCode: 200,
          body: _rssXml(title: 'OK', articleGuid: 'ok-updated'),
        );
      }),
      now: () => now,
      maxConcurrentFeeds: 1,
    );

    final result = await coordinator.refreshCollectionOnOpen(
      collectionId: _collectionId,
      preferences: CollectionRssRefreshPreferences.defaults,
    );

    expect(result.staleFeedCount, 2);
    expect(result.successCount, 1);
    expect(result.failureCount, 1);
    expect(result.failures.single.feedTitle, 'Feed fail');
    final failedFeed = await context.rssRepository.readFeedByUrl(
      failPreview.feedUrl,
    );
    expect(failedFeed?.lastError, contains('network down'));
    final okArticles = await context.rssRepository.listFeedArticles(
      (await context.rssRepository.readFeedByUrl(okPreview.feedUrl))!.id,
    );
    expect(okArticles.map((article) => article.guid), contains('ok-updated'));
  });

  test('bounded concurrency limits simultaneous feed refreshes', () async {
    final context = await _buildContext('rss_open_refresh_bounded');
    addTearDown(context.dispose);

    final now = DateTime(2026, 5, 15, 12);
    for (final key in <String>['a', 'b', 'c', 'd']) {
      await context.seedFeed(
        _preview(key),
        fetchedAt: now.subtract(const Duration(hours: 2)),
      );
    }

    var active = 0;
    var maxActive = 0;
    final coordinator = RssRefreshCoordinator(
      repository: context.rssRepository,
      fetchService: context.fetchService((uri, {headers}) async {
        active += 1;
        maxActive = active > maxActive ? active : maxActive;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        active -= 1;
        return RssHttpResponse(
          statusCode: 200,
          body: _rssXml(
            title: 'Updated ${uri.pathSegments.first}',
            articleGuid: 'updated-${uri.pathSegments.first}',
          ),
        );
      }),
      now: () => now,
      maxConcurrentFeeds: 2,
    );

    final result = await coordinator.refreshCollectionOnOpen(
      collectionId: _collectionId,
      preferences: CollectionRssRefreshPreferences.defaults,
    );

    expect(result.successCount, 4);
    expect(maxActive, lessThanOrEqualTo(2));
  });
}

const _collectionId = 'collection-rss';

Future<_RssRefreshTestContext> _buildContext(String name) async {
  final dbName = uniqueDbName(name);
  final db = AppDatabase(dbName: dbName);
  final collectionsRepository = CollectionsRepository(db: db);
  final rssRepository = RssRepository(db: db);
  await collectionsRepository.upsert(
    MemoCollection.createRss(id: _collectionId, title: 'RSS'),
  );
  return _RssRefreshTestContext(
    dbName: dbName,
    db: db,
    rssRepository: rssRepository,
  );
}

class _RssRefreshTestContext {
  const _RssRefreshTestContext({
    required this.dbName,
    required this.db,
    required this.rssRepository,
  });

  final String dbName;
  final AppDatabase db;
  final RssRepository rssRepository;

  Future<void> seedFeed(
    RssFeedPreview preview, {
    required DateTime fetchedAt,
  }) async {
    await rssRepository.subscribeCollectionToPreview(
      collectionId: _collectionId,
      preview: preview,
    );
    await rssRepository.recordFeedSuccess(
      preview: preview,
      fetchedAt: fetchedAt,
    );
  }

  RssFeedFetchService fetchService(RssHttpFetcher fetcher) {
    return RssFeedFetchService(repository: rssRepository, fetcher: fetcher);
  }

  Future<void> dispose() async {
    await db.close();
    await deleteTestDatabase(dbName);
  }
}

RssFeed _feed({DateTime? lastFetchTime, DateTime? lastSuccessTime}) {
  return RssFeed(
    id: 'feed',
    feedUrl: 'https://example.com/feed.xml',
    siteUrl: 'https://example.com/',
    title: 'Feed',
    description: '',
    iconUrl: '',
    etag: '',
    lastModified: '',
    lastFetchTime: lastFetchTime,
    lastSuccessTime: lastSuccessTime,
    lastError: null,
    createdTime: DateTime(2026, 5, 1),
    updatedTime: DateTime(2026, 5, 1),
  );
}

RssFeedPreview _preview(String key) {
  return RssFeedPreview(
    requestedUrl: 'https://example.com/$key/feed.xml',
    feedUrl: 'https://example.com/$key/feed.xml',
    siteUrl: 'https://example.com/$key/',
    title: 'Feed $key',
    description: '',
    iconUrl: '',
    articles: <RssArticlePreview>[
      RssArticlePreview(
        guid: '$key-initial',
        link: 'https://example.com/$key/initial',
        title: 'Initial $key',
        author: '',
        summaryHtml: 'Initial summary',
        contentHtml: '<p>Initial body</p>',
        leadImageUrl: '',
        publishedTime: DateTime(2026, 5, 10, 12),
      ),
    ],
  );
}

String _rssXml({required String title, required String articleGuid}) {
  return '''
<rss version="2.0">
  <channel>
    <title>$title</title>
    <link>https://example.com/</link>
    <description>Example feed</description>
    <item>
      <guid>$articleGuid</guid>
      <title>$articleGuid title</title>
      <link>https://example.com/$articleGuid</link>
      <pubDate>Sun, 10 May 2026 12:00:00 +0000</pubDate>
      <description>$articleGuid summary</description>
    </item>
  </channel>
</rss>
''';
}

import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/db/app_database.dart';
import 'package:memos_flutter_app/data/models/memo_collection.dart';
import 'package:memos_flutter_app/data/models/rss_article.dart';
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

  test('creates an RSS collection with one feed attached', () async {
    final dbName = uniqueDbName('rss_collection_one_feed');
    final db = AppDatabase(dbName: dbName);
    final collections = CollectionsRepository(db: db);
    final rss = RssRepository(db: db);

    addTearDown(() async {
      await db.close();
      await deleteTestDatabase(dbName);
    });

    await collections.upsert(
      MemoCollection.createRss(id: 'collection-rss', title: 'RSS'),
    );
    await rss.subscribeCollectionToPreview(
      collectionId: 'collection-rss',
      preview: _preview(
        feedUrl: 'https://example.com/feed.xml',
        title: 'Example Feed',
        articleTitle: 'First Article',
      ),
    );

    final storedCollection = await collections.readById('collection-rss');
    final sources = await rss.listCollectionRssSources('collection-rss');
    final articles = await rss.listCollectionRssArticles('collection-rss');

    expect(storedCollection?.type, MemoCollectionType.rss);
    expect(sources, hasLength(1));
    expect(sources.single.feed.displayTitle, 'Example Feed');
    expect(articles, hasLength(1));
    expect(articles.single.article.title, 'First Article');
  });

  test('creates an RSS collection with multiple feeds attached', () async {
    final dbName = uniqueDbName('rss_collection_multiple_feeds');
    final db = AppDatabase(dbName: dbName);
    final collections = CollectionsRepository(db: db);
    final rss = RssRepository(db: db);

    addTearDown(() async {
      await db.close();
      await deleteTestDatabase(dbName);
    });

    await collections.upsert(
      MemoCollection.createRss(id: 'collection-rss', title: 'RSS'),
    );
    await rss.subscribeCollectionToPreview(
      collectionId: 'collection-rss',
      preview: _preview(
        feedUrl: 'https://example.com/feed.xml',
        title: 'Example Feed',
        articleTitle: 'First Article',
      ),
    );
    await rss.subscribeCollectionToPreview(
      collectionId: 'collection-rss',
      preview: _preview(
        feedUrl: 'https://second.example.com/feed.xml',
        title: 'Second Feed',
        articleTitle: 'Second Article',
      ),
    );

    final sources = await rss.listCollectionRssSources('collection-rss');
    final articles = await rss.listCollectionRssArticles('collection-rss');

    expect(sources.map((item) => item.feed.displayTitle), <String>[
      'Example Feed',
      'Second Feed',
    ]);
    expect(articles.map((item) => item.article.title).toSet(), {
      'First Article',
      'Second Article',
    });
  });

  test('persists RSS full-content metadata and feed opt-in state', () async {
    final dbName = uniqueDbName('rss_full_content_metadata');
    final db = AppDatabase(dbName: dbName);
    final collections = CollectionsRepository(db: db);
    final rss = RssRepository(db: db);

    addTearDown(() async {
      await db.close();
      await deleteTestDatabase(dbName);
    });

    await collections.upsert(
      MemoCollection.createRss(id: 'collection-rss', title: 'RSS'),
    );
    final feed = await rss.subscribeCollectionToPreview(
      collectionId: 'collection-rss',
      preview: _preview(
        feedUrl: 'https://example.com/feed.xml',
        title: 'Example Feed',
        articleTitle: 'First Article',
      ),
    );
    final initialArticle = (await rss.listFeedArticles(feed.id)).single;

    await rss.setFeedFullContentEnabled(feedId: feed.id, enabled: true);
    await rss.recordArticleFullContentFetched(
      articleId: initialArticle.id,
      fullContentHtml: '<p>Fetched full content</p>',
    );
    await rss.upsertArticlesForFeed(
      feedId: feed.id,
      articles: <RssArticlePreview>[
        RssArticlePreview(
          guid: 'https://example.com/feed.xml#article',
          link: 'https://example.com/feed.xml/article',
          title: 'Updated Article',
          author: '',
          summaryHtml: '<p>Updated summary</p>',
          contentHtml: '<p>Updated feed body</p>',
          leadImageUrl: '',
          publishedTime: DateTime(2026, 5, 2),
        ),
      ],
    );

    final storedFeed = await rss.readFeedById(feed.id);
    final storedArticle = (await rss.listFeedArticles(feed.id)).single;

    expect(storedFeed?.fullContentEnabled, isTrue);
    expect(storedArticle.title, 'Updated Article');
    expect(
      storedArticle.fullContentStatus,
      RssArticleFullContentStatus.fetched,
    );
    expect(storedArticle.fullContentHtml, '<p>Fetched full content</p>');
    expect(storedArticle.readableHtml, '<p>Fetched full content</p>');
  });
}

RssFeedPreview _preview({
  required String feedUrl,
  required String title,
  required String articleTitle,
}) {
  return RssFeedPreview(
    requestedUrl: feedUrl,
    feedUrl: feedUrl,
    siteUrl: Uri.parse(feedUrl).origin,
    title: title,
    description: '',
    iconUrl: '',
    articles: <RssArticlePreview>[
      RssArticlePreview(
        guid: '$feedUrl#article',
        link: '$feedUrl/article',
        title: articleTitle,
        author: '',
        summaryHtml: '<p>$articleTitle</p>',
        contentHtml: '<p>$articleTitle body</p>',
        leadImageUrl: '',
        publishedTime: DateTime(2026, 5, 1),
      ),
    ],
  );
}

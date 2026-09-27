import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/db/app_database.dart';
import 'package:memos_flutter_app/data/models/collection_readable_item.dart';
import 'package:memos_flutter_app/data/models/memo_collection.dart';
import 'package:memos_flutter_app/data/models/rss_feed_preview.dart';
import 'package:memos_flutter_app/data/repositories/collections_repository.dart';
import 'package:memos_flutter_app/data/repositories/rss_repository.dart';
import 'package:memos_flutter_app/state/collections/collection_rss_providers.dart';
import 'package:memos_flutter_app/state/system/database_provider.dart';

import '../../test_support.dart';

void main() {
  late TestSupport support;

  setUpAll(() async {
    support = await initializeTestSupport();
  });

  tearDownAll(() async {
    await support.dispose();
  });

  test('save-as-memo is explicit and does not duplicate saved state', () async {
    final dbName = uniqueDbName('collection_rss_save_as_memo');
    final db = AppDatabase(dbName: dbName);
    final container = ProviderContainer(
      overrides: <Override>[databaseProvider.overrideWithValue(db)],
    );
    final collectionsRepository = CollectionsRepository(db: db);
    final rssRepository = RssRepository(db: db);

    addTearDown(() async {
      container.dispose();
      await db.close();
      await deleteTestDatabase(dbName);
    });

    await collectionsRepository.upsert(
      MemoCollection.createRss(id: 'collection-rss', title: 'RSS'),
    );
    await rssRepository.subscribeCollectionToPreview(
      collectionId: 'collection-rss',
      preview: RssFeedPreview(
        requestedUrl: 'https://example.com/feed.xml',
        feedUrl: 'https://example.com/feed.xml',
        siteUrl: 'https://example.com/',
        title: 'Example Feed',
        description: '',
        iconUrl: 'https://example.com/icon.png',
        articles: <RssArticlePreview>[
          RssArticlePreview(
            guid: 'article-1',
            link: 'https://example.com/article-1',
            title: 'RSS Article',
            author: 'Author',
            summaryHtml: 'Summary',
            contentHtml: '<p>Article body</p>',
            leadImageUrl: 'https://example.com/lead.png',
            publishedTime: DateTime(2026, 5, 10),
          ),
        ],
      ),
    );
    final items = await rssRepository.listCollectionRssArticles(
      'collection-rss',
    );
    await rssRepository.recordArticleFullContentFetched(
      articleId: items.single.article.id,
      fullContentHtml: '<p>Fetched full article body</p>',
    );
    final refreshedArticle = await rssRepository.readArticleById(
      items.single.article.id,
    );
    final item = RssCollectionReadableItem(
      article: refreshedArticle!,
      feed: items.single.feed,
    );

    final firstUid = await container
        .read(collectionRssActionsProvider)
        .saveAsMemo(item);
    final secondUid = await container
        .read(collectionRssActionsProvider)
        .saveAsMemo(item);

    expect(firstUid, isNotNull);
    expect(secondUid, firstUid);

    final sqlite = await db.db;
    final memos = await sqlite.query('memos');
    expect(memos, hasLength(1));
    expect(memos.single['content'], contains('RSS Article'));
    expect(memos.single['content'], contains('Fetched full article body'));
    expect(memos.single['content'], isNot(contains('Article body</p>')));
    expect(memos.single['content'], contains('https://example.com/article-1'));

    final clipCards = await sqlite.query('memo_clip_cards');
    expect(clipCards, hasLength(1));
    expect(clipCards.single['source_name'], 'Example Feed');
    expect(clipCards.single['source_url'], 'https://example.com/article-1');

    final savedArticle = await rssRepository.readArticleById(
      items.single.article.id,
    );
    expect(savedArticle?.savedMemoUid, firstUid);
  });
}

import 'package:charset/charset.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/application/rss/rss_feed_discovery.dart';
import 'package:memos_flutter_app/application/rss/rss_feed_fetch_service.dart';
import 'package:memos_flutter_app/application/rss/rss_feed_parser.dart';
import 'package:memos_flutter_app/data/db/app_database.dart';
import 'package:memos_flutter_app/data/models/memo_collection.dart';
import 'package:memos_flutter_app/data/models/rss_article.dart';
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

  test('parser reads common RSS feed metadata and articles', () {
    final preview = const RssFeedParser().parse(
      _rssFeed(title: 'Example Feed', articleTitle: 'First Article'),
      sourceUri: Uri.parse('https://example.com/feed.xml'),
    );

    expect(preview.title, 'Example Feed');
    expect(preview.siteUrl, 'https://example.com/');
    expect(preview.articles, hasLength(1));
    expect(preview.articles.single.guid, 'article-1');
    expect(preview.articles.single.title, 'First Article');
    expect(preview.articles.single.link, 'https://example.com/article-1');
    expect(preview.articles.single.contentHtml, contains('Full text'));
  });

  test('parser reads Atom feed metadata and entries', () {
    final preview = const RssFeedParser().parse('''
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Atom Notes</title>
  <link href="https://example.com/" rel="alternate" />
  <entry>
    <id>tag:example.com,2026:1</id>
    <title>Atom Article</title>
    <link href="/atom-article" />
    <updated>2026-05-10T12:00:00Z</updated>
    <summary>Atom summary</summary>
  </entry>
</feed>
''', sourceUri: Uri.parse('https://example.com/atom.xml'));

    expect(preview.title, 'Atom Notes');
    expect(preview.articles.single.guid, 'tag:example.com,2026:1');
    expect(preview.articles.single.link, 'https://example.com/atom-article');
    expect(preview.articles.single.summaryHtml, 'Atom summary');
  });

  test('HTML discovery finds alternate RSS and Atom links', () {
    final links = const RssFeedDiscovery().discoverAlternateFeeds('''
<html><head>
<link rel="alternate" type="application/rss+xml" href="/rss.xml">
<link rel="alternate" type="application/atom+xml" href="https://example.com/atom.xml">
</head></html>
''', pageUri: Uri.parse('https://example.com/blog/'));

    expect(links.map((item) => item.toString()), <String>[
      'https://example.com/rss.xml',
      'https://example.com/atom.xml',
    ]);
  });

  test('fetch preview falls back to discovered feed link', () async {
    final dbName = uniqueDbName('rss_fetch_preview_discovery');
    final db = AppDatabase(dbName: dbName);
    final repository = RssRepository(db: db);

    addTearDown(() async {
      await db.close();
      await deleteTestDatabase(dbName);
    });

    final service = RssFeedFetchService(
      repository: repository,
      fetcher: (uri, {headers}) async {
        if (uri.path == '/blog') {
          return const RssHttpResponse(
            statusCode: 200,
            body:
                '<html><head><link rel="alternate" type="application/rss+xml" href="/feed.xml"></head></html>',
          );
        }
        return RssHttpResponse(
          statusCode: 200,
          body: _rssFeed(title: 'Discovered Feed', articleTitle: 'Hello'),
        );
      },
    );

    final preview = await service.previewUrl('https://example.com/blog');

    expect(preview.discoveredFromHtml, isTrue);
    expect(preview.feedUrl, 'https://example.com/feed.xml');
    expect(preview.title, 'Discovered Feed');
  });

  test('HTTP byte decoding honors GBK charset from RSS responses', () {
    final response = RssHttpResponse.fromBytes(
      statusCode: 200,
      headers: const <String, String>{'content-type': 'text/xml; charset=gbk'},
      bodyBytes: gbk.encode(
        _rssFeed(title: '吾爱破解 - 52pojie.cn', articleTitle: '中文标题'),
      ),
    );

    final preview = const RssFeedParser().parse(
      response.body,
      sourceUri: Uri.parse('https://www.52pojie.cn/forum.php?mod=rss&fid=2'),
    );

    expect(preview.title, '吾爱破解 - 52pojie.cn');
    expect(preview.articles.single.title, '中文标题');
    expect(response.body, isNot(contains('���')));
  });

  test(
    'manual refresh deduplicates articles and preserves local article state',
    () async {
      final dbName = uniqueDbName('rss_refresh_dedupes');
      final db = AppDatabase(dbName: dbName);
      final repository = RssRepository(db: db);

      addTearDown(() async {
        await db.close();
        await deleteTestDatabase(dbName);
      });

      await CollectionsRepository(
        db: db,
      ).upsert(MemoCollection.createRss(id: 'collection-rss', title: 'RSS'));
      final initialPreview = const RssFeedParser().parse(
        _rssFeed(title: 'Example Feed', articleTitle: 'Initial Article'),
        sourceUri: Uri.parse('https://example.com/feed.xml'),
      );
      final feed = await repository.subscribeCollectionToPreview(
        collectionId: 'collection-rss',
        preview: initialPreview,
      );
      final articles = await repository.listCollectionRssArticles(
        'collection-rss',
      );
      expect(articles, hasLength(1));

      await repository.markArticleRead(
        articleId: articles.single.article.id,
        read: true,
      );
      final sqlite = await db.db;
      await sqlite.insert('memos', <String, Object?>{
        'uid': 'saved-memo',
        'content': 'saved',
        'visibility': 'PRIVATE',
        'pinned': 0,
        'state': 'NORMAL',
        'create_time': 1735689600,
        'display_time': 1735689600,
        'update_time': 1735689600,
        'tags': '',
        'attachments_json': '[]',
        'relation_count': 0,
        'sync_state': 0,
      });
      await repository.updateArticleSavedMemoUid(
        articleId: articles.single.article.id,
        memoUid: 'saved-memo',
      );

      final service = RssFeedFetchService(
        repository: repository,
        fetcher: (uri, {headers}) async => RssHttpResponse(
          statusCode: 200,
          body: _rssFeed(title: 'Example Feed', articleTitle: 'Updated Title'),
        ),
      );
      await service.refreshFeed(feed);

      final refreshed = await repository.listCollectionRssArticles(
        'collection-rss',
      );
      expect(refreshed, hasLength(1));
      expect(refreshed.single.article.title, 'Updated Title');
      expect(refreshed.single.article.readState, RssArticleReadState.read);
      expect(refreshed.single.article.savedMemoUid, 'saved-memo');
    },
  );

  test('manual refresh records network failure on the feed', () async {
    final dbName = uniqueDbName('rss_refresh_failure');
    final db = AppDatabase(dbName: dbName);
    final repository = RssRepository(db: db);

    addTearDown(() async {
      await db.close();
      await deleteTestDatabase(dbName);
    });

    await CollectionsRepository(
      db: db,
    ).upsert(MemoCollection.createRss(id: 'collection-rss', title: 'RSS'));
    final feed = await repository.subscribeCollectionToPreview(
      collectionId: 'collection-rss',
      preview: const RssFeedParser().parse(
        _rssFeed(title: 'Example Feed', articleTitle: 'Initial Article'),
        sourceUri: Uri.parse('https://example.com/feed.xml'),
      ),
    );
    final service = RssFeedFetchService(
      repository: repository,
      fetcher: (uri, {headers}) async => throw StateError('network down'),
    );

    await expectLater(service.refreshFeed(feed), throwsStateError);

    final updated = await repository.readFeedById(feed.id);
    expect(updated?.lastError, contains('network down'));
  });
}

String _rssFeed({required String title, required String articleTitle}) {
  return '''
<rss version="2.0" xmlns:content="http://purl.org/rss/1.0/modules/content/">
  <channel>
    <title>$title</title>
    <link>https://example.com/</link>
    <description>Example description</description>
    <item>
      <guid>article-1</guid>
      <title>$articleTitle</title>
      <link>https://example.com/article-1</link>
      <pubDate>Sun, 10 May 2026 12:00:00 +0000</pubDate>
      <description>Short summary</description>
      <content:encoded><p>Full text</p></content:encoded>
    </item>
  </channel>
</rss>
''';
}

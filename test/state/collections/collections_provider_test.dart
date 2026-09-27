import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/models/collection_readable_item.dart';
import 'package:memos_flutter_app/data/models/memo_collection.dart';
import 'package:memos_flutter_app/data/models/rss_article.dart';
import 'package:memos_flutter_app/data/models/rss_feed.dart';
import 'package:memos_flutter_app/state/collections/collection_rss_providers.dart';
import 'package:memos_flutter_app/state/collections/collections_provider.dart';

void main() {
  test('manual membership targets exclude RSS collections', () async {
    final manual = MemoCollection.createManual(id: 'manual-1', title: 'Manual');
    final rss = MemoCollection.createRss(id: 'rss-1', title: 'RSS');
    final container = ProviderContainer(
      overrides: [
        collectionsProvider.overrideWith((ref) => Stream.value([manual, rss])),
        collectionManualItemUidsProvider.overrideWith((ref, collectionId) {
          return Stream.value(
            collectionId == manual.id ? const <String>['memo-1'] : const [],
          );
        }),
      ],
    );
    addTearDown(container.dispose);

    await container.read(collectionsProvider.future);
    await container.read(collectionManualItemUidsProvider(manual.id).future);

    final memberships = container
        .read(manualCollectionMembershipsProvider('memo-1'))
        .requireValue;

    expect(memberships.map((item) => item.collection.id).toList(), <String>[
      'manual-1',
    ]);
    expect(memberships.single.containsMemo, isTrue);
  });

  test(
    'RSS resolved providers ignore memo candidates and compose RSS items',
    () async {
      final collection = MemoCollection.createRss(id: 'rss-1', title: 'RSS');
      final articleWithFeed = _rssArticleWithFeed(
        articleId: 'article-1',
        title: 'RSS article',
      );
      final container = ProviderContainer(
        overrides: [
          collectionsProvider.overrideWith((ref) => Stream.value([collection])),
          collectionCandidateMemosProvider.overrideWith(
            (ref) =>
                Stream.error(StateError('memo candidates should not load')),
          ),
          collectionRssArticlesProvider.overrideWith((ref, collectionId) {
            return Stream.value(
              collectionId == collection.id
                  ? <RssArticleWithFeed>[articleWithFeed]
                  : const <RssArticleWithFeed>[],
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      await container.read(collectionsProvider.future);
      await container.read(collectionRssArticlesProvider(collection.id).future);

      final memoItems = container
          .read(collectionResolvedItemsProvider(collection.id))
          .requireValue;
      final readableItems = container
          .read(collectionResolvedReadableItemsProvider(collection.id))
          .requireValue;
      final preview = container
          .read(collectionPreviewProvider(collection.id))
          .requireValue;

      expect(memoItems, isEmpty);
      expect(readableItems, hasLength(1));
      expect(readableItems.single.kind, CollectionReadableItemKind.rssArticle);
      expect(readableItems.single.rssArticle?.id, 'article-1');
      expect(readableItems.single.localMemo, isNull);
      expect(preview.itemCount, 1);
    },
  );
}

RssArticleWithFeed _rssArticleWithFeed({
  required String articleId,
  required String title,
}) {
  final created = DateTime(2026, 5, 1, 9);
  final feed = RssFeed(
    id: 'feed-1',
    feedUrl: 'https://example.com/feed.xml',
    siteUrl: 'https://example.com/',
    title: 'Example Feed',
    description: '',
    iconUrl: '',
    etag: '',
    lastModified: '',
    lastFetchTime: created,
    lastSuccessTime: created,
    lastError: null,
    createdTime: created,
    updatedTime: created,
  );
  final article = RssArticle(
    id: articleId,
    feedId: feed.id,
    guid: articleId,
    link: 'https://example.com/$articleId',
    title: title,
    author: '',
    summaryHtml: '<p>$title summary</p>',
    contentHtml: '<p>$title body</p>',
    leadImageUrl: '',
    publishedTime: created,
    fetchedTime: created,
    readState: RssArticleReadState.unread,
    savedMemoUid: null,
    createdTime: created,
    updatedTime: created,
  );
  return RssArticleWithFeed(article: article, feed: feed);
}

import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/models/attachment.dart';
import 'package:memos_flutter_app/data/models/local_memo.dart';
import 'package:memos_flutter_app/data/models/memo_collection.dart';
import 'package:memos_flutter_app/data/models/rss_article.dart';
import 'package:memos_flutter_app/data/models/rss_feed.dart';
import 'package:memos_flutter_app/state/collections/collection_resolver.dart';

void main() {
  group('resolveCollectionItems', () {
    test(
      'matches aliases, descendants, visibility, attachments and pinned',
      () {
        final now = DateTime.now();
        final collection = MemoCollection.createSmart(
          id: 'reading',
          title: 'Reading',
          rules: CollectionRuleSet(
            tagPaths: const <String>['reading', 'project/legacy'],
            tagMatchMode: CollectionTagMatchMode.all,
            includeDescendants: true,
            visibility: CollectionVisibilityScope.privateOnly,
            dateRule: CollectionDateRule(
              type: CollectionDateRuleType.lastDays,
              lastDays: 30,
            ),
            attachmentRule: CollectionAttachmentRule.imagesOnly,
            pinnedOnly: true,
          ),
        );

        final matched = buildMemo(
          uid: 'memo-1',
          tags: const <String>['reading/2025', 'project/current'],
          visibility: 'PRIVATE',
          pinned: true,
          createTime: now.subtract(const Duration(days: 3)),
          attachments: const <Attachment>[
            Attachment(
              name: 'attachments/photo-1',
              filename: 'cover.png',
              type: 'image/png',
              size: 1,
              externalLink: '',
            ),
          ],
        );
        final wrongVisibility = buildMemo(
          uid: 'memo-2',
          tags: const <String>['reading/2025', 'project/current'],
          visibility: 'PUBLIC',
          pinned: true,
          createTime: now.subtract(const Duration(days: 3)),
          attachments: const <Attachment>[
            Attachment(
              name: 'attachments/photo-2',
              filename: 'cover.png',
              type: 'image/png',
              size: 1,
              externalLink: '',
            ),
          ],
        );
        final wrongDate = buildMemo(
          uid: 'memo-3',
          tags: const <String>['reading/2025', 'project/current'],
          visibility: 'PRIVATE',
          pinned: true,
          createTime: now.subtract(const Duration(days: 45)),
          attachments: const <Attachment>[
            Attachment(
              name: 'attachments/photo-3',
              filename: 'cover.png',
              type: 'image/png',
              size: 1,
              externalLink: '',
            ),
          ],
        );
        final wrongPinned = buildMemo(
          uid: 'memo-4',
          tags: const <String>['reading/2025', 'project/current'],
          visibility: 'PRIVATE',
          pinned: false,
          createTime: now.subtract(const Duration(days: 3)),
          attachments: const <Attachment>[
            Attachment(
              name: 'attachments/photo-4',
              filename: 'cover.png',
              type: 'image/png',
              size: 1,
              externalLink: '',
            ),
          ],
        );

        final items = resolveCollectionItems(
          collection,
          <LocalMemo>[matched, wrongVisibility, wrongDate, wrongPinned],
          resolveCanonicalTagPath: (path) {
            return switch (path) {
              'project/legacy' => 'project/current',
              _ => path,
            };
          },
        );

        expect(items.map((item) => item.uid), <String>['memo-1']);
      },
    );

    test('supports custom range and excluded attachments', () {
      final start = DateTime(2025, 1, 1);
      final endExclusive = DateTime(2025, 2, 1);
      final collection = MemoCollection.createSmart(
        id: 'journal',
        title: 'Journal',
        rules: CollectionRuleSet(
          tagPaths: const <String>['journal'],
          tagMatchMode: CollectionTagMatchMode.any,
          includeDescendants: false,
          visibility: CollectionVisibilityScope.all,
          dateRule: CollectionDateRule(
            type: CollectionDateRuleType.customRange,
            startTimeSec: start.toUtc().millisecondsSinceEpoch ~/ 1000,
            endTimeSecExclusive:
                endExclusive.toUtc().millisecondsSinceEpoch ~/ 1000,
          ),
          attachmentRule: CollectionAttachmentRule.excluded,
          pinnedOnly: false,
        ),
      );

      final inRangeNoAttachments = buildMemo(
        uid: 'memo-10',
        tags: const <String>['journal'],
        createTime: DateTime(2025, 1, 12),
      );
      final outOfRange = buildMemo(
        uid: 'memo-11',
        tags: const <String>['journal'],
        createTime: DateTime(2025, 2, 12),
      );
      final withAttachment = buildMemo(
        uid: 'memo-12',
        tags: const <String>['journal'],
        createTime: DateTime(2025, 1, 12),
        attachments: const <Attachment>[
          Attachment(
            name: 'attachments/doc-1',
            filename: 'doc.pdf',
            type: 'application/pdf',
            size: 1,
            externalLink: '',
          ),
        ],
      );

      final items = resolveCollectionItems(collection, <LocalMemo>[
        inRangeNoAttachments,
        outOfRange,
        withAttachment,
      ]);

      expect(items.map((item) => item.uid), <String>['memo-10']);
    });

    test('resolves manual collections using stored member order', () {
      final collection = MemoCollection.createManual(
        id: 'manual-collection',
        title: 'Pinned shelf',
      );
      final first = buildMemo(uid: 'memo-1', createTime: DateTime(2025, 1, 1));
      final second = buildMemo(uid: 'memo-2', createTime: DateTime(2025, 1, 2));
      final third = buildMemo(uid: 'memo-3', createTime: DateTime(2025, 1, 3));

      final items = resolveCollectionItems(
        collection,
        <LocalMemo>[first, second, third],
        manualMemoUids: const <String>['memo-3', 'memo-1'],
      );

      expect(items.map((item) => item.uid), <String>['memo-3', 'memo-1']);
    });

    test('RSS collections never resolve LocalMemo items', () {
      final collection = MemoCollection.createRss(
        id: 'rss-collection',
        title: 'RSS',
      );
      final memo = buildMemo(uid: 'memo-1', createTime: DateTime(2025, 1, 1));

      final items = resolveCollectionItems(collection, <LocalMemo>[memo]);

      expect(items, isEmpty);
    });
  });

  group('composeCollectionReadableItems', () {
    test('non-RSS collections keep readable items memo-only', () {
      final created = DateTime(2026, 5, 10);
      final collection = MemoCollection.createSmart(
        id: 'mixed',
        title: 'Mixed shelf',
      );
      final memo = buildMemo(uid: 'memo-1', createTime: created);
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
        id: 'article-1',
        feedId: feed.id,
        guid: 'guid-1',
        link: 'https://example.com/article',
        title: 'RSS Article',
        author: '',
        summaryHtml: 'summary',
        contentHtml: '<p>body</p>',
        leadImageUrl: '',
        publishedTime: created.add(const Duration(hours: 1)),
        fetchedTime: created.add(const Duration(hours: 1)),
        readState: RssArticleReadState.unread,
        savedMemoUid: null,
        createdTime: created,
        updatedTime: created,
      );

      final items = composeCollectionReadableItems(
        collection: collection,
        memoItems: <LocalMemo>[memo],
        rssItems: <RssArticleWithFeed>[
          RssArticleWithFeed(article: article, feed: feed),
        ],
      );

      expect(items, hasLength(1));
      expect(items.single.localMemo?.uid, 'memo-1');
      expect(items.single.rssArticle, isNull);
    });

    test('RSS collections resolve only RSS articles', () {
      final created = DateTime(2026, 5, 10);
      final collection = MemoCollection.createRss(
        id: 'rss',
        title: 'RSS shelf',
      );
      final memo = buildMemo(uid: 'memo-1', createTime: created);
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
      final older = RssArticle(
        id: 'article-older',
        feedId: feed.id,
        guid: 'guid-older',
        link: 'https://example.com/older',
        title: 'Older Article',
        author: '',
        summaryHtml: 'summary',
        contentHtml: '<p>older</p>',
        leadImageUrl: '',
        publishedTime: created,
        fetchedTime: created,
        readState: RssArticleReadState.unread,
        savedMemoUid: null,
        createdTime: created,
        updatedTime: created,
      );
      final newer = RssArticle(
        id: 'article-newer',
        feedId: feed.id,
        guid: 'guid-newer',
        link: 'https://example.com/newer',
        title: 'Newer Article',
        author: '',
        summaryHtml: 'summary',
        contentHtml: '<p>newer</p>',
        leadImageUrl: '',
        publishedTime: created.add(const Duration(hours: 1)),
        fetchedTime: created.add(const Duration(hours: 1)),
        readState: RssArticleReadState.unread,
        savedMemoUid: null,
        createdTime: created,
        updatedTime: created,
      );

      final items = composeCollectionReadableItems(
        collection: collection,
        memoItems: <LocalMemo>[memo],
        rssItems: <RssArticleWithFeed>[
          RssArticleWithFeed(article: older, feed: feed),
          RssArticleWithFeed(article: newer, feed: feed),
        ],
      );

      expect(items.map((item) => item.rssArticle?.id), <String>[
        'article-newer',
        'article-older',
      ]);
      expect(items.every((item) => item.localMemo == null), isTrue);
    });
  });
}

LocalMemo buildMemo({
  required String uid,
  List<String> tags = const <String>[],
  String visibility = 'PRIVATE',
  bool pinned = false,
  DateTime? createTime,
  DateTime? updateTime,
  List<Attachment> attachments = const <Attachment>[],
}) {
  final created = createTime ?? DateTime.now();
  return LocalMemo(
    uid: uid,
    content: 'Content for $uid',
    contentFingerprint: uid,
    visibility: visibility,
    pinned: pinned,
    state: 'NORMAL',
    createTime: created,
    displayTime: created,
    updateTime: updateTime ?? created,
    tags: tags,
    attachments: attachments,
    relationCount: 0,
    location: null,
    syncState: SyncState.synced,
    lastError: null,
  );
}

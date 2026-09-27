import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/uid.dart';
import '../../state/system/database_provider.dart';
import '../db/app_database.dart';
import '../db/app_database_write_dao.dart';
import '../models/rss_article.dart';
import '../models/rss_feed.dart';
import '../models/rss_feed_preview.dart';

final rssRepositoryProvider = Provider<RssRepository>((ref) {
  return RssRepository(db: ref.watch(databaseProvider));
});

class RssRepository {
  RssRepository({required AppDatabase db}) : _db = db;

  final AppDatabase _db;

  Future<RssFeed?> readFeedById(String feedId) async {
    final normalized = feedId.trim();
    if (normalized.isEmpty) return null;
    final sqlite = await _db.db;
    return _readFeedById(sqlite, normalized);
  }

  Future<RssFeed?> readFeedByUrl(String feedUrl) async {
    final normalized = feedUrl.trim();
    if (normalized.isEmpty) return null;
    final sqlite = await _db.db;
    return _readFeedByUrl(sqlite, normalized);
  }

  Future<RssArticle?> readArticleById(String articleId) async {
    final normalized = articleId.trim();
    if (normalized.isEmpty) return null;
    final sqlite = await _db.db;
    final rows = await sqlite.query(
      'rss_articles',
      where: 'id = ?',
      whereArgs: <Object?>[normalized],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return RssArticle.fromDb(rows.first);
  }

  Future<List<RssArticle>> listFeedArticles(String feedId, {int? limit}) async {
    final normalizedFeedId = feedId.trim();
    if (normalizedFeedId.isEmpty) return const <RssArticle>[];
    final sqlite = await _db.db;
    final rows = await sqlite.query(
      'rss_articles',
      where: 'feed_id = ?',
      whereArgs: <Object?>[normalizedFeedId],
      orderBy:
          'COALESCE(published_time, fetched_time) DESC, fetched_time DESC, id ASC',
      limit: limit,
    );
    return rows.map(RssArticle.fromDb).toList(growable: false);
  }

  Future<List<RssArticle>> listFullContentEligibleArticlesForFeed(
    String feedId, {
    int limit = 10,
  }) async {
    final normalizedFeedId = feedId.trim();
    if (normalizedFeedId.isEmpty || limit <= 0) return const <RssArticle>[];
    final sqlite = await _db.db;
    final rows = await sqlite.query(
      'rss_articles',
      where:
          'feed_id = ? AND link <> ? AND full_content_html = ? AND full_content_status = ?',
      whereArgs: <Object?>[
        normalizedFeedId,
        '',
        '',
        rssArticleFullContentStatusValue(RssArticleFullContentStatus.idle),
      ],
      orderBy:
          'COALESCE(published_time, fetched_time) DESC, fetched_time DESC, id ASC',
      limit: limit,
    );
    return rows.map(RssArticle.fromDb).toList(growable: false);
  }

  Future<RssFeed> upsertFeedFromPreview(RssFeedPreview preview) async {
    final sqlite = await _db.db;
    final feed = await AppDatabaseWriteDao.runTransaction<RssFeed>(sqlite, (
      txn,
    ) async {
      final feed = await _upsertFeedFromPreview(txn, preview);
      await _upsertArticlePreviews(
        txn,
        feedId: feed.id,
        articles: preview.articles,
      );
      return feed;
    });
    _db.notifyDataChanged();
    return feed;
  }

  Future<RssFeed> subscribeCollectionToPreview({
    required String collectionId,
    required RssFeedPreview preview,
  }) async {
    final normalizedCollectionId = collectionId.trim();
    if (normalizedCollectionId.isEmpty) {
      throw ArgumentError.value(collectionId, 'collectionId');
    }
    final sqlite = await _db.db;
    final feed = await AppDatabaseWriteDao.runTransaction<RssFeed>(sqlite, (
      txn,
    ) async {
      final feed = await _upsertFeedFromPreview(txn, preview);
      await _upsertArticlePreviews(
        txn,
        feedId: feed.id,
        articles: preview.articles,
      );
      await _attachFeedToCollection(
        txn,
        collectionId: normalizedCollectionId,
        feedId: feed.id,
      );
      return feed;
    });
    _db.notifyDataChanged();
    return feed;
  }

  Future<void> attachFeedToCollection({
    required String collectionId,
    required String feedId,
  }) async {
    final normalizedCollectionId = collectionId.trim();
    final normalizedFeedId = feedId.trim();
    if (normalizedCollectionId.isEmpty || normalizedFeedId.isEmpty) return;
    final sqlite = await _db.db;
    await AppDatabaseWriteDao.runTransaction<void>(sqlite, (txn) async {
      await _attachFeedToCollection(
        txn,
        collectionId: normalizedCollectionId,
        feedId: normalizedFeedId,
      );
    });
    _db.notifyDataChanged();
  }

  Future<void> detachFeedFromCollection({
    required String collectionId,
    required String feedId,
  }) async {
    final normalizedCollectionId = collectionId.trim();
    final normalizedFeedId = feedId.trim();
    if (normalizedCollectionId.isEmpty || normalizedFeedId.isEmpty) return;
    final sqlite = await _db.db;
    await sqlite.delete(
      'collection_rss_sources',
      where: 'collection_id = ? AND feed_id = ?',
      whereArgs: <Object?>[normalizedCollectionId, normalizedFeedId],
    );
    _db.notifyDataChanged();
  }

  Future<List<CollectionRssSourceWithFeed>> listCollectionRssSources(
    String collectionId,
  ) async {
    final normalizedCollectionId = collectionId.trim();
    if (normalizedCollectionId.isEmpty) {
      return const <CollectionRssSourceWithFeed>[];
    }
    final sqlite = await _db.db;
    final sourceRows = await sqlite.query(
      'collection_rss_sources',
      where: 'collection_id = ?',
      whereArgs: <Object?>[normalizedCollectionId],
      orderBy: 'sort_order ASC, created_time ASC',
    );
    final result = <CollectionRssSourceWithFeed>[];
    for (final row in sourceRows) {
      final source = CollectionRssSource.fromDb(row);
      final feed = await _readFeedById(sqlite, source.feedId);
      if (feed == null) continue;
      result.add(CollectionRssSourceWithFeed(source: source, feed: feed));
    }
    return result;
  }

  Future<List<RssArticleWithFeed>> listCollectionRssArticles(
    String collectionId,
  ) async {
    final sources = await listCollectionRssSources(collectionId);
    if (sources.isEmpty) return const <RssArticleWithFeed>[];
    final sqlite = await _db.db;
    final result = <RssArticleWithFeed>[];
    for (final source in sources) {
      final rows = await sqlite.query(
        'rss_articles',
        where: 'feed_id = ?',
        whereArgs: <Object?>[source.feed.id],
        orderBy:
            'COALESCE(published_time, fetched_time) DESC, fetched_time DESC, id ASC',
      );
      for (final row in rows) {
        result.add(
          RssArticleWithFeed(
            article: RssArticle.fromDb(row),
            feed: source.feed,
          ),
        );
      }
    }
    result.sort((a, b) {
      final timeCompare = b.article.effectiveDisplayTime.compareTo(
        a.article.effectiveDisplayTime,
      );
      if (timeCompare != 0) return timeCompare;
      return a.article.id.compareTo(b.article.id);
    });
    return result;
  }

  Future<void> upsertArticlesForFeed({
    required String feedId,
    required List<RssArticlePreview> articles,
  }) async {
    final normalizedFeedId = feedId.trim();
    if (normalizedFeedId.isEmpty || articles.isEmpty) return;
    final sqlite = await _db.db;
    await AppDatabaseWriteDao.runTransaction<void>(sqlite, (txn) async {
      await _upsertArticlePreviews(
        txn,
        feedId: normalizedFeedId,
        articles: articles,
      );
    });
    _db.notifyDataChanged();
  }

  Future<void> recordFeedSuccess({
    required RssFeedPreview preview,
    required DateTime fetchedAt,
  }) async {
    final sqlite = await _db.db;
    await AppDatabaseWriteDao.runTransaction<void>(sqlite, (txn) async {
      final feed = await _upsertFeedFromPreview(txn, preview, now: fetchedAt);
      await txn.update(
        'rss_feeds',
        <String, Object?>{
          'etag': preview.etag.trim(),
          'last_modified': preview.lastModified.trim(),
          'last_fetch_time': _toSec(fetchedAt),
          'last_success_time': _toSec(fetchedAt),
          'last_error': null,
          'updated_time': _toSec(fetchedAt),
        },
        where: 'id = ?',
        whereArgs: <Object?>[feed.id],
      );
    });
    _db.notifyDataChanged();
  }

  Future<void> recordFeedFailure({
    required String feedId,
    required String error,
    DateTime? fetchedAt,
  }) async {
    final normalizedFeedId = feedId.trim();
    if (normalizedFeedId.isEmpty) return;
    final now = fetchedAt ?? DateTime.now();
    final sqlite = await _db.db;
    await sqlite.update(
      'rss_feeds',
      <String, Object?>{
        'last_fetch_time': _toSec(now),
        'last_error': error.trim().isEmpty ? 'Feed refresh failed' : error,
        'updated_time': _toSec(now),
      },
      where: 'id = ?',
      whereArgs: <Object?>[normalizedFeedId],
    );
    _db.notifyDataChanged();
  }

  Future<void> markArticleRead({
    required String articleId,
    required bool read,
  }) async {
    final normalizedArticleId = articleId.trim();
    if (normalizedArticleId.isEmpty) return;
    final now = DateTime.now();
    final sqlite = await _db.db;
    await sqlite.update(
      'rss_articles',
      <String, Object?>{
        'read_state': rssArticleReadStateValue(
          read ? RssArticleReadState.read : RssArticleReadState.unread,
        ),
        'updated_time': _toSec(now),
      },
      where: 'id = ?',
      whereArgs: <Object?>[normalizedArticleId],
    );
    _db.notifyDataChanged();
  }

  Future<void> updateArticleSavedMemoUid({
    required String articleId,
    required String? memoUid,
  }) async {
    final normalizedArticleId = articleId.trim();
    if (normalizedArticleId.isEmpty) return;
    final normalizedMemoUid = memoUid?.trim();
    final now = DateTime.now();
    final sqlite = await _db.db;
    await sqlite.update(
      'rss_articles',
      <String, Object?>{
        'saved_memo_uid': normalizedMemoUid == null || normalizedMemoUid.isEmpty
            ? null
            : normalizedMemoUid,
        'updated_time': _toSec(now),
      },
      where: 'id = ?',
      whereArgs: <Object?>[normalizedArticleId],
    );
    _db.notifyDataChanged();
  }

  Future<void> setFeedFullContentEnabled({
    required String feedId,
    required bool enabled,
  }) async {
    final normalizedFeedId = feedId.trim();
    if (normalizedFeedId.isEmpty) return;
    final now = DateTime.now();
    final sqlite = await _db.db;
    await sqlite.update(
      'rss_feeds',
      <String, Object?>{
        'full_content_enabled': enabled ? 1 : 0,
        'updated_time': _toSec(now),
      },
      where: 'id = ?',
      whereArgs: <Object?>[normalizedFeedId],
    );
    _db.notifyDataChanged();
  }

  Future<void> markArticleFullContentFetching({
    required String articleId,
    DateTime? now,
  }) async {
    await _updateArticleFullContentState(
      articleId: articleId,
      status: RssArticleFullContentStatus.fetching,
      fullContentHtml: null,
      fetchedTime: null,
      error: null,
      now: now,
    );
  }

  Future<void> recordArticleFullContentFetched({
    required String articleId,
    required String fullContentHtml,
    DateTime? fetchedAt,
  }) async {
    final normalizedHtml = fullContentHtml.trim();
    await _updateArticleFullContentState(
      articleId: articleId,
      status: normalizedHtml.isEmpty
          ? RssArticleFullContentStatus.failed
          : RssArticleFullContentStatus.fetched,
      fullContentHtml: normalizedHtml,
      fetchedTime: fetchedAt ?? DateTime.now(),
      error: normalizedHtml.isEmpty ? 'Full content extraction failed' : null,
      now: fetchedAt,
    );
  }

  Future<void> recordArticleFullContentFailure({
    required String articleId,
    required String error,
    bool skipped = false,
    DateTime? failedAt,
  }) async {
    await _updateArticleFullContentState(
      articleId: articleId,
      status: skipped
          ? RssArticleFullContentStatus.skipped
          : RssArticleFullContentStatus.failed,
      fullContentHtml: null,
      fetchedTime: failedAt ?? DateTime.now(),
      error: error.trim().isEmpty ? 'Full content fetch failed' : error,
      now: failedAt,
    );
  }

  Future<RssFeed> _upsertFeedFromPreview(
    DatabaseExecutor executor,
    RssFeedPreview preview, {
    DateTime? now,
  }) async {
    final effectiveNow = now ?? DateTime.now();
    final feedUrl = preview.feedUrl.trim();
    if (feedUrl.isEmpty) {
      throw ArgumentError.value(preview.feedUrl, 'feedUrl');
    }
    final existing = await _readFeedByUrl(executor, feedUrl);
    final feed = RssFeed(
      id: existing?.id ?? generateUid(length: 16),
      feedUrl: feedUrl,
      siteUrl: preview.siteUrl.trim(),
      title: preview.title.trim(),
      description: preview.description.trim(),
      iconUrl: preview.iconUrl.trim(),
      etag: preview.etag.trim(),
      lastModified: preview.lastModified.trim(),
      lastFetchTime: effectiveNow,
      lastSuccessTime: effectiveNow,
      lastError: null,
      fullContentEnabled: existing?.fullContentEnabled ?? false,
      createdTime: existing?.createdTime ?? effectiveNow,
      updatedTime: effectiveNow,
    );
    final row = _feedToRow(feed);
    if (existing == null) {
      await executor.insert('rss_feeds', row);
    } else {
      await executor.update(
        'rss_feeds',
        row,
        where: 'id = ?',
        whereArgs: <Object?>[feed.id],
      );
    }
    return feed;
  }

  Future<void> _upsertArticlePreviews(
    DatabaseExecutor executor, {
    required String feedId,
    required List<RssArticlePreview> articles,
    DateTime? now,
  }) async {
    final normalizedFeedId = feedId.trim();
    if (normalizedFeedId.isEmpty) return;
    final effectiveNow = now ?? DateTime.now();
    for (final preview in articles) {
      final existing = await _findExistingArticle(
        executor,
        feedId: normalizedFeedId,
        guid: preview.guid,
        link: preview.link,
      );
      final article = RssArticle(
        id: existing?.id ?? generateUid(length: 16),
        feedId: normalizedFeedId,
        guid: preview.guid.trim(),
        link: preview.link.trim(),
        title: preview.title.trim(),
        author: preview.author.trim(),
        summaryHtml: preview.summaryHtml.trim(),
        contentHtml: preview.contentHtml.trim(),
        leadImageUrl: preview.leadImageUrl.trim(),
        publishedTime: preview.publishedTime,
        fetchedTime: effectiveNow,
        readState: existing?.readState ?? RssArticleReadState.unread,
        savedMemoUid: existing?.savedMemoUid,
        createdTime: existing?.createdTime ?? effectiveNow,
        updatedTime: effectiveNow,
        fullContentHtml: existing?.fullContentHtml ?? '',
        fullContentStatus:
            existing?.fullContentStatus ?? RssArticleFullContentStatus.idle,
        fullContentFetchedTime: existing?.fullContentFetchedTime,
        fullContentError: existing?.fullContentError,
      );
      final row = _articleToRow(article);
      if (existing == null) {
        await executor.insert('rss_articles', row);
      } else {
        await executor.update(
          'rss_articles',
          row,
          where: 'id = ?',
          whereArgs: <Object?>[article.id],
        );
      }
    }
  }

  Future<void> _attachFeedToCollection(
    DatabaseExecutor executor, {
    required String collectionId,
    required String feedId,
  }) async {
    final existing = await executor.query(
      'collection_rss_sources',
      where: 'collection_id = ? AND feed_id = ?',
      whereArgs: <Object?>[collectionId, feedId],
      limit: 1,
    );
    final now = DateTime.now();
    if (existing.isNotEmpty) {
      await executor.update(
        'collection_rss_sources',
        <String, Object?>{'updated_time': _toSec(now)},
        where: 'collection_id = ? AND feed_id = ?',
        whereArgs: <Object?>[collectionId, feedId],
      );
      return;
    }
    final order = await _nextCollectionSourceSortOrder(executor, collectionId);
    await executor.insert('collection_rss_sources', <String, Object?>{
      'collection_id': collectionId,
      'feed_id': feedId,
      'sort_order': order,
      'created_time': _toSec(now),
      'updated_time': _toSec(now),
    });
  }

  Future<RssFeed?> _readFeedById(
    DatabaseExecutor executor,
    String feedId,
  ) async {
    final rows = await executor.query(
      'rss_feeds',
      where: 'id = ?',
      whereArgs: <Object?>[feedId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return RssFeed.fromDb(rows.first);
  }

  Future<RssFeed?> _readFeedByUrl(
    DatabaseExecutor executor,
    String feedUrl,
  ) async {
    final rows = await executor.query(
      'rss_feeds',
      where: 'feed_url = ?',
      whereArgs: <Object?>[feedUrl.trim()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return RssFeed.fromDb(rows.first);
  }

  Future<RssArticle?> _findExistingArticle(
    DatabaseExecutor executor, {
    required String feedId,
    required String guid,
    required String link,
  }) async {
    final normalizedGuid = guid.trim();
    if (normalizedGuid.isNotEmpty) {
      final rows = await executor.query(
        'rss_articles',
        where: 'feed_id = ? AND guid = ?',
        whereArgs: <Object?>[feedId, normalizedGuid],
        limit: 1,
      );
      if (rows.isNotEmpty) return RssArticle.fromDb(rows.first);
    }
    final normalizedLink = link.trim();
    if (normalizedLink.isNotEmpty) {
      final rows = await executor.query(
        'rss_articles',
        where: 'feed_id = ? AND link = ?',
        whereArgs: <Object?>[feedId, normalizedLink],
        limit: 1,
      );
      if (rows.isNotEmpty) return RssArticle.fromDb(rows.first);
    }
    return null;
  }

  Future<int> _nextCollectionSourceSortOrder(
    DatabaseExecutor executor,
    String collectionId,
  ) async {
    final rows = await executor.rawQuery(
      'SELECT COALESCE(MAX(sort_order), -1) AS max_sort_order FROM collection_rss_sources WHERE collection_id = ?;',
      <Object?>[collectionId],
    );
    final raw = rows.isEmpty ? null : rows.first['max_sort_order'];
    if (raw is int) return raw + 1;
    if (raw is num) return raw.toInt() + 1;
    return 0;
  }

  Map<String, Object?> _feedToRow(RssFeed feed) {
    return <String, Object?>{
      'id': feed.id,
      'feed_url': feed.feedUrl.trim(),
      'site_url': feed.siteUrl.trim(),
      'title': feed.title.trim(),
      'description': feed.description.trim(),
      'icon_url': feed.iconUrl.trim(),
      'etag': feed.etag.trim(),
      'last_modified': feed.lastModified.trim(),
      'last_fetch_time': _toOptionalSec(feed.lastFetchTime),
      'last_success_time': _toOptionalSec(feed.lastSuccessTime),
      'last_error': feed.lastError?.trim(),
      'full_content_enabled': feed.fullContentEnabled ? 1 : 0,
      'created_time': _toSec(feed.createdTime),
      'updated_time': _toSec(feed.updatedTime),
    };
  }

  Map<String, Object?> _articleToRow(RssArticle article) {
    return <String, Object?>{
      'id': article.id,
      'feed_id': article.feedId.trim(),
      'guid': article.guid.trim(),
      'link': article.link.trim(),
      'title': article.title.trim(),
      'author': article.author.trim(),
      'summary_html': article.summaryHtml.trim(),
      'content_html': article.contentHtml.trim(),
      'lead_image_url': article.leadImageUrl.trim(),
      'published_time': _toOptionalSec(article.publishedTime),
      'fetched_time': _toSec(article.fetchedTime),
      'read_state': rssArticleReadStateValue(article.readState),
      'saved_memo_uid': article.savedMemoUid?.trim(),
      'full_content_html': article.fullContentHtml.trim(),
      'full_content_status': rssArticleFullContentStatusValue(
        article.fullContentStatus,
      ),
      'full_content_fetched_time': _toOptionalSec(
        article.fullContentFetchedTime,
      ),
      'full_content_error': article.fullContentError?.trim(),
      'created_time': _toSec(article.createdTime),
      'updated_time': _toSec(article.updatedTime),
    };
  }

  Future<void> _updateArticleFullContentState({
    required String articleId,
    required RssArticleFullContentStatus status,
    required String? fullContentHtml,
    required DateTime? fetchedTime,
    required String? error,
    DateTime? now,
  }) async {
    final normalizedArticleId = articleId.trim();
    if (normalizedArticleId.isEmpty) return;
    final effectiveNow = now ?? DateTime.now();
    final values = <String, Object?>{
      'full_content_status': rssArticleFullContentStatusValue(status),
      'full_content_fetched_time': _toOptionalSec(fetchedTime),
      'full_content_error': error?.trim(),
      'updated_time': _toSec(effectiveNow),
    };
    if (fullContentHtml != null) {
      values['full_content_html'] = fullContentHtml.trim();
    }
    final sqlite = await _db.db;
    await sqlite.update(
      'rss_articles',
      values,
      where: 'id = ?',
      whereArgs: <Object?>[normalizedArticleId],
    );
    _db.notifyDataChanged();
  }

  int _toSec(DateTime value) => value.toUtc().millisecondsSinceEpoch ~/ 1000;

  int? _toOptionalSec(DateTime? value) => value == null ? null : _toSec(value);
}

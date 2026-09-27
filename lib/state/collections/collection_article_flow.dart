import '../../data/models/collection_article_flow.dart';
import '../../data/models/collection_readable_item.dart';

class CollectionArticleFlowFeedOption {
  const CollectionArticleFlowFeedOption({
    required this.feedId,
    required this.title,
    required this.iconUrl,
    required this.count,
  });

  final String feedId;
  final String title;
  final String iconUrl;
  final int count;
}

class CollectionArticleFlowDateOption {
  const CollectionArticleFlowDateOption({
    required this.bucketKey,
    required this.date,
    required this.count,
  });

  final String bucketKey;
  final DateTime date;
  final int count;
}

class CollectionArticleFlowListModel {
  const CollectionArticleFlowListModel({
    required this.items,
    required this.feedOptions,
    required this.dateOptions,
  });

  final List<CollectionReadableItem> items;
  final List<CollectionArticleFlowFeedOption> feedOptions;
  final List<CollectionArticleFlowDateOption> dateOptions;
}

CollectionArticleFlowListModel buildCollectionArticleFlowList({
  required List<CollectionReadableItem> sourceItems,
  required CollectionArticleFlowStatusFilter statusFilter,
  required String? feedId,
  required String? dateBucketKey,
}) {
  final feedCounts = <String, int>{};
  final feedTitles = <String, String>{};
  final feedIcons = <String, String>{};
  final dateCounts = <String, int>{};
  final dateValues = <String, DateTime>{};

  for (final item in sourceItems) {
    final rssArticle = item.rssArticle;
    final rssFeed = item.rssFeed;
    if (rssArticle != null && rssFeed != null) {
      feedCounts[rssArticle.feedId] = (feedCounts[rssArticle.feedId] ?? 0) + 1;
      feedTitles[rssArticle.feedId] = rssFeed.displayTitle;
      feedIcons[rssArticle.feedId] = rssFeed.iconUrl;
    }
    final bucket = CollectionArticleFlowDateBucket.fromDate(
      item.effectiveDisplayTime,
    );
    dateCounts[bucket.key] = (dateCounts[bucket.key] ?? 0) + 1;
    dateValues[bucket.key] = bucket.date ?? item.effectiveDisplayTime;
  }

  final filtered = sourceItems
      .where((item) {
        if (!_matchesStatus(item, statusFilter)) {
          return false;
        }
        final normalizedFeedId = feedId?.trim();
        if (normalizedFeedId != null && normalizedFeedId.isNotEmpty) {
          final itemFeedId = item.rssArticle?.feedId.trim();
          if (itemFeedId != normalizedFeedId) {
            return false;
          }
        }
        final normalizedDateBucket = dateBucketKey?.trim();
        if (normalizedDateBucket != null && normalizedDateBucket.isNotEmpty) {
          final itemBucket = CollectionArticleFlowDateBucket.fromDate(
            item.effectiveDisplayTime,
          ).key;
          if (itemBucket != normalizedDateBucket) {
            return false;
          }
        }
        return true;
      })
      .toList(growable: false);

  final feedOptions = [
    for (final entry in feedCounts.entries)
      CollectionArticleFlowFeedOption(
        feedId: entry.key,
        title: feedTitles[entry.key]?.trim().isNotEmpty == true
            ? feedTitles[entry.key]!.trim()
            : entry.key,
        iconUrl: feedIcons[entry.key] ?? '',
        count: entry.value,
      ),
  ]..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

  final dateOptions = [
    for (final entry in dateCounts.entries)
      CollectionArticleFlowDateOption(
        bucketKey: entry.key,
        date: dateValues[entry.key] ?? DateTime.now(),
        count: entry.value,
      ),
  ]..sort((a, b) => b.date.compareTo(a.date));

  return CollectionArticleFlowListModel(
    items: filtered,
    feedOptions: feedOptions,
    dateOptions: dateOptions,
  );
}

bool collectionArticleFlowItemCanMarkRead(CollectionReadableItem item) {
  return item.kind == CollectionReadableItemKind.rssArticle;
}

bool collectionArticleFlowItemCanSaveAsMemo(CollectionReadableItem item) {
  return item.kind == CollectionReadableItemKind.rssArticle;
}

bool collectionArticleFlowItemCanFetchFullContent(CollectionReadableItem item) {
  return item.kind == CollectionReadableItemKind.rssArticle &&
      item.originalUrl?.trim().isNotEmpty == true;
}

String buildCollectionArticleFlowExcerpt(CollectionReadableItem item) {
  final rssArticle = item.rssArticle;
  final source = rssArticle == null
      ? item.content
      : (rssArticle.summaryHtml.trim().isNotEmpty
            ? rssArticle.summaryHtml
            : rssArticle.readableHtml);
  return _stripHtml(source).replaceAll(RegExp(r'\s+'), ' ').trim();
}

bool _matchesStatus(
  CollectionReadableItem item,
  CollectionArticleFlowStatusFilter statusFilter,
) {
  return switch (statusFilter) {
    CollectionArticleFlowStatusFilter.all => true,
    CollectionArticleFlowStatusFilter.unread =>
      item.kind == CollectionReadableItemKind.rssArticle && !item.isRead,
    CollectionArticleFlowStatusFilter.read =>
      item.kind != CollectionReadableItemKind.rssArticle || item.isRead,
    CollectionArticleFlowStatusFilter.saved =>
      item.savedMemoUid?.trim().isNotEmpty == true,
  };
}

String _stripHtml(String value) {
  return value
      .replaceAll(
        RegExp(r'<script[\s\S]*?</script>', caseSensitive: false),
        ' ',
      )
      .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");
}

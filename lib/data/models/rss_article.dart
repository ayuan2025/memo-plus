import 'rss_feed.dart';

enum RssArticleReadState { unread, read }

enum RssArticleFullContentStatus { idle, fetching, fetched, failed, skipped }

RssArticleReadState rssArticleReadStateFromValue(String? value) {
  return switch ((value ?? '').trim().toLowerCase()) {
    'read' => RssArticleReadState.read,
    _ => RssArticleReadState.unread,
  };
}

String rssArticleReadStateValue(RssArticleReadState value) {
  return switch (value) {
    RssArticleReadState.unread => 'unread',
    RssArticleReadState.read => 'read',
  };
}

RssArticleFullContentStatus rssArticleFullContentStatusFromValue(
  String? value,
) {
  return switch ((value ?? '').trim().toLowerCase()) {
    'fetching' => RssArticleFullContentStatus.fetching,
    'fetched' => RssArticleFullContentStatus.fetched,
    'failed' => RssArticleFullContentStatus.failed,
    'skipped' => RssArticleFullContentStatus.skipped,
    _ => RssArticleFullContentStatus.idle,
  };
}

String rssArticleFullContentStatusValue(RssArticleFullContentStatus value) {
  return switch (value) {
    RssArticleFullContentStatus.idle => 'idle',
    RssArticleFullContentStatus.fetching => 'fetching',
    RssArticleFullContentStatus.fetched => 'fetched',
    RssArticleFullContentStatus.failed => 'failed',
    RssArticleFullContentStatus.skipped => 'skipped',
  };
}

class RssArticle {
  const RssArticle({
    required this.id,
    required this.feedId,
    required this.guid,
    required this.link,
    required this.title,
    required this.author,
    required this.summaryHtml,
    required this.contentHtml,
    required this.leadImageUrl,
    required this.publishedTime,
    required this.fetchedTime,
    required this.readState,
    required this.savedMemoUid,
    required this.createdTime,
    required this.updatedTime,
    this.fullContentHtml = '',
    this.fullContentStatus = RssArticleFullContentStatus.idle,
    this.fullContentFetchedTime,
    this.fullContentError,
  });

  final String id;
  final String feedId;
  final String guid;
  final String link;
  final String title;
  final String author;
  final String summaryHtml;
  final String contentHtml;
  final String leadImageUrl;
  final DateTime? publishedTime;
  final DateTime fetchedTime;
  final RssArticleReadState readState;
  final String? savedMemoUid;
  final DateTime createdTime;
  final DateTime updatedTime;
  final String fullContentHtml;
  final RssArticleFullContentStatus fullContentStatus;
  final DateTime? fullContentFetchedTime;
  final String? fullContentError;

  bool get isRead => readState == RssArticleReadState.read;

  String get stableIdentity {
    final normalizedGuid = guid.trim();
    if (normalizedGuid.isNotEmpty) return normalizedGuid;
    final normalizedLink = link.trim();
    if (normalizedLink.isNotEmpty) return normalizedLink;
    return id.trim();
  }

  String get readableHtml {
    final fetched = fullContentHtml.trim();
    if (fetched.isNotEmpty) return fetched;
    final full = contentHtml.trim();
    if (full.isNotEmpty) return full;
    return summaryHtml.trim();
  }

  DateTime get effectiveDisplayTime => publishedTime ?? fetchedTime;

  factory RssArticle.fromDb(Map<String, dynamic> row) {
    return RssArticle(
      id: _readString(row['id']),
      feedId: _readString(row['feed_id']),
      guid: _readString(row['guid']),
      link: _readString(row['link']),
      title: _readString(row['title']),
      author: _readString(row['author']),
      summaryHtml: _readString(row['summary_html']),
      contentHtml: _readString(row['content_html']),
      leadImageUrl: _readString(row['lead_image_url']),
      publishedTime: _readOptionalTime(row['published_time']),
      fetchedTime: _readTime(row['fetched_time']),
      readState: rssArticleReadStateFromValue(row['read_state'] as String?),
      savedMemoUid: _readNullableString(row['saved_memo_uid']),
      createdTime: _readTime(row['created_time']),
      updatedTime: _readTime(row['updated_time']),
      fullContentHtml: _readString(row['full_content_html']),
      fullContentStatus: rssArticleFullContentStatusFromValue(
        row['full_content_status'] as String?,
      ),
      fullContentFetchedTime: _readOptionalTime(
        row['full_content_fetched_time'],
      ),
      fullContentError: _readNullableString(row['full_content_error']),
    );
  }

  RssArticle copyWith({
    String? id,
    String? feedId,
    String? guid,
    String? link,
    String? title,
    String? author,
    String? summaryHtml,
    String? contentHtml,
    String? leadImageUrl,
    Object? publishedTime = _unset,
    DateTime? fetchedTime,
    RssArticleReadState? readState,
    Object? savedMemoUid = _unset,
    DateTime? createdTime,
    DateTime? updatedTime,
    String? fullContentHtml,
    RssArticleFullContentStatus? fullContentStatus,
    Object? fullContentFetchedTime = _unset,
    Object? fullContentError = _unset,
  }) {
    return RssArticle(
      id: id ?? this.id,
      feedId: feedId ?? this.feedId,
      guid: guid ?? this.guid,
      link: link ?? this.link,
      title: title ?? this.title,
      author: author ?? this.author,
      summaryHtml: summaryHtml ?? this.summaryHtml,
      contentHtml: contentHtml ?? this.contentHtml,
      leadImageUrl: leadImageUrl ?? this.leadImageUrl,
      publishedTime: identical(publishedTime, _unset)
          ? this.publishedTime
          : publishedTime as DateTime?,
      fetchedTime: fetchedTime ?? this.fetchedTime,
      readState: readState ?? this.readState,
      savedMemoUid: identical(savedMemoUid, _unset)
          ? this.savedMemoUid
          : savedMemoUid as String?,
      createdTime: createdTime ?? this.createdTime,
      updatedTime: updatedTime ?? this.updatedTime,
      fullContentHtml: fullContentHtml ?? this.fullContentHtml,
      fullContentStatus: fullContentStatus ?? this.fullContentStatus,
      fullContentFetchedTime: identical(fullContentFetchedTime, _unset)
          ? this.fullContentFetchedTime
          : fullContentFetchedTime as DateTime?,
      fullContentError: identical(fullContentError, _unset)
          ? this.fullContentError
          : fullContentError as String?,
    );
  }
}

class RssArticleWithFeed {
  const RssArticleWithFeed({required this.article, required this.feed});

  final RssArticle article;
  final RssFeed feed;
}

const Object _unset = Object();

String _readString(Object? raw) {
  if (raw is String) return raw.trim();
  return raw?.toString().trim() ?? '';
}

String? _readNullableString(Object? raw) {
  final value = _readString(raw);
  return value.isEmpty ? null : value;
}

int _readInt(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw.trim()) ?? 0;
  return 0;
}

DateTime _readTime(Object? raw) {
  return DateTime.fromMillisecondsSinceEpoch(
    _readInt(raw) * 1000,
    isUtc: true,
  ).toLocal();
}

DateTime? _readOptionalTime(Object? raw) {
  if (raw == null) return null;
  final seconds = _readInt(raw);
  if (seconds <= 0) return null;
  return DateTime.fromMillisecondsSinceEpoch(
    seconds * 1000,
    isUtc: true,
  ).toLocal();
}

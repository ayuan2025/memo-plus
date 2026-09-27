enum RssFetchStatus { neverFetched, success, failed }

class RssFeed {
  const RssFeed({
    required this.id,
    required this.feedUrl,
    required this.siteUrl,
    required this.title,
    required this.description,
    required this.iconUrl,
    required this.etag,
    required this.lastModified,
    required this.lastFetchTime,
    required this.lastSuccessTime,
    required this.lastError,
    required this.createdTime,
    required this.updatedTime,
    this.fullContentEnabled = false,
  });

  final String id;
  final String feedUrl;
  final String siteUrl;
  final String title;
  final String description;
  final String iconUrl;
  final String etag;
  final String lastModified;
  final DateTime? lastFetchTime;
  final DateTime? lastSuccessTime;
  final String? lastError;
  final DateTime createdTime;
  final DateTime updatedTime;
  final bool fullContentEnabled;

  String get displayTitle {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isNotEmpty) return trimmedTitle;
    final host = Uri.tryParse(siteUrl.trim())?.host;
    if (host != null && host.isNotEmpty) return host;
    final feedHost = Uri.tryParse(feedUrl.trim())?.host;
    return feedHost?.isNotEmpty == true ? feedHost! : feedUrl.trim();
  }

  RssFetchStatus get fetchStatus {
    if (lastError?.trim().isNotEmpty == true) {
      return RssFetchStatus.failed;
    }
    if (lastSuccessTime != null) {
      return RssFetchStatus.success;
    }
    return RssFetchStatus.neverFetched;
  }

  factory RssFeed.fromDb(Map<String, dynamic> row) {
    return RssFeed(
      id: _readString(row['id']),
      feedUrl: _readString(row['feed_url']),
      siteUrl: _readString(row['site_url']),
      title: _readString(row['title']),
      description: _readString(row['description']),
      iconUrl: _readString(row['icon_url']),
      etag: _readString(row['etag']),
      lastModified: _readString(row['last_modified']),
      lastFetchTime: _readOptionalTime(row['last_fetch_time']),
      lastSuccessTime: _readOptionalTime(row['last_success_time']),
      lastError: _readNullableString(row['last_error']),
      createdTime: _readTime(row['created_time']),
      updatedTime: _readTime(row['updated_time']),
      fullContentEnabled: _readBool(row['full_content_enabled']),
    );
  }

  RssFeed copyWith({
    String? id,
    String? feedUrl,
    String? siteUrl,
    String? title,
    String? description,
    String? iconUrl,
    String? etag,
    String? lastModified,
    Object? lastFetchTime = _unset,
    Object? lastSuccessTime = _unset,
    Object? lastError = _unset,
    DateTime? createdTime,
    DateTime? updatedTime,
    bool? fullContentEnabled,
  }) {
    return RssFeed(
      id: id ?? this.id,
      feedUrl: feedUrl ?? this.feedUrl,
      siteUrl: siteUrl ?? this.siteUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      etag: etag ?? this.etag,
      lastModified: lastModified ?? this.lastModified,
      lastFetchTime: identical(lastFetchTime, _unset)
          ? this.lastFetchTime
          : lastFetchTime as DateTime?,
      lastSuccessTime: identical(lastSuccessTime, _unset)
          ? this.lastSuccessTime
          : lastSuccessTime as DateTime?,
      lastError: identical(lastError, _unset)
          ? this.lastError
          : lastError as String?,
      createdTime: createdTime ?? this.createdTime,
      updatedTime: updatedTime ?? this.updatedTime,
      fullContentEnabled: fullContentEnabled ?? this.fullContentEnabled,
    );
  }
}

class CollectionRssSource {
  const CollectionRssSource({
    required this.collectionId,
    required this.feedId,
    required this.sortOrder,
    required this.createdTime,
    required this.updatedTime,
  });

  final String collectionId;
  final String feedId;
  final int sortOrder;
  final DateTime createdTime;
  final DateTime updatedTime;

  factory CollectionRssSource.fromDb(Map<String, dynamic> row) {
    return CollectionRssSource(
      collectionId: _readString(row['collection_id']),
      feedId: _readString(row['feed_id']),
      sortOrder: _readInt(row['sort_order']),
      createdTime: _readTime(row['created_time']),
      updatedTime: _readTime(row['updated_time']),
    );
  }
}

class CollectionRssSourceWithFeed {
  const CollectionRssSourceWithFeed({required this.source, required this.feed});

  final CollectionRssSource source;
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

bool _readBool(Object? raw) {
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  if (raw is String) {
    final normalized = raw.trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
  return false;
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

enum CollectionArticleFlowStatusFilter { all, unread, read, saved }

class CollectionArticleFlowDateBucket {
  const CollectionArticleFlowDateBucket(this.key);

  final String key;

  DateTime? get date {
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  static CollectionArticleFlowDateBucket fromDate(DateTime date) {
    final local = date.toLocal();
    return CollectionArticleFlowDateBucket(
      '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}',
    );
  }
}

class CollectionArticleFlowProgress {
  const CollectionArticleFlowProgress({
    required this.collectionId,
    required this.statusFilter,
    required this.feedId,
    required this.dateBucketKey,
    required this.currentItemUid,
    required this.listScrollOffset,
    required this.updatedAt,
  });

  static CollectionArticleFlowProgress empty(String collectionId) {
    return CollectionArticleFlowProgress(
      collectionId: collectionId,
      statusFilter: CollectionArticleFlowStatusFilter.all,
      feedId: null,
      dateBucketKey: null,
      currentItemUid: null,
      listScrollOffset: 0,
      updatedAt: DateTime.now(),
    );
  }

  final String collectionId;
  final CollectionArticleFlowStatusFilter statusFilter;
  final String? feedId;
  final String? dateBucketKey;
  final String? currentItemUid;
  final double listScrollOffset;
  final DateTime updatedAt;

  Map<String, Object?> toRow() => <String, Object?>{
    'collection_id': collectionId.trim(),
    'status_filter': statusFilter.name,
    'feed_id': feedId?.trim(),
    'date_bucket': dateBucketKey?.trim(),
    'current_item_uid': currentItemUid?.trim(),
    'list_scroll_offset': listScrollOffset,
    'updated_time': updatedAt.toUtc().millisecondsSinceEpoch,
  };

  factory CollectionArticleFlowProgress.fromRow(Map<String, dynamic> row) {
    return CollectionArticleFlowProgress(
      collectionId: (row['collection_id'] as String? ?? '').trim(),
      statusFilter: _readEnum(
        row['status_filter'],
        CollectionArticleFlowStatusFilter.values,
        CollectionArticleFlowStatusFilter.all,
      ),
      feedId: _readTrimmedString(row['feed_id']),
      dateBucketKey: _readTrimmedString(row['date_bucket']),
      currentItemUid: _readTrimmedString(row['current_item_uid']),
      listScrollOffset: _readDouble(row['list_scroll_offset']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        _readInt(row['updated_time']),
        isUtc: true,
      ).toLocal(),
    );
  }

  CollectionArticleFlowProgress copyWith({
    String? collectionId,
    CollectionArticleFlowStatusFilter? statusFilter,
    Object? feedId = _unset,
    Object? dateBucketKey = _unset,
    Object? currentItemUid = _unset,
    double? listScrollOffset,
    DateTime? updatedAt,
  }) {
    return CollectionArticleFlowProgress(
      collectionId: collectionId ?? this.collectionId,
      statusFilter: statusFilter ?? this.statusFilter,
      feedId: identical(feedId, _unset) ? this.feedId : feedId as String?,
      dateBucketKey: identical(dateBucketKey, _unset)
          ? this.dateBucketKey
          : dateBucketKey as String?,
      currentItemUid: identical(currentItemUid, _unset)
          ? this.currentItemUid
          : currentItemUid as String?,
      listScrollOffset: listScrollOffset ?? this.listScrollOffset,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

const Object _unset = Object();

T _readEnum<T>(Object? raw, List<T> values, T fallback) {
  final name = (raw as String? ?? '').trim();
  for (final value in values) {
    if (value is Enum && value.name == name) {
      return value;
    }
  }
  return fallback;
}

String? _readTrimmedString(Object? raw) {
  final value = (raw as String?)?.trim();
  if (value == null || value.isEmpty) return null;
  return value;
}

int _readInt(Object? raw, [int fallback = 0]) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw.trim()) ?? fallback;
  return fallback;
}

double _readDouble(Object? raw, [double fallback = 0]) {
  if (raw is double) return raw;
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw.trim()) ?? fallback;
  return fallback;
}

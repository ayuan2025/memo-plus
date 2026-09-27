enum MediaCacheCategoryId {
  networkImage,
  flutterImageMemory,
  videoThumbnail,
  imageCompressionTemporary,
}

class MediaCacheCategorySummary {
  const MediaCacheCategorySummary({
    required this.categoryId,
    required this.sizeBytes,
    this.error,
  });

  final MediaCacheCategoryId categoryId;
  final int? sizeBytes;
  final Object? error;

  bool get hasSize => sizeBytes != null;
  bool get hasError => error != null;
}

class MediaCacheSummary {
  const MediaCacheSummary({required this.categories});

  final List<MediaCacheCategorySummary> categories;

  int get totalKnownSizeBytes => categories.fold<int>(
    0,
    (total, category) => total + (category.sizeBytes ?? 0),
  );

  bool get hasUnknownSize => categories.any((category) => !category.hasSize);
  bool get hasFailures => categories.any((category) => category.hasError);
}

class MediaCacheCategoryClearResult {
  const MediaCacheCategoryClearResult({
    required this.categoryId,
    required this.success,
    this.sizeBeforeBytes,
    this.error,
  });

  final MediaCacheCategoryId categoryId;
  final bool success;
  final int? sizeBeforeBytes;
  final Object? error;
}

class MediaCacheClearResult {
  const MediaCacheClearResult({required this.categories});

  final List<MediaCacheCategoryClearResult> categories;

  bool get hasFailures => categories.any((category) => !category.success);
  bool get hasSuccesses => categories.any((category) => category.success);

  bool get isSuccess => hasSuccesses && !hasFailures;
  bool get isPartialFailure => hasSuccesses && hasFailures;
  bool get isFailure => !hasSuccesses && hasFailures;

  int get clearedKnownBytes => categories.fold<int>(
    0,
    (total, category) =>
        total + (category.success ? category.sizeBeforeBytes ?? 0 : 0),
  );
}

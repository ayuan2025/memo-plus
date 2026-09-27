import 'media_cache_maintenance_models.dart';

enum StorageSpaceCategoryId {
  cache,
  noteContent,
  noteImages,
  noteVideos,
  noteAudio,
  noteFiles,
}

class StorageSpaceCategorySummary {
  const StorageSpaceCategorySummary({
    required this.categoryId,
    required this.sizeBytes,
    this.clearable = false,
    this.error,
  });

  final StorageSpaceCategoryId categoryId;
  final int sizeBytes;
  final bool clearable;
  final Object? error;

  bool get hasError => error != null;
}

class DeviceStorageCapacitySummary {
  const DeviceStorageCapacitySummary({
    this.totalBytes,
    this.availableBytes,
    this.error,
  });

  const DeviceStorageCapacitySummary.unavailable([Object? error])
    : this(totalBytes: null, availableBytes: null, error: error);

  final int? totalBytes;
  final int? availableBytes;
  final Object? error;

  bool get hasTotalBytes => totalBytes != null && totalBytes! > 0;
}

class MemoStorageUsageSummary {
  const MemoStorageUsageSummary({
    required this.noteContentBytes,
    required this.noteImageBytes,
    required this.noteVideoBytes,
    required this.noteAudioBytes,
    required this.noteFileBytes,
  });

  const MemoStorageUsageSummary.empty()
    : this(
        noteContentBytes: 0,
        noteImageBytes: 0,
        noteVideoBytes: 0,
        noteAudioBytes: 0,
        noteFileBytes: 0,
      );

  final int noteContentBytes;
  final int noteImageBytes;
  final int noteVideoBytes;
  final int noteAudioBytes;
  final int noteFileBytes;

  int get totalBytes =>
      noteContentBytes +
      noteImageBytes +
      noteVideoBytes +
      noteAudioBytes +
      noteFileBytes;
}

class StorageSpaceSummary {
  const StorageSpaceSummary({
    required this.categories,
    required this.deviceCapacity,
    required this.mediaCacheSummary,
  });

  final List<StorageSpaceCategorySummary> categories;
  final DeviceStorageCapacitySummary deviceCapacity;
  final MediaCacheSummary mediaCacheSummary;

  int get knownUsageBytes =>
      categories.fold<int>(0, (total, category) => total + category.sizeBytes);

  double? get deviceUsageRatio {
    final total = deviceCapacity.totalBytes;
    if (total == null || total <= 0) return null;
    return knownUsageBytes / total;
  }

  StorageSpaceCategorySummary? category(StorageSpaceCategoryId id) {
    for (final category in categories) {
      if (category.categoryId == id) return category;
    }
    return null;
  }
}

class StorageSpaceCacheClearResult {
  const StorageSpaceCacheClearResult({
    required this.isSuccess,
    required this.isPartialFailure,
    required this.isFailure,
    required this.clearedKnownBytes,
  });

  factory StorageSpaceCacheClearResult.fromMediaCacheClearResult(
    MediaCacheClearResult result,
  ) {
    return StorageSpaceCacheClearResult(
      isSuccess: result.isSuccess,
      isPartialFailure: result.isPartialFailure,
      isFailure: result.isFailure,
      clearedKnownBytes: result.clearedKnownBytes,
    );
  }

  final bool isSuccess;
  final bool isPartialFailure;
  final bool isFailure;
  final int clearedKnownBytes;
}

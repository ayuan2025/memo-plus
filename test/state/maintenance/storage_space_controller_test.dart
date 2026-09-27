import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memos_flutter_app/application/maintenance/media_cache_maintenance_models.dart';
import 'package:memos_flutter_app/application/maintenance/storage_space_summary_models.dart';
import 'package:memos_flutter_app/application/maintenance/storage_space_summary_service.dart';
import 'package:memos_flutter_app/state/maintenance/storage_space_controller.dart';

void main() {
  test('loads storage summary on construction', () async {
    final service = _FakeStorageSpaceSummaryService(
      summaries: [_summary(cacheBytes: 1024, noteContentBytes: 512)],
    );
    final controller = StorageSpaceController(service: service);
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.loading, isFalse);
    expect(controller.state.summary?.knownUsageBytes, 1536);
    expect(service.loadCalls, 1);
  });

  test('clear cache records result and refreshes summary', () async {
    final service = _FakeStorageSpaceSummaryService(
      summaries: [
        _summary(cacheBytes: 1024),
        _summary(cacheBytes: 0, noteContentBytes: 10),
      ],
      clearResult: _mediaClearResult(success: true),
    );
    final controller = StorageSpaceController(service: service);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    final result = await controller.clearCache();

    expect(result.isSuccess, isTrue);
    expect(service.clearCalls, 1);
    expect(service.loadCalls, 2);
    expect(controller.state.clearing, isFalse);
    expect(controller.state.summary?.knownUsageBytes, 10);
    expect(controller.state.lastClearResult?.isSuccess, isTrue);
  });

  test('partial failure clear result remains recoverable', () async {
    final service = _FakeStorageSpaceSummaryService(
      summaries: [_summary(cacheBytes: 100), _summary(cacheBytes: 50)],
      clearResult: _mediaClearResult(success: true, failure: true),
    );
    final controller = StorageSpaceController(service: service);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    final result = await controller.clearCache();

    expect(result.isPartialFailure, isTrue);
    expect(controller.state.lastClearResult?.isPartialFailure, isTrue);
    expect(controller.state.loadError, isNull);
  });

  test('load errors are exposed in state', () async {
    final error = StateError('load failed');
    final service = _FakeStorageSpaceSummaryService(
      summaries: const [],
      loadError: error,
    );
    final controller = StorageSpaceController(service: service);
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.loading, isFalse);
    expect(controller.state.loadError, same(error));
  });

  test('provider builds controller from overridable service seam', () async {
    final container = ProviderContainer(
      overrides: [
        storageSpaceSummaryServiceProvider.overrideWithValue(
          _FakeStorageSpaceSummaryService(summaries: [_summary(cacheBytes: 7)]),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(storageSpaceControllerProvider);
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(storageSpaceControllerProvider).summary?.knownUsageBytes,
      7,
    );
  });
}

StorageSpaceSummary _summary({
  required int cacheBytes,
  int noteContentBytes = 0,
}) {
  return StorageSpaceSummary(
    categories: [
      StorageSpaceCategorySummary(
        categoryId: StorageSpaceCategoryId.cache,
        sizeBytes: cacheBytes,
        clearable: true,
      ),
      StorageSpaceCategorySummary(
        categoryId: StorageSpaceCategoryId.noteContent,
        sizeBytes: noteContentBytes,
      ),
      const StorageSpaceCategorySummary(
        categoryId: StorageSpaceCategoryId.noteImages,
        sizeBytes: 0,
      ),
      const StorageSpaceCategorySummary(
        categoryId: StorageSpaceCategoryId.noteVideos,
        sizeBytes: 0,
      ),
      const StorageSpaceCategorySummary(
        categoryId: StorageSpaceCategoryId.noteAudio,
        sizeBytes: 0,
      ),
      const StorageSpaceCategorySummary(
        categoryId: StorageSpaceCategoryId.noteFiles,
        sizeBytes: 0,
      ),
    ],
    deviceCapacity: const DeviceStorageCapacitySummary.unavailable(),
    mediaCacheSummary: const MediaCacheSummary(categories: []),
  );
}

MediaCacheClearResult _mediaClearResult({
  required bool success,
  bool failure = false,
}) {
  return MediaCacheClearResult(
    categories: [
      MediaCacheCategoryClearResult(
        categoryId: MediaCacheCategoryId.networkImage,
        success: success,
        sizeBeforeBytes: success ? 100 : null,
      ),
      if (failure)
        MediaCacheCategoryClearResult(
          categoryId: MediaCacheCategoryId.videoThumbnail,
          success: false,
          error: StateError('clear failed'),
        ),
    ],
  );
}

class _FakeStorageSpaceSummaryService implements StorageSpaceSummaryService {
  _FakeStorageSpaceSummaryService({
    required List<StorageSpaceSummary> summaries,
    MediaCacheClearResult? clearResult,
    Object? loadError,
  }) : _summaries = List<StorageSpaceSummary>.from(summaries),
       _clearResult = clearResult ?? _mediaClearResult(success: true),
       _loadError = loadError;

  final List<StorageSpaceSummary> _summaries;
  final MediaCacheClearResult _clearResult;
  final Object? _loadError;
  int loadCalls = 0;
  int clearCalls = 0;

  @override
  Future<StorageSpaceSummary> loadSummary() async {
    loadCalls += 1;
    final error = _loadError;
    if (error != null) throw error;
    if (_summaries.length > 1) {
      return _summaries.removeAt(0);
    }
    return _summaries.single;
  }

  @override
  Future<MemoStorageUsageSummary> loadMemoUsageSummary() async {
    return const MemoStorageUsageSummary.empty();
  }

  @override
  Future<MediaCacheClearResult> clearCache() async {
    clearCalls += 1;
    return _clearResult;
  }
}

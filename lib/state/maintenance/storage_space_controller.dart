import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/maintenance/storage_space_summary_models.dart';
import '../../application/maintenance/storage_space_summary_service.dart';
import '../system/database_provider.dart';
import '../system/session_provider.dart';
import 'media_cache_maintenance_provider.dart';

final deviceStorageCapacityAdapterProvider =
    Provider<DeviceStorageCapacityAdapter>((ref) {
      return const UnavailableDeviceStorageCapacityAdapter();
    });

final storageSpaceSummaryServiceProvider = Provider<StorageSpaceSummaryService>(
  (ref) {
    final currentKey = ref.watch(
      appSessionProvider.select((state) => state.valueOrNull?.currentKey),
    );
    return StorageSpaceSummaryService(
      database: currentKey == null ? null : ref.watch(databaseProvider),
      mediaCacheMaintenanceService: ref.watch(
        mediaCacheMaintenanceServiceProvider,
      ),
      deviceStorageCapacityAdapter: ref.watch(
        deviceStorageCapacityAdapterProvider,
      ),
    );
  },
);

final storageSpaceControllerProvider =
    StateNotifierProvider<StorageSpaceController, StorageSpaceState>((ref) {
      return StorageSpaceController(
        service: ref.watch(storageSpaceSummaryServiceProvider),
      );
    });

class StorageSpaceState {
  const StorageSpaceState({
    this.summary,
    this.loading = false,
    this.clearing = false,
    this.loadError,
    this.lastClearResult,
  });

  final StorageSpaceSummary? summary;
  final bool loading;
  final bool clearing;
  final Object? loadError;
  final StorageSpaceCacheClearResult? lastClearResult;

  bool get busy => loading || clearing;

  StorageSpaceState copyWith({
    StorageSpaceSummary? summary,
    bool? loading,
    bool? clearing,
    Object? loadError,
    bool clearLoadError = false,
    StorageSpaceCacheClearResult? lastClearResult,
    bool clearLastClearResult = false,
  }) {
    return StorageSpaceState(
      summary: summary ?? this.summary,
      loading: loading ?? this.loading,
      clearing: clearing ?? this.clearing,
      loadError: clearLoadError ? null : loadError ?? this.loadError,
      lastClearResult: clearLastClearResult
          ? null
          : lastClearResult ?? this.lastClearResult,
    );
  }
}

class StorageSpaceController extends StateNotifier<StorageSpaceState> {
  StorageSpaceController({required StorageSpaceSummaryService service})
    : _service = service,
      super(const StorageSpaceState(loading: true)) {
    unawaited(loadSummary());
  }

  final StorageSpaceSummaryService _service;
  Future<StorageSpaceCacheClearResult>? _runningClear;

  Future<void> loadSummary() async {
    state = state.copyWith(loading: true, clearLoadError: true);
    try {
      final summary = await _service.loadSummary();
      if (!mounted) return;
      state = state.copyWith(
        summary: summary,
        loading: false,
        clearLoadError: true,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(loading: false, loadError: error);
    }
  }

  Future<StorageSpaceCacheClearResult> clearCache() async {
    final current = _runningClear;
    if (current != null) {
      throw StateError('A storage cache cleanup is already running.');
    }

    late final Future<StorageSpaceCacheClearResult> operation;
    operation = () async {
      state = state.copyWith(
        clearing: true,
        clearLoadError: true,
        clearLastClearResult: true,
      );
      try {
        final mediaResult = await _service.clearCache();
        final result = StorageSpaceCacheClearResult.fromMediaCacheClearResult(
          mediaResult,
        );
        StorageSpaceSummary? refreshedSummary;
        Object? refreshError;
        try {
          refreshedSummary = await _service.loadSummary();
        } catch (error) {
          refreshError = error;
        }
        if (!mounted) return result;
        state = state.copyWith(
          summary: refreshedSummary,
          clearing: false,
          loadError: refreshError,
          clearLoadError: refreshError == null,
          lastClearResult: result,
        );
        return result;
      } catch (error) {
        if (mounted) {
          state = state.copyWith(clearing: false, loadError: error);
        }
        rethrow;
      } finally {
        if (identical(_runningClear, operation)) {
          _runningClear = null;
        }
      }
    }();
    _runningClear = operation;
    return operation;
  }
}

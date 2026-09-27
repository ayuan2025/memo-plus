import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/sync/local_library_import_migration_service.dart';
import '../../data/logs/log_manager.dart';
import '../../data/models/local_library.dart';
import '../../data/repositories/local_library_repository.dart';
import '../../core/storage_read.dart';
import 'session_provider.dart';
import 'storage_error_provider.dart';

final localLibraryRepositoryProvider = Provider<LocalLibraryRepository>((ref) {
  return LocalLibraryRepository(ref.watch(secureStorageProvider));
});

final localLibrariesLoadedProvider = StateProvider<bool>((ref) => false);

final localLibrariesProvider =
    StateNotifierProvider<LocalLibrariesController, List<LocalLibrary>>((ref) {
      final loadedState = ref.read(localLibrariesLoadedProvider.notifier);
      Future.microtask(() => loadedState.state = false);
      return LocalLibrariesController(
        ref.watch(localLibraryRepositoryProvider),
        ref,
        onLoaded: () => loadedState.state = true,
      );
    });

class LocalLibrariesController extends StateNotifier<List<LocalLibrary>> {
  LocalLibrariesController(this._repo, this._ref, {void Function()? onLoaded})
    : _onLoaded = onLoaded,
      super(const []) {
    _loadFromStorage();
  }

  final LocalLibraryRepository _repo;
  final Ref _ref;
  final void Function()? _onLoaded;
  final _migrationService = LocalLibraryImportMigrationService();
  Future<void> _writeChain = Future<void>.value();

  Future<void> reloadFromStorage() async {
    await _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    if (kDebugMode) {
      LogManager.instance.info('LocalLibrary: load_start');
    }
    final stateBeforeLoad = state;
    final result = await _repo.readWithStatus();
    if (!mounted) return;
    if (!identical(state, stateBeforeLoad)) {
      if (kDebugMode) {
        LogManager.instance.info(
          'LocalLibrary: load_skip_state_changed',
          context: {'currentCount': state.length},
        );
      }
      _onLoaded?.call();
      return;
    }
    if (result.isError) {
      final error = StorageLoadError(
        source: 'local_library',
        error: result.error!,
        stackTrace: result.stackTrace ?? StackTrace.current,
      );
      LogManager.instance.error(
        'Failed to load local library state.',
        error: error.error,
        stackTrace: error.stackTrace,
      );
      // Keep previous state on error.
      _setStorageError(error);
      _onLoaded?.call();
      return;
    }
    _setStorageError(null);
    if (result.isEmpty) {
      state = const [];
      _onLoaded?.call();
      return;
    }
    final migratedLibraries = await _migrateLibrariesIfNeeded(
      result.data!.libraries,
    );
    if (!mounted) return;
    state = migratedLibraries;
    if (kDebugMode) {
      LogManager.instance.info(
        'LocalLibrary: load_complete',
        context: {'libraryCount': state.length},
      );
    }
    _onLoaded?.call();
  }

  void _setStorageError(StorageLoadError? error) {
    _ref.read(localLibraryStorageErrorProvider.notifier).state = error;
  }

  void upsert(LocalLibrary library) {
    final key = library.key.trim();
    if (key.isEmpty) return;
    final beforeCount = state.length;
    final next = [...state];
    final index = next.indexWhere((l) => l.key == key);
    final now = DateTime.now();
    final updated = library.copyWith(
      createdAt: library.createdAt ?? now,
      updatedAt: now,
    );
    if (index >= 0) {
      next[index] = updated;
    } else {
      next.add(updated);
    }
    state = next;
    if (kDebugMode) {
      LogManager.instance.info(
        'LocalLibrary: upsert',
        context: {
          'key': key,
          'beforeCount': beforeCount,
          'afterCount': next.length,
          'updatedExisting': index >= 0,
        },
      );
    }
    _persist(next);
  }

  Future<void> remove(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return;
    final next = state.where((l) => l.key != trimmed).toList(growable: false);
    state = next;
    await _persistAndWait(next);
  }

  void _persist(List<LocalLibrary> libraries) {
    _writeChain = _writeChain.then(
      (_) => _repo.write(LocalLibraryState(libraries: libraries)),
    );
  }

  Future<void> _persistAndWait(List<LocalLibrary> libraries) {
    _persist(libraries);
    return _writeChain;
  }

  Future<List<LocalLibrary>> _migrateLibrariesIfNeeded(
    List<LocalLibrary> libraries,
  ) async {
    var changed = false;
    final migrated = <LocalLibrary>[];
    for (final library in libraries) {
      try {
        final next = await _migrationService.migrateIfNeeded(library);
        if (next.storageKind != library.storageKind ||
            next.rootPath != library.rootPath ||
            next.treeUri != library.treeUri) {
          changed = true;
        }
        migrated.add(next);
      } catch (error, stackTrace) {
        migrated.add(library);
        LogManager.instance.warn(
          'LocalLibrary: migration_failed',
          context: <String, Object?>{'key': library.key},
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    if (changed) {
      await _repo.write(LocalLibraryState(libraries: migrated));
    }
    return migrated;
  }
}

final currentLocalLibraryProvider = Provider<LocalLibrary?>((ref) {
  final key = ref.watch(
    appSessionProvider.select((s) => s.valueOrNull?.currentKey),
  );
  if (key == null || key.trim().isEmpty) return null;
  final libraries = ref.watch(localLibrariesProvider);
  for (final library in libraries) {
    if (library.key == key) return library;
  }
  return null;
});

final isLocalLibraryModeProvider = Provider<bool>((ref) {
  return ref.watch(currentLocalLibraryProvider) != null;
});

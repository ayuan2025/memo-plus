import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage_read.dart';

final appSessionStorageErrorProvider =
    StateProvider<StorageLoadError?>((ref) => null);

final legacyAppPreferencesStorageErrorProvider =
    StateProvider<StorageLoadError?>((ref) => null);

final devicePreferencesStorageErrorProvider =
    StateProvider<StorageLoadError?>((ref) => null);

final workspacePreferencesStorageErrorProvider =
    StateProvider<StorageLoadError?>((ref) => null);

final appPreferencesStorageErrorProvider = Provider<StorageLoadError?>((ref) {
  return ref.watch(legacyAppPreferencesStorageErrorProvider) ??
      ref.watch(devicePreferencesStorageErrorProvider) ??
      ref.watch(workspacePreferencesStorageErrorProvider);
});

final localLibraryStorageErrorProvider =
    StateProvider<StorageLoadError?>((ref) => null);

final storageLoadErrorProvider = Provider<StorageLoadError?>((ref) {
  return ref.watch(appSessionStorageErrorProvider) ??
      ref.watch(appPreferencesStorageErrorProvider) ??
      ref.watch(localLibraryStorageErrorProvider);
});

final storageLoadHasErrorProvider = Provider<bool>((ref) {
  return ref.watch(storageLoadErrorProvider) != null;
});

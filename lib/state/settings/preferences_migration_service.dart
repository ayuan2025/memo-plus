import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/debug_ephemeral_storage.dart';
import '../../core/hash.dart';
import '../../core/storage_read.dart';
import '../../data/logs/log_manager.dart';
import '../../data/models/app_preferences.dart';
import '../../data/models/device_preferences.dart';
import '../../data/models/workspace_preferences.dart';
import '../system/session_provider.dart';

const devicePreferencesStorageKey = 'device_preferences_v1';
const workspacePreferencesStoragePrefix = 'workspace_preferences_v1_';
const legacyAppPreferencesDeviceKey = 'app_preferences_device_v1';
const legacyAppPreferencesStoragePrefix = 'app_preferences_v2_';
const legacyAppPreferencesGlobalKey = 'app_preferences_v1';

final preferencesMigrationServiceProvider = Provider<PreferencesMigrationService>(
  (ref) {
    return PreferencesMigrationService(ref.watch(secureStorageProvider));
  },
);

class PreferencesMigrationService {
  PreferencesMigrationService(this._storage);

  static const _kFallbackFilePrefix = 'memoflow_prefs_';

  final FlutterSecureStorage _storage;

  String workspaceStorageKey(String workspaceKey) =>
      '$workspacePreferencesStoragePrefix$workspaceKey';

  String legacyWorkspaceStorageKey(String workspaceKey) =>
      '$legacyAppPreferencesStoragePrefix$workspaceKey';

  Future<StorageReadResult<DevicePreferences>> readDeviceWithStatus() async {
    final current = await _readTypedWithStatus<DevicePreferences>(
      devicePreferencesStorageKey,
      DevicePreferences.fromJson,
    );
    if (current.isError) {
      return StorageReadResult.failure(
        cause: current.error!,
        stackTrace: current.stackTrace ?? StackTrace.current,
      );
    }
    final currentValue = current.data;
    if (currentValue != null) {
      await writeDevice(currentValue);
      return StorageReadResult.success(currentValue);
    }

    final legacy = await _readLegacyDevice();
    if (legacy != null) {
      await writeDevice(legacy);
      return StorageReadResult.success(legacy);
    }
    return StorageReadResult.success(DevicePreferences.defaults);
  }

  Future<DevicePreferences> readDevice() async {
    final result = await readDeviceWithStatus();
    return result.data ?? DevicePreferences.defaults;
  }

  Future<void> writeDevice(DevicePreferences prefs) async {
    await _safeStorageWrite(
      devicePreferencesStorageKey,
      jsonEncode(prefs.toJson()),
    );
    await _writeFallback(devicePreferencesStorageKey, prefs.toJson());
  }

  Future<StorageReadResult<WorkspacePreferences>> readWorkspaceWithStatus(
    String? workspaceKey,
  ) async {
    final normalizedKey = workspaceKey?.trim();
    if (normalizedKey == null || normalizedKey.isEmpty) {
      return StorageReadResult.success(WorkspacePreferences.defaults);
    }

    final current = await _readTypedWithStatus<WorkspacePreferences>(
      workspaceStorageKey(normalizedKey),
      WorkspacePreferences.fromJson,
    );
    if (current.isError) {
      return StorageReadResult.failure(
        cause: current.error!,
        stackTrace: current.stackTrace ?? StackTrace.current,
      );
    }
    final currentValue = current.data;
    if (currentValue != null) {
      await writeWorkspace(normalizedKey, currentValue);
      return StorageReadResult.success(currentValue);
    }

    final legacy = await _readLegacyWorkspace(normalizedKey);
    if (legacy != null) {
      await writeWorkspace(normalizedKey, legacy);
      return StorageReadResult.success(legacy);
    }
    return StorageReadResult.success(WorkspacePreferences.defaults);
  }

  Future<WorkspacePreferences> readWorkspace(String? workspaceKey) async {
    final result = await readWorkspaceWithStatus(workspaceKey);
    return result.data ?? WorkspacePreferences.defaults;
  }

  Future<void> writeWorkspace(
    String? workspaceKey,
    WorkspacePreferences prefs,
  ) async {
    final normalizedKey = workspaceKey?.trim();
    if (normalizedKey == null || normalizedKey.isEmpty) return;
    final key = workspaceStorageKey(normalizedKey);
    await _safeStorageWrite(key, jsonEncode(prefs.toJson()));
    await _writeFallback(key, prefs.toJson());
  }

  Future<void> migrateKnownWorkspaces(Iterable<String?> workspaceKeys) async {
    await readDeviceWithStatus();
    final seen = <String>{};
    for (final key in workspaceKeys) {
      final normalizedKey = key?.trim();
      if (normalizedKey == null || normalizedKey.isEmpty) continue;
      if (!seen.add(normalizedKey)) continue;
      await readWorkspaceWithStatus(normalizedKey);
    }
  }

  Future<DevicePreferences?> _readLegacyDevice() async {
    final deviceLegacy = await _readTypedWithStatus<AppPreferences>(
      legacyAppPreferencesDeviceKey,
      AppPreferences.fromJson,
    );
    if (deviceLegacy.isError) return null;
    final direct = deviceLegacy.data;
    if (direct != null) {
      return DevicePreferences.fromLegacy(direct);
    }

    final globalLegacy = await _readTypedWithStatus<AppPreferences>(
      legacyAppPreferencesGlobalKey,
      AppPreferences.fromJson,
    );
    if (globalLegacy.isError) return null;
    final global = globalLegacy.data;
    if (global != null) {
      return DevicePreferences.fromLegacy(global);
    }

    return null;
  }

  Future<WorkspacePreferences?> _readLegacyWorkspace(String workspaceKey) async {
    final directLegacy = await _readTypedWithStatus<AppPreferences>(
      legacyWorkspaceStorageKey(workspaceKey),
      AppPreferences.fromJson,
    );
    if (directLegacy.isError) return null;
    final direct = directLegacy.data;
    if (direct != null) {
      return WorkspacePreferences.fromLegacy(direct, workspaceKey: workspaceKey);
    }

    final globalLegacy = await _readTypedWithStatus<AppPreferences>(
      legacyAppPreferencesGlobalKey,
      AppPreferences.fromJson,
    );
    if (globalLegacy.isError) return null;
    final global = globalLegacy.data;
    if (global != null) {
      return WorkspacePreferences.fromLegacy(global, workspaceKey: workspaceKey);
    }

    return null;
  }

  Future<StorageReadResult<T?>> _readTypedWithStatus<T>(
    String key,
    T Function(Map<String, dynamic>) parser,
  ) async {
    final raw = await _storageReadWithStatus(key);
    if (raw.isError) {
      return StorageReadResult.failure(
        cause: raw.error!,
        stackTrace: raw.stackTrace ?? StackTrace.current,
      );
    }
    if (!raw.isEmpty) {
      try {
        final decoded = jsonDecode(raw.data!);
        if (decoded is Map) {
          return StorageReadResult.success(
            parser(decoded.cast<String, dynamic>()),
          );
        }
      } catch (error, stackTrace) {
        LogManager.instance.warn(
          'Failed to parse preferences payload from secure storage.',
          error: error,
          stackTrace: stackTrace,
          context: <String, Object?>{'key': key},
        );
      }
    }

    final fallback = await _readFallbackJson(key);
    if (fallback != null) {
      try {
        final parsed = parser(fallback);
        await _safeStorageWrite(key, jsonEncode(fallback));
        return StorageReadResult.success(parsed);
      } catch (error, stackTrace) {
        LogManager.instance.warn(
          'Failed to parse preferences fallback payload.',
          error: error,
          stackTrace: stackTrace,
          context: <String, Object?>{'key': key},
        );
      }
    }

    if (!raw.isEmpty) {
      return StorageReadResult.failure(
        cause: FormatException('Invalid preferences payload for $key'),
        stackTrace: StackTrace.current,
      );
    }

    return StorageReadResult.success(null);
  }

  Future<StorageReadResult<String?>> _storageReadWithStatus(String key) async {
    try {
      final raw = await _storage.read(key: key);
      if (raw == null || raw.trim().isEmpty) {
        return StorageReadResult.empty();
      }
      return StorageReadResult.success(raw);
    } catch (error, stackTrace) {
      LogManager.instance.warn(
        'Secure storage read failed in preferences migration service.',
        error: error,
        stackTrace: stackTrace,
        context: <String, Object?>{'key': key},
      );
      return StorageReadResult.failure(cause: error, stackTrace: stackTrace);
    }
  }

  Future<void> _safeStorageWrite(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (error, stackTrace) {
      LogManager.instance.warn(
        'Secure storage write failed in preferences migration service.',
        error: error,
        stackTrace: stackTrace,
        context: <String, Object?>{'key': key},
      );
    }
  }

  Future<File?> _fallbackFileForKey(String key) async {
    try {
      final dir = await resolveAppSupportDirectory();
      final safe = fnv1a64Hex(key);
      return File('${dir.path}/$_kFallbackFilePrefix$safe.json');
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _readFallbackJson(String key) async {
    final file = await _fallbackFileForKey(key);
    if (file == null) return null;
    try {
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.cast<String, dynamic>();
      }
    } catch (_) {}
    return null;
  }

  Future<void> _writeFallback(String key, Map<String, dynamic> json) async {
    final file = await _fallbackFileForKey(key);
    if (file == null) return;
    try {
      await file.writeAsString(jsonEncode(json));
    } catch (_) {}
  }
}

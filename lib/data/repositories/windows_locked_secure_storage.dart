import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;

import '../../core/debug_ephemeral_storage.dart';
import '../../core/desktop_runtime_role.dart';
import '../../data/logs/log_manager.dart';
import 'queued_secure_storage.dart';

class SecureStorageLockTimeoutException implements Exception {
  const SecureStorageLockTimeoutException({
    required this.operation,
    required this.waited,
  });

  final String operation;
  final Duration waited;

  @override
  String toString() {
    return 'SecureStorageLockTimeoutException(operation=$operation, waited=${waited.inMilliseconds}ms)';
  }
}

class WindowsLockedQueuedFlutterSecureStorage
    extends QueuedFlutterSecureStorage {
  WindowsLockedQueuedFlutterSecureStorage({
    required this.runtimeRole,
    super.iOptions = IOSOptions.defaultOptions,
    super.aOptions = AndroidOptions.defaultOptions,
    super.lOptions = LinuxOptions.defaultOptions,
    super.wOptions = WindowsOptions.defaultOptions,
    super.webOptions = WebOptions.defaultOptions,
    super.mOptions = MacOsOptions.defaultOptions,
  });

  final DesktopRuntimeRole runtimeRole;

  static const Duration lockWaitTimeout = Duration(seconds: 5);
  static const Duration lockRetryDelay = Duration(milliseconds: 100);
  static const Duration staleLockAge = Duration(seconds: 30);

  @visibleForTesting
  static Future<Directory> Function() resolveAppSupportDirectoryForLock =
      resolveAppSupportDirectory;

  @visibleForTesting
  static DateTime Function() now = DateTime.now;

  @protected
  Future<T> withCrossProcessLock<T>({
    required String operation,
    required Future<T> Function() action,
    String? key,
  }) async {
    final startedAt = now();
    while (true) {
      final lease = await _tryAcquireLease(operation: operation, key: key);
      if (lease != null) {
        final waitMs = now().difference(startedAt).inMilliseconds;
        if (waitMs >= lockRetryDelay.inMilliseconds) {
          LogManager.instance.debug(
            'SecureStorage: lock_waited',
            context: <String, Object?>{
              'runtimeRole': runtimeRole.logName,
              'operation': operation,
              'waitMs': waitMs,
              if (key != null && key.trim().isNotEmpty) 'key': _maskKey(key),
            },
          );
        }
        try {
          return await action();
        } finally {
          await lease.release();
        }
      }

      final waited = now().difference(startedAt);
      if (waited >= lockWaitTimeout) {
        LogManager.instance.warn(
          'SecureStorage: lock_timeout',
          context: <String, Object?>{
            'runtimeRole': runtimeRole.logName,
            'operation': operation,
            'waitMs': waited.inMilliseconds,
            'timeout': lockWaitTimeout.inMilliseconds,
            if (key != null && key.trim().isNotEmpty) 'key': _maskKey(key),
          },
        );
        throw SecureStorageLockTimeoutException(
          operation: operation,
          waited: waited,
        );
      }

      await Future<void>.delayed(lockRetryDelay);
    }
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) {
    return enqueueTask(
      () => withCrossProcessLock<void>(
        operation: 'write',
        key: key,
        action: () => rawWrite(
          key: key,
          value: value,
          iOptions: iOptions,
          aOptions: aOptions,
          lOptions: lOptions,
          webOptions: webOptions,
          mOptions: mOptions,
          wOptions: wOptions,
        ),
      ),
    );
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) {
    return enqueueTask(
      () => withCrossProcessLock<String?>(
        operation: 'read',
        key: key,
        action: () => rawRead(
          key: key,
          iOptions: iOptions,
          aOptions: aOptions,
          lOptions: lOptions,
          webOptions: webOptions,
          mOptions: mOptions,
          wOptions: wOptions,
        ),
      ),
    );
  }

  @override
  Future<bool> containsKey({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) {
    return enqueueTask(
      () => withCrossProcessLock<bool>(
        operation: 'containsKey',
        key: key,
        action: () => rawContainsKey(
          key: key,
          iOptions: iOptions,
          aOptions: aOptions,
          lOptions: lOptions,
          webOptions: webOptions,
          mOptions: mOptions,
          wOptions: wOptions,
        ),
      ),
    );
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) {
    return enqueueTask(
      () => withCrossProcessLock<void>(
        operation: 'delete',
        key: key,
        action: () => rawDelete(
          key: key,
          iOptions: iOptions,
          aOptions: aOptions,
          lOptions: lOptions,
          webOptions: webOptions,
          mOptions: mOptions,
          wOptions: wOptions,
        ),
      ),
    );
  }

  @override
  Future<Map<String, String>> readAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) {
    return enqueueTask(
      () => withCrossProcessLock<Map<String, String>>(
        operation: 'readAll',
        action: () => rawReadAll(
          iOptions: iOptions,
          aOptions: aOptions,
          lOptions: lOptions,
          webOptions: webOptions,
          mOptions: mOptions,
          wOptions: wOptions,
        ),
      ),
    );
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) {
    return enqueueTask(
      () => withCrossProcessLock<void>(
        operation: 'deleteAll',
        action: () => rawDeleteAll(
          iOptions: iOptions,
          aOptions: aOptions,
          lOptions: lOptions,
          webOptions: webOptions,
          mOptions: mOptions,
          wOptions: wOptions,
        ),
      ),
    );
  }

  Future<_SecureStorageLockLease?> _tryAcquireLease({
    required String operation,
    String? key,
  }) async {
    final lockFile = await _lockFile();
    try {
      await lockFile.create(recursive: true, exclusive: true);
      final payload = jsonEncode(<String, Object?>{
        'runtimeRole': runtimeRole.logName,
        'operation': operation,
        'acquiredAt': now().toIso8601String(),
        if (key != null && key.trim().isNotEmpty) 'key': _maskKey(key),
      });
      await lockFile.writeAsString(payload, flush: true);
      return _SecureStorageLockLease(lockFile);
    } on PathExistsException {
      await _tryDeleteStaleLock(lockFile);
      return null;
    } on FileSystemException catch (error) {
      if (await lockFile.exists()) {
        await _tryDeleteStaleLock(lockFile);
        return null;
      }
      LogManager.instance.warn(
        'SecureStorage: lock_acquire_failed',
        error: error,
        context: <String, Object?>{
          'runtimeRole': runtimeRole.logName,
          'operation': operation,
          if (key != null && key.trim().isNotEmpty) 'key': _maskKey(key),
        },
      );
      rethrow;
    }
  }

  Future<File> _lockFile() async {
    final base = await resolveAppSupportDirectoryForLock();
    final dir = Directory(p.join(base.path, 'secure_storage'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return File(p.join(dir.path, 'windows_secure_storage.lock'));
  }

  Future<void> _tryDeleteStaleLock(File file) async {
    try {
      if (!await file.exists()) return;
      final stat = await file.stat();
      final modified = stat.modified;
      final age = now().difference(modified);
      if (age < staleLockAge) {
        return;
      }
      await file.delete();
      LogManager.instance.warn(
        'SecureStorage: stale_lock_deleted',
        context: <String, Object?>{
          'runtimeRole': runtimeRole.logName,
          'ageMs': age.inMilliseconds,
        },
      );
    } catch (_) {}
  }

  static String _maskKey(String key) {
    final trimmed = key.trim();
    if (trimmed.length <= 8) {
      return trimmed.isEmpty
          ? trimmed
          : '${trimmed[0]}***${trimmed[trimmed.length - 1]}';
    }
    return '${trimmed.substring(0, 4)}***${trimmed.substring(trimmed.length - 4)}';
  }
}

class _SecureStorageLockLease {
  _SecureStorageLockLease(this._file);

  final File _file;

  Future<void> release() async {
    try {
      if (await _file.exists()) {
        await _file.delete();
      }
    } catch (_) {}
  }
}

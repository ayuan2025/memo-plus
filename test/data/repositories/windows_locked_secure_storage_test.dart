import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/desktop_runtime_role.dart';
import 'package:memos_flutter_app/data/repositories/windows_locked_secure_storage.dart';

class _TestWindowsLockedSecureStorage
    extends WindowsLockedQueuedFlutterSecureStorage {
  _TestWindowsLockedSecureStorage({required super.runtimeRole});

  Future<T> runLocked<T>({
    required String operation,
    required Future<T> Function() action,
    String? key,
  }) {
    return withCrossProcessLock(operation: operation, action: action, key: key);
  }
}

void main() {
  late Directory tempDir;
  late Future<Directory> Function() originalResolveDirectory;
  late DateTime Function() originalNow;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('secure-storage-lock-test');
    originalResolveDirectory = WindowsLockedQueuedFlutterSecureStorage
        .resolveAppSupportDirectoryForLock;
    originalNow = WindowsLockedQueuedFlutterSecureStorage.now;
    WindowsLockedQueuedFlutterSecureStorage.resolveAppSupportDirectoryForLock =
        () async => tempDir;
    WindowsLockedQueuedFlutterSecureStorage.now = DateTime.now;
  });

  tearDown(() async {
    WindowsLockedQueuedFlutterSecureStorage.resolveAppSupportDirectoryForLock =
        originalResolveDirectory;
    WindowsLockedQueuedFlutterSecureStorage.now = originalNow;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('serializes lock acquisition across instances', () async {
    final first = _TestWindowsLockedSecureStorage(
      runtimeRole: DesktopRuntimeRole.mainApp,
    );
    final second = _TestWindowsLockedSecureStorage(
      runtimeRole: DesktopRuntimeRole.desktopSettings,
    );
    final steps = <String>[];
    final releaseFirst = Completer<void>();

    final firstFuture = first.runLocked<void>(
      operation: 'write',
      key: 'session',
      action: () async {
        steps.add('first:start');
        await releaseFirst.future;
        steps.add('first:end');
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));

    final secondFuture = second.runLocked<void>(
      operation: 'read',
      key: 'session',
      action: () async {
        steps.add('second:start');
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(steps, <String>['first:start']);

    releaseFirst.complete();
    await firstFuture;
    await secondFuture;

    expect(steps, <String>['first:start', 'first:end', 'second:start']);
  });

  test('times out when lock stays held', () async {
    final lockDir = Directory(
      '${tempDir.path}${Platform.pathSeparator}secure_storage',
    )..createSync(recursive: true);
    final lockFile = File(
      '${lockDir.path}${Platform.pathSeparator}windows_secure_storage.lock',
    )..writeAsStringSync('held');

    var tick = 0;
    WindowsLockedQueuedFlutterSecureStorage.now = () {
      tick += 1;
      return DateTime(2026, 1, 1).add(Duration(seconds: tick * 6));
    };

    final storage = _TestWindowsLockedSecureStorage(
      runtimeRole: DesktopRuntimeRole.desktopQuickInput,
    );

    await expectLater(
      () => storage.runLocked<void>(
        operation: 'read',
        key: 'session',
        action: () async {},
      ),
      throwsA(isA<SecureStorageLockTimeoutException>()),
    );

    expect(lockFile.existsSync(), isTrue);
  });
}

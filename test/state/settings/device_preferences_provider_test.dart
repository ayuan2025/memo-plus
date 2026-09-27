import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/application/sync/sync_coordinator.dart';
import 'package:memos_flutter_app/application/sync/sync_error.dart';
import 'package:memos_flutter_app/application/sync/sync_request.dart';
import 'package:memos_flutter_app/application/sync/sync_types.dart';
import 'package:memos_flutter_app/application/sync/webdav_backup_service.dart';
import 'package:memos_flutter_app/application/sync/webdav_sync_service.dart';
import 'package:memos_flutter_app/core/storage_read.dart';
import 'package:memos_flutter_app/data/models/app_preferences.dart';
import 'package:memos_flutter_app/data/models/device_preferences.dart';
import 'package:memos_flutter_app/data/models/local_library.dart';
import 'package:memos_flutter_app/data/models/webdav_backup.dart';
import 'package:memos_flutter_app/data/models/webdav_export_status.dart';
import 'package:memos_flutter_app/data/models/webdav_settings.dart';
import 'package:memos_flutter_app/data/models/webdav_sync_meta.dart';
import 'package:memos_flutter_app/state/settings/device_preferences_provider.dart';
import 'package:memos_flutter_app/state/settings/preferences_migration_service.dart';
import 'package:memos_flutter_app/state/sync/sync_coordinator_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'acceptLegalDocuments waits for persistence before updating state',
    () async {
      final repo = _TestDevicePreferencesRepository(
        DevicePreferences.defaultsForLanguage(AppLanguage.en),
      );
      final writeCompleter = Completer<void>();
      repo.writeBlockers.add(writeCompleter);

      final container = _buildContainer(repo);
      addTearDown(container.dispose);

      final notifier = container.read(devicePreferencesProvider.notifier);
      await notifier.reloadFromStorage();

      final acceptFuture = notifier.acceptLegalDocuments(
        hash: 'legal-hash',
        appVersion: '1.0.27',
      );

      expect(
        container.read(devicePreferencesProvider).acceptedLegalDocumentsHash,
        isEmpty,
      );

      writeCompleter.complete();
      await acceptFuture;

      final prefs = container.read(devicePreferencesProvider);
      expect(prefs.acceptedLegalDocumentsHash, 'legal-hash');
      expect(prefs.lastSeenAppVersion, '1.0.27');
      expect(repo.stored.acceptedLegalDocumentsHash, 'legal-hash');
    },
  );

  test(
    'acceptLegalDocuments keeps consent blocked when persistence verification fails',
    () async {
      final repo = _TestDevicePreferencesRepository(
        DevicePreferences.defaultsForLanguage(AppLanguage.en),
      )..persistAcceptedHash = false;

      final container = _buildContainer(repo);
      addTearDown(container.dispose);

      final notifier = container.read(devicePreferencesProvider.notifier);
      await notifier.reloadFromStorage();

      await expectLater(
        notifier.acceptLegalDocuments(hash: 'legal-hash', appVersion: '1.0.27'),
        throwsA(isA<StateError>()),
      );

      final prefs = container.read(devicePreferencesProvider);
      expect(prefs.acceptedLegalDocumentsHash, isEmpty);
      expect(repo.stored.acceptedLegalDocumentsHash, isEmpty);
    },
  );

  test(
    'deferred device preference writes keep legal consent when queued during acceptance',
    () async {
      final repo = _TestDevicePreferencesRepository(
        DevicePreferences.defaultsForLanguage(AppLanguage.en),
      );
      final writeCompleter = Completer<void>();
      repo.writeBlockers.add(writeCompleter);

      final container = _buildContainer(repo);
      addTearDown(container.dispose);

      final notifier = container.read(devicePreferencesProvider.notifier);
      await notifier.reloadFromStorage();

      final acceptFuture = notifier.acceptLegalDocuments(
        hash: 'legal-hash',
        appVersion: '1.0.27',
      );
      notifier.setLastSeenNoticeHash('notice-hash');

      expect(
        container.read(devicePreferencesProvider).acceptedLegalDocumentsHash,
        isEmpty,
      );
      expect(
        container.read(devicePreferencesProvider).lastSeenNoticeHash,
        isEmpty,
      );

      writeCompleter.complete();
      await acceptFuture;
      await notifier.waitForPendingWrites();

      final prefs = container.read(devicePreferencesProvider);
      expect(prefs.acceptedLegalDocumentsHash, 'legal-hash');
      expect(prefs.lastSeenNoticeHash, 'notice-hash');
      expect(repo.stored.acceptedLegalDocumentsHash, 'legal-hash');
      expect(repo.stored.lastSeenNoticeHash, 'notice-hash');
      expect(repo.writeSnapshots, hasLength(2));
      expect(
        repo.writeSnapshots.first.acceptedLegalDocumentsHash,
        'legal-hash',
      );
      expect(repo.writeSnapshots.first.lastSeenNoticeHash, isEmpty);
      expect(repo.writeSnapshots.last.acceptedLegalDocumentsHash, 'legal-hash');
      expect(repo.writeSnapshots.last.lastSeenNoticeHash, 'notice-hash');
    },
  );

  test('setSeenNoticeRevision updates state and persists', () async {
    final repo = _TestDevicePreferencesRepository(
      DevicePreferences.defaultsForLanguage(AppLanguage.en),
    );

    final container = _buildContainer(repo);
    addTearDown(container.dispose);

    final notifier = container.read(devicePreferencesProvider.notifier);
    await notifier.reloadFromStorage();

    notifier.setSeenNoticeRevision(id: 'notice-1', revision: 2);
    await notifier.waitForPendingWrites();

    final prefs = container.read(devicePreferencesProvider);
    expect(prefs.seenNoticeRevisions, {'notice-1': 2});
    expect(repo.stored.seenNoticeRevisions, {'notice-1': 2});
  });

  test('setDesktopHomeLayoutPreference updates state and persists', () async {
    final repo = _TestDevicePreferencesRepository(
      DevicePreferences.defaultsForLanguage(AppLanguage.en),
    );

    final container = _buildContainer(repo);
    addTearDown(container.dispose);

    final notifier = container.read(devicePreferencesProvider.notifier);
    await notifier.reloadFromStorage();

    notifier.setDesktopHomeLayoutPreference(
      const DesktopHomeLayoutPreference(
        navMode: DesktopHomeNavPreference.rail,
        secondaryPaneVisible: false,
        secondaryPaneWidth: 404,
      ),
    );
    await notifier.waitForPendingWrites();

    final prefs = container.read(devicePreferencesProvider);
    expect(
      prefs.desktopHomeLayoutPreference.navMode,
      DesktopHomeNavPreference.rail,
    );
    expect(prefs.desktopHomeLayoutPreference.secondaryPaneVisible, isFalse);
    expect(prefs.desktopHomeLayoutPreference.secondaryPaneWidth, 404);
    expect(repo.writeSnapshots, isNotEmpty);
    expect(
      repo.stored.desktopHomeLayoutPreference.navMode,
      DesktopHomeNavPreference.rail,
    );
  });

  test('setMacosCloseToMenuBar updates state and persists', () async {
    final repo = _TestDevicePreferencesRepository(
      DevicePreferences.defaultsForLanguage(
        AppLanguage.en,
      ).copyWith(windowsCloseToTray: true),
    );

    final container = _buildContainer(repo);
    addTearDown(container.dispose);

    final notifier = container.read(devicePreferencesProvider.notifier);
    await notifier.reloadFromStorage();

    notifier.setMacosCloseToMenuBar(false);
    await notifier.waitForPendingWrites();

    final prefs = container.read(devicePreferencesProvider);
    expect(prefs.macosCloseToMenuBar, isFalse);
    expect(prefs.windowsCloseToTray, isTrue);
    expect(repo.stored.macosCloseToMenuBar, isFalse);
    expect(repo.stored.windowsCloseToTray, isTrue);
  });
}

ProviderContainer _buildContainer(_TestDevicePreferencesRepository repo) {
  return ProviderContainer(
    overrides: [
      devicePreferencesRepositoryProvider.overrideWithValue(repo),
      syncCoordinatorProvider.overrideWith((ref) => _NoopSyncFacade()),
    ],
  );
}

class _TestDevicePreferencesRepository extends DevicePreferencesRepository {
  _TestDevicePreferencesRepository(this.stored)
    : super(PreferencesMigrationService(const FlutterSecureStorage()));

  DevicePreferences stored;
  final List<DevicePreferences> writeSnapshots = <DevicePreferences>[];
  final List<Completer<void>> writeBlockers = <Completer<void>>[];
  bool persistAcceptedHash = true;

  @override
  Future<StorageReadResult<DevicePreferences>> readWithStatus() async {
    return StorageReadResult.success(stored);
  }

  @override
  Future<DevicePreferences> read() async {
    return stored;
  }

  @override
  Future<void> write(DevicePreferences prefs) async {
    writeSnapshots.add(prefs);
    if (writeBlockers.isNotEmpty) {
      final blocker = writeBlockers.removeAt(0);
      await blocker.future;
    }
    if (persistAcceptedHash) {
      stored = prefs;
      return;
    }
    stored = stored.copyWith(
      acceptedLegalDocumentsAt: prefs.acceptedLegalDocumentsAt,
      lastSeenAppVersion: prefs.lastSeenAppVersion,
    );
  }
}

class _NoopSyncFacade extends DesktopSyncFacade {
  _NoopSyncFacade() : super(SyncCoordinatorState.initial);

  @override
  void applyRemoteStateSnapshot(SyncCoordinatorState next) {
    state = next;
  }

  @override
  Future<WebDavExportCleanupStatus> cleanWebDavPlainExport() async {
    return WebDavExportCleanupStatus.notFound;
  }

  @override
  Future<WebDavSyncMeta?> cleanWebDavDeprecatedPlainFiles() async {
    return null;
  }

  @override
  Future<WebDavExportStatus> fetchWebDavExportStatus() async {
    return const WebDavExportStatus(
      webDavConfigured: false,
      encSignature: null,
      plainSignature: null,
      plainDetected: false,
      plainDeprecated: false,
      plainDetectedAt: null,
      plainRemindAfter: null,
      lastExportSuccessAt: null,
      lastUploadSuccessAt: null,
    );
  }

  @override
  Future<WebDavSyncMeta?> fetchWebDavSyncMeta() async {
    return null;
  }

  @override
  Future<List<WebDavBackupSnapshotInfo>> listWebDavBackupSnapshots({
    required WebDavSettings settings,
    required String? accountKey,
    required String password,
  }) async {
    return const <WebDavBackupSnapshotInfo>[];
  }

  @override
  Future<String> recoverWebDavBackupPassword({
    required WebDavSettings settings,
    required String? accountKey,
    required String recoveryCode,
    required String newPassword,
  }) async {
    return '';
  }

  @override
  Future<SyncRunResult> requestSync(SyncRequest request) async {
    return const SyncRunStarted();
  }

  @override
  Future<SyncRunResult> requestWebDavBackup({
    required SyncRequestReason reason,
    String? password,
    WebDavBackupExportIssueHandler? onExportIssue,
  }) async {
    return const SyncRunStarted();
  }

  @override
  Future<WebDavRestoreResult> restoreWebDavPlainBackup({
    required WebDavSettings settings,
    required String? accountKey,
    required LocalLibrary? activeLocalLibrary,
    Map<String, bool>? conflictDecisions,
    WebDavBackupConfigRestorePromptHandler? onConfigRestorePrompt,
  }) async {
    return const WebDavRestoreSuccess();
  }

  @override
  Future<WebDavRestoreResult> restoreWebDavPlainBackupToDirectory({
    required WebDavSettings settings,
    required String? accountKey,
    required LocalLibrary exportLibrary,
    required String exportPrefix,
    WebDavBackupConfigRestorePromptHandler? onConfigRestorePrompt,
  }) async {
    return const WebDavRestoreSuccess();
  }

  @override
  Future<WebDavRestoreResult> restoreWebDavSnapshot({
    required WebDavSettings settings,
    required String? accountKey,
    required LocalLibrary? activeLocalLibrary,
    required WebDavBackupSnapshotInfo snapshot,
    required String password,
    Map<String, bool>? conflictDecisions,
    WebDavBackupConfigRestorePromptHandler? onConfigRestorePrompt,
  }) async {
    return const WebDavRestoreSuccess();
  }

  @override
  Future<WebDavRestoreResult> restoreWebDavSnapshotToDirectory({
    required WebDavSettings settings,
    required String? accountKey,
    required WebDavBackupSnapshotInfo snapshot,
    required String password,
    required LocalLibrary exportLibrary,
    required String exportPrefix,
    WebDavBackupConfigRestorePromptHandler? onConfigRestorePrompt,
  }) async {
    return const WebDavRestoreSuccess();
  }

  @override
  Future<void> resolveLocalScanConflicts(Map<String, bool> resolutions) async {}

  @override
  Future<void> resolveWebDavConflicts(Map<String, bool> resolutions) async {}

  @override
  Future<void> retryPending() async {}

  @override
  Future<WebDavConnectionTestResult> testWebDavConnection({
    required WebDavSettings settings,
  }) async {
    return const WebDavConnectionTestResult.success();
  }

  @override
  Future<SyncError?> verifyWebDavBackup({
    required String password,
    required bool deep,
  }) async {
    return null;
  }
}

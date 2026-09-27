import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/sync/webdav_backup_service.dart';
import '../../application/sync/desktop_remote_sync_facade.dart';
import '../../core/desktop_runtime_role.dart';
import '../../core/desktop_sync_channel.dart';
import 'webdav_local_adapter.dart';
import '../../data/local_library/local_attachment_store.dart';
import '../../data/logs/webdav_backup_progress_tracker.dart';
import '../../data/repositories/webdav_backup_password_repository.dart';
import '../../data/repositories/webdav_backup_state_repository.dart';
import 'webdav_device_id_provider.dart';
import 'webdav_vault_provider.dart';
import '../system/database_provider.dart';
import '../system/session_provider.dart';
import 'webdav_log_provider.dart';

export '../../application/sync/webdav_backup_service.dart'
    show
        WebDavBackupExportAction,
        WebDavBackupExportIssue,
        WebDavBackupExportIssueHandler,
        WebDavBackupExportIssueKind,
        WebDavBackupExportResolution;

final webDavBackupProgressTrackerProvider =
    ChangeNotifierProvider<WebDavBackupProgressTracker>((ref) {
      final runtimeRole = ref.watch(desktopRuntimeRoleProvider);
      if (runtimeRole != DesktopRuntimeRole.mainApp) {
        return _DesktopRemoteWebDavBackupProgressTracker();
      }
      return WebDavBackupProgressTracker();
    });

final webDavBackupStateRepositoryProvider =
    Provider<WebDavBackupStateRepository>((ref) {
      final accountKey = ref.watch(webDavAccountKeyProvider);
      return WebDavBackupStateRepository(
        ref.watch(secureStorageProvider),
        accountKey: accountKey,
      );
    });

final webDavBackupPasswordRepositoryProvider =
    Provider<WebDavBackupPasswordRepository>((ref) {
      final accountKey = ref.watch(webDavAccountKeyProvider);
      return WebDavBackupPasswordRepository(
        ref.watch(secureStorageProvider),
        accountKey: accountKey,
      );
    });

final webDavBackupServiceProvider = Provider<WebDavBackupService>((ref) {
  final container = ref.container;
  return WebDavBackupService(
    readDatabase: () => container.read(databaseProvider),
    attachmentStore: LocalAttachmentStore(),
    stateRepository: ref.watch(webDavBackupStateRepositoryProvider),
    passwordRepository: ref.watch(webDavBackupPasswordRepositoryProvider),
    vaultService: ref.watch(webDavVaultServiceProvider),
    vaultPasswordRepository: ref.watch(webDavVaultPasswordRepositoryProvider),
    configAdapter: RiverpodWebDavSyncLocalAdapter(container),
    progressTracker: ref.watch(webDavBackupProgressTrackerProvider),
    logWriter: (entry) =>
        unawaited(container.read(webDavLogStoreProvider).add(entry)),
  );
});

class _DesktopRemoteWebDavBackupProgressTracker
    extends WebDavBackupProgressTracker {
  bool _disposed = false;

  _DesktopRemoteWebDavBackupProgressTracker() {
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      final raw = await DesktopRemoteSyncFacade.invokeDesktopMainWindowMethod(
        desktopSyncProgressSnapshotMethod,
        null,
      );
      if (raw is! Map) return;
      final response = Map<Object?, Object?>.from(raw).map<String, dynamic>(
        (key, value) => MapEntry(key.toString(), value),
      );
      if (response['ok'] != true) return;
      final value = response['value'];
      if (value is! Map) return;
      if (_disposed || !identical(snapshot, WebDavBackupProgressSnapshot.idle)) {
        return;
      }
      super.applySnapshot(
        WebDavBackupProgressSnapshot.fromJson(
          Map<Object?, Object?>.from(value).cast<String, dynamic>(),
        ),
      );
    } catch (_) {}
  }

  @override
  void applySnapshot(WebDavBackupProgressSnapshot next) {
    if (_disposed) return;
    super.applySnapshot(next);
  }

  @override
  void pauseIfRunning() {
    if (_disposed) return;
    unawaited(
      DesktopRemoteSyncFacade.invokeDesktopMainWindowMethod(
        desktopSyncRequestMethod,
        <String, dynamic>{'operation': 'pauseBackupProgress'},
      ),
    );
  }

  @override
  void resume() {
    if (_disposed) return;
    unawaited(
      DesktopRemoteSyncFacade.invokeDesktopMainWindowMethod(
        desktopSyncRequestMethod,
        <String, dynamic>{'operation': 'resumeBackupProgress'},
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

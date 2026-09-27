import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/sync/sync_request.dart';
import '../../data/api/memos_api.dart';
import '../../data/db/app_database.dart';
import '../../data/logs/log_manager.dart';
import '../../data/logs/logger_service.dart';
import '../../data/models/device_preferences.dart';
import '../../data/models/local_library.dart';
import '../../data/models/resolved_app_settings.dart';
import '../../data/models/user_setting.dart';
import '../../data/models/workspace_preferences.dart';
import '../../data/updates/update_config.dart';
import '../system/database_provider.dart';
import '../system/debug_screenshot_mode_provider.dart';
import '../system/home_loading_overlay_provider.dart';
import '../system/local_library_provider.dart';
import '../system/logging_provider.dart';
import 'memos_providers.dart';
import '../settings/device_preferences_provider.dart';
import '../settings/resolved_preferences_provider.dart';
import '../system/reminder_scheduler.dart';
import '../settings/reminder_settings_provider.dart';
import '../system/session_provider.dart';
import '../sync/sync_coordinator_provider.dart';
import '../system/update_config_provider.dart';
import '../settings/user_settings_provider.dart';
import '../webdav/webdav_backup_provider.dart';
import '../settings/workspace_preferences_provider.dart';

final appBootstrapAdapterProvider = Provider<AppBootstrapAdapter>((ref) {
  return const AppBootstrapAdapter();
});

class AppBootstrapAdapter {
  const AppBootstrapAdapter();

  DevicePreferences watchDevicePreferences(WidgetRef ref) =>
      ref.watch(devicePreferencesProvider);
  WorkspacePreferences watchWorkspacePreferences(WidgetRef ref) =>
      ref.watch(currentWorkspacePreferencesProvider);
  ResolvedAppSettings watchResolvedAppSettings(WidgetRef ref) =>
      ref.watch(resolvedAppSettingsProvider);
  bool watchDevicePreferencesLoaded(WidgetRef ref) =>
      ref.watch(devicePreferencesLoadedProvider);
  bool watchWorkspacePreferencesLoaded(WidgetRef ref) =>
      ref.watch(workspacePreferencesLoadedProvider);
  AsyncValue<AppSessionState> watchSession(WidgetRef ref) =>
      ref.watch(appSessionProvider);
  LoggerService watchLoggerService(WidgetRef ref) =>
      ref.watch(loggerServiceProvider);
  ReminderSettings watchReminderSettings(WidgetRef ref) =>
      ref.watch(reminderSettingsProvider);
  bool watchDebugScreenshotMode(WidgetRef ref) =>
      ref.watch(debugScreenshotModeProvider);
  LocalLibrary? watchCurrentLocalLibrary(WidgetRef ref) =>
      ref.watch(currentLocalLibraryProvider);

  DevicePreferences readDevicePreferences(WidgetRef ref) =>
      ref.read(devicePreferencesProvider);
  WorkspacePreferences readWorkspacePreferences(WidgetRef ref) =>
      ref.read(currentWorkspacePreferencesProvider);
  ResolvedAppSettings readResolvedAppSettings(WidgetRef ref) =>
      ref.read(resolvedAppSettingsProvider);
  bool readDevicePreferencesLoaded(WidgetRef ref) =>
      ref.read(devicePreferencesLoadedProvider);
  bool readWorkspacePreferencesLoaded(WidgetRef ref) =>
      ref.read(workspacePreferencesLoadedProvider);
  AsyncValue<AppSessionState> readSessionAsync(WidgetRef ref) =>
      ref.read(appSessionProvider);
  AppSessionState? readSession(WidgetRef ref) =>
      ref.read(appSessionProvider).valueOrNull;
  LocalLibrary? readCurrentLocalLibrary(WidgetRef ref) =>
      ref.read(currentLocalLibraryProvider);
  bool readDebugScreenshotMode(WidgetRef ref) =>
      ref.read(debugScreenshotModeProvider);
  LogManager readLogManager(WidgetRef ref) => ref.read(logManagerProvider);
  ReminderScheduler readReminderScheduler(WidgetRef ref) =>
      ref.read(reminderSchedulerProvider);
  bool readReminderSettingsLoaded(WidgetRef ref) =>
      ref.read(reminderSettingsLoadedProvider);
  UserGeneralSetting? readUserGeneralSetting(WidgetRef ref) =>
      ref.read(userGeneralSettingProvider).valueOrNull;
  AppDatabase readDatabase(WidgetRef ref) => ref.read(databaseProvider);
  MemosApi readMemosApi(WidgetRef ref) => ref.read(memosApiProvider);

  ProviderSubscription<AsyncValue<AppSessionState>> listenSession(
    WidgetRef ref,
    void Function(
      AsyncValue<AppSessionState>? prev,
      AsyncValue<AppSessionState> next,
    )
    listener,
  ) {
    return ref.listenManual<AsyncValue<AppSessionState>>(
      appSessionProvider,
      listener,
    );
  }

  ProviderSubscription<DevicePreferences> listenDevicePreferences(
    WidgetRef ref,
    void Function(DevicePreferences? prev, DevicePreferences next) listener,
  ) {
    return ref.listenManual<DevicePreferences>(
      devicePreferencesProvider,
      listener,
    );
  }

  ProviderSubscription<WorkspacePreferences> listenWorkspacePreferences(
    WidgetRef ref,
    void Function(WorkspacePreferences? prev, WorkspacePreferences next)
    listener,
  ) {
    return ref.listenManual<WorkspacePreferences>(
      currentWorkspacePreferencesProvider,
      listener,
    );
  }

  ProviderSubscription<ResolvedAppSettings> listenResolvedAppSettings(
    WidgetRef ref,
    void Function(ResolvedAppSettings? prev, ResolvedAppSettings next) listener,
  ) {
    return ref.listenManual<ResolvedAppSettings>(
      resolvedAppSettingsProvider,
      listener,
    );
  }

  ProviderSubscription<ReminderSettings> listenReminderSettings(
    WidgetRef ref,
    void Function(ReminderSettings? prev, ReminderSettings next) listener,
  ) {
    return ref.listenManual<ReminderSettings>(
      reminderSettingsProvider,
      listener,
    );
  }

  ProviderSubscription<bool> listenDebugScreenshotMode(
    WidgetRef ref,
    void Function(bool? prev, bool next) listener,
  ) {
    return ref.listenManual<bool>(debugScreenshotModeProvider, listener);
  }

  Future<List<TagStat>> readTagStats(WidgetRef ref) =>
      ref.read(tagStatsProvider.future);

  Future<void> reloadSessionFromStorage(WidgetRef ref) =>
      ref.read(appSessionProvider.notifier).reloadFromStorage();

  Future<void> reloadLocalLibrariesFromStorage(WidgetRef ref) =>
      ref.read(localLibrariesProvider.notifier).reloadFromStorage();

  Future<void> reloadDevicePreferencesFromStorage(WidgetRef ref) =>
      ref.read(devicePreferencesProvider.notifier).reloadFromStorage();

  Future<void> reloadWorkspacePreferencesFromStorage(WidgetRef ref) => ref
      .read(currentWorkspacePreferencesProvider.notifier)
      .reloadFromStorage();

  Future<void> setCurrentSessionKey(WidgetRef ref, String? key) =>
      ref.read(appSessionProvider.notifier).setCurrentKey(key);

  void setHasSelectedLanguage(WidgetRef ref, bool value) {
    ref.read(devicePreferencesProvider.notifier).setHasSelectedLanguage(value);
  }

  void setLastSeenAnnouncement({
    required WidgetRef ref,
    required String version,
    required int announcementId,
  }) {
    ref
        .read(devicePreferencesProvider.notifier)
        .setLastSeenAnnouncement(
          version: version,
          announcementId: announcementId,
        );
  }

  void setSkippedUpdateVersion({
    required WidgetRef ref,
    required String version,
  }) {
    ref
        .read(devicePreferencesProvider.notifier)
        .setSkippedUpdateVersion(version);
  }

  void setLastSeenNoticeHash(WidgetRef ref, String hash) {
    ref.read(devicePreferencesProvider.notifier).setLastSeenNoticeHash(hash);
  }

  void setSeenNoticeRevision({
    required WidgetRef ref,
    required String id,
    required int revision,
  }) {
    ref
        .read(devicePreferencesProvider.notifier)
        .setSeenNoticeRevision(id: id, revision: revision);
  }

  void forceHomeLoadingOverlay(WidgetRef ref) {
    ref.read(homeLoadingOverlayForceProvider.notifier).state = true;
  }

  Future<void> requestSync(WidgetRef ref, SyncRequest request) =>
      ref.read(syncCoordinatorProvider.notifier).requestSync(request);

  Future<UpdateAnnouncementConfig?> fetchLatestUpdateConfig(
    WidgetRef ref, {
    String localeTag = '',
  }) => ref.read(updateConfigServiceProvider).fetchLatest(localeTag: localeTag);

  void resumeWebDavBackupProgress(WidgetRef ref) {
    ref.read(webDavBackupProgressTrackerProvider).resume();
  }

  void pauseWebDavBackupProgress(WidgetRef ref) {
    ref.read(webDavBackupProgressTrackerProvider).pauseIfRunning();
  }
}

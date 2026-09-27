import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'package:memos_flutter_app/data/models/account.dart';
import 'package:memos_flutter_app/data/models/app_preferences.dart';
import 'package:memos_flutter_app/data/models/device_preferences.dart';
import 'package:memos_flutter_app/data/models/home_navigation_preferences.dart';
import 'package:memos_flutter_app/data/models/instance_profile.dart';
import 'package:memos_flutter_app/data/models/local_library.dart';
import 'package:memos_flutter_app/data/models/notification_item.dart';
import 'package:memos_flutter_app/data/models/user.dart';
import 'package:memos_flutter_app/data/models/webdav_backup.dart';
import 'package:memos_flutter_app/data/models/webdav_export_status.dart';
import 'package:memos_flutter_app/data/models/webdav_settings.dart';
import 'package:memos_flutter_app/data/models/webdav_sync_meta.dart';
import 'package:memos_flutter_app/data/models/workspace_preferences.dart';
import 'package:memos_flutter_app/features/home/app_drawer.dart';
import 'package:memos_flutter_app/features/home/home_bottom_nav_shell.dart';
import 'package:memos_flutter_app/features/home/home_navigation_host.dart';
import 'package:memos_flutter_app/features/home/home_root_destination_registry.dart';
import 'package:memos_flutter_app/i18n/strings.g.dart';
import 'package:memos_flutter_app/state/memos/sync_queue_provider.dart';
import 'package:memos_flutter_app/state/settings/device_preferences_provider.dart';
import 'package:memos_flutter_app/state/settings/preferences_migration_service.dart';
import 'package:memos_flutter_app/state/settings/workspace_preferences_provider.dart';
import 'package:memos_flutter_app/state/sync/sync_coordinator_provider.dart';
import 'package:memos_flutter_app/state/system/notifications_provider.dart';
import 'package:memos_flutter_app/state/system/session_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LocaleSettings.setLocale(AppLocale.en);
    debugHomeRootScreenBuilderOverride =
        ({
          required BuildContext context,
          required HomeRootDestination destination,
          required HomeScreenPresentation presentation,
          required HomeEmbeddedNavigationHost? navigationHost,
          String? memosTag,
        }) {
          return _TestRootPage(
            destination: destination,
            presentation: presentation,
            navigationHost: navigationHost,
          );
        };
    HomeBottomNavShell.debugShowNoteInputOverride = null;
  });

  tearDown(() {
    debugHomeRootScreenBuilderOverride = null;
    HomeBottomNavShell.debugShowNoteInputOverride = null;
  });

  testWidgets(
    'opening notifications from shell returns to shell memos page on back',
    (tester) async {
      final container = _buildContainer(
        workspacePrefs: _simpleBottomBarPrefs(),
        hasAccount: true,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildApp(container));
      await tester.pumpAndSettle();

      final state = tester.state(find.byType(HomeBottomNavShell)) as dynamic;
      state.handleOpenNotifications(
        tester.element(find.byType(HomeBottomNavShell)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsNothing);
      expect(find.text('page-memos-embeddedBottomNav'), findsOneWidget);
    },
  );

  testWidgets(
    'opening notifications from non-primary tab returns to same shell tab',
    (tester) async {
      final container = _buildContainer(
        workspacePrefs: _simpleBottomBarPrefs(),
        hasAccount: true,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildApp(container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('page-settings-embeddedBottomNav'), findsOneWidget);

      final state = tester.state(find.byType(HomeBottomNavShell)) as dynamic;
      state.handleOpenNotifications(
        tester.element(find.byType(HomeBottomNavShell)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsNothing);
      expect(find.text('page-settings-embeddedBottomNav'), findsOneWidget);
      expect(find.text('page-memos-embeddedBottomNav'), findsNothing);
    },
  );
}

WorkspacePreferences _simpleBottomBarPrefs() {
  return WorkspacePreferences.defaults.copyWith(
    homeNavigationPreferences: HomeNavigationPreferences.defaults.copyWith(
      mode: HomeNavigationMode.bottomBar,
      leftPrimary: HomeRootDestination.memos,
      leftSecondary: HomeRootDestination.none,
      rightPrimary: HomeRootDestination.none,
      rightSecondary: HomeRootDestination.settings,
    ),
  );
}

Widget _buildApp(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: TranslationProvider(
      child: MaterialApp(
        locale: AppLocale.en.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const MediaQuery(
          data: MediaQueryData(size: Size(430, 900)),
          child: HomeBottomNavShell(),
        ),
      ),
    ),
  );
}

ProviderContainer _buildContainer({
  required WorkspacePreferences workspacePrefs,
  required bool hasAccount,
}) {
  return ProviderContainer(
    overrides: [
      currentWorkspacePreferencesProvider.overrideWith(
        (ref) =>
            _TestWorkspacePreferencesController(ref, initial: workspacePrefs),
      ),
      workspacePreferencesLoadedProvider.overrideWith((ref) => true),
      devicePreferencesProvider.overrideWith(
        (ref) => _TestDevicePreferencesController(ref),
      ),
      appSessionProvider.overrideWith(
        (ref) => _TestSessionController(hasAccount: hasAccount),
      ),
      notificationsProvider.overrideWith(
        (ref) async => const <AppNotification>[],
      ),
      unreadNotificationCountProvider.overrideWith((ref) => 0),
      syncQueuePendingCountProvider.overrideWith((ref) => Stream.value(0)),
      syncQueueAttentionCountProvider.overrideWith((ref) => Stream.value(0)),
      syncCoordinatorProvider.overrideWith((ref) => _NoopSyncFacade()),
    ],
  );
}

class _TestRootPage extends StatefulWidget {
  const _TestRootPage({
    required this.destination,
    required this.presentation,
    required this.navigationHost,
  });

  final HomeRootDestination destination;
  final HomeScreenPresentation presentation;
  final HomeEmbeddedNavigationHost? navigationHost;

  @override
  State<_TestRootPage> createState() => _TestRootPageState();
}

class _TestRootPageState extends State<_TestRootPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('page-${widget.destination.name}-${widget.presentation.name}'),
            if (widget.navigationHost != null)
              TextButton(
                onPressed: () => widget.navigationHost!
                    .handleBackToPrimaryDestination(context),
                child: Text('back-${widget.destination.name}'),
              ),
            if (widget.navigationHost != null)
              TextButton(
                onPressed: () => widget.navigationHost!.handleDrawerDestination(
                  context,
                  AppDrawerDestination.memos,
                ),
                child: Text('goto-memos-${widget.destination.name}'),
              ),
          ],
        ),
      ),
    );
  }
}

class _TestWorkspacePreferencesRepository
    extends WorkspacePreferencesRepository {
  _TestWorkspacePreferencesRepository(this._stored)
    : super(
        PreferencesMigrationService(const FlutterSecureStorage()),
        workspaceKey: 'test-workspace',
      );

  WorkspacePreferences _stored;

  @override
  Future<StorageReadResult<WorkspacePreferences>> readWithStatus() async {
    return StorageReadResult.success(_stored);
  }

  @override
  Future<WorkspacePreferences> read() async {
    return _stored;
  }

  @override
  Future<void> write(WorkspacePreferences prefs) async {
    _stored = prefs;
  }
}

class _TestWorkspacePreferencesController
    extends WorkspacePreferencesController {
  _TestWorkspacePreferencesController(
    Ref ref, {
    required WorkspacePreferences initial,
  }) : super(ref, _TestWorkspacePreferencesRepository(initial)) {
    state = initial;
  }
}

class _TestDevicePreferencesRepository extends DevicePreferencesRepository {
  _TestDevicePreferencesRepository()
    : _stored = DevicePreferences.defaultsForLanguage(AppLanguage.en),
      super(PreferencesMigrationService(const FlutterSecureStorage()));

  DevicePreferences _stored;

  @override
  Future<StorageReadResult<DevicePreferences>> readWithStatus() async {
    return StorageReadResult.success(_stored);
  }

  @override
  Future<DevicePreferences> read() async {
    return _stored;
  }

  @override
  Future<void> write(DevicePreferences prefs) async {
    _stored = prefs;
  }
}

class _TestDevicePreferencesController extends DevicePreferencesController {
  _TestDevicePreferencesController(Ref ref)
    : super(ref, _TestDevicePreferencesRepository()) {
    state = DevicePreferences.defaultsForLanguage(AppLanguage.en);
  }
}

class _TestSessionController extends AppSessionController {
  _TestSessionController({required bool hasAccount})
    : super(
        AsyncValue.data(
          AppSessionState(
            accounts: hasAccount ? [_testAccount] : const <Account>[],
            currentKey: hasAccount ? _testAccountKey : null,
          ),
        ),
      );

  @override
  Future<void> addAccountWithPat({
    required Uri baseUrl,
    required String personalAccessToken,
    bool? useLegacyApiOverride,
    String? serverVersionOverride,
  }) async {}

  @override
  Future<void> addAccountWithPassword({
    required Uri baseUrl,
    required String username,
    required String password,
    required bool useLegacyApi,
    String? serverVersionOverride,
  }) async {}

  @override
  Future<void> removeAccount(String accountKey) async {}

  @override
  Future<void> switchAccount(String accountKey) async {}

  @override
  Future<void> setCurrentKey(String? key) async {}

  @override
  Future<void> switchWorkspace(String workspaceKey) async {}

  @override
  Future<void> refreshCurrentUser({bool ignoreErrors = true}) async {}

  @override
  Future<void> reloadFromStorage() async {}

  @override
  bool resolveUseLegacyApiForAccount({
    required Account account,
    required bool globalDefault,
  }) => globalDefault;

  @override
  InstanceProfile resolveEffectiveInstanceProfileForAccount({
    required Account account,
  }) => account.instanceProfile;

  @override
  String resolveEffectiveServerVersionForAccount({required Account account}) =>
      account.serverVersionOverride ?? account.instanceProfile.version;

  @override
  Future<void> setCurrentAccountUseLegacyApiOverride(bool value) async {}

  @override
  Future<void> setCurrentAccountServerVersionOverride(String? version) async {}

  @override
  Future<InstanceProfile> detectCurrentAccountInstanceProfile() async {
    return const InstanceProfile.empty();
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

const _testAccountKey = 'account-1';
final _testAccount = Account(
  key: _testAccountKey,
  baseUrl: Uri.parse('https://example.com'),
  personalAccessToken: 'token',
  user: User.empty(),
  instanceProfile: InstanceProfile.empty(),
);

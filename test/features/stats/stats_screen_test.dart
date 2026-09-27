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
import 'package:memos_flutter_app/data/db/app_database.dart';
import 'package:memos_flutter_app/data/models/account.dart';
import 'package:memos_flutter_app/data/models/app_preferences.dart';
import 'package:memos_flutter_app/data/models/device_preferences.dart';
import 'package:memos_flutter_app/data/models/instance_profile.dart';
import 'package:memos_flutter_app/data/models/local_memo.dart';
import 'package:memos_flutter_app/data/models/local_library.dart';
import 'package:memos_flutter_app/data/models/user.dart';
import 'package:memos_flutter_app/data/models/webdav_backup.dart';
import 'package:memos_flutter_app/data/models/webdav_export_status.dart';
import 'package:memos_flutter_app/data/models/webdav_settings.dart';
import 'package:memos_flutter_app/data/models/webdav_sync_meta.dart';
import 'package:memos_flutter_app/data/models/workspace_preferences.dart';
import 'package:memos_flutter_app/features/stats/stats_screen.dart';
import 'package:memos_flutter_app/features/memos/widgets/memos_list_memo_card.dart';
import 'package:memos_flutter_app/i18n/strings.g.dart';
import 'package:memos_flutter_app/platform/platform_target.dart';
import 'package:memos_flutter_app/state/memos/memo_clip_card_providers.dart';
import 'package:memos_flutter_app/state/memos/memos_list_providers.dart';
import 'package:memos_flutter_app/state/memos/stats_providers.dart';
import 'package:memos_flutter_app/state/settings/device_preferences_provider.dart';
import 'package:memos_flutter_app/state/settings/preferences_migration_service.dart';
import 'package:memos_flutter_app/state/settings/workspace_preferences_provider.dart';
import 'package:memos_flutter_app/state/sync/sync_coordinator_provider.dart';
import 'package:memos_flutter_app/state/system/database_provider.dart';
import 'package:memos_flutter_app/state/system/local_library_provider.dart';
import 'package:memos_flutter_app/state/system/session_provider.dart';
import 'package:memos_flutter_app/state/tags/tag_color_lookup.dart';

import '../../test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestSupport support;
  late AppDatabase database;
  late String dbName;

  setUpAll(() async {
    support = await initializeTestSupport();
    LocaleSettings.setLocale(AppLocale.en);
  });

  tearDownAll(() async {
    await support.dispose();
  });

  setUp(() async {
    dbName = uniqueDbName('stats_screen_test');
    database = AppDatabase(dbName: dbName);
    await database.db;
    await _insertMemo(database, uid: 'memo-stats-1');
    await database.rebuildStatsCache();
  });

  tearDown(() async {
    debugPlatformTargetOverride = null;
    await database.close();
    await deleteTestDatabase(dbName);
  });

  testWidgets('desktop stats data view is bounded as a dashboard', (
    tester,
  ) async {
    debugPlatformTargetOverride = TargetPlatform.macOS;
    await _setViewport(tester, const Size(1440, 900));

    await tester.pumpWidget(
      _buildTestApp(
        database: database,
        screenSize: const Size(1440, 900),
        platform: TargetPlatform.macOS,
      ),
    );
    await _settle(tester);
    await _pumpUntilFound(tester, find.byKey(statsDesktopDashboardKey));

    final dashboard = find.byKey(statsDesktopDashboardKey);
    expect(dashboard, findsOneWidget);
    expect(tester.getSize(dashboard).width, lessThanOrEqualTo(1180));
    expect(find.text('Memo stats'), findsOneWidget);
  });

  testWidgets('desktop stats calendar uses split layout', (tester) async {
    debugPlatformTargetOverride = TargetPlatform.macOS;
    await _setViewport(tester, const Size(1440, 900));

    await tester.pumpWidget(
      _buildTestApp(
        database: database,
        screenSize: const Size(1440, 900),
        platform: TargetPlatform.macOS,
      ),
    );
    await _settle(tester);
    await _pumpUntilFound(tester, find.text('Calendar'));

    await tester.tap(find.text('Calendar'));
    await _settle(tester);
    await _pumpUntilFound(tester, find.byKey(statsDesktopCalendarSplitKey));
    await _pumpUntilFound(
      tester,
      find.byKey(
        const ValueKey<String>('stats-calendar-compact-memo-memo-stats-1'),
      ),
    );

    final split = find.byKey(statsDesktopCalendarSplitKey);
    expect(split, findsOneWidget);
    expect(tester.getSize(split).width, lessThanOrEqualTo(1180));
    expect(
      find.byKey(
        const ValueKey<String>('stats-calendar-compact-memo-memo-stats-1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('mobile stats calendar keeps stacked memo card fallback', (
    tester,
  ) async {
    debugPlatformTargetOverride = TargetPlatform.android;
    await _setViewport(tester, const Size(390, 844));

    await tester.pumpWidget(
      _buildTestApp(
        database: database,
        screenSize: const Size(390, 844),
        platform: TargetPlatform.android,
      ),
    );
    await _settle(tester);
    await _pumpUntilFound(tester, find.text('Calendar'));

    await tester.tap(find.text('Calendar'));
    await _settle(tester);
    await _pumpUntilFound(tester, find.byType(MemoListCard));
    await _pumpUntilFound(
      tester,
      find.textContaining('Stats screen memo body', findRichText: true),
    );

    expect(find.byKey(statsDesktopCalendarSplitKey), findsNothing);
    expect(
      find.byKey(
        const ValueKey<String>('stats-calendar-compact-memo-memo-stats-1'),
      ),
      findsNothing,
    );
    expect(
      find.textContaining('Stats screen memo body', findRichText: true),
      findsWidgets,
    );
  });
}

Future<void> _insertMemo(AppDatabase db, {required String uid}) async {
  final now = DateTime.now();
  final createTime = DateTime(now.year, now.month, now.day, 10);
  final createTimeSec = createTime.toUtc().millisecondsSinceEpoch ~/ 1000;
  await db.upsertMemo(
    uid: uid,
    content: 'Stats screen memo body for adaptive calendar layout.',
    visibility: 'PRIVATE',
    pinned: false,
    state: 'NORMAL',
    createTimeSec: createTimeSec,
    updateTimeSec: createTimeSec,
    tags: const <String>[],
    attachments: const <Map<String, dynamic>>[],
    location: null,
    relationCount: 0,
    syncState: 0,
    lastError: null,
  );
}

LocalMemo _buildTestMemo({required String uid, required DateTime createTime}) {
  return LocalMemo(
    uid: uid,
    content: 'Stats screen memo body for adaptive calendar layout.',
    contentFingerprint: 'stats-screen-memo-body',
    visibility: 'PRIVATE',
    pinned: false,
    state: 'NORMAL',
    createTime: createTime,
    displayTime: createTime,
    updateTime: createTime,
    tags: const <String>[],
    attachments: const [],
    relationCount: 0,
    location: null,
    syncState: SyncState.synced,
    lastError: null,
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 40,
}) async {
  for (var index = 0; index < maxPumps; index++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _setViewport(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Widget _buildTestApp({
  required AppDatabase database,
  required Size screenSize,
  required TargetPlatform platform,
}) {
  return ProviderScope(
    overrides: [
      appSessionProvider.overrideWith((ref) => _TestSessionController()),
      databaseProvider.overrideWithValue(database),
      currentLocalLibraryProvider.overrideWith((ref) => null),
      localStatsProvider.overrideWith(
        (ref) => Stream.value(
          LocalStats(
            totalMemos: 1,
            archivedMemos: 0,
            activeDays: 1,
            daysSinceFirstMemo: 1,
            totalChars: 48,
            dailyCounts: {
              DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
              ): 1,
            },
          ),
        ),
      ),
      monthlyStatsProvider.overrideWith(
        (ref, key) => Stream.value(
          MonthlyStats(
            year: key.year,
            month: key.month,
            totalMemos: 1,
            totalChars: 48,
            maxMemosPerDay: 1,
            maxCharsPerDay: 48,
            activeDays: 1,
            dailyCounts: {
              DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
              ): 1,
            },
          ),
        ),
      ),
      annualInsightsProvider.overrideWith(
        (ref, key) => Stream.value(
          AnnualInsights(
            monthlyChars: [
              MonthlyChars(
                month: DateTime(key.year, key.month, 1),
                totalChars: 48,
              ),
            ],
            tagDistribution: const <TagDistribution>[],
          ),
        ),
      ),
      writingHourSummaryProvider.overrideWith(
        (ref) =>
            Stream.value(const WritingHourSummary(peakHour: 10, peakCount: 1)),
      ),
      statsCalendarDayMemosProvider.overrideWith(
        (ref, day) => Stream.value([
          _buildTestMemo(
            uid: 'memo-stats-1',
            createTime: DateTime(day.year, day.month, day.day, 10),
          ),
        ]),
      ),
      devicePreferencesProvider.overrideWith(
        (ref) => _TestDevicePreferencesController(ref),
      ),
      currentWorkspacePreferencesProvider.overrideWith(
        (ref) => _TestWorkspacePreferencesController(ref),
      ),
      memosListOutboxStatusProvider.overrideWith(
        (ref) => Stream.value(const OutboxMemoStatus.empty()),
      ),
      memoClipCardsProvider.overrideWith((ref) => Stream.value(const [])),
      tagColorLookupProvider.overrideWith((ref) => TagColorLookup(const [])),
      syncCoordinatorProvider.overrideWith((ref) => _NoopSyncFacade()),
    ],
    child: TranslationProvider(
      child: MaterialApp(
        theme: ThemeData(platform: platform),
        locale: AppLocale.en.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: const StatsScreen(showBackButton: false),
        ),
      ),
    ),
  );
}

class _TestSessionController extends AppSessionController {
  _TestSessionController()
    : super(
        AsyncValue.data(
          AppSessionState(
            accounts: [
              Account(
                key: 'users/1',
                baseUrl: Uri.parse('https://example.com'),
                personalAccessToken: 'token',
                user: const User(
                  name: 'users/1',
                  username: 'tester',
                  displayName: 'Tester',
                  avatarUrl: '',
                  description: '',
                ),
                instanceProfile: const InstanceProfile.empty(),
              ),
            ],
            currentKey: 'users/1',
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
  Future<InstanceProfile> detectCurrentAccountInstanceProfile() async {
    return const InstanceProfile.empty();
  }

  @override
  Future<void> refreshCurrentUser({bool ignoreErrors = true}) async {}

  @override
  Future<void> reloadFromStorage() async {}

  @override
  Future<void> removeAccount(String accountKey) async {}

  @override
  String resolveEffectiveServerVersionForAccount({required Account account}) =>
      account.serverVersionOverride ?? account.instanceProfile.version;

  @override
  InstanceProfile resolveEffectiveInstanceProfileForAccount({
    required Account account,
  }) => account.instanceProfile;

  @override
  bool resolveUseLegacyApiForAccount({
    required Account account,
    required bool globalDefault,
  }) => globalDefault;

  @override
  Future<void> setCurrentAccountServerVersionOverride(String? version) async {}

  @override
  Future<void> setCurrentAccountUseLegacyApiOverride(bool value) async {}

  @override
  Future<void> setCurrentKey(String? key) async {}

  @override
  Future<void> switchAccount(String accountKey) async {}

  @override
  Future<void> switchWorkspace(String workspaceKey) async {}
}

class _TestDevicePreferencesRepository extends DevicePreferencesRepository {
  _TestDevicePreferencesRepository()
    : super(PreferencesMigrationService(const FlutterSecureStorage()));

  @override
  Future<DevicePreferences> read() async {
    return DevicePreferences.defaultsForLanguage(AppLanguage.en);
  }

  @override
  Future<StorageReadResult<DevicePreferences>> readWithStatus() async {
    return StorageReadResult.success(
      DevicePreferences.defaultsForLanguage(AppLanguage.en),
    );
  }

  @override
  Future<void> write(DevicePreferences prefs) async {}
}

class _TestDevicePreferencesController extends DevicePreferencesController {
  _TestDevicePreferencesController(Ref ref)
    : super(
        ref,
        _TestDevicePreferencesRepository(),
        onLoaded: () {
          ref.read(devicePreferencesLoadedProvider.notifier).state = true;
        },
      );
}

class _TestWorkspacePreferencesRepository
    extends WorkspacePreferencesRepository {
  _TestWorkspacePreferencesRepository()
    : super(
        PreferencesMigrationService(const FlutterSecureStorage()),
        workspaceKey: 'users/1',
      );

  @override
  Future<WorkspacePreferences> read() async {
    return WorkspacePreferences.defaults;
  }

  @override
  Future<StorageReadResult<WorkspacePreferences>> readWithStatus() async {
    return StorageReadResult.success(WorkspacePreferences.defaults);
  }

  @override
  Future<void> write(WorkspacePreferences prefs) async {}
}

class _TestWorkspacePreferencesController
    extends WorkspacePreferencesController {
  _TestWorkspacePreferencesController(Ref ref)
    : super(
        ref,
        _TestWorkspacePreferencesRepository(),
        onLoaded: () {
          ref.read(workspacePreferencesLoadedProvider.notifier).state = true;
        },
      );
}

class _NoopSyncFacade extends DesktopSyncFacade {
  _NoopSyncFacade() : super(SyncCoordinatorState.initial);

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

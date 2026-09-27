import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/application/sync/sync_coordinator.dart';
import 'package:memos_flutter_app/application/sync/sync_error.dart';
import 'package:memos_flutter_app/application/sync/sync_request.dart';
import 'package:memos_flutter_app/application/sync/sync_types.dart';
import 'package:memos_flutter_app/application/sync/webdav_backup_service.dart';
import 'package:memos_flutter_app/application/sync/webdav_sync_service.dart';
import 'package:memos_flutter_app/data/api/memos_api.dart';
import 'package:memos_flutter_app/data/models/account.dart';
import 'package:memos_flutter_app/data/models/content_fingerprint.dart';
import 'package:memos_flutter_app/data/models/local_memo.dart';
import 'package:memos_flutter_app/data/models/home_navigation_preferences.dart';
import 'package:memos_flutter_app/data/models/instance_profile.dart';
import 'package:memos_flutter_app/data/models/local_library.dart';
import 'package:memos_flutter_app/data/models/user.dart';
import 'package:memos_flutter_app/data/models/webdav_backup.dart';
import 'package:memos_flutter_app/data/models/webdav_export_status.dart';
import 'package:memos_flutter_app/data/models/webdav_settings.dart';
import 'package:memos_flutter_app/data/models/webdav_sync_meta.dart';
import 'package:memos_flutter_app/features/home/home_navigation_host.dart';
import 'package:memos_flutter_app/features/review/daily_review_screen.dart';
import 'package:memos_flutter_app/features/review/random_walk_models.dart';
import 'package:memos_flutter_app/features/review/random_walk_providers.dart';
import 'package:memos_flutter_app/i18n/strings.g.dart';
import 'package:memos_flutter_app/state/memos/memos_providers.dart';
import 'package:memos_flutter_app/state/memos/sync_queue_provider.dart';
import 'package:memos_flutter_app/state/sync/sync_coordinator_provider.dart';
import 'package:memos_flutter_app/state/system/local_library_provider.dart';
import 'package:memos_flutter_app/state/system/notifications_provider.dart';
import 'package:memos_flutter_app/state/system/session_provider.dart';
import 'package:memos_flutter_app/state/tags/tag_color_lookup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'windows daily review uses desktop shell rail on compact widths',
    (tester) async {
      LocaleSettings.setLocale(AppLocale.en);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSessionProvider.overrideWith(
              (ref) => _TestSessionController(hasAccount: false),
            ),
            memosApiProvider.overrideWith(
              (ref) => MemosApi.unauthenticated(
                Uri.parse('https://example.com'),
                instanceProfile: InstanceProfile.empty(),
              ),
            ),
            currentLocalLibraryProvider.overrideWith((ref) => null),
            randomWalkDeckProvider.overrideWith(
              (ref, query) => Stream.value(const <RandomWalkDeckEntry>[]),
            ),
            tagStatsProvider.overrideWith(
              (ref) => Stream.value(const <TagStat>[]),
            ),
            tagColorLookupProvider.overrideWith(
              (ref) => TagColorLookup(const []),
            ),
            syncCoordinatorProvider.overrideWith((ref) => _NoopSyncFacade()),
            unreadNotificationCountProvider.overrideWith((ref) => 0),
            syncQueuePendingCountProvider.overrideWith(
              (ref) => Stream.value(0),
            ),
            syncQueueAttentionCountProvider.overrideWith(
              (ref) => Stream.value(0),
            ),
          ],
          child: TranslationProvider(
            child: MaterialApp(
              theme: ThemeData(platform: TargetPlatform.windows),
              locale: AppLocale.en.flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: const MediaQuery(
                data: MediaQueryData(size: Size(1100, 900)),
                child: DailyReviewScreen(
                  presentation: HomeScreenPresentation.embeddedBottomNav,
                  embeddedNavigationHost: _TestEmbeddedNavigationHost(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('desktop-navigation-rail')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('drawer-menu-button')), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('windows-desktop-command-bar')),
        findsOneWidget,
      );
    },
  );

  testWidgets('windows standalone daily review omits top-level back button', (
    tester,
  ) async {
    LocaleSettings.setLocale(AppLocale.en);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSessionProvider.overrideWith(
            (ref) => _TestSessionController(hasAccount: false),
          ),
          memosApiProvider.overrideWith(
            (ref) => MemosApi.unauthenticated(
              Uri.parse('https://example.com'),
              instanceProfile: InstanceProfile.empty(),
            ),
          ),
          currentLocalLibraryProvider.overrideWith((ref) => null),
          randomWalkDeckProvider.overrideWith(
            (ref, query) => Stream.value(const <RandomWalkDeckEntry>[]),
          ),
          tagStatsProvider.overrideWith(
            (ref) => Stream.value(const <TagStat>[]),
          ),
          tagColorLookupProvider.overrideWith(
            (ref) => TagColorLookup(const []),
          ),
          syncCoordinatorProvider.overrideWith((ref) => _NoopSyncFacade()),
          unreadNotificationCountProvider.overrideWith((ref) => 0),
          syncQueuePendingCountProvider.overrideWith((ref) => Stream.value(0)),
          syncQueueAttentionCountProvider.overrideWith(
            (ref) => Stream.value(0),
          ),
        ],
        child: TranslationProvider(
          child: MaterialApp(
            theme: ThemeData(platform: TargetPlatform.windows),
            locale: AppLocale.en.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const MediaQuery(
              data: MediaQueryData(size: Size(1400, 900)),
              child: DailyReviewScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('windows-desktop-command-bar')),
      findsOneWidget,
    );
    expect(find.byTooltip('Back'), findsNothing);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });

  testWidgets('macOS expanded sidebar daily review omits duplicate title', (
    tester,
  ) async {
    LocaleSettings.setLocale(AppLocale.en);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSessionProvider.overrideWith(
            (ref) => _TestSessionController(hasAccount: false),
          ),
          memosApiProvider.overrideWith(
            (ref) => MemosApi.unauthenticated(
              Uri.parse('https://example.com'),
              instanceProfile: InstanceProfile.empty(),
            ),
          ),
          currentLocalLibraryProvider.overrideWith((ref) => null),
          randomWalkDeckProvider.overrideWith(
            (ref, query) => Stream.value(const <RandomWalkDeckEntry>[]),
          ),
          tagStatsProvider.overrideWith(
            (ref) => Stream.value(const <TagStat>[]),
          ),
          tagColorLookupProvider.overrideWith(
            (ref) => TagColorLookup(const []),
          ),
          syncCoordinatorProvider.overrideWith((ref) => _NoopSyncFacade()),
          unreadNotificationCountProvider.overrideWith((ref) => 0),
          syncQueuePendingCountProvider.overrideWith((ref) => Stream.value(0)),
          syncQueueAttentionCountProvider.overrideWith(
            (ref) => Stream.value(0),
          ),
        ],
        child: TranslationProvider(
          child: MaterialApp(
            theme: ThemeData(platform: TargetPlatform.macOS),
            locale: AppLocale.en.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const MediaQuery(
              data: MediaQueryData(size: Size(1400, 900)),
              child: DailyReviewScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('apple-macos-page-shell')),
      findsOneWidget,
    );
    expect(find.text('Random Review'), findsOneWidget);
  });

  testWidgets('embedded daily review shows drawer menu button', (tester) async {
    LocaleSettings.setLocale(AppLocale.en);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSessionProvider.overrideWith(
            (ref) => _TestSessionController(hasAccount: false),
          ),
          memosApiProvider.overrideWith(
            (ref) => MemosApi.unauthenticated(
              Uri.parse('https://example.com'),
              instanceProfile: InstanceProfile.empty(),
            ),
          ),
          currentLocalLibraryProvider.overrideWith((ref) => null),
          randomWalkDeckProvider.overrideWith(
            (ref, query) => Stream.value(const <RandomWalkDeckEntry>[]),
          ),
          tagStatsProvider.overrideWith(
            (ref) => Stream.value(const <TagStat>[]),
          ),
          tagColorLookupProvider.overrideWith(
            (ref) => TagColorLookup(const []),
          ),
          syncCoordinatorProvider.overrideWith((ref) => _NoopSyncFacade()),
          unreadNotificationCountProvider.overrideWith((ref) => 0),
          syncQueuePendingCountProvider.overrideWith((ref) => Stream.value(0)),
          syncQueueAttentionCountProvider.overrideWith(
            (ref) => Stream.value(0),
          ),
        ],
        child: TranslationProvider(
          child: MaterialApp(
            locale: AppLocale.en.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const MediaQuery(
              data: MediaQueryData(size: Size(430, 900)),
              child: DailyReviewScreen(
                presentation: HomeScreenPresentation.embeddedBottomNav,
                embeddedNavigationHost: _TestEmbeddedNavigationHost(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('drawer-menu-button')), findsOneWidget);
  });

  testWidgets(
    'daily review avoids auth prefetch crash and duplicate hero tags',
    (tester) async {
      LocaleSettings.setLocale(AppLocale.en);
      final memo = _buildMemo(uid: 'shared-memo', content: 'Shared memo body');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSessionProvider.overrideWith(
              (ref) => _TestSessionController(hasAccount: false),
            ),
            currentLocalLibraryProvider.overrideWith((ref) => null),
            randomWalkDeckProvider.overrideWith(
              (ref, query) => Stream.value(<RandomWalkDeckEntry>[
                RandomWalkDeckEntry.memo(
                  memo: memo,
                  memoOrigin: RandomWalkMemoOrigin.localAll,
                ),
                RandomWalkDeckEntry.memo(
                  memo: memo,
                  memoOrigin: RandomWalkMemoOrigin.explore,
                  creatorRef: 'alice',
                  creatorFallback: 'Alice',
                ),
              ]),
            ),
            tagStatsProvider.overrideWith(
              (ref) => Stream.value(const <TagStat>[]),
            ),
            tagColorLookupProvider.overrideWith(
              (ref) => TagColorLookup(const []),
            ),
            syncCoordinatorProvider.overrideWith((ref) => _NoopSyncFacade()),
            unreadNotificationCountProvider.overrideWith((ref) => 0),
            syncQueuePendingCountProvider.overrideWith(
              (ref) => Stream.value(0),
            ),
            syncQueueAttentionCountProvider.overrideWith(
              (ref) => Stream.value(0),
            ),
          ],
          child: TranslationProvider(
            child: MaterialApp(
              locale: AppLocale.en.flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: const MediaQuery(
                data: MediaQueryData(size: Size(430, 900)),
                child: DailyReviewScreen(
                  presentation: HomeScreenPresentation.embeddedBottomNav,
                  embeddedNavigationHost: _TestEmbeddedNavigationHost(),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);

      final cardFinder = find.byKey(
        const ValueKey('memo:localAll:shared-memo'),
      );
      expect(cardFinder, findsOneWidget);

      await tester.tap(cardFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    },
  );
}

LocalMemo _buildMemo({required String uid, required String content}) {
  final now = DateTime(2024, 1, 2, 3, 4, 5);
  return LocalMemo(
    uid: uid,
    content: content,
    contentFingerprint: computeContentFingerprint(content),
    visibility: 'PRIVATE',
    pinned: false,
    state: 'NORMAL',
    createTime: now,
    updateTime: now,
    tags: const <String>[],
    attachments: const [],
    relationCount: 0,
    syncState: SyncState.synced,
    lastError: null,
  );
}

class _TestEmbeddedNavigationHost implements HomeEmbeddedNavigationHost {
  const _TestEmbeddedNavigationHost();

  @override
  void handleBackToPrimaryDestination(BuildContext context) {}

  @override
  void handleDrawerDestination(BuildContext context, destination) {}

  @override
  void handleDrawerTag(BuildContext context, String tag) {}

  @override
  void handleOpenNotifications(BuildContext context) {}

  @override
  void updateGlobalSwipeExclusionRects(
    HomeRootDestination destination,
    List<Rect> rects,
  ) {}

  @override
  void clearGlobalSwipeExclusionRects(HomeRootDestination destination) {}
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

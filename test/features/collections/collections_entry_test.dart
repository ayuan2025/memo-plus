import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:memos_flutter_app/core/storage_read.dart';
import 'package:memos_flutter_app/data/db/app_database.dart';
import 'package:memos_flutter_app/data/models/account.dart';
import 'package:memos_flutter_app/data/models/instance_profile.dart';
import 'package:memos_flutter_app/data/models/workspace_preferences.dart';
import 'package:memos_flutter_app/features/home/app_drawer.dart';
import 'package:memos_flutter_app/features/settings/customize_drawer_screen.dart';
import 'package:memos_flutter_app/features/settings/settings_ui.dart';
import 'package:memos_flutter_app/i18n/strings.g.dart';
import 'package:memos_flutter_app/state/memos/memos_providers.dart';
import 'package:memos_flutter_app/state/memos/stats_providers.dart';
import 'package:memos_flutter_app/state/settings/preferences_migration_service.dart';
import 'package:memos_flutter_app/state/settings/workspace_preferences_provider.dart';
import 'package:memos_flutter_app/state/system/database_provider.dart';
import 'package:memos_flutter_app/state/system/local_library_provider.dart';
import 'package:memos_flutter_app/state/system/notifications_provider.dart';
import 'package:memos_flutter_app/state/system/session_provider.dart';
import 'package:memos_flutter_app/state/tags/tag_color_lookup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'MemoFlow',
      packageName: 'dev.memoflow.test',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  setUp(() {
    LocaleSettings.setLocale(AppLocale.en);
  });

  testWidgets('drawer shows collections entry when enabled', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        initial: WorkspacePreferences.defaults,
        home: Scaffold(
          body: AppDrawer(
            selected: AppDrawerDestination.memos,
            embedded: true,
            onSelect: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Collections'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Collections'), findsOneWidget);
  });

  testWidgets('drawer shows Draft Box entry by default', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        initial: WorkspacePreferences.defaults,
        home: Scaffold(
          body: AppDrawer(
            selected: AppDrawerDestination.memos,
            embedded: true,
            onSelect: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Draft Box'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Draft Box'), findsOneWidget);
  });

  testWidgets('drawer hides Draft Box entry when disabled', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        initial: WorkspacePreferences.defaults.copyWith(
          showDrawerDraftBox: false,
        ),
        home: Scaffold(
          body: AppDrawer(
            selected: AppDrawerDestination.memos,
            embedded: true,
            onSelect: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1600));
    await tester.pumpAndSettle();
    expect(find.text('Draft Box'), findsNothing);
  });

  testWidgets('drawer hides collections entry when disabled', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        initial: WorkspacePreferences.defaults.copyWith(
          showDrawerCollections: false,
        ),
        home: Scaffold(
          body: AppDrawer(
            selected: AppDrawerDestination.memos,
            embedded: true,
            onSelect: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1600));
    await tester.pumpAndSettle();
    expect(find.text('Collections'), findsNothing);
  });

  testWidgets('customize drawer toggles collections visibility preference', (
    tester,
  ) async {
    _TestWorkspacePreferencesController? controller;

    await tester.pumpWidget(
      _buildTestApp(
        initial: WorkspacePreferences.defaults,
        home: const CustomizeDrawerScreen(),
        controllerSink: (value) => controller = value,
      ),
    );
    await tester.pumpAndSettle();

    expect(controller, isNotNull);
    expect(controller!.state.showDrawerCollections, isTrue);

    await tester.scrollUntilVisible(
      find.text('Collections'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    final collectionsRow = find.byWidgetPredicate(
      (widget) => widget is SettingsToggleRow && widget.label == 'Collections',
    );
    await tester.tap(
      find.descendant(of: collectionsRow, matching: find.byType(Switch)),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(controller!.state.showDrawerCollections, isFalse);
  });

  testWidgets('customize drawer toggles Draft Box visibility preference', (
    tester,
  ) async {
    _TestWorkspacePreferencesController? controller;

    await tester.pumpWidget(
      _buildTestApp(
        initial: WorkspacePreferences.defaults.copyWith(
          showDrawerDraftBox: false,
        ),
        home: const CustomizeDrawerScreen(),
        controllerSink: (value) => controller = value,
      ),
    );
    await tester.pumpAndSettle();

    expect(controller, isNotNull);
    expect(controller!.state.showDrawerDraftBox, isFalse);

    await tester.scrollUntilVisible(
      find.text('Draft Box'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    final draftBoxRow = find.byWidgetPredicate(
      (widget) => widget is SettingsToggleRow && widget.label == 'Draft Box',
    );
    await tester.tap(
      find.descendant(of: draftBoxRow, matching: find.byType(Switch)),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(controller!.state.showDrawerDraftBox, isTrue);
  });
}

Widget _buildTestApp({
  required WorkspacePreferences initial,
  required Widget home,
  void Function(_TestWorkspacePreferencesController controller)? controllerSink,
}) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(_FakeAppDatabase()),
      appSessionProvider.overrideWith((ref) => _TestSessionController()),
      currentLocalLibraryProvider.overrideWith((ref) => null),
      localStatsProvider.overrideWith(
        (ref) => Stream.value(
          const LocalStats(
            totalMemos: 0,
            archivedMemos: 0,
            activeDays: 0,
            daysSinceFirstMemo: 0,
            totalChars: 0,
            dailyCounts: <DateTime, int>{},
          ),
        ),
      ),
      tagStatsProvider.overrideWith((ref) => Stream.value(const <TagStat>[])),
      tagColorLookupProvider.overrideWith((ref) => TagColorLookup(const [])),
      unreadNotificationCountProvider.overrideWith((ref) => 0),
      currentWorkspacePreferencesProvider.overrideWith((ref) {
        final controller = _TestWorkspacePreferencesController(
          ref,
          initial: initial,
        );
        controllerSink?.call(controller);
        return controller;
      }),
    ],
    child: TranslationProvider(
      child: MaterialApp(
        locale: AppLocale.en.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: MediaQuery(
          data: const MediaQueryData(size: Size(430, 900)),
          child: home,
        ),
      ),
    ),
  );
}

class _FakeAppDatabase extends AppDatabase {
  _FakeAppDatabase() : super(dbName: 'fake.db');

  @override
  Future<int> countOutboxPending() async => 0;
}

class _TestSessionController extends AppSessionController {
  _TestSessionController()
    : super(
        const AsyncValue.data(
          AppSessionState(accounts: <Account>[], currentKey: null),
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
    return InstanceProfile.empty();
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
  _TestWorkspacePreferencesController(Ref ref, {WorkspacePreferences? initial})
    : super(
        ref,
        _TestWorkspacePreferencesRepository(
          initial ?? WorkspacePreferences.defaults,
        ),
        onLoaded: () {
          ref.read(workspacePreferencesLoadedProvider.notifier).state = true;
        },
      ) {
    state = initial ?? WorkspacePreferences.defaults;
  }
}

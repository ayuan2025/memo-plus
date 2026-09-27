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
import 'package:memos_flutter_app/i18n/strings.g.dart';
import 'package:memos_flutter_app/state/memos/memos_providers.dart';
import 'package:memos_flutter_app/state/memos/stats_providers.dart';
import 'package:memos_flutter_app/state/settings/preferences_migration_service.dart';
import 'package:memos_flutter_app/state/settings/workspace_preferences_provider.dart';
import 'package:memos_flutter_app/state/system/database_provider.dart';
import 'package:memos_flutter_app/state/system/local_library_provider.dart';
import 'package:memos_flutter_app/state/system/notifications_provider.dart';
import 'package:memos_flutter_app/state/system/session_provider.dart';

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

  testWidgets('drawer shows view more when tag section exceeds max height', (
    tester,
  ) async {
    AppDrawerDestination? selectedDestination;
    final tags = List.generate(
      12,
      (index) => TagStat(
        tag: 'tag${index + 1}',
        path: 'tag${index + 1}',
        count: index + 1,
        tagId: index + 1,
      ),
    );

    await tester.pumpWidget(
      _buildDrawerApp(
        tagStats: tags,
        child: Scaffold(
          body: AppDrawer(
            selected: AppDrawerDestination.memos,
            embedded: true,
            onSelect: (destination) => selectedDestination = destination,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('More'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('More'), findsOneWidget);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(selectedDestination, AppDrawerDestination.tags);
  });

  testWidgets('drawer expands selected tag ancestor chain', (tester) async {
    const tags = [
      TagStat(tag: 'work', path: 'work', count: 3, tagId: 1),
      TagStat(
        tag: 'work/project',
        path: 'work/project',
        count: 2,
        tagId: 2,
        parentId: 1,
      ),
    ];

    await tester.pumpWidget(
      _buildDrawerApp(
        tagStats: tags,
        child: Scaffold(
          body: AppDrawer(
            selected: AppDrawerDestination.memos,
            embedded: true,
            selectedTagPath: 'work/project',
            onSelect: (_) {},
            onSelectTag: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('work'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('project'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('drawer frequent filter changes tree ordering', (tester) async {
    const tags = [
      TagStat(tag: 'alpha', path: 'alpha', count: 1, tagId: 1),
      TagStat(tag: 'zeta', path: 'zeta', count: 9, tagId: 2),
    ];

    await tester.pumpWidget(
      _buildDrawerApp(
        tagStats: tags,
        child: Scaffold(
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
      find.text('alpha'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final alphaBefore = tester.getTopLeft(find.text('alpha')).dy;
    final zetaBefore = tester.getTopLeft(find.text('zeta')).dy;
    expect(alphaBefore, lessThan(zetaBefore));

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Frequent').last, warnIfMissed: false);
    await tester.pumpAndSettle();

    final alphaAfter = tester.getTopLeft(find.text('alpha')).dy;
    final zetaAfter = tester.getTopLeft(find.text('zeta')).dy;
    expect(zetaAfter, lessThan(alphaAfter));
  });

  testWidgets('drawer frequent filter keeps parents collapsed by default', (
    tester,
  ) async {
    const tags = [
      TagStat(tag: 'work', path: 'work', count: 1, tagId: 1),
      TagStat(
        tag: 'work/project',
        path: 'work/project',
        count: 9,
        tagId: 2,
        parentId: 1,
      ),
    ];

    await tester.pumpWidget(
      _buildDrawerApp(
        tagStats: tags,
        child: Scaffold(
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
      find.byIcon(Icons.tune),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Frequent').last, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('work'), findsOneWidget);
    expect(find.text('project'), findsNothing);
  });

  testWidgets('drawer expandedSidebar view mode renders sidebar wrapper', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildDrawerApp(
        tagStats: const [
          TagStat(tag: 'work', path: 'work', count: 1, tagId: 1),
        ],
        child: Scaffold(
          body: AppDrawer(
            selected: AppDrawerDestination.memos,
            embedded: true,
            viewMode: AppDrawerViewMode.expandedSidebar,
            onSelect: (_) {},
            onSelectTag: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('desktop-navigation-sidebar')),
      findsOneWidget,
    );
  });

  testWidgets('drawer rail view mode renders rail buttons with tooltips', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildDrawerApp(
        tagStats: const [
          TagStat(tag: 'work', path: 'work', count: 1, tagId: 1),
        ],
        child: Scaffold(
          body: AppDrawer(
            selected: AppDrawerDestination.memos,
            embedded: true,
            viewMode: AppDrawerViewMode.rail,
            onSelect: (_) {},
            onSelectTag: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('desktop-navigation-rail')),
      findsOneWidget,
    );
    expect(find.byTooltip('Tags'), findsOneWidget);
  });

  testWidgets('drawer rail menu opens labeled destination panel', (
    tester,
  ) async {
    AppDrawerDestination? selectedDestination;

    await tester.pumpWidget(
      _buildDrawerApp(
        tagStats: const [
          TagStat(tag: 'work', path: 'work', count: 1, tagId: 1),
        ],
        child: Scaffold(
          body: AppDrawer(
            selected: AppDrawerDestination.memos,
            embedded: true,
            viewMode: AppDrawerViewMode.rail,
            onSelect: (destination) => selectedDestination = destination,
            onSelectTag: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('desktop-navigation-rail-button-menu')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('desktop-navigation-rail-menu-panel')),
      findsOneWidget,
    );
    expect(find.text('Draft Box'), findsOneWidget);
    expect(find.text('Archive'), findsOneWidget);

    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    expect(selectedDestination, AppDrawerDestination.archived);
    expect(
      find.byKey(const ValueKey<String>('desktop-navigation-rail-menu-panel')),
      findsNothing,
    );
  });

  testWidgets('drawer rail tags button opens popover and selects tag', (
    tester,
  ) async {
    String? selectedTagPath;
    AppDrawerDestination? selectedDestination;

    await tester.pumpWidget(
      _buildDrawerApp(
        tagStats: const [
          TagStat(tag: 'work', path: 'work', count: 1, tagId: 1),
        ],
        child: Scaffold(
          body: AppDrawer(
            selected: AppDrawerDestination.memos,
            embedded: true,
            viewMode: AppDrawerViewMode.rail,
            onSelect: (destination) => selectedDestination = destination,
            onSelectTag: (path) => selectedTagPath = path,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('desktop-navigation-rail-button-tags')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey<String>('desktop-navigation-rail-tags-popover'),
      ),
      findsOneWidget,
    );
    expect(selectedDestination, isNull);

    await tester.tap(find.text('work').last);
    await tester.pumpAndSettle();

    expect(selectedTagPath, 'work');
    expect(
      find.byKey(
        const ValueKey<String>('desktop-navigation-rail-tags-popover'),
      ),
      findsNothing,
    );
  });

  testWidgets('drawer overlayPanel view mode renders overlay panel', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildDrawerApp(
        tagStats: const [
          TagStat(tag: 'work', path: 'work', count: 1, tagId: 1),
        ],
        child: Scaffold(
          body: AppDrawer(
            selected: AppDrawerDestination.memos,
            embedded: true,
            viewMode: AppDrawerViewMode.overlayPanel,
            onSelect: (_) {},
            onSelectTag: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('desktop-overlay-navigation-panel')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.grid_view), findsOneWidget);
  });

  testWidgets('heatmap uses day selection callback when supplied', (
    tester,
  ) async {
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    DateTime? selectedDay;

    await tester.pumpWidget(
      _buildDrawerApp(
        tagStats: const <TagStat>[],
        dailyCounts: <DateTime, int>{day: 2},
        child: Scaffold(
          body: AppDrawer(
            selected: AppDrawerDestination.memos,
            embedded: true,
            onSelect: (_) {},
            onSelectDay: (value) => selectedDay = value,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final dateLabel =
        '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    final heatmapCell = find.byWidgetPredicate(
      (widget) =>
          widget is Tooltip && widget.message?.contains(dateLabel) == true,
    );
    expect(heatmapCell, findsOneWidget);

    await tester.tap(heatmapCell);
    await tester.pumpAndSettle();

    expect(selectedDay, day);
    expect(tester.takeException(), isNull);
  });
}

Widget _buildDrawerApp({
  required List<TagStat> tagStats,
  required Widget child,
  Map<DateTime, int> dailyCounts = const <DateTime, int>{},
}) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(_FakeAppDatabase()),
      appSessionProvider.overrideWith((ref) => _TestSessionController()),
      currentLocalLibraryProvider.overrideWith((ref) => null),
      localStatsProvider.overrideWith(
        (ref) => Stream.value(
          LocalStats(
            totalMemos: 0,
            archivedMemos: 0,
            activeDays: 0,
            daysSinceFirstMemo: 0,
            totalChars: 0,
            dailyCounts: dailyCounts,
          ),
        ),
      ),
      tagStatsProvider.overrideWith((ref) => Stream.value(tagStats)),
      unreadNotificationCountProvider.overrideWith((ref) => 0),
      currentWorkspacePreferencesProvider.overrideWith(
        (ref) => _TestWorkspacePreferencesController(
          ref,
          initial: WorkspacePreferences.defaults,
        ),
      ),
    ],
    child: TranslationProvider(
      child: MaterialApp(
        locale: AppLocale.en.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: MediaQuery(
          data: const MediaQueryData(size: Size(430, 900)),
          child: child,
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

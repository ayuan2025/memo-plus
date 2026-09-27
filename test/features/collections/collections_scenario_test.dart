import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:memos_flutter_app/core/storage_read.dart';
import 'package:memos_flutter_app/data/db/app_database.dart';
import 'package:memos_flutter_app/data/models/account.dart';
import 'package:memos_flutter_app/data/models/collection_reader.dart';
import 'package:memos_flutter_app/data/models/instance_profile.dart';
import 'package:memos_flutter_app/data/models/local_library.dart';
import 'package:memos_flutter_app/data/models/local_memo.dart';
import 'package:memos_flutter_app/data/models/memo_collection.dart';
import 'package:memos_flutter_app/data/models/rss_article.dart';
import 'package:memos_flutter_app/data/models/workspace_preferences.dart';
import 'package:memos_flutter_app/features/collections/collection_detail_screen.dart';
import 'package:memos_flutter_app/features/collections/collections_screen.dart';
import 'package:memos_flutter_app/i18n/strings.g.dart';
import 'package:memos_flutter_app/state/collections/collection_reader_progress_provider.dart';
import 'package:memos_flutter_app/state/collections/collection_rss_providers.dart';
import 'package:memos_flutter_app/state/collections/collections_provider.dart';
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

  testWidgets(
    'smart collection shelf refreshes and opens detail when matching memo appears',
    (tester) async {
      final memosController = StreamController<List<LocalMemo>>();
      addTearDown(memosController.close);

      final collection = MemoCollection.createSmart(
        id: 'reading',
        title: 'Reading shelf',
        description: 'Reading highlights',
        rules: const CollectionRuleSet(
          tagPaths: <String>['reading'],
          tagMatchMode: CollectionTagMatchMode.any,
          includeDescendants: true,
          visibility: CollectionVisibilityScope.all,
          dateRule: CollectionDateRule.defaults,
          attachmentRule: CollectionAttachmentRule.any,
          pinnedOnly: false,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(_FakeAppDatabase()),
            appSessionProvider.overrideWith((ref) => _TestSessionController()),
            collectionReaderProgressRepositoryProvider.overrideWith(
              (ref) => _MemoryCollectionReaderProgressRepository(),
            ),
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
            collectionsProvider.overrideWith(
              (ref) => Stream.value([collection]),
            ),
            collectionCandidateMemosProvider.overrideWith(
              (ref) => memosController.stream,
            ),
            _emptyRssArticlesOverride(),
            tagStatsProvider.overrideWith(
              (ref) => Stream.value(const <TagStat>[]),
            ),
            tagColorLookupProvider.overrideWith(
              (ref) => TagColorLookup(const []),
            ),
            unreadNotificationCountProvider.overrideWith((ref) => 0),
            currentWorkspacePreferencesProvider.overrideWith(
              (ref) => _TestWorkspacePreferencesController(ref),
            ),
          ],
          child: TranslationProvider(
            child: MaterialApp(
              locale: AppLocale.en.flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: const MediaQuery(
                data: MediaQueryData(size: Size(430, 900)),
                child: CollectionsScreen(),
              ),
            ),
          ),
        ),
      );

      memosController.add(const <LocalMemo>[]);
      await tester.pumpAndSettle();

      expect(find.text('Reading shelf'), findsOneWidget);
      expect(find.text('No memo matched yet'), findsOneWidget);

      memosController.add(<LocalMemo>[
        _memo(
          uid: 'memo-1',
          content: 'Book note #reading',
          tags: const <String>['reading'],
          createTime: DateTime(2024, 2, 12, 9),
        ),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Reading shelf'), findsOneWidget);
      expect(find.text('No memo matched yet'), findsNothing);

      await tester.tap(find.text('Reading shelf'));
      await tester.pumpAndSettle();

      expect(_findRichTextContaining('Book note'), findsOneWidget);
    },
  );

  testWidgets('smart collection still matches after tag alias remapping', (
    tester,
  ) async {
    final collection = MemoCollection.createSmart(
      id: 'project-a',
      title: 'Project shelf',
      description: 'Project notes',
      rules: const CollectionRuleSet(
        tagPaths: <String>['project/a'],
        tagMatchMode: CollectionTagMatchMode.any,
        includeDescendants: true,
        visibility: CollectionVisibilityScope.all,
        dateRule: CollectionDateRule.defaults,
        attachmentRule: CollectionAttachmentRule.any,
        pinnedOnly: false,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(_FakeAppDatabase()),
          appSessionProvider.overrideWith((ref) => _TestSessionController()),
          collectionReaderProgressRepositoryProvider.overrideWith(
            (ref) => _MemoryCollectionReaderProgressRepository(),
          ),
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
          collectionsProvider.overrideWith((ref) => Stream.value([collection])),
          collectionCandidateMemosProvider.overrideWith(
            (ref) => Stream.value(<LocalMemo>[
              _memo(
                uid: 'memo-2',
                content: 'Alpha project note',
                tags: const <String>['project/alpha'],
                createTime: DateTime(2024, 2, 13, 10),
              ),
            ]),
          ),
          _emptyRssArticlesOverride(),
          tagStatsProvider.overrideWith(
            (ref) => Stream.value(const <TagStat>[]),
          ),
          tagColorLookupProvider.overrideWith(
            (ref) => TagColorLookup(
              const [],
              aliasPaths: const <String, String>{'project/a': 'project/alpha'},
            ),
          ),
          unreadNotificationCountProvider.overrideWith((ref) => 0),
          currentWorkspacePreferencesProvider.overrideWith(
            (ref) => _TestWorkspacePreferencesController(ref),
          ),
        ],
        child: TranslationProvider(
          child: MaterialApp(
            locale: AppLocale.en.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const CollectionDetailScreen(collectionId: 'project-a'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Project shelf'), findsWidgets);
    expect(_findRichTextContaining('Alpha project note'), findsOneWidget);
  });

  testWidgets('manual collection detail respects stored manual order', (
    tester,
  ) async {
    final collection = MemoCollection.createManual(
      id: 'manual-1',
      title: 'Trip shelf',
    );
    final memos = <LocalMemo>[
      _memo(
        uid: 'memo-1',
        content: 'First stop',
        tags: const <String>['travel'],
        createTime: DateTime(2024, 2, 10, 8),
      ),
      _memo(
        uid: 'memo-2',
        content: 'Second stop',
        tags: const <String>['travel'],
        createTime: DateTime(2024, 2, 11, 8),
      ),
      _memo(
        uid: 'memo-3',
        content: 'Third stop',
        tags: const <String>['travel'],
        createTime: DateTime(2024, 2, 12, 8),
      ),
    ];

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(_FakeAppDatabase()),
        appSessionProvider.overrideWith((ref) => _TestSessionController()),
        collectionReaderProgressRepositoryProvider.overrideWith(
          (ref) => _MemoryCollectionReaderProgressRepository(),
        ),
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
        collectionsProvider.overrideWith((ref) => Stream.value([collection])),
        collectionCandidateMemosProvider.overrideWith(
          (ref) => Stream.value(memos),
        ),
        _emptyRssArticlesOverride(),
        collectionManualItemUidsProvider.overrideWith((ref, collectionId) {
          return Stream.value(
            collectionId == 'manual-1'
                ? const <String>['memo-3', 'memo-1', 'memo-2']
                : const <String>[],
          );
        }),
        tagStatsProvider.overrideWith((ref) => Stream.value(const <TagStat>[])),
        tagColorLookupProvider.overrideWith((ref) => TagColorLookup(const [])),
        unreadNotificationCountProvider.overrideWith((ref) => 0),
        currentWorkspacePreferencesProvider.overrideWith(
          (ref) => _TestWorkspacePreferencesController(ref),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(collectionsProvider.future);
    await container.read(collectionCandidateMemosProvider.future);
    await container.read(collectionManualItemUidsProvider('manual-1').future);

    final resolved = container.read(
      collectionResolvedItemsProvider('manual-1'),
    );
    final resolvedUids = resolved.valueOrNull?.map((item) => item.uid).toList();

    expect(resolvedUids, const <String>['memo-3', 'memo-1', 'memo-2']);
  });

  testWidgets('collections stay browsable in local library mode', (
    tester,
  ) async {
    final collection = MemoCollection.createSmart(
      id: 'reading-local',
      title: 'Offline shelf',
      rules: const CollectionRuleSet(
        tagPaths: <String>['reading'],
        tagMatchMode: CollectionTagMatchMode.any,
        includeDescendants: true,
        visibility: CollectionVisibilityScope.all,
        dateRule: CollectionDateRule.defaults,
        attachmentRule: CollectionAttachmentRule.any,
        pinnedOnly: false,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(_FakeAppDatabase()),
          appSessionProvider.overrideWith((ref) => _TestSessionController()),
          collectionReaderProgressRepositoryProvider.overrideWith(
            (ref) => _MemoryCollectionReaderProgressRepository(),
          ),
          currentLocalLibraryProvider.overrideWithValue(
            const LocalLibrary(key: 'local-key', name: 'Local Library'),
          ),
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
          collectionsProvider.overrideWith((ref) => Stream.value([collection])),
          collectionCandidateMemosProvider.overrideWith(
            (ref) => Stream.value(<LocalMemo>[
              _memo(
                uid: 'memo-local',
                content: 'Offline reading note',
                tags: const <String>['reading'],
                createTime: DateTime(2024, 2, 14, 10),
              ),
            ]),
          ),
          _emptyRssArticlesOverride(),
          tagStatsProvider.overrideWith(
            (ref) => Stream.value(const <TagStat>[]),
          ),
          tagColorLookupProvider.overrideWith(
            (ref) => TagColorLookup(const []),
          ),
          unreadNotificationCountProvider.overrideWith((ref) => 0),
          currentWorkspacePreferencesProvider.overrideWith(
            (ref) => _TestWorkspacePreferencesController(ref),
          ),
        ],
        child: TranslationProvider(
          child: MaterialApp(
            locale: AppLocale.en.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const MediaQuery(
              data: MediaQueryData(size: Size(430, 900)),
              child: CollectionsScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Offline shelf'), findsOneWidget);

    final titleFinder = find.text('Offline shelf');
    await tester.scrollUntilVisible(
      titleFinder,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(titleFinder);
    await tester.tap(
      find.ancestor(of: titleFinder, matching: find.byType(InkWell)).first,
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(_findRichTextContaining('Offline reading note'), findsOneWidget);
  });

  testWidgets(
    'manual collection falls back to empty state when item disappears',
    (tester) async {
      final memosController = StreamController<List<LocalMemo>>();
      addTearDown(memosController.close);

      final collection = MemoCollection.createManual(
        id: 'manual-edge',
        title: 'Edge shelf',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(_FakeAppDatabase()),
            appSessionProvider.overrideWith((ref) => _TestSessionController()),
            collectionReaderProgressRepositoryProvider.overrideWith(
              (ref) => _MemoryCollectionReaderProgressRepository(),
            ),
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
            collectionsProvider.overrideWith(
              (ref) => Stream.value([collection]),
            ),
            collectionCandidateMemosProvider.overrideWith(
              (ref) => memosController.stream,
            ),
            _emptyRssArticlesOverride(),
            collectionManualItemUidsProvider.overrideWith((ref, collectionId) {
              return Stream.value(
                collectionId == 'manual-edge'
                    ? const <String>['memo-1']
                    : const <String>[],
              );
            }),
            tagStatsProvider.overrideWith(
              (ref) => Stream.value(const <TagStat>[]),
            ),
            tagColorLookupProvider.overrideWith(
              (ref) => TagColorLookup(const []),
            ),
            unreadNotificationCountProvider.overrideWith((ref) => 0),
            currentWorkspacePreferencesProvider.overrideWith(
              (ref) => _TestWorkspacePreferencesController(ref),
            ),
          ],
          child: TranslationProvider(
            child: MaterialApp(
              locale: AppLocale.en.flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: const MediaQuery(
                data: MediaQueryData(size: Size(430, 900)),
                child: CollectionDetailScreen(collectionId: 'manual-edge'),
              ),
            ),
          ),
        ),
      );

      memosController.add(<LocalMemo>[
        _memo(
          uid: 'memo-1',
          content: 'Temporary memo',
          tags: const <String>['travel'],
          createTime: DateTime(2024, 2, 15, 10),
        ),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('This collection has no items yet.'), findsNothing);

      memosController.add(const <LocalMemo>[]);
      await tester.pumpAndSettle();

      expect(find.text('This collection has no items yet.'), findsOneWidget);
    },
  );
}

LocalMemo _memo({
  required String uid,
  required String content,
  required List<String> tags,
  required DateTime createTime,
}) {
  return LocalMemo(
    uid: uid,
    content: content,
    contentFingerprint: 'fingerprint-$uid',
    visibility: 'PRIVATE',
    pinned: false,
    state: 'NORMAL',
    createTime: createTime,
    displayTime: createTime,
    updateTime: createTime.add(const Duration(minutes: 5)),
    tags: tags,
    attachments: const [],
    relationCount: 0,
    location: null,
    syncState: SyncState.synced,
    lastError: null,
  );
}

Override _emptyRssArticlesOverride() {
  return collectionRssArticlesProvider.overrideWith(
    (ref, collectionId) => Stream.value(const <RssArticleWithFeed>[]),
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
  _TestWorkspacePreferencesController(Ref ref)
    : super(
        ref,
        _TestWorkspacePreferencesRepository(WorkspacePreferences.defaults),
        onLoaded: () {
          ref.read(workspacePreferencesLoadedProvider.notifier).state = true;
        },
      ) {
    state = WorkspacePreferences.defaults;
  }
}

Finder _findRichTextContaining(String text) {
  return find.byElementPredicate((element) {
    final widget = element.widget;
    if (widget is RichText) {
      final renderObject = element.renderObject;
      if (renderObject is RenderBox &&
          renderObject.attached &&
          renderObject.hasSize) {
        final viewport =
            Offset.zero &
            (WidgetsBinding
                    .instance
                    .platformDispatcher
                    .views
                    .first
                    .physicalSize /
                WidgetsBinding
                    .instance
                    .platformDispatcher
                    .views
                    .first
                    .devicePixelRatio);
        final rect =
            renderObject.localToGlobal(Offset.zero) & renderObject.size;
        if (!rect.overlaps(viewport)) {
          return false;
        }
      }
      return widget.text.toPlainText().contains(text);
    }
    return false;
  });
}

class _MemoryCollectionReaderProgressRepository
    extends CollectionReaderProgressRepository {
  _MemoryCollectionReaderProgressRepository()
    : super(database: AppDatabase(dbName: 'collections_scenario_test.db'));

  CollectionReaderProgress? _progress;

  @override
  Future<CollectionReaderProgress?> load(String collectionId) async =>
      _progress;

  @override
  Future<void> save(CollectionReaderProgress progress) async {
    _progress = progress;
  }

  @override
  Future<void> clear(String collectionId) async {
    _progress = null;
  }
}

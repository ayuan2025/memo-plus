import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'package:memos_flutter_app/data/models/memo_collection.dart';
import 'package:memos_flutter_app/data/models/local_memo.dart';
import 'package:memos_flutter_app/data/repositories/collections_repository.dart';
import 'package:memos_flutter_app/features/collections/collection_editor_screen.dart';
import 'package:memos_flutter_app/i18n/strings.g.dart';
import 'package:memos_flutter_app/platform/platform_target.dart';
import 'package:memos_flutter_app/state/collections/collections_provider.dart';
import 'package:memos_flutter_app/state/memos/memos_providers.dart';
import 'package:memos_flutter_app/state/tags/tag_color_lookup.dart';
import 'package:memos_flutter_app/data/db/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LocaleSettings.setLocale(AppLocale.en);
    debugPlatformTargetOverride = null;
  });

  tearDown(() {
    debugPlatformTargetOverride = null;
  });

  testWidgets('prefills a smart collection from the selected tag', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(
        tagStats: const <TagStat>[
          TagStat(tag: 'project/alpha', path: 'project/alpha', count: 3),
        ],
        child: const CollectionEditorScreen(
          initialSelectedTags: <String>['project/alpha'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final titleField = tester.widget<TextField>(find.byType(TextField).first);
    expect(titleField.controller?.text, 'project/alpha');
    expect(find.text('#project/alpha'), findsWidgets);
    expect(find.text('Smart'), findsWidgets);
  });

  testWidgets('new smart collection exits immediately when unchanged', (
    tester,
  ) async {
    final observer = _RecordingNavigatorObserver();

    await tester.pumpWidget(
      _buildRouteTestApp(
        observer: observer,
        child: const CollectionEditorScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Discard unsaved changes?'), findsNothing);
    expect(observer.popCount, 1);
    expect(find.byType(CollectionEditorScreen), findsNothing);
    expect(find.text('route-host'), findsOneWidget);
  });

  testWidgets('new smart collection shows discard dialog after edits', (
    tester,
  ) async {
    final observer = _RecordingNavigatorObserver();

    await tester.pumpWidget(
      _buildRouteTestApp(
        observer: observer,
        child: const CollectionEditorScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Unsaved smart');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Discard unsaved changes?'), findsOneWidget);
    expect(observer.popCount, 0);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(observer.popCount, 0);
    expect(find.byType(CollectionEditorScreen), findsOneWidget);
  });

  testWidgets('new smart collection discards edits and closes once', (
    tester,
  ) async {
    final observer = _RecordingNavigatorObserver();

    await tester.pumpWidget(
      _buildRouteTestApp(
        observer: observer,
        child: const CollectionEditorScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Unsaved smart');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Discard'));
    await tester.pumpAndSettle();

    expect(observer.popCount, 1);
    expect(find.text('Discard unsaved changes?'), findsNothing);
    expect(find.byType(CollectionEditorScreen), findsNothing);
    expect(find.text('route-host'), findsOneWidget);
  });

  testWidgets('prefilled smart collection does not prompt on exit', (
    tester,
  ) async {
    final observer = _RecordingNavigatorObserver();

    await tester.pumpWidget(
      _buildRouteTestApp(
        observer: observer,
        tagStats: const <TagStat>[
          TagStat(tag: 'project/alpha', path: 'project/alpha', count: 3),
        ],
        child: const CollectionEditorScreen(
          initialSelectedTags: <String>['project/alpha'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Discard unsaved changes?'), findsNothing);
    expect(observer.popCount, 1);
  });

  testWidgets('new smart collection does not prompt after reverting edits', (
    tester,
  ) async {
    final observer = _RecordingNavigatorObserver();

    await tester.pumpWidget(
      _buildRouteTestApp(
        observer: observer,
        child: const CollectionEditorScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Transient');
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Discard unsaved changes?'), findsNothing);
    expect(observer.popCount, 1);
  });

  testWidgets('switches from smart rules to manual selection', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(child: const CollectionEditorScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Select tags'), findsOneWidget);

    await tester.tap(find.text('Manual').first);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Add memos'), findsOneWidget);
    expect(find.text('Select tags'), findsNothing);
  });

  testWidgets(
    'RSS creation option hides memo source controls and requires feed',
    (tester) async {
      await tester.pumpWidget(
        _buildTestApp(child: const CollectionEditorScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('RSS').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'RSS shelf');
      await tester.pumpAndSettle();

      expect(find.text('Manage feeds'), findsOneWidget);
      expect(find.text('Select tags'), findsNothing);
      expect(find.text('Add memos'), findsNothing);

      final createButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Create collection'),
      );
      expect(createButton.onPressed, isNull);
    },
  );

  testWidgets('editing unchanged manual collection exits immediately', (
    tester,
  ) async {
    final observer = _RecordingNavigatorObserver();
    final initialCollection = MemoCollection.createManual(
      id: 'manual-1',
      title: 'Manual shelf',
    );
    final candidateMemos = <LocalMemo>[
      _memo(uid: 'memo-1', content: 'Alpha note', tags: const <String>['a']),
      _memo(uid: 'memo-2', content: 'Beta note', tags: const <String>['b']),
    ];

    await tester.pumpWidget(
      _buildRouteTestApp(
        observer: observer,
        candidateMemos: candidateMemos,
        overrides: [
          collectionManualItemUidsProvider.overrideWith((ref, id) {
            return Stream.value(
              id == initialCollection.id
                  ? const <String>['memo-1', 'memo-2']
                  : const <String>[],
            );
          }),
        ],
        child: CollectionEditorScreen(initialCollection: initialCollection),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Discard unsaved changes?'), findsNothing);
    expect(observer.popCount, 1);
  });

  testWidgets('disables saving a smart collection without any rules', (
    tester,
  ) async {
    final repository = _MemoryCollectionsRepository();

    await tester.pumpWidget(
      _buildTestApp(
        repository: repository,
        child: const CollectionEditorScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Untitled smart');
    final createButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Create collection'),
    );

    expect(createButton.onPressed, isNull);
    expect(await repository.readAll(), isEmpty);
  });

  testWidgets('saves a manual collection and persists initial members', (
    tester,
  ) async {
    final repository = _MemoryCollectionsRepository();

    await tester.pumpWidget(
      _buildTestApp(
        repository: repository,
        child: const CollectionEditorScreen(
          initialType: MemoCollectionType.manual,
          initialManualMemoUids: <String>['memo-1', 'memo-2'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Manual shelf');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, 'Create and add 2 memos'),
    );
    await tester.pumpAndSettle();

    final collections = await repository.readAll();
    expect(collections, hasLength(1));
    final collection = collections.single;
    expect(collection.title, 'Manual shelf');
    expect(collection.type, MemoCollectionType.manual);
    expect(await repository.readManualItemUids(collection.id), <String>[
      'memo-1',
      'memo-2',
    ]);
  });

  testWidgets('desktop openCollectionEditor uses task surface chrome', (
    tester,
  ) async {
    debugPlatformTargetOverride = TargetPlatform.macOS;

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _buildTestApp(
        child: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => openCollectionEditor(
                    context,
                    initialType: MemoCollectionType.manual,
                    initialManualMemoUids: const <String>['memo-1'],
                  ),
                  child: const Text('Open editor'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Create collection'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    expect(find.byType(CollectionEditorScreen), findsOneWidget);
  });

  testWidgets('desktop task surface returns saved collection result', (
    tester,
  ) async {
    debugPlatformTargetOverride = TargetPlatform.macOS;
    final repository = _MemoryCollectionsRepository();
    MemoCollection? result;

    await tester.pumpWidget(
      _buildTestApp(
        repository: repository,
        child: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    result = await openCollectionEditor(
                      context,
                      initialType: MemoCollectionType.manual,
                      initialManualMemoUids: const <String>['memo-1'],
                    );
                  },
                  child: const Text('Open editor'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Desktop shelf');
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, 'Create and add 1 memo'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(result, isNotNull);
    expect(result?.title, 'Desktop shelf');
    expect((await repository.readAll()).single.title, 'Desktop shelf');
  });

  testWidgets('desktop task surface still confirms unsaved close', (
    tester,
  ) async {
    debugPlatformTargetOverride = TargetPlatform.macOS;

    await tester.pumpWidget(
      _buildTestApp(
        child: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => openCollectionEditor(context),
                  child: const Text('Open editor'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Unsaved smart');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Discard unsaved changes?'), findsOneWidget);
    expect(find.byType(CollectionEditorScreen), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Discard unsaved changes?'), findsNothing);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(CollectionEditorScreen), findsOneWidget);
  });

  testWidgets('saves display preferences', (tester) async {
    final repository = _MemoryCollectionsRepository();

    await tester.pumpWidget(
      _buildTestApp(
        repository: repository,
        child: const CollectionEditorScreen(
          initialType: MemoCollectionType.manual,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Quiet shelf');
    final personalizeLabel = find.text('Personalize & display');
    await tester.scrollUntilVisible(
      personalizeLabel,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(personalizeLabel);
    await tester.pumpAndSettle();

    final showStatsLabel = find.text('Show detail stats');
    await tester.scrollUntilVisible(
      showStatsLabel,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(showStatsLabel);
    await tester.pumpAndSettle();
    await tester.tap(
      find.ancestor(of: showStatsLabel, matching: find.byType(SwitchListTile)),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    final hideWhenEmptyLabel = find.text('Hide on shelf when empty');
    await tester.scrollUntilVisible(
      hideWhenEmptyLabel,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(hideWhenEmptyLabel);
    await tester.pumpAndSettle();
    await tester.tap(
      find.ancestor(
        of: hideWhenEmptyLabel,
        matching: find.byType(SwitchListTile),
      ),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Create collection'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final collections = await repository.readAll();
    expect(collections, hasLength(1));
    expect(collections.single.view.showStats, isFalse);
    expect(collections.single.hideWhenEmpty, isTrue);
  });

  testWidgets('editing a manual collection can clear all selected memos', (
    tester,
  ) async {
    final repository = _MemoryCollectionsRepository();
    final initialCollection = MemoCollection.createManual(
      id: 'manual-1',
      title: 'Manual shelf',
    );
    repository.seedManualCollection(
      initialCollection,
      manualItemUids: const <String>['memo-1'],
    );
    final existingManualItems = <LocalMemo>[
      _memo(
        uid: 'memo-1',
        content: 'Alpha note',
        tags: const <String>['project'],
      ),
    ];

    await tester.pumpWidget(
      _buildTestApp(
        repository: repository,
        candidateMemos: existingManualItems,
        overrides: [
          collectionManualItemUidsProvider.overrideWith((ref, id) {
            return Stream.value(
              id == initialCollection.id
                  ? const <String>['memo-1']
                  : const <String>[],
            );
          }),
        ],
        child: CollectionEditorScreen(initialCollection: initialCollection),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Add memos'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Add memos').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Empty manual collection'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(await repository.readManualItemUids(initialCollection.id), isEmpty);
  });

  testWidgets(
    'editing a manual collection preserves stored order when display sort differs',
    (tester) async {
      final repository = _MemoryCollectionsRepository();
      final initialCollection =
          MemoCollection.createManual(
            id: 'manual-1',
            title: 'Manual shelf',
          ).copyWith(
            view: const CollectionViewPreferences(
              defaultLayout: CollectionLayoutMode.shelf,
              sectionMode: CollectionSectionMode.none,
              sortMode: CollectionSortMode.updateTimeDesc,
              showStats: true,
              readingExperience: null,
              articleFlowDisplay: CollectionArticleFlowDisplaySettings.defaults,
              rssRefresh: CollectionRssRefreshPreferences.defaults,
            ),
          );
      repository.seedManualCollection(
        initialCollection,
        manualItemUids: const <String>['memo-1', 'memo-2'],
      );
      final existingManualItems = <LocalMemo>[
        _memo(
          uid: 'memo-1',
          content: 'Alpha note',
          tags: const <String>['project'],
          updateTime: DateTime(2024, 2, 1, 10, 5),
        ),
        _memo(
          uid: 'memo-2',
          content: 'Beta note',
          tags: const <String>['project'],
          updateTime: DateTime(2024, 2, 1, 11, 5),
        ),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          repository: repository,
          candidateMemos: existingManualItems,
          overrides: [
            collectionManualItemUidsProvider.overrideWith((ref, id) {
              return Stream.value(
                id == initialCollection.id
                    ? const <String>['memo-1', 'memo-2']
                    : const <String>[],
              );
            }),
            collectionResolvedItemsProvider.overrideWith((ref, id) {
              return AsyncValue.data(
                id == initialCollection.id
                    ? <LocalMemo>[
                        existingManualItems[1],
                        existingManualItems[0],
                      ]
                    : const <LocalMemo>[],
              );
            }),
          ],
          child: CollectionEditorScreen(initialCollection: initialCollection),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
      await tester.pumpAndSettle();

      expect(
        await repository.readManualItemUids(initialCollection.id),
        <String>['memo-1', 'memo-2'],
      );
    },
  );
}

Widget _buildTestApp({
  required Widget child,
  List<TagStat> tagStats = const <TagStat>[],
  CollectionsRepository? repository,
  List<LocalMemo> candidateMemos = const <LocalMemo>[],
  List<Override> overrides = const <Override>[],
}) {
  return ProviderScope(
    overrides: [
      if (repository != null)
        collectionsRepositoryProvider.overrideWith((ref) => repository),
      tagStatsProvider.overrideWith((ref) => Stream.value(tagStats)),
      collectionCandidateMemosProvider.overrideWith(
        (ref) => Stream.value(candidateMemos),
      ),
      tagColorLookupProvider.overrideWith((ref) => TagColorLookup(tagStats)),
      ...overrides,
    ],
    child: TranslationProvider(
      child: MaterialApp(
        locale: AppLocale.en.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: child,
      ),
    ),
  );
}

Widget _buildRouteTestApp({
  required Widget child,
  required NavigatorObserver observer,
  List<TagStat> tagStats = const <TagStat>[],
  CollectionsRepository? repository,
  List<LocalMemo> candidateMemos = const <LocalMemo>[],
  List<Override> overrides = const <Override>[],
}) {
  return ProviderScope(
    overrides: [
      if (repository != null)
        collectionsRepositoryProvider.overrideWith((ref) => repository),
      tagStatsProvider.overrideWith((ref) => Stream.value(tagStats)),
      collectionCandidateMemosProvider.overrideWith(
        (ref) => Stream.value(candidateMemos),
      ),
      tagColorLookupProvider.overrideWith((ref) => TagColorLookup(tagStats)),
      ...overrides,
    ],
    child: TranslationProvider(
      child: MaterialApp(
        locale: AppLocale.en.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        navigatorObservers: [observer],
        home: _EditorRouteTestHost(child: child),
      ),
    ),
  );
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  int popCount = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is! PageRoute<dynamic>) {
      super.didPop(route, previousRoute);
      return;
    }
    popCount += 1;
    super.didPop(route, previousRoute);
  }
}

class _EditorRouteTestHost extends StatefulWidget {
  const _EditorRouteTestHost({required this.child});

  final Widget child;

  @override
  State<_EditorRouteTestHost> createState() => _EditorRouteTestHostState();
}

class _EditorRouteTestHostState extends State<_EditorRouteTestHost> {
  bool _didPush = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPush) return;
    _didPush = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => widget.child));
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('route-host')));
  }
}

class _MemoryCollectionsRepository extends CollectionsRepository {
  _MemoryCollectionsRepository() : super(db: _NoopAppDatabase());

  final List<MemoCollection> _collections = <MemoCollection>[];
  final Map<String, List<String>> _manualItems = <String, List<String>>{};

  void seedManualCollection(
    MemoCollection collection, {
    List<String> manualItemUids = const <String>[],
  }) {
    final index = _collections.indexWhere((item) => item.id == collection.id);
    if (index >= 0) {
      _collections[index] = collection;
    } else {
      _collections.add(collection);
    }
    _manualItems[collection.id] = List<String>.from(manualItemUids);
  }

  @override
  Future<void> upsert(MemoCollection collection) async {
    final index = _collections.indexWhere((item) => item.id == collection.id);
    if (index >= 0) {
      _collections[index] = collection;
    } else {
      _collections.add(collection);
    }
  }

  @override
  Future<List<MemoCollection>> readAll() async {
    return List<MemoCollection>.unmodifiable(_collections);
  }

  @override
  Future<void> addManualItems(
    String collectionId,
    List<String> memoUids,
  ) async {
    final existing = _manualItems.putIfAbsent(collectionId, () => <String>[]);
    for (final memoUid in memoUids) {
      if (!existing.contains(memoUid)) {
        existing.add(memoUid);
      }
    }
  }

  @override
  Future<List<String>> readManualItemUids(String collectionId) async {
    return List<String>.unmodifiable(_manualItems[collectionId] ?? const []);
  }

  @override
  Future<void> reorderManualItems(
    String collectionId,
    List<String> memoUids,
  ) async {
    _manualItems[collectionId] = List<String>.from(memoUids);
  }

  @override
  Future<void> removeManualItem(
    String collectionId,
    List<String> memoUids,
  ) async {
    final existing = _manualItems.putIfAbsent(collectionId, () => <String>[]);
    existing.removeWhere(memoUids.contains);
  }
}

class _NoopAppDatabase extends AppDatabase {
  _NoopAppDatabase() : super(dbName: 'noop.db');

  @override
  Future<Database> get db async {
    throw UnimplementedError('No database access in memory-backed tests.');
  }
}

LocalMemo _memo({
  required String uid,
  required String content,
  required List<String> tags,
  DateTime? updateTime,
}) {
  final createTime = DateTime(2024, 2, 1, 10);
  return LocalMemo(
    uid: uid,
    content: content,
    contentFingerprint: 'fingerprint-$uid',
    visibility: 'PRIVATE',
    pinned: false,
    state: 'NORMAL',
    createTime: createTime,
    displayTime: createTime,
    updateTime: updateTime ?? createTime.add(const Duration(minutes: 5)),
    tags: tags,
    attachments: const [],
    relationCount: 0,
    location: null,
    syncState: SyncState.synced,
    lastError: null,
  );
}

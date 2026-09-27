import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'package:memos_flutter_app/data/db/app_database.dart';
import 'package:memos_flutter_app/data/models/local_memo.dart';
import 'package:memos_flutter_app/data/models/memo_collection.dart';
import 'package:memos_flutter_app/data/repositories/collections_repository.dart';
import 'package:memos_flutter_app/features/collections/manual_collection_manage_screen.dart';
import 'package:memos_flutter_app/i18n/strings.g.dart';
import 'package:memos_flutter_app/state/collections/collections_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LocaleSettings.setLocale(AppLocale.en);
  });

  testWidgets('shows empty state for a manual collection without items', (
    tester,
  ) async {
    const collectionId = 'manual-1';

    await tester.pumpWidget(
      _buildTestApp(
        collectionId: collectionId,
        collection: MemoCollection.createManual(
          id: collectionId,
          title: 'Project shelf',
        ),
        items: const <LocalMemo>[],
        manualItemUids: const <String>[],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('This collection has no items yet.'), findsOneWidget);
    expect(find.text('Add memos'), findsWidgets);
  });

  testWidgets('remove action calls repository for the selected memo', (
    tester,
  ) async {
    const collectionId = 'manual-1';
    final repository = _SpyCollectionsRepository();

    await tester.pumpWidget(
      _buildTestApp(
        collectionId: collectionId,
        repository: repository,
        collection: MemoCollection.createManual(
          id: collectionId,
          title: 'Project shelf',
        ),
        items: <LocalMemo>[
          _memo(
            uid: 'memo-1',
            content: 'Alpha note',
            tags: const <String>['project'],
          ),
        ],
        manualItemUids: const <String>['memo-1'],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Alpha note'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove'));
    await tester.pumpAndSettle();

    expect(repository.removedCollectionId, collectionId);
    expect(repository.removedMemoUids, <String>['memo-1']);
  });

  testWidgets(
    'shows stored manual order even when collection display sort differs',
    (tester) async {
      const collectionId = 'manual-1';

      await tester.pumpWidget(
        _buildTestApp(
          collectionId: collectionId,
          collection:
              MemoCollection.createManual(
                id: collectionId,
                title: 'Project shelf',
              ).copyWith(
                view: const CollectionViewPreferences(
                  defaultLayout: CollectionLayoutMode.shelf,
                  sectionMode: CollectionSectionMode.none,
                  sortMode: CollectionSortMode.updateTimeDesc,
                  showStats: true,
                  readingExperience: null,
                  articleFlowDisplay:
                      CollectionArticleFlowDisplaySettings.defaults,
                  rssRefresh: CollectionRssRefreshPreferences.defaults,
                ),
              ),
          items: <LocalMemo>[
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
          ],
          manualItemUids: const <String>['memo-1', 'memo-2'],
        ),
      );
      await tester.pumpAndSettle();

      final alphaFinder = find.textContaining('Alpha note');
      final betaFinder = find.textContaining('Beta note');

      expect(alphaFinder, findsOneWidget);
      expect(betaFinder, findsOneWidget);
      expect(
        tester.getTopLeft(alphaFinder).dy,
        lessThan(tester.getTopLeft(betaFinder).dy),
      );
    },
  );
}

Widget _buildTestApp({
  required String collectionId,
  required MemoCollection collection,
  required List<LocalMemo> items,
  required List<String> manualItemUids,
  CollectionsRepository? repository,
}) {
  return ProviderScope(
    overrides: [
      if (repository != null)
        collectionsRepositoryProvider.overrideWith((ref) => repository),
      collectionByIdProvider.overrideWith((ref, id) {
        return AsyncValue.data(id == collectionId ? collection : null);
      }),
      collectionManualItemUidsProvider.overrideWith((ref, id) {
        return Stream.value(
          id == collectionId ? manualItemUids : const <String>[],
        );
      }),
      collectionCandidateMemosProvider.overrideWith(
        (ref) => Stream.value(items),
      ),
    ],
    child: TranslationProvider(
      child: MaterialApp(
        locale: AppLocale.en.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: ManualCollectionManageScreen(collectionId: collectionId),
      ),
    ),
  );
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

class _SpyCollectionsRepository extends CollectionsRepository {
  _SpyCollectionsRepository() : super(db: _NoopAppDatabase());

  String? removedCollectionId;
  List<String>? removedMemoUids;

  @override
  Future<void> removeManualItem(
    String collectionId,
    List<String> memoUids,
  ) async {
    removedCollectionId = collectionId;
    removedMemoUids = List<String>.from(memoUids);
  }
}

class _NoopAppDatabase extends AppDatabase {
  _NoopAppDatabase() : super(dbName: 'noop.db');

  @override
  Future<Database> get db async {
    throw UnimplementedError('No database access in spy-backed tests.');
  }
}

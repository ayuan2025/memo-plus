import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/db/app_database.dart';
import 'package:memos_flutter_app/data/models/memo_collection.dart';
import 'package:memos_flutter_app/data/repositories/collections_repository.dart';

import '../../test_support.dart';

void main() {
  late TestSupport support;

  setUpAll(() async {
    support = await initializeTestSupport();
  });

  tearDownAll(() async {
    await support.dispose();
  });

  test(
    'CollectionsRepository supports CRUD, pin/archive and duplicate',
    () async {
      final dbName = uniqueDbName('collections_repository');
      final db = AppDatabase(dbName: dbName);
      final repository = CollectionsRepository(db: db);

      addTearDown(() async {
        await db.close();
        await deleteTestDatabase(dbName);
      });

      final created = MemoCollection.createSmart(
        id: 'collection-1',
        title: 'Reading',
        description: 'Reading shelf',
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

      await repository.upsert(created);

      final initialItems = await repository.readAll();
      expect(initialItems, hasLength(1));
      expect(initialItems.single.title, 'Reading');

      await repository.pin(created.id, true);
      await repository.archive(created.id, true);
      final updated = await repository.readById(created.id);
      expect(updated, isNotNull);
      expect(updated!.pinned, isTrue);
      expect(updated.archived, isTrue);

      final copy = await repository.duplicate(updated);
      expect(copy.id, isNot(equals(updated.id)));
      expect(copy.title, contains('Copy'));

      final allItems = await repository.readAll();
      expect(allItems, hasLength(2));

      await repository.delete(created.id);
      final remaining = await repository.readAll();
      expect(remaining, hasLength(1));
      expect(remaining.single.id, copy.id);
    },
  );

  test(
    'CollectionsRepository manages manual items and preserves order',
    () async {
      final dbName = uniqueDbName('collections_repository_manual');
      final db = AppDatabase(dbName: dbName);
      final repository = CollectionsRepository(db: db);

      addTearDown(() async {
        await db.close();
        await deleteTestDatabase(dbName);
      });

      final sqlite = await db.db;
      for (final uid in <String>['memo-1', 'memo-2', 'memo-3']) {
        await sqlite.insert('memos', <String, Object?>{
          'uid': uid,
          'content': uid,
          'visibility': 'PRIVATE',
          'pinned': 0,
          'state': 'NORMAL',
          'create_time': 1735689600,
          'display_time': 1735689600,
          'update_time': 1735689600,
          'tags': '',
          'attachments_json': '[]',
          'relation_count': 0,
          'sync_state': 0,
        });
      }

      final collection = MemoCollection.createManual(
        id: 'manual-1',
        title: 'Manual shelf',
      );
      await repository.upsert(collection);

      await repository.addManualItems(collection.id, const <String>[
        'memo-1',
        'memo-2',
        'memo-2',
      ]);
      expect(await repository.readManualItemUids(collection.id), <String>[
        'memo-1',
        'memo-2',
      ]);

      await repository.addManualItems(collection.id, const <String>['memo-3']);
      await repository.reorderManualItems(collection.id, const <String>[
        'memo-3',
        'memo-1',
        'memo-2',
      ]);
      expect(await repository.readManualItemUids(collection.id), <String>[
        'memo-3',
        'memo-1',
        'memo-2',
      ]);

      await repository.removeManualItem(collection.id, const <String>[
        'memo-1',
      ]);
      expect(await repository.readManualItemUids(collection.id), <String>[
        'memo-3',
        'memo-2',
      ]);

      final duplicate = await repository.duplicate(collection);
      expect(await repository.readManualItemUids(duplicate.id), <String>[
        'memo-3',
        'memo-2',
      ]);
    },
  );

  test(
    'CollectionsRepository preserves manual items when updating metadata',
    () async {
      final dbName = uniqueDbName('collections_repository_manual_update');
      final db = AppDatabase(dbName: dbName);
      final repository = CollectionsRepository(db: db);

      addTearDown(() async {
        await db.close();
        await deleteTestDatabase(dbName);
      });

      final sqlite = await db.db;
      for (final uid in <String>['memo-1', 'memo-2']) {
        await sqlite.insert('memos', <String, Object?>{
          'uid': uid,
          'content': uid,
          'visibility': 'PRIVATE',
          'pinned': 0,
          'state': 'NORMAL',
          'create_time': 1735689600,
          'display_time': 1735689600,
          'update_time': 1735689600,
          'tags': '',
          'attachments_json': '[]',
          'relation_count': 0,
          'sync_state': 0,
        });
      }

      final collection = MemoCollection.createManual(
        id: 'manual-update',
        title: 'Manual shelf',
      );
      await repository.upsert(collection);
      await repository.addManualItems(collection.id, const <String>[
        'memo-1',
        'memo-2',
      ]);

      await repository.upsert(
        collection.copyWith(
          title: 'Updated shelf',
          description: 'Renamed only',
          hideWhenEmpty: true,
        ),
      );

      expect(await repository.readManualItemUids(collection.id), <String>[
        'memo-1',
        'memo-2',
      ]);
    },
  );

  test(
    'CollectionsRepository reorder keeps omitted collections after reordered items',
    () async {
      final dbName = uniqueDbName('collections_repository_reorder_subset');
      final db = AppDatabase(dbName: dbName);
      final repository = CollectionsRepository(db: db);

      addTearDown(() async {
        await db.close();
        await deleteTestDatabase(dbName);
      });

      final first = MemoCollection.createSmart(id: 'a', title: 'Alpha');
      final second = MemoCollection.createSmart(id: 'b', title: 'Beta');
      final third = MemoCollection.createSmart(id: 'c', title: 'Gamma');

      await repository.upsert(first);
      await repository.upsert(second);
      await repository.upsert(third);

      await repository.reorder(const <String>['c', 'a']);

      final items = await repository.readAll();
      expect(items.map((item) => item.id), <String>['c', 'a', 'b']);
      expect(items.map((item) => item.sortOrder), <int>[0, 1, 2]);
    },
  );
}

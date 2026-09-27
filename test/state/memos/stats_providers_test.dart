import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memos_flutter_app/data/db/app_database.dart';
import 'package:memos_flutter_app/state/memos/stats_providers.dart';
import 'package:memos_flutter_app/state/system/database_provider.dart';
import 'package:memos_flutter_app/state/tags/tag_repository.dart';

import '../../test_support.dart';

void main() {
  late TestSupport support;

  setUpAll(() async {
    support = await initializeTestSupport();
  });

  tearDownAll(() async {
    await support.dispose();
  });

  test('annual insights inherits tag color from parent path', () async {
    final dbName = uniqueDbName('annual_insights_inherit_tag_color');
    final db = AppDatabase(dbName: dbName);
    final repository = TagRepository(db: db);
    final now = DateTime.utc(2025, 1, 15, 12);

    try {
      final parent = await repository.createTag(
        name: 'work',
        colorHex: '#3366FF',
      );
      await repository.createTag(name: 'project', parentId: parent.id);
      await db.upsertMemo(
        uid: 'memo-1',
        content: 'hello world',
        visibility: 'PRIVATE',
        pinned: false,
        state: 'NORMAL',
        createTimeSec: now.millisecondsSinceEpoch ~/ 1000,
        updateTimeSec: now.millisecondsSinceEpoch ~/ 1000,
        tags: const ['work/project'],
        attachments: const [],
        location: null,
        relationCount: 0,
        syncState: 0,
        lastError: null,
      );

      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      final insights = await container.read(
        annualInsightsProvider((year: 2025, month: 1)).future,
      );
      final project = insights.tagDistribution.firstWhere(
        (item) => item.tag == 'work/project',
      );

      expect(project.colorHex, '#3366FF');
    } finally {
      await db.close();
      await deleteTestDatabase(dbName);
    }
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/application/rss/rss_refresh_coordinator.dart';
import 'package:memos_flutter_app/application/rss/rss_feed_fetch_service.dart';
import 'package:memos_flutter_app/data/db/app_database.dart';
import 'package:memos_flutter_app/data/models/memo_collection.dart';
import 'package:memos_flutter_app/data/repositories/rss_repository.dart';
import 'package:memos_flutter_app/features/collections/collection_rss_open_refresh_gate.dart';
import 'package:memos_flutter_app/state/collections/collection_rss_providers.dart';

import '../../test_support.dart';

void main() {
  late TestSupport support;

  setUpAll(() async {
    support = await initializeTestSupport();
  });

  tearDownAll(() async {
    await support.dispose();
  });

  testWidgets('collection-open gate refreshes after the configured delay', (
    tester,
  ) async {
    final coordinator = _createRecordingCoordinator('rss_open_gate_delay');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rssRefreshCoordinatorProvider.overrideWithValue(coordinator),
        ],
        child: MaterialApp(
          home: CollectionRssOpenRefreshGate(
            collectionId: 'collection-rss',
            preferences: const CollectionRssRefreshPreferences(
              enabled: true,
              intervalMinutes: 30,
            ),
            delay: const Duration(milliseconds: 50),
            child: const Scaffold(body: Text('RSS collection ready')),
          ),
        ),
      ),
    );

    expect(find.text('RSS collection ready'), findsOneWidget);
    expect(coordinator.callCount, 0);

    await tester.pump(const Duration(milliseconds: 49));
    expect(coordinator.callCount, 0);

    await tester.pump(const Duration(milliseconds: 1));
    expect(coordinator.callCount, 1);
    expect(coordinator.collectionIds, <String>['collection-rss']);
  });

  testWidgets('collection-open gate does not refresh when disabled', (
    tester,
  ) async {
    final coordinator = _createRecordingCoordinator('rss_open_gate_disabled');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rssRefreshCoordinatorProvider.overrideWithValue(coordinator),
        ],
        child: MaterialApp(
          home: CollectionRssOpenRefreshGate(
            collectionId: 'collection-rss',
            preferences: const CollectionRssRefreshPreferences(
              enabled: false,
              intervalMinutes: 30,
            ),
            delay: const Duration(milliseconds: 1),
            child: const Scaffold(body: Text('RSS collection ready')),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 10));

    expect(coordinator.callCount, 0);
  });
}

_RecordingRssRefreshCoordinator _createRecordingCoordinator(String dbPrefix) {
  final dbName = uniqueDbName(dbPrefix);
  final db = AppDatabase(dbName: dbName);
  addTearDown(() async {
    await db.close();
    await deleteTestDatabase(dbName);
  });
  final repository = RssRepository(db: db);
  return _RecordingRssRefreshCoordinator(repository);
}

class _RecordingRssRefreshCoordinator extends RssRefreshCoordinator {
  _RecordingRssRefreshCoordinator(RssRepository repository)
    : super(
        repository: repository,
        fetchService: RssFeedFetchService(repository: repository),
      );

  int callCount = 0;
  final List<String> collectionIds = <String>[];

  @override
  Future<RssCollectionOpenRefreshResult> refreshCollectionOnOpen({
    required String collectionId,
    required CollectionRssRefreshPreferences preferences,
  }) async {
    callCount += 1;
    collectionIds.add(collectionId);
    final now = DateTime(2026, 5, 15, 12);
    return RssCollectionOpenRefreshResult(
      collectionId: collectionId,
      trigger: RssRefreshTrigger.collectionOpen,
      enabled: preferences.enabled,
      coalesced: false,
      startedAt: now,
      completedAt: now,
      consideredFeedCount: 0,
      staleFeedCount: 0,
      successCount: 0,
      failureCount: 0,
      failures: const <RssFeedRefreshFailure>[],
    );
  }
}

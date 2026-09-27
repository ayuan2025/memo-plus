import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/collection_readable_item.dart';
import '../../data/models/local_memo.dart';
import '../../data/models/memo_collection.dart';
import '../../data/models/rss_article.dart';
import '../../data/repositories/collections_repository.dart';
import '../system/database_provider.dart';
import '../tags/tag_color_lookup.dart';
import 'collection_rss_providers.dart';
import 'collection_resolver.dart';

class ManualCollectionMembershipItem {
  const ManualCollectionMembershipItem({
    required this.collection,
    required this.itemCount,
    required this.containsMemo,
  });

  final MemoCollection collection;
  final int itemCount;
  final bool containsMemo;
}

final collectionCandidateMemosProvider = StreamProvider<List<LocalMemo>>((
  ref,
) async* {
  final db = ref.watch(databaseProvider);

  Future<List<LocalMemo>> load() async {
    final rows = await db.listMemos(state: 'NORMAL', limit: null);
    return rows.map(LocalMemo.fromDb).toList(growable: false);
  }

  yield await load();
  await for (final _ in db.changes) {
    yield await load();
  }
});

final collectionsProvider = StreamProvider<List<MemoCollection>>((ref) async* {
  final db = ref.watch(databaseProvider);
  final repository = ref.watch(collectionsRepositoryProvider);

  Future<List<MemoCollection>> load() => repository.readAll();

  yield await load();
  await for (final _ in db.changes) {
    yield await load();
  }
});

final collectionViewPreferenceActionsProvider =
    Provider<CollectionViewPreferenceActions>((ref) {
      return CollectionViewPreferenceActions(
        repository: ref.watch(collectionsRepositoryProvider),
      );
    });

class CollectionViewPreferenceActions {
  const CollectionViewPreferenceActions({
    required CollectionsRepository repository,
  }) : _repository = repository;

  final CollectionsRepository _repository;

  Future<void> setReadingExperience(
    String collectionId,
    CollectionReadingExperience experience,
  ) {
    return _repository.setReadingExperience(collectionId, experience);
  }

  Future<void> setArticleFlowDisplaySettings(
    String collectionId,
    CollectionArticleFlowDisplaySettings display,
  ) {
    return _repository.setArticleFlowDisplaySettings(collectionId, display);
  }
}

final collectionManualItemUidsProvider =
    StreamProvider.family<List<String>, String>((ref, collectionId) async* {
      final db = ref.watch(databaseProvider);
      final repository = ref.watch(collectionsRepositoryProvider);

      Future<List<String>> load() =>
          repository.readManualItemUids(collectionId);

      yield await load();
      await for (final _ in db.changes) {
        yield await load();
      }
    });

final collectionByIdProvider =
    Provider.family<AsyncValue<MemoCollection?>, String>((ref, collectionId) {
      final collectionsAsync = ref.watch(collectionsProvider);
      if (collectionsAsync.isLoading && !collectionsAsync.hasValue) {
        return const AsyncValue.loading();
      }
      if (collectionsAsync.hasError) {
        return AsyncValue.error(
          collectionsAsync.error!,
          collectionsAsync.stackTrace ?? StackTrace.current,
        );
      }
      final items = collectionsAsync.valueOrNull ?? const <MemoCollection>[];
      for (final item in items) {
        if (item.id == collectionId) {
          return AsyncValue.data(item);
        }
      }
      return const AsyncValue.data(null);
    });

final collectionResolvedItemsProvider =
    Provider.family<AsyncValue<List<LocalMemo>>, String>((ref, collectionId) {
      final collectionAsync = ref.watch(collectionByIdProvider(collectionId));
      if (collectionAsync.isLoading && !collectionAsync.hasValue) {
        return const AsyncValue.loading();
      }
      if (collectionAsync.hasError) {
        return AsyncValue.error(
          collectionAsync.error!,
          collectionAsync.stackTrace ?? StackTrace.current,
        );
      }
      final collection = collectionAsync.valueOrNull;
      if (collection == null || collection.type == MemoCollectionType.rss) {
        return const AsyncValue.data(<LocalMemo>[]);
      }

      final memosAsync = ref.watch(collectionCandidateMemosProvider);
      final manualUidsAsync = collection.type == MemoCollectionType.manual
          ? ref.watch(collectionManualItemUidsProvider(collectionId))
          : const AsyncValue.data(<String>[]);
      if (memosAsync.isLoading || manualUidsAsync.isLoading) {
        if (!memosAsync.hasValue) {
          return const AsyncValue.loading();
        }
        if (collection.type == MemoCollectionType.manual &&
            !manualUidsAsync.hasValue) {
          return const AsyncValue.loading();
        }
      }
      if (memosAsync.hasError) {
        return AsyncValue.error(
          memosAsync.error!,
          memosAsync.stackTrace ?? StackTrace.current,
        );
      }
      if (manualUidsAsync.hasError) {
        return AsyncValue.error(
          manualUidsAsync.error!,
          manualUidsAsync.stackTrace ?? StackTrace.current,
        );
      }
      final memos = memosAsync.valueOrNull ?? const <LocalMemo>[];
      final tagLookup = ref.watch(tagColorLookupProvider);
      final manualMemoUids = manualUidsAsync.valueOrNull ?? const <String>[];
      return AsyncValue.data(
        resolveCollectionItems(
          collection,
          memos,
          manualMemoUids: manualMemoUids,
          resolveCanonicalTagPath: tagLookup.resolveCanonicalPath,
        ),
      );
    });

final collectionPreviewProvider =
    Provider.family<AsyncValue<MemoCollectionPreview>, String>((
      ref,
      collectionId,
    ) {
      final collectionAsync = ref.watch(collectionByIdProvider(collectionId));
      if (collectionAsync.isLoading && !collectionAsync.hasValue) {
        return const AsyncValue.loading();
      }
      if (collectionAsync.hasError) {
        return AsyncValue.error(
          collectionAsync.error!,
          collectionAsync.stackTrace ?? StackTrace.current,
        );
      }
      final collection = collectionAsync.valueOrNull;
      if (collection == null) {
        return AsyncValue.data(
          buildCollectionPreview(
            MemoCollection.createSmart(id: '', title: ''),
            const <LocalMemo>[],
          ),
        );
      }
      final tagLookup = ref.watch(tagColorLookupProvider);
      if (collection.type == MemoCollectionType.rss) {
        final rssItemsAsync = ref.watch(
          collectionRssArticlesProvider(collectionId),
        );
        if (rssItemsAsync.isLoading && !rssItemsAsync.hasValue) {
          return const AsyncValue.loading();
        }
        if (rssItemsAsync.hasError) {
          return AsyncValue.error(
            rssItemsAsync.error!,
            rssItemsAsync.stackTrace ?? StackTrace.current,
          );
        }
        return AsyncValue.data(
          buildRssCollectionPreview(
            collection,
            rssItemsAsync.valueOrNull ?? const <RssArticleWithFeed>[],
            resolveTagColorHexByPath: tagLookup.resolveEffectiveHexByPath,
          ),
        );
      }

      final itemsAsync = ref.watch(
        collectionResolvedItemsProvider(collectionId),
      );
      if (itemsAsync.isLoading && !itemsAsync.hasValue) {
        return const AsyncValue.loading();
      }
      if (itemsAsync.hasError) {
        return AsyncValue.error(
          itemsAsync.error!,
          itemsAsync.stackTrace ?? StackTrace.current,
        );
      }
      final items = itemsAsync.valueOrNull ?? const <LocalMemo>[];
      return AsyncValue.data(
        buildCollectionPreview(
          collection,
          items,
          resolveTagColorHexByPath: tagLookup.resolveEffectiveHexByPath,
        ),
      );
    });

final collectionResolvedReadableItemsProvider =
    Provider.family<AsyncValue<List<CollectionReadableItem>>, String>((
      ref,
      collectionId,
    ) {
      final collectionAsync = ref.watch(collectionByIdProvider(collectionId));
      if (collectionAsync.isLoading && !collectionAsync.hasValue) {
        return const AsyncValue.loading();
      }
      if (collectionAsync.hasError) {
        return AsyncValue.error(
          collectionAsync.error!,
          collectionAsync.stackTrace ?? StackTrace.current,
        );
      }
      final collection = collectionAsync.valueOrNull;
      if (collection == null) {
        return const AsyncValue.data(<CollectionReadableItem>[]);
      }
      if (collection.type == MemoCollectionType.rss) {
        final rssItemsAsync = ref.watch(
          collectionRssArticlesProvider(collectionId),
        );
        if (rssItemsAsync.isLoading && !rssItemsAsync.hasValue) {
          return const AsyncValue.loading();
        }
        if (rssItemsAsync.hasError) {
          return AsyncValue.error(
            rssItemsAsync.error!,
            rssItemsAsync.stackTrace ?? StackTrace.current,
          );
        }
        return AsyncValue.data(
          composeCollectionReadableItems(
            collection: collection,
            memoItems: const <LocalMemo>[],
            rssItems: rssItemsAsync.valueOrNull ?? const <RssArticleWithFeed>[],
          ),
        );
      }

      final memoItemsAsync = ref.watch(
        collectionResolvedItemsProvider(collectionId),
      );
      if (memoItemsAsync.isLoading && !memoItemsAsync.hasValue) {
        return const AsyncValue.loading();
      }
      if (memoItemsAsync.hasError) {
        return AsyncValue.error(
          memoItemsAsync.error!,
          memoItemsAsync.stackTrace ?? StackTrace.current,
        );
      }
      return AsyncValue.data(
        composeCollectionReadableItems(
          collection: collection,
          memoItems: memoItemsAsync.valueOrNull ?? const <LocalMemo>[],
          rssItems: const <RssArticleWithFeed>[],
        ),
      );
    });

final collectionsDashboardProvider =
    Provider<AsyncValue<List<MemoCollectionDashboardItem>>>((ref) {
      final collectionsAsync = ref.watch(collectionsProvider);
      if (collectionsAsync.isLoading && !collectionsAsync.hasValue) {
        return const AsyncValue.loading();
      }
      if (collectionsAsync.hasError) {
        return AsyncValue.error(
          collectionsAsync.error!,
          collectionsAsync.stackTrace ?? StackTrace.current,
        );
      }

      final collections =
          collectionsAsync.valueOrNull ?? const <MemoCollection>[];
      final needsMemoItems = collections.any(
        (collection) => collection.type != MemoCollectionType.rss,
      );
      final memosAsync = needsMemoItems
          ? ref.watch(collectionCandidateMemosProvider)
          : const AsyncValue.data(<LocalMemo>[]);
      if (memosAsync.isLoading && !memosAsync.hasValue) {
        return const AsyncValue.loading();
      }
      if (memosAsync.hasError) {
        return AsyncValue.error(
          memosAsync.error!,
          memosAsync.stackTrace ?? StackTrace.current,
        );
      }

      final memos = memosAsync.valueOrNull ?? const <LocalMemo>[];
      final tagLookup = ref.watch(tagColorLookupProvider);
      final dashboard = <MemoCollectionDashboardItem>[];
      for (final collection in collections) {
        final manualUidsAsync = collection.type == MemoCollectionType.manual
            ? ref.watch(collectionManualItemUidsProvider(collection.id))
            : const AsyncValue.data(<String>[]);
        final rssItemsAsync = collection.type == MemoCollectionType.rss
            ? ref.watch(collectionRssArticlesProvider(collection.id))
            : const AsyncValue.data(<RssArticleWithFeed>[]);
        if (manualUidsAsync.isLoading && !manualUidsAsync.hasValue) {
          return const AsyncValue.loading();
        }
        if (rssItemsAsync.isLoading && !rssItemsAsync.hasValue) {
          return const AsyncValue.loading();
        }
        if (manualUidsAsync.hasError) {
          return AsyncValue.error(
            manualUidsAsync.error!,
            manualUidsAsync.stackTrace ?? StackTrace.current,
          );
        }
        if (rssItemsAsync.hasError) {
          return AsyncValue.error(
            rssItemsAsync.error!,
            rssItemsAsync.stackTrace ?? StackTrace.current,
          );
        }
        final manualMemoUids = manualUidsAsync.valueOrNull ?? const <String>[];
        final items = collection.type == MemoCollectionType.rss
            ? const <LocalMemo>[]
            : resolveCollectionItems(
                collection,
                memos,
                manualMemoUids: manualMemoUids,
                resolveCanonicalTagPath: tagLookup.resolveCanonicalPath,
              );
        final preview = collection.type == MemoCollectionType.rss
            ? buildRssCollectionPreview(
                collection,
                rssItemsAsync.valueOrNull ?? const <RssArticleWithFeed>[],
                resolveTagColorHexByPath: tagLookup.resolveEffectiveHexByPath,
              )
            : buildCollectionPreview(
                collection,
                items,
                resolveTagColorHexByPath: tagLookup.resolveEffectiveHexByPath,
              );
        dashboard.add(
          MemoCollectionDashboardItem(
            collection: collection,
            preview: preview,
            items: items,
          ),
        );
      }
      return AsyncValue.data(dashboard);
    });

final manualCollectionMembershipsProvider =
    Provider.family<AsyncValue<List<ManualCollectionMembershipItem>>, String>((
      ref,
      memoUid,
    ) {
      final normalizedMemoUid = memoUid.trim();
      final collectionsAsync = ref.watch(collectionsProvider);
      if (collectionsAsync.isLoading && !collectionsAsync.hasValue) {
        return const AsyncValue.loading();
      }
      if (collectionsAsync.hasError) {
        return AsyncValue.error(
          collectionsAsync.error!,
          collectionsAsync.stackTrace ?? StackTrace.current,
        );
      }
      final collections =
          (collectionsAsync.valueOrNull ?? const <MemoCollection>[])
              .where((item) => item.type == MemoCollectionType.manual)
              .toList(growable: false);
      final memberships = <ManualCollectionMembershipItem>[];
      for (final collection in collections) {
        final manualUidsAsync = ref.watch(
          collectionManualItemUidsProvider(collection.id),
        );
        if (manualUidsAsync.isLoading && !manualUidsAsync.hasValue) {
          return const AsyncValue.loading();
        }
        if (manualUidsAsync.hasError) {
          return AsyncValue.error(
            manualUidsAsync.error!,
            manualUidsAsync.stackTrace ?? StackTrace.current,
          );
        }
        final itemUids = manualUidsAsync.valueOrNull ?? const <String>[];
        memberships.add(
          ManualCollectionMembershipItem(
            collection: collection,
            itemCount: itemUids.length,
            containsMemo:
                normalizedMemoUid.isNotEmpty &&
                itemUids.contains(normalizedMemoUid),
          ),
        );
      }
      return AsyncValue.data(memberships);
    });

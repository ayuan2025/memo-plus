import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/models/collection_article_flow.dart';
import '../system/database_provider.dart';
import 'collection_article_flow_progress_mutation_service.dart';

final collectionArticleFlowProgressRepositoryProvider =
    Provider<CollectionArticleFlowProgressRepository>((ref) {
      return CollectionArticleFlowProgressRepository(
        database: ref.watch(databaseProvider),
        mutations: ref.watch(
          collectionArticleFlowProgressMutationServiceProvider,
        ),
      );
    });

class CollectionArticleFlowProgressRepository {
  CollectionArticleFlowProgressRepository({
    required AppDatabase database,
    CollectionArticleFlowProgressMutationService? mutations,
  }) : _database = database,
       _mutations =
           mutations ??
           CollectionArticleFlowProgressMutationService(db: database);

  final AppDatabase _database;
  final CollectionArticleFlowProgressMutationService _mutations;

  Future<CollectionArticleFlowProgress?> load(String collectionId) async {
    final row = await _database.getCollectionArticleFlowProgressRow(
      collectionId,
    );
    if (row == null) {
      return null;
    }
    return CollectionArticleFlowProgress.fromRow(row);
  }

  Future<void> save(CollectionArticleFlowProgress progress) {
    return _mutations.save(progress);
  }

  Future<void> clear(String collectionId) {
    return _mutations.clear(collectionId);
  }
}

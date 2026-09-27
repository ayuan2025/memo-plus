import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/models/collection_article_flow.dart';
import '../system/database_provider.dart';

final collectionArticleFlowProgressMutationServiceProvider =
    Provider<CollectionArticleFlowProgressMutationService>((ref) {
      return CollectionArticleFlowProgressMutationService(
        db: ref.watch(databaseProvider),
      );
    });

class CollectionArticleFlowProgressMutationService {
  const CollectionArticleFlowProgressMutationService({required this.db});

  final AppDatabase db;

  Future<void> save(CollectionArticleFlowProgress progress) {
    return db.upsertCollectionArticleFlowProgressRow(progress.toRow());
  }

  Future<void> clear(String collectionId) {
    return db.deleteCollectionArticleFlowProgress(collectionId);
  }
}

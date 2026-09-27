import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../system/database_provider.dart';

final memoRelationsCacheMutationServiceProvider =
    Provider<MemoRelationsCacheMutationService>((ref) {
      return MemoRelationsCacheMutationService(db: ref.watch(databaseProvider));
    });

class MemoRelationsCacheMutationService {
  MemoRelationsCacheMutationService({required this.db});

  final AppDatabase db;

  Future<void> upsertMemoRelationsCache(
    String memoUid, {
    required String relationsJson,
  }) {
    return db.upsertMemoRelationsCache(memoUid, relationsJson: relationsJson);
  }
}

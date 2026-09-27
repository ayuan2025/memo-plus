import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../system/database_provider.dart';

final statsCacheMutationServiceProvider = Provider<StatsCacheMutationService>((
  ref,
) {
  return StatsCacheMutationService(db: ref.watch(databaseProvider));
});

class StatsCacheMutationService {
  StatsCacheMutationService({required this.db});

  final AppDatabase db;

  Future<void> rebuildStatsCache() async {
    await db.rebuildStatsCache();
  }
}

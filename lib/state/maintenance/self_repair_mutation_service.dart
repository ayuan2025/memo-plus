import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../system/database_provider.dart';

final selfRepairMutationServiceProvider = Provider<SelfRepairMutationService>((
  ref,
) {
  return SelfRepairMutationService(db: ref.watch(databaseProvider));
});

class SelfRepairMutationService {
  SelfRepairMutationService({required this.db});

  final AppDatabase db;
  Future<void>? _running;

  Future<void> repairTagsFromContent() {
    return _runExclusive(() async {
      await db.rebuildMemoTagsFromContent();
      await db.pruneOrphanTags();
    });
  }

  Future<void> rebuildSearchIndex() {
    return _runExclusive(db.rebuildMemoSearchIndex);
  }

  Future<void> rebuildStatsCache() {
    return _runExclusive(db.rebuildStatsCache);
  }

  Future<void> _runExclusive(Future<void> Function() action) {
    final current = _running;
    if (current != null) {
      throw StateError('A self-repair operation is already running.');
    }
    late final Future<void> next;
    next = action().whenComplete(() {
      if (identical(_running, next)) {
        _running = null;
      }
    });
    _running = next;
    return next;
  }
}

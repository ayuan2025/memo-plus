import 'package:sqflite/sqflite.dart';

import '../../core/tags.dart';
import 'tag_db_persistence.dart';

class MemoTagReconciliationResult {
  const MemoTagReconciliationResult({
    required this.canonicalPaths,
    required this.tagIds,
  });

  final List<String> canonicalPaths;
  final List<int> tagIds;

  String get tagsText => canonicalPaths.join(' ');
}

final class MemoTagReconciler {
  const MemoTagReconciler._();

  static Future<MemoTagReconciliationResult> reconcile(
    DatabaseExecutor executor,
    Iterable<String> rawTags,
  ) async {
    final resolved = <String, int>{};
    for (final raw in rawTags) {
      final normalized = normalizeTagPath(raw);
      if (normalized.isEmpty) continue;
      final resolvedTag = await TagDbPersistence.resolvePath(
        executor,
        normalized,
      );
      if (resolvedTag == null) continue;
      resolved.putIfAbsent(resolvedTag.path, () => resolvedTag.id);
    }
    return MemoTagReconciliationResult(
      canonicalPaths: resolved.keys.toList(growable: false),
      tagIds: resolved.values.toList(growable: false),
    );
  }
}

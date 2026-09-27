import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../system/database_provider.dart';

final composeDraftMutationServiceProvider = Provider<ComposeDraftMutationService>(
  (ref) {
    return ComposeDraftMutationService(db: ref.watch(databaseProvider));
  },
);

class ComposeDraftMutationService {
  ComposeDraftMutationService({required this.db});

  final AppDatabase db;

  Future<void> upsertDraftRow(Map<String, Object?> row) async {
    await db.upsertComposeDraftRow(row);
  }

  Future<void> deleteDraft(String uid) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) return;
    await db.deleteComposeDraft(normalizedUid);
  }

  Future<void> deleteDraftsByWorkspace(String workspaceKey) async {
    final normalizedWorkspaceKey = workspaceKey.trim();
    if (normalizedWorkspaceKey.isEmpty) return;
    await db.deleteComposeDraftsByWorkspace(normalizedWorkspaceKey);
  }

  Future<void> replaceDraftRows({
    required String workspaceKey,
    required List<Map<String, Object?>> rows,
  }) async {
    final normalizedWorkspaceKey = workspaceKey.trim();
    if (normalizedWorkspaceKey.isEmpty) return;
    await db.replaceComposeDraftRows(
      workspaceKey: normalizedWorkspaceKey,
      rows: rows,
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/models/quick_clip_recovery_job.dart';
import '../system/database_provider.dart';

final quickClipRecoveryMutationServiceProvider =
    Provider<QuickClipRecoveryMutationService>((ref) {
      return QuickClipRecoveryMutationService(db: ref.watch(databaseProvider));
    });

class QuickClipRecoveryMutationService {
  const QuickClipRecoveryMutationService({required this.db});

  final AppDatabase db;

  Future<void> upsertJob(QuickClipRecoveryJob job) {
    return db.upsertQuickClipRecoveryJob(job);
  }

  Future<QuickClipRecoveryJob?> getJobByMemoUid(String memoUid) {
    return db.getQuickClipRecoveryJobByMemoUid(memoUid);
  }

  Future<List<QuickClipRecoveryJob>> listRecoverableJobs({int limit = 20}) {
    return db.listRecoverableQuickClipRecoveryJobs(limit: limit);
  }

  Future<List<QuickClipRecoveryJob>> listStaleJobs({
    required DateTime staleBefore,
    int limit = 20,
  }) {
    return db.listStaleQuickClipRecoveryJobs(
      staleBefore: staleBefore,
      limit: limit,
    );
  }

  Future<int> markRunning({
    required String memoUid,
    required DateTime now,
    String? lastError,
  }) {
    return db.markQuickClipRecoveryJobRunning(
      memoUid: memoUid,
      now: now,
      lastError: lastError,
    );
  }

  Future<int> markCompleted({required String memoUid, required DateTime now}) {
    return db.markQuickClipRecoveryJobCompleted(memoUid: memoUid, now: now);
  }

  Future<int> markAbandoned({
    required String memoUid,
    required DateTime now,
    String? lastError,
  }) {
    return db.markQuickClipRecoveryJobAbandoned(
      memoUid: memoUid,
      now: now,
      lastError: lastError,
    );
  }

  Future<int> markFailed({
    required String memoUid,
    required DateTime now,
    String? lastError,
  }) {
    return db.markQuickClipRecoveryJobFailed(
      memoUid: memoUid,
      now: now,
      lastError: lastError,
    );
  }

  Future<int> deleteTerminalJobs({
    required DateTime completedBefore,
    int limit = 100,
  }) {
    return db.deleteTerminalQuickClipRecoveryJobs(
      completedBefore: completedBefore,
      limit: limit,
    );
  }
}

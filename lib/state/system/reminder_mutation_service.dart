import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/models/memo_reminder.dart';
import 'database_provider.dart';

final reminderMutationServiceProvider = Provider<ReminderMutationService>((
  ref,
) {
  return ReminderMutationService(db: ref.watch(databaseProvider));
});

class ReminderMutationService {
  ReminderMutationService({required this.db});

  final AppDatabase db;

  Future<void> saveReminder({
    required String memoUid,
    required ReminderMode mode,
    required List<DateTime> times,
  }) async {
    final normalizedUid = memoUid.trim();
    if (normalizedUid.isEmpty) return;
    final sortedTimes = [...times]..sort();
    await db.upsertMemoReminder(
      memoUid: normalizedUid,
      mode: mode.name,
      timesJson: MemoReminder.encodeTimes(sortedTimes),
    );
  }

  Future<void> deleteReminder(String memoUid) async {
    final normalizedUid = memoUid.trim();
    if (normalizedUid.isEmpty) return;
    await db.deleteMemoReminder(normalizedUid);
  }
}

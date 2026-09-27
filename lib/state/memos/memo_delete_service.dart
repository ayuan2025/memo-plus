import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/memo_content_diagnostics.dart';
import '../../data/models/local_memo.dart';
import '../system/logging_provider.dart';
import 'memo_mutation_service.dart';
import 'memo_timeline_provider.dart';

final memoDeleteServiceProvider = Provider<MemoDeleteService>((ref) {
  return MemoDeleteService(ref);
});

class MemoDeleteService {
  MemoDeleteService(this._ref);

  final Ref _ref;

  Future<void> deleteMemo(
    LocalMemo memo, {
    void Function()? onMovedToRecycleBin,
  }) async {
    final logManager = _ref.read(logManagerProvider);
    final diagnostics = <String, Object?>{
      ...buildMemoContentDiagnostics(memo.content, memoUid: memo.uid),
      'attachmentCount': memo.attachments.length,
      'tagCount': memo.tags.length,
      'state': memo.state,
      'visibility': memo.visibility,
      'pinned': memo.pinned,
    };
    logManager.info('Memo delete requested', context: diagnostics);
    final timelineService = _ref.read(memoTimelineServiceProvider);
    await timelineService.moveMemoToRecycleBin(memo);
    logManager.info('Memo delete moved to recycle bin', context: diagnostics);
    onMovedToRecycleBin?.call();
    logManager.info(
      'Memo delete animation callback fired',
      context: diagnostics,
    );
    await _ref
        .read(memoMutationServiceProvider)
        .deleteMemoAfterRecycleBinMove(memo);
    logManager.info(
      'Memo delete queued for local removal',
      context: diagnostics,
    );
  }
}

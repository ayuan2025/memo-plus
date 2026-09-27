import '../../data/ai/ai_analysis_models.dart';
import '../../data/models/local_memo.dart';

enum RandomWalkSourceScope { allMemos, exploreMemos, aiHistory }

enum RandomWalkMemoOrigin { localAll, explore }

class RandomWalkQuery {
  RandomWalkQuery({
    required this.source,
    required List<String> selectedTagKeys,
    required this.dateStartSec,
    required this.dateEndSecExclusive,
    required this.sampleLimit,
    required this.sampleSeed,
  }) : selectedTagKeys = List.unmodifiable(selectedTagKeys);

  final RandomWalkSourceScope source;
  final List<String> selectedTagKeys;
  final int? dateStartSec;
  final int? dateEndSecExclusive;
  final int sampleLimit;
  final int sampleSeed;

  bool get supportsTagFilter => source != RandomWalkSourceScope.aiHistory;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RandomWalkQuery &&
        other.source == source &&
        other.dateStartSec == dateStartSec &&
        other.dateEndSecExclusive == dateEndSecExclusive &&
        other.sampleLimit == sampleLimit &&
        other.sampleSeed == sampleSeed &&
        _sameList(other.selectedTagKeys, selectedTagKeys);
  }

  @override
  int get hashCode {
    return Object.hash(
      source,
      dateStartSec,
      dateEndSecExclusive,
      sampleLimit,
      sampleSeed,
      Object.hashAll(selectedTagKeys),
    );
  }

  static bool _sameList(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}

class RandomWalkDeckEntry {
  const RandomWalkDeckEntry.memo({
    required this.memo,
    required this.memoOrigin,
    this.creatorRef,
    this.creatorFallback = '',
  }) : historyEntry = null,
       fullBodyText = null;

  const RandomWalkDeckEntry.aiHistory({
    required this.historyEntry,
    required this.fullBodyText,
  }) : memo = null,
       memoOrigin = null,
       creatorRef = null,
       creatorFallback = '';

  final LocalMemo? memo;
  final RandomWalkMemoOrigin? memoOrigin;
  final AiSavedAnalysisHistoryEntry? historyEntry;
  final String? creatorRef;
  final String creatorFallback;
  final String? fullBodyText;

  bool get isMemo => memo != null;
  bool get isAiHistory => historyEntry != null;

  String get key {
    final resolvedMemo = memo;
    if (resolvedMemo != null) {
      return 'memo:${memoOrigin!.name}:${resolvedMemo.uid}';
    }
    return 'ai:${historyEntry!.taskId}';
  }

  String get revisionKey {
    final resolvedMemo = memo;
    if (resolvedMemo != null) {
      return [
        resolvedMemo.contentFingerprint,
        resolvedMemo.pinned.toString(),
        resolvedMemo.state,
        resolvedMemo.updateTime.microsecondsSinceEpoch.toString(),
        resolvedMemo.syncState.index.toString(),
        resolvedMemo.lastError ?? '',
        creatorRef ?? '',
        creatorFallback,
      ].join('|');
    }
    final resolvedHistory = historyEntry!;
    return [
      resolvedHistory.taskId.toString(),
      resolvedHistory.summary,
      resolvedHistory.promptTemplate,
      resolvedHistory.createdTime.toString(),
      resolvedHistory.isStale.toString(),
      fullBodyText ?? '',
    ].join('|');
  }
}

class RandomWalkSignInRequiredException implements Exception {
  const RandomWalkSignInRequiredException();

  @override
  String toString() => 'RandomWalkSignInRequiredException';
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tags.dart';
import '../../data/ai/ai_analysis_models.dart';
import '../../data/api/memos_api.dart';
import '../../data/models/local_memo.dart';
import '../../state/memos/memos_providers.dart';
import '../../state/review/ai_analysis_provider.dart';
import '../../state/settings/device_preferences_provider.dart';
import '../../state/system/database_provider.dart';
import '../../state/system/session_provider.dart';
import '../../state/tags/tag_color_lookup.dart';
import 'random_walk_display.dart';
import 'random_walk_models.dart';
import 'random_walk_sampling.dart';

const randomWalkSampleLimit = 200;
const _exploreFetchPageSize = 200;
const _exploreOrderBy = 'display_time desc';

final randomWalkDeckProvider =
    StreamProvider.family<List<RandomWalkDeckEntry>, RandomWalkQuery>((
      ref,
      query,
    ) {
      switch (query.source) {
        case RandomWalkSourceScope.allMemos:
          final db = ref.watch(databaseProvider);
          final tagColors = ref.watch(tagColorLookupProvider);
          return db
              .watchMemos(state: 'NORMAL', limit: null)
              .map(
                (rows) => buildRandomWalkEntriesFromLocalRows(
                  rows,
                  query: query,
                  tagColors: tagColors,
                ),
              );
        case RandomWalkSourceScope.exploreMemos:
          return Stream.fromFuture(loadExploreRandomWalkEntries(ref, query));
        case RandomWalkSourceScope.aiHistory:
          return Stream.fromFuture(loadAiHistoryRandomWalkEntries(ref, query));
      }
    });

List<RandomWalkDeckEntry> buildRandomWalkEntriesFromLocalRows(
  List<Map<String, dynamic>> rows, {
  required RandomWalkQuery query,
  required TagColorLookup tagColors,
}) {
  final random = math.Random(query.sampleSeed);
  final filtered = rows
      .map(LocalMemo.fromDb)
      .where((memo) => _memoMatchesQuery(memo, query, tagColors))
      .map(
        (memo) => RandomWalkDeckEntry.memo(
          memo: memo,
          memoOrigin: RandomWalkMemoOrigin.localAll,
          creatorFallback: '',
        ),
      );
  return sampleUpTo(filtered, query.sampleLimit, random);
}

Future<List<RandomWalkDeckEntry>> loadExploreRandomWalkEntries(
  Ref ref,
  RandomWalkQuery query,
) async {
  final account = ref.read(appSessionProvider).valueOrNull?.currentAccount;
  if (account == null) {
    throw const RandomWalkSignInRequiredException();
  }
  final tagColors = ref.read(tagColorLookupProvider);
  final api = ref.read(memosApiProvider);
  final includeProtected = account.personalAccessToken.trim().isNotEmpty;
  return collectExploreRandomWalkEntries(
    api: api,
    query: query,
    tagColors: tagColors,
    includeProtected: includeProtected,
  );
}

Future<List<RandomWalkDeckEntry>> collectExploreRandomWalkEntries({
  required MemosApi api,
  required RandomWalkQuery query,
  required TagColorLookup tagColors,
  required bool includeProtected,
}) async {
  final random = math.Random(query.sampleSeed);
  final sampler = ReservoirSampler<RandomWalkDeckEntry>(
    query.sampleLimit,
    random,
  );
  final seenMemoUids = <String>{};
  String? pageToken;
  do {
    final result = await api.listExploreMemos(
      pageSize: _exploreFetchPageSize,
      pageToken: pageToken,
      state: 'NORMAL',
      filter: _buildExploreFilter(includeProtected: includeProtected),
      orderBy: _exploreOrderBy,
    );
    for (final memo in result.memos) {
      final uid = memo.uid.trim();
      if (uid.isEmpty || !seenMemoUids.add(uid)) continue;
      final localMemo = LocalMemo.fromRemote(memo);
      if (!_memoMatchesQuery(localMemo, query, tagColors)) continue;
      sampler.add(
        RandomWalkDeckEntry.memo(
          memo: localMemo,
          memoOrigin: RandomWalkMemoOrigin.explore,
          creatorRef: memo.creator.trim(),
          creatorFallback: normalizeCreatorFallback(memo.creator),
        ),
      );
    }
    pageToken = result.nextPageToken.trim().isEmpty
        ? null
        : result.nextPageToken;
  } while (pageToken != null);
  return sampler.take();
}

Future<List<RandomWalkDeckEntry>> loadAiHistoryRandomWalkEntries(
  Ref ref,
  RandomWalkQuery query,
) async {
  final repository = ref.read(aiAnalysisRepositoryProvider);
  final history = await repository.listAnalysisReportHistory(
    analysisType: AiAnalysisType.emotionMap,
    limit: null,
  );
  final selected = buildRandomWalkEntriesFromAiHistory(history, query: query);
  if (selected.isEmpty) return const <RandomWalkDeckEntry>[];

  final reports = <int, AiSavedAnalysisReport>{};
  await Future.wait(
    selected.map((entry) async {
      final historyEntry = entry.historyEntry;
      if (historyEntry == null || historyEntry.taskId <= 0) return;
      final report = await repository.loadAnalysisReportByTaskId(
        historyEntry.taskId,
      );
      if (report != null) {
        reports[historyEntry.taskId] = report;
      }
    }),
  );

  final language = ref.read(devicePreferencesProvider).language;
  final isZh = isZhLanguage(language);
  return selected
      .map((entry) {
        final historyEntry = entry.historyEntry!;
        final report = reports[historyEntry.taskId];
        final fullBodyText = report == null
            ? historyEntry.summary.trim()
            : buildAiHistoryFullBodyText(report, isZh: isZh);
        return RandomWalkDeckEntry.aiHistory(
          historyEntry: historyEntry,
          fullBodyText: fullBodyText,
        );
      })
      .toList(growable: false);
}

List<RandomWalkDeckEntry> buildRandomWalkEntriesFromAiHistory(
  Iterable<AiSavedAnalysisHistoryEntry> history, {
  required RandomWalkQuery query,
}) {
  final random = math.Random(query.sampleSeed);
  final filtered = history
      .where((entry) {
        if (entry.taskId <= 0) return false;
        if (entry.summary.trim().isEmpty &&
            entry.promptTemplate.trim().isEmpty) {
          return false;
        }
        return _entryMatchesDate(entry, query);
      })
      .map(
        (entry) => RandomWalkDeckEntry.aiHistory(
          historyEntry: entry,
          fullBodyText: entry.summary.trim(),
        ),
      );
  return sampleUpTo(filtered, query.sampleLimit, random);
}

String _buildExploreFilter({required bool includeProtected}) {
  final visibilities = includeProtected ? ['PUBLIC', 'PROTECTED'] : ['PUBLIC'];
  final visibilityExpr = visibilities.map((value) => '"$value"').join(', ');
  return 'visibility in [$visibilityExpr]';
}

bool _memoMatchesQuery(
  LocalMemo memo,
  RandomWalkQuery query,
  TagColorLookup tagColors,
) {
  if (!_memoMatchesDate(memo, query)) return false;
  if (!query.supportsTagFilter || query.selectedTagKeys.isEmpty) {
    return true;
  }
  final memoTagKeys = memo.tags
      .map(normalizeTagPath)
      .map(tagColors.resolveCanonicalPath)
      .where((key) => key.isNotEmpty)
      .toSet();
  for (final key in query.selectedTagKeys) {
    if (memoTagKeys.contains(key)) return true;
  }
  return false;
}

bool _memoMatchesDate(LocalMemo memo, RandomWalkQuery query) {
  final startSec = query.dateStartSec;
  if (startSec != null) {
    final memoSec = memo.createTime.toUtc().millisecondsSinceEpoch ~/ 1000;
    if (memoSec < startSec) return false;
  }
  final endSec = query.dateEndSecExclusive;
  if (endSec != null) {
    final memoSec = memo.createTime.toUtc().millisecondsSinceEpoch ~/ 1000;
    if (memoSec >= endSec) return false;
  }
  return true;
}

bool _entryMatchesDate(
  AiSavedAnalysisHistoryEntry entry,
  RandomWalkQuery query,
) {
  final startSec = query.dateStartSec;
  if (startSec != null && entry.createdTime ~/ 1000 < startSec) {
    return false;
  }
  final endSec = query.dateEndSecExclusive;
  if (endSec != null && entry.createdTime ~/ 1000 >= endSec) {
    return false;
  }
  return true;
}

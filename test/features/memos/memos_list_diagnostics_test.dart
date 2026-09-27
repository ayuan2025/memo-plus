import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/application/sync/sync_types.dart';
import 'package:memos_flutter_app/data/logs/sync_queue_progress_tracker.dart';
import 'package:memos_flutter_app/data/models/local_memo.dart';
import 'package:memos_flutter_app/features/memos/memos_list_diagnostics.dart';
import 'package:memos_flutter_app/state/memos/memos_providers.dart';

void main() {
  test('maybeLogEmptyViewDiagnostics skips work outside debug mode', () async {
    var emptyDiagnosticsCalls = 0;
    final diagnostics = MemosListDiagnostics(
      debugLog: (_, {error, stackTrace, context}) {},
      infoLog: (_, {error, stackTrace, context}) {},
      logEmptyViewDiagnostics:
          ({
            required queryKey,
            required providerCount,
            required animatedCount,
            required searchQuery,
            required resolvedTag,
            required useShortcutFilter,
            required useQuickSearch,
            required useAiSearch,
            required useRemoteSearch,
            required startTimeSec,
            required endTimeSecExclusive,
            required shortcutFilter,
            required quickSearchKind,
          }) async {
            emptyDiagnosticsCalls++;
          },
    );

    diagnostics.maybeLogEmptyViewDiagnostics(
      debugMode: false,
      queryKey: 'NORMAL|tag|secret query|shortcut filter',
      memosValue: const <LocalMemo>[],
      memosLoading: false,
      memosError: null,
      visibleMemos: const <LocalMemo>[],
      searchQuery: 'secret query',
      resolvedTag: 'tag',
      useShortcutFilter: false,
      useQuickSearch: false,
      useAiSearch: false,
      useRemoteSearch: true,
      startTimeSec: null,
      endTimeSecExclusive: null,
      shortcutFilter: 'shortcut filter',
      quickSearchKind: null,
    );

    await Future<void>.delayed(Duration.zero);

    expect(emptyDiagnosticsCalls, 0);
  });

  test('maybeLogMemosLoadingPhase redacts query metadata', () {
    Map<String, Object?>? capturedContext;
    final diagnostics = MemosListDiagnostics(
      debugLog: (_, {error, stackTrace, context}) {},
      infoLog: (message, {error, stackTrace, context}) {
        if (message == 'Memos loading: phase') {
          capturedContext = context;
        }
      },
      logEmptyViewDiagnostics:
          ({
            required queryKey,
            required providerCount,
            required animatedCount,
            required searchQuery,
            required resolvedTag,
            required useShortcutFilter,
            required useQuickSearch,
            required useAiSearch,
            required useRemoteSearch,
            required startTimeSec,
            required endTimeSecExclusive,
            required shortcutFilter,
            required quickSearchKind,
          }) async {},
    );

    diagnostics.maybeLogMemosLoadingPhase(
      debugMode: true,
      queryKey: 'NORMAL|tag|secret query|shortcut filter',
      memosLoading: false,
      memosError: null,
      memosValue: const <LocalMemo>[],
      visibleMemos: const <LocalMemo>[],
      useShortcutFilter: true,
      useQuickSearch: false,
      useAiSearch: true,
      useRemoteSearch: false,
      shortcutFilter: 'shortcut filter',
      quickSearchKind: QuickSearchKind.attachments,
      syncState: SyncFlowStatus.idle,
      syncQueueSnapshot: SyncQueueProgressSnapshot.idle,
      pageSize: 50,
      reachedEnd: true,
      loadingMore: false,
      providerLoading: false,
      showSearchLanding: false,
    );

    expect(capturedContext, isNotNull);
    expect(capturedContext!.containsKey('queryKey'), isFalse);
    expect(capturedContext!['queryKeyFingerprint'], isA<String>());
    expect(
      (capturedContext!['queryKeyFingerprint'] as String).contains(
        'secret query',
      ),
      isFalse,
    );
    expect(capturedContext!.containsKey('shortcutFilter'), isFalse);
    expect(capturedContext!['useAiSearch'], isTrue);
    expect(capturedContext!['shortcutFilterFingerprint'], isA<String>());
    expect(
      (capturedContext!['shortcutFilterFingerprint'] as String).contains(
        'shortcut filter',
      ),
      isFalse,
    );
    expect(capturedContext!['shortcutFilterLength'], 'shortcut filter'.length);
  });

  test('memo list UI does not own AI embedding or ranking logic', () async {
    final uiFiles = <String>[
      'lib/features/memos/memos_list_screen.dart',
      'lib/features/memos/widgets/memos_list_screen_body.dart',
    ];
    const forbiddenTokens = <String>[
      'AiMemoIndexing',
      'AiAnalysisRepository',
      'ai_chunks',
      'ai_embeddings',
      'ai_memo_policy',
      'chunkMemo',
      'computeMemoContentHash',
      'cosineSimilarity',
      'estimateIndexWorkForSearchScope',
      'listMemoRowsForAi',
      'memoHasFreshIndex',
      'listSemanticSearchCandidateChunkRows',
      'tokenEstimate',
      '.embed(',
    ];

    final violations = <String>[];
    for (final path in uiFiles) {
      final contents = await File(path).readAsString();
      for (final token in forbiddenTokens) {
        if (contents.contains(token)) {
          violations.add('$path contains $token');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Memo list UI may render AI search states, but semantic '
          'retrieval/index/ranking logic must stay in data/ai seams.',
    );
  });

  test('AI search state provider does not import memo feature UI', () async {
    final contents = await File(
      'lib/state/memos/memos_providers.dart',
    ).readAsString();

    expect(
      contents.contains('features/memos/'),
      isFalse,
      reason:
          'AI search state integration must not introduce new '
          'state -> features/memos reverse dependencies.',
    );
  });

  test('AI analysis and AI search reuse shared memo indexing seam', () async {
    final analysisContents = await File(
      'lib/data/ai/ai_analysis_service.dart',
    ).readAsString();
    final searchContents = await File(
      'lib/data/ai/ai_semantic_memo_search_service.dart',
    ).readAsString();

    expect(analysisContents, contains("import 'ai_memo_indexing.dart';"));
    expect(searchContents, contains("import 'ai_memo_indexing.dart';"));
    expect(analysisContents, contains('AiMemoIndexing.chunkMemo'));
    expect(searchContents, contains('AiMemoIndexing.chunkMemo'));
    expect(searchContents, contains('estimateIndexWorkForSearchScope'));
    expect(searchContents, contains('AiMemoIndexing.computeMemoContentHash'));
    expect(searchContents, contains('AiMemoIndexing.cosineSimilarity'));
  });
}

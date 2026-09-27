part of 'memos_list_providers.dart';

class MemosListController {
  MemosListController(this._ref);

  final Ref _ref;

  Future<void> logEmptyViewDiagnostics({
    required String queryKey,
    required String state,
    required int providerCount,
    required int animatedCount,
    required String searchQuery,
    required String? resolvedTag,
    required bool useShortcutFilter,
    required bool useQuickSearch,
    required bool useAiSearch,
    required bool useRemoteSearch,
    required int? startTimeSec,
    required int? endTimeSecExclusive,
    required String shortcutFilter,
    required QuickSearchKind? quickSearchKind,
  }) async {
    try {
      final db = _ref.read(databaseProvider);
      final sqlite = await db.db;
      int readCountValue(Object? raw) {
        return switch (raw) {
          int value => value,
          num value => value.toInt(),
          String value => int.tryParse(value.trim()) ?? 0,
          _ => 0,
        };
      }

      final countRows = await sqlite.rawQuery('''
        SELECT
          COUNT(*) AS total_count,
          SUM(CASE WHEN UPPER(COALESCE(state, 'NORMAL')) = 'ARCHIVED' THEN 1 ELSE 0 END) AS archived_count,
          SUM(CASE WHEN UPPER(COALESCE(state, 'NORMAL')) = 'ARCHIVED' THEN 0 ELSE 1 END) AS normal_count
        FROM memos
      ''');
      final countRow = countRows.isEmpty
          ? const <String, Object?>{}
          : countRows.first;
      final dbTotal = readCountValue(countRow['total_count']);
      final dbNormal = readCountValue(countRow['normal_count']);
      final dbArchived = readCountValue(countRow['archived_count']);
      final tag = resolvedTag?.trim();
      final normalizedSearch = searchQuery.trim();
      final normalizedShortcutFilter = shortcutFilter.trim();
      final previewRows = await db.listMemos(
        searchQuery: normalizedSearch.isEmpty ? null : normalizedSearch,
        state: state,
        tag: (tag == null || tag.isEmpty) ? null : tag,
        startTimeSec: startTimeSec,
        endTimeSecExclusive: endTimeSecExclusive,
        limit: 5,
      );
      final previewUids = previewRows
          .map((row) => row['uid'])
          .whereType<String>()
          .map((uid) => LogSanitizer.redactOpaque(uid, kind: 'memo_uid'))
          .toList(growable: false);
      _ref
          .read(logManagerProvider)
          .info(
            'Memos list: empty_view_diagnostic',
            context: <String, Object?>{
              'queryKeyFingerprint': LogSanitizer.redactOpaque(
                queryKey,
                kind: 'memos_query_key',
              ),
              'state': state,
              'providerCount': providerCount,
              'animatedCount': animatedCount,
              'searchLength': normalizedSearch.length,
              if (normalizedSearch.isNotEmpty)
                'searchQueryFingerprint': LogSanitizer.redactSemanticText(
                  normalizedSearch,
                  kind: 'search_query',
                ),
              if (tag != null && tag.isNotEmpty) ...<String, Object?>{
                'tagFingerprint': LogSanitizer.redactSemanticText(
                  tag,
                  kind: 'tag',
                ),
                'tagLength': tag.length,
              },
              'useShortcutFilter': useShortcutFilter,
              if (normalizedShortcutFilter.isNotEmpty) ...<String, Object?>{
                'shortcutFilterFingerprint': LogSanitizer.redactSemanticText(
                  normalizedShortcutFilter,
                  kind: 'shortcut_filter',
                ),
                'shortcutFilterLength': normalizedShortcutFilter.length,
              },
              'useQuickSearch': useQuickSearch,
              'useAiSearch': useAiSearch,
              if (quickSearchKind != null)
                'quickSearchKind': quickSearchKind.name,
              'useRemoteSearch': useRemoteSearch,
              if (startTimeSec != null) 'startTimeSec': startTimeSec,
              if (endTimeSecExclusive != null)
                'endTimeSecExclusive': endTimeSecExclusive,
              'dbTotal': dbTotal,
              'dbNormal': dbNormal,
              'dbArchived': dbArchived,
              'dbPreviewCount': previewRows.length,
              if (previewUids.isNotEmpty) 'dbPreviewUids': previewUids,
            },
          );
    } catch (e, stackTrace) {
      _ref
          .read(logManagerProvider)
          .warn(
            'Memos list: empty_view_diagnostic_failed',
            error: e,
            stackTrace: stackTrace,
            context: <String, Object?>{
              'queryKeyFingerprint': LogSanitizer.redactOpaque(
                queryKey,
                kind: 'memos_query_key',
              ),
            },
          );
    }
  }

  Future<void> createQuickInputMemo({
    required String uid,
    required String content,
    required String visibility,
    required int nowSec,
    required List<String> tags,
  }) async {
    await _ref
        .read(memoMutationServiceProvider)
        .createQuickInputMemo(
          uid: uid,
          content: content,
          visibility: visibility,
          nowSec: nowSec,
          tags: tags,
        );
  }

  Future<int> retryOutboxErrors({required String memoUid}) async {
    return _ref
        .read(memoMutationServiceProvider)
        .retryOutboxErrors(memoUid: memoUid);
  }

  Future<void> createInlineComposeMemo({
    required String uid,
    required String content,
    required String visibility,
    required int nowSec,
    required List<String> tags,
    required List<Map<String, dynamic>> attachments,
    required MemoLocation? location,
    required List<Map<String, dynamic>> relations,
    required List<MemoComposerPendingAttachment> pendingAttachments,
  }) async {
    await _ref
        .read(memoMutationServiceProvider)
        .createInlineComposeMemo(
          uid: uid,
          content: content,
          visibility: visibility,
          nowSec: nowSec,
          tags: tags,
          attachments: attachments,
          location: location,
          relations: relations,
          pendingAttachments: pendingAttachments,
        );
  }

  Future<void> updateMemo(LocalMemo memo, {bool? pinned, String? state}) async {
    await _ref
        .read(memoMutationServiceProvider)
        .updateMemo(memo, pinned: pinned, state: state);
  }

  Future<void> adjustMemoTime({
    required LocalMemo memo,
    required DateTime selectedTime,
  }) async {
    await _ref
        .read(memoMutationServiceProvider)
        .adjustMemoTime(memo: memo, selectedTime: selectedTime);
  }

  Future<void> updateMemoContent(
    LocalMemo memo,
    String content, {
    bool preserveUpdateTime = false,
  }) async {
    await _ref
        .read(memoMutationServiceProvider)
        .updateMemoContent(
          memo,
          content,
          preserveUpdateTime: preserveUpdateTime,
        );
  }

  Future<void> deleteMemo(
    LocalMemo memo, {
    void Function()? onMovedToRecycleBin,
  }) async {
    await _ref
        .read(memoDeleteServiceProvider)
        .deleteMemo(memo, onMovedToRecycleBin: onMovedToRecycleBin);
  }

  Future<bool> hasAnyLocalMemos() async {
    final db = _ref.read(databaseProvider);
    final existing = await db.listMemos(limit: 1);
    return existing.isNotEmpty;
  }

  Future<MemosListMemoResolveResult> resolveMemoForOpen({
    required String uid,
  }) async {
    final db = _ref.read(databaseProvider);
    if (await db.hasMemoDeleteMarker(uid)) {
      return const MemosListMemoResolveResult.notFound();
    }
    final row = await db.getMemoByUid(uid);
    LocalMemo? memo = row == null ? null : LocalMemo.fromDb(row);

    if (memo == null) {
      final account = _ref.read(appSessionProvider).valueOrNull?.currentAccount;
      if (account != null) {
        try {
          final api = _ref.read(memosApiProvider);
          final remote = await api.getMemo(memoUid: uid);
          await _ref
              .read(memoMutationServiceProvider)
              .cacheRemoteMemoForOpen(remoteMemo: remote, fallbackUid: uid);
          final remoteUid = remote.uid.isNotEmpty ? remote.uid : uid;
          final refreshed = await db.getMemoByUid(remoteUid);
          if (refreshed != null) {
            memo = LocalMemo.fromDb(refreshed);
          }
        } catch (e) {
          return MemosListMemoResolveResult.error(e);
        }
      }
    }

    if (memo == null) {
      return const MemosListMemoResolveResult.notFound();
    }
    return MemosListMemoResolveResult.found(memo);
  }

  Future<Shortcut> createShortcut({
    required String title,
    required String filter,
  }) async {
    final account = _ref.read(appSessionProvider).valueOrNull?.currentAccount;
    if (account == null) {
      throw StateError('Not authenticated');
    }
    final api = _ref.read(memosApiProvider);
    await api.ensureServerHintsLoaded();
    final useLocalShortcuts =
        api.usesLegacySearchFilterDialect ||
        api.shortcutsSupportedHint == false;
    return useLocalShortcuts
        ? await _ref
              .read(localShortcutsRepositoryProvider)
              .create(title: title, filter: filter)
        : await api.createShortcut(
            userName: account.user.name,
            title: title,
            filter: filter,
          );
  }
}

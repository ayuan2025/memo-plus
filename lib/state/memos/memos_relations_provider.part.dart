part of 'memos_providers.dart';

List<MemoRelation> _decodeMemoRelationsCache(String raw) {
  if (raw.trim().isEmpty) return const <MemoRelation>[];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      final relations = <MemoRelation>[];
      for (final item in decoded) {
        if (item is Map) {
          relations.add(MemoRelation.fromJson(item.cast<String, dynamic>()));
        }
      }
      return relations;
    }
  } catch (_) {}
  return const <MemoRelation>[];
}

String _encodeMemoRelationsCache(List<MemoRelation> relations) {
  if (relations.isEmpty) return '[]';
  final items = <Map<String, dynamic>>[];
  for (final relation in relations) {
    items.add({
      'memo': {'name': relation.memo.name, 'snippet': relation.memo.snippet},
      'relatedMemo': {
        'name': relation.relatedMemo.name,
        'snippet': relation.relatedMemo.snippet,
      },
      'type': relation.type,
    });
  }
  return jsonEncode(items);
}

Future<List<MemoRelation>> _loadMemoRelationsCache(
  AppDatabase db,
  String memoUid,
) async {
  final raw = await db.getMemoRelationsCacheJson(memoUid);
  if (raw == null) return const <MemoRelation>[];
  return _decodeMemoRelationsCache(raw);
}

Future<void> _storeMemoRelationsCache(
  MemoRelationsCacheMutationService mutations,
  String memoUid,
  List<MemoRelation> relations,
) async {
  await mutations.upsertMemoRelationsCache(
    memoUid,
    relationsJson: _encodeMemoRelationsCache(relations),
  );
}

Future<void> _refreshMemoRelationsCache(Ref ref, String memoUid) async {
  final normalized = memoUid.trim();
  if (normalized.isEmpty) return;
  try {
    final account = ref.read(appSessionProvider).valueOrNull?.currentAccount;
    if (account == null) return;
    final api = ref.read(memosApiProvider);
    final (relations, _) = await api.listMemoRelations(
      memoUid: normalized,
      pageSize: 200,
    );
    final mutations = ref.read(memoRelationsCacheMutationServiceProvider);
    await _storeMemoRelationsCache(mutations, normalized, relations);
  } catch (_) {}
}

final memoRelationsProvider = StreamProvider.family<List<MemoRelation>, String>(
  (ref, memoUid) async* {
    final normalized = memoUid.trim();
    if (normalized.isEmpty) {
      yield const <MemoRelation>[];
      return;
    }

    final db = ref.watch(databaseProvider);

    Future<List<MemoRelation>> load() async =>
        _loadMemoRelationsCache(db, normalized);

    unawaited(_refreshMemoRelationsCache(ref, normalized));

    yield await load();
    await for (final _ in db.changes) {
      yield await load();
    }
  },
);

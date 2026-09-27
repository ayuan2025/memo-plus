import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tag_colors.dart';
import '../../core/tags.dart';
import '../memos/memos_providers.dart';
import '../system/database_provider.dart';

final tagAliasMapProvider = StreamProvider<Map<String, String>>((ref) async* {
  final db = ref.watch(databaseProvider);

  Future<Map<String, String>> load() async {
    final sqlite = await db.db;
    try {
      final rows = await sqlite.rawQuery('''
SELECT a.alias, t.path
FROM tag_aliases a
JOIN tags t ON t.id = a.tag_id;
''');
      final map = <String, String>{};
      for (final row in rows) {
        final alias = normalizeTagPath((row['alias'] as String?) ?? '');
        final path = normalizeTagPath((row['path'] as String?) ?? '');
        if (alias.isEmpty || path.isEmpty) continue;
        map[alias] = path;
      }
      return map;
    } catch (_) {
      return const <String, String>{};
    }
  }

  yield await load();
  await for (final _ in db.changes) {
    yield await load();
  }
});

final tagColorLookupProvider = Provider<TagColorLookup>((ref) {
  final stats = ref.watch(tagStatsProvider).valueOrNull ?? const <TagStat>[];
  final aliasPaths =
      ref.watch(tagAliasMapProvider).valueOrNull ?? const <String, String>{};
  return TagColorLookup(stats, aliasPaths: aliasPaths);
});

class TagColorLookup {
  TagColorLookup(
    List<TagStat> stats, {
    Map<String, String> aliasPaths = const <String, String>{},
  }) {
    for (final stat in stats) {
      final path = normalizeTagPath(stat.path);
      if (path.isEmpty) continue;
      _byPath[path] = stat;
      final id = stat.tagId;
      if (id != null) _byId[id] = stat;
    }
    for (final entry in aliasPaths.entries) {
      final alias = normalizeTagPath(entry.key);
      final path = normalizeTagPath(entry.value);
      if (alias.isEmpty || path.isEmpty) continue;
      _aliasToPath[alias] = path;
    }
  }

  final Map<int, TagStat> _byId = <int, TagStat>{};
  final Map<String, String> _aliasToPath = <String, String>{};
  final Map<String, TagStat> _byPath = <String, TagStat>{};

  String resolveCanonicalPath(String path) {
    final normalized = normalizeTagPath(path);
    if (normalized.isEmpty) return '';
    return _aliasToPath[normalized] ?? normalized;
  }

  TagStat? resolveTag(String path) {
    final canonical = resolveCanonicalPath(path);
    if (canonical.isEmpty) return null;
    return _byPath[canonical];
  }

  String? resolveEffectiveHexByPath(String path) {
    final tag = resolveTag(path);
    if (tag == null) return null;
    return _resolveEffectiveHex(tag);
  }

  Color? resolveColorByPath(String path) {
    final hex = resolveEffectiveHexByPath(path);
    return parseTagColor(hex);
  }

  TagChipColors? resolveChipColorsByPath(
    String path, {
    required Color surfaceColor,
    required bool isDark,
  }) {
    final color = resolveColorByPath(path);
    if (color == null) return null;
    return buildTagChipColors(
      baseColor: color,
      surfaceColor: surfaceColor,
      isDark: isDark,
    );
  }

  String? _resolveEffectiveHex(TagStat tag) {
    TagStat? current = tag;
    final visited = <int>{};
    while (current != null) {
      final hex = normalizeTagColorHex(current.colorHex);
      if (hex != null) return hex;
      final parentId = current.parentId;
      if (parentId == null || !visited.add(parentId)) break;
      current = _byId[parentId];
    }
    return null;
  }
}

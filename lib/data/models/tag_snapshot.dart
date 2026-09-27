import 'tag.dart';

class TagAliasRecord {
  const TagAliasRecord({
    required this.tagId,
    required this.alias,
    required this.createdTimeSec,
  });

  final int tagId;
  final String alias;
  final int createdTimeSec;

  factory TagAliasRecord.fromDb(Map<String, dynamic> row) {
    int readInt(Object? value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value.trim()) ?? 0;
      return 0;
    }

    return TagAliasRecord(
      tagId: readInt(row['tag_id']),
      alias: (row['alias'] as String?) ?? '',
      createdTimeSec: readInt(row['created_time']),
    );
  }

  Map<String, dynamic> toJson() => {
        'tagId': tagId,
        'alias': alias,
        'createdTime': createdTimeSec,
      };

  factory TagAliasRecord.fromJson(Map<String, dynamic> json) {
    int readInt(Object? value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value.trim()) ?? 0;
      return 0;
    }

    return TagAliasRecord(
      tagId: readInt(json['tagId']),
      alias: (json['alias'] as String?) ?? '',
      createdTimeSec: readInt(json['createdTime']),
    );
  }
}

class TagSnapshot {
  const TagSnapshot({required this.tags, required this.aliases});

  final List<TagEntity> tags;
  final List<TagAliasRecord> aliases;

  Map<String, dynamic> toJson() => {
        'schemaVersion': 1,
        'tags': tags.map((tag) => tag.toJson()).toList(growable: false),
        'aliases': aliases
            .map((alias) => alias.toJson())
            .toList(growable: false),
      };

  factory TagSnapshot.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    final tags = <TagEntity>[];
    if (rawTags is List) {
      for (final item in rawTags) {
        if (item is Map) {
          tags.add(TagEntity.fromJson(item.cast<String, dynamic>()));
        }
      }
    }

    final rawAliases = json['aliases'];
    final aliases = <TagAliasRecord>[];
    if (rawAliases is List) {
      for (final item in rawAliases) {
        if (item is Map) {
          aliases.add(TagAliasRecord.fromJson(item.cast<String, dynamic>()));
        }
      }
    }

    return TagSnapshot(tags: tags, aliases: aliases);
  }
}

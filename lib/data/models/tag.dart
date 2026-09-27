class TagEntity {
  const TagEntity({
    required this.id,
    required this.name,
    required this.path,
    this.parentId,
    required this.pinned,
    this.colorHex,
    required this.createTimeSec,
    required this.updateTimeSec,
  });

  final int id;
  final String name;
  final String path;
  final int? parentId;
  final bool pinned;
  final String? colorHex;
  final int createTimeSec;
  final int updateTimeSec;

  factory TagEntity.fromDb(Map<String, dynamic> row) {
    int? readInt(Object? value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value.trim());
      return null;
    }

    final id = readInt(row['id']) ?? 0;
    final name = (row['name'] as String?) ?? '';
    final path = (row['path'] as String?) ?? '';
    final parentId = readInt(row['parent_id']);
    final pinned = (readInt(row['pinned']) ?? 0) == 1;
    final colorHex = row['color_hex'] as String?;
    final createTimeSec = readInt(row['create_time']) ?? 0;
    final updateTimeSec = readInt(row['update_time']) ?? 0;

    return TagEntity(
      id: id,
      name: name,
      path: path,
      parentId: parentId,
      pinned: pinned,
      colorHex: colorHex,
      createTimeSec: createTimeSec,
      updateTimeSec: updateTimeSec,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'path': path,
        'parentId': parentId,
        'pinned': pinned,
        'colorHex': colorHex,
        'createTime': createTimeSec,
        'updateTime': updateTimeSec,
      };

  factory TagEntity.fromJson(Map<String, dynamic> json) {
    int readInt(Object? value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value.trim()) ?? 0;
      return 0;
    }

    return TagEntity(
      id: readInt(json['id']),
      name: (json['name'] as String?) ?? '',
      path: (json['path'] as String?) ?? '',
      parentId: json['parentId'] == null ? null : readInt(json['parentId']),
      pinned: json['pinned'] is bool ? json['pinned'] as bool : false,
      colorHex: json['colorHex'] as String?,
      createTimeSec: readInt(json['createTime']),
      updateTimeSec: readInt(json['updateTime']),
    );
  }
}

enum LocalLibraryStorageKind { managedPrivate, externalLegacy }

class LocalLibrary {
  const LocalLibrary({
    required this.key,
    required this.name,
    this.storageKind = LocalLibraryStorageKind.externalLegacy,
    this.treeUri,
    this.rootPath,
    this.createdAt,
    this.updatedAt,
  });

  final String key;
  final String name;
  final LocalLibraryStorageKind storageKind;
  final String? treeUri;
  final String? rootPath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isManagedPrivate =>
      storageKind == LocalLibraryStorageKind.managedPrivate;
  bool get isSaf => treeUri != null && treeUri!.trim().isNotEmpty;

  String get locationLabel {
    if (isSaf) return _formatSafLabel(treeUri!.trim());
    return (rootPath ?? '').trim();
  }

  String _formatSafLabel(String uri) {
    final trimmed = uri.trim();
    if (trimmed.isEmpty) return '';
    try {
      final parsed = Uri.parse(trimmed);
      final segments = parsed.pathSegments;
      String? encoded;
      for (var i = 0; i < segments.length; i++) {
        if (segments[i] == 'tree' && i + 1 < segments.length) {
          encoded = segments[i + 1];
          break;
        }
      }
      encoded ??= segments.isNotEmpty ? segments.last : null;
      if (encoded != null && encoded.isNotEmpty) {
        final decoded = Uri.decodeComponent(encoded);
        final normalized = _normalizeSafDocId(decoded);
        if (normalized.isNotEmpty) return normalized;
      }
    } catch (_) {}
    return trimmed;
  }

  String _normalizeSafDocId(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return value;
    if (value.startsWith('raw:')) {
      return value.substring(4);
    }
    final index = value.indexOf(':');
    if (index != -1) {
      final storage = value.substring(0, index);
      final rest = value.substring(index + 1);
      if (storage == 'primary') {
        return rest.isEmpty ? 'primary' : rest;
      }
      if (rest.isEmpty) return storage;
      return '$storage/$rest';
    }
    return value;
  }

  LocalLibrary copyWith({
    String? key,
    String? name,
    LocalLibraryStorageKind? storageKind,
    String? treeUri,
    bool clearTreeUri = false,
    String? rootPath,
    bool clearRootPath = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LocalLibrary(
      key: key ?? this.key,
      name: name ?? this.name,
      storageKind: storageKind ?? this.storageKind,
      treeUri: clearTreeUri ? null : (treeUri ?? this.treeUri),
      rootPath: clearRootPath ? null : (rootPath ?? this.rootPath),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'name': name,
    'storageKind': storageKind.name,
    'treeUri': treeUri,
    'rootPath': rootPath,
    'createdAt': createdAt?.toUtc().millisecondsSinceEpoch,
    'updatedAt': updatedAt?.toUtc().millisecondsSinceEpoch,
  };

  factory LocalLibrary.fromJson(Map<String, dynamic> json) {
    LocalLibraryStorageKind readStorageKind() {
      final raw = json['storageKind'];
      if (raw is String) {
        return LocalLibraryStorageKind.values.firstWhere(
          (value) => value.name == raw,
          orElse: () => LocalLibraryStorageKind.externalLegacy,
        );
      }
      return LocalLibraryStorageKind.externalLegacy;
    }

    DateTime? readTime(dynamic raw) {
      if (raw is int) {
        return DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true);
      }
      if (raw is String) {
        final parsed = int.tryParse(raw.trim());
        if (parsed != null) {
          return DateTime.fromMillisecondsSinceEpoch(parsed, isUtc: true);
        }
      }
      return null;
    }

    return LocalLibrary(
      key: (json['key'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      storageKind: readStorageKind(),
      treeUri: (json['treeUri'] as String?)?.trim(),
      rootPath: (json['rootPath'] as String?)?.trim(),
      createdAt: readTime(json['createdAt'])?.toLocal(),
      updatedAt: readTime(json['updatedAt'])?.toLocal(),
    );
  }
}

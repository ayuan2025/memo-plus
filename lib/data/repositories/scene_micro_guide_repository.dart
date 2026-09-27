import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum SceneMicroGuideId {
  memoListGestures,
  memoListSearchAndShortcuts,
  memoEditorTagAutocomplete,
  attachmentGalleryControls,
  desktopGlobalShortcuts,
}

class SceneMicroGuideRepository {
  SceneMicroGuideRepository(this._storage);

  static const storageKey = 'scene_micro_guides_device_v1';

  final FlutterSecureStorage _storage;

  Future<Set<SceneMicroGuideId>> read() async {
    final raw = await _storage.read(key: storageKey);
    if (raw == null || raw.trim().isEmpty) return <SceneMicroGuideId>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <SceneMicroGuideId>{};
      return decoded
          .whereType<String>()
          .map(_sceneMicroGuideIdFromName)
          .whereType<SceneMicroGuideId>()
          .toSet();
    } catch (_) {
      return <SceneMicroGuideId>{};
    }
  }

  Future<void> write(Set<SceneMicroGuideId> ids) async {
    final payload = ids.map((id) => id.name).toList(growable: false)..sort();
    await _storage.write(key: storageKey, value: jsonEncode(payload));
  }
}

SceneMicroGuideId? _sceneMicroGuideIdFromName(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  for (final value in SceneMicroGuideId.values) {
    if (value.name == trimmed) return value;
  }
  return null;
}

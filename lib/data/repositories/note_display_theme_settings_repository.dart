import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/note_display_theme_settings.dart';

/// 笔记显示主题偏好仓库：按账号隔离存于安全存储。
class NoteDisplayThemeSettingsRepository {
  NoteDisplayThemeSettingsRepository(this._storage, {required this.accountKey});

  static const _kPrefix = 'note_display_theme_v1_';

  final FlutterSecureStorage _storage;
  final String accountKey;

  String get _storageKey => '$_kPrefix$accountKey';

  Future<NoteDisplayThemeSettings> read() async {
    final raw = await _storage.read(key: _storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return NoteDisplayThemeSettings.defaults;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return NoteDisplayThemeSettings.fromJson(
          decoded.cast<String, dynamic>(),
        );
      }
    } catch (_) {}
    return NoteDisplayThemeSettings.defaults;
  }

  Future<void> write(NoteDisplayThemeSettings settings) async {
    await _storage.write(key: _storageKey, value: jsonEncode(settings.toJson()));
  }

  Future<void> clear() async {
    await _storage.delete(key: _storageKey);
  }
}

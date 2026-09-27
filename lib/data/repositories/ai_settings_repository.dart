import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/app_preferences.dart';
import '../ai/ai_settings_migration.dart';
import '../ai/ai_settings_models.dart';

export '../ai/ai_provider_adapter.dart';
export '../ai/ai_provider_models.dart';
export '../ai/ai_provider_registry.dart';
export '../ai/ai_provider_templates.dart';
export '../ai/ai_route_resolver.dart';
export '../ai/ai_settings_migration.dart';
export '../ai/ai_settings_models.dart';

class AiSettingsRepository {
  AiSettingsRepository(this._storage, {required String? accountKey})
    : _accountKey = accountKey;

  static const _kPrefix = 'ai_settings_v2_';
  static const _kLegacyKey = 'ai_settings_v1';

  final FlutterSecureStorage _storage;
  final String? _accountKey;

  String? get _storageKey {
    final key = _accountKey;
    if (key == null || key.trim().isEmpty) return null;
    return '$_kPrefix$key';
  }

  Future<AiSettings> read({AppLanguage language = AppLanguage.en}) async {
    final fallback = AiSettings.defaultsFor(language);
    final storageKey = _storageKey;
    if (storageKey == null) return fallback;

    final raw = await _storage.read(key: storageKey);
    if (raw == null || raw.trim().isEmpty) {
      final legacy = await _readLegacy();
      if (legacy != null) {
        final normalized = AiSettingsMigration.normalize(legacy);
        await write(normalized);
        return normalized;
      }
      return fallback;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final parsed = AiSettings.fromJson(decoded.cast<String, dynamic>());
        final normalized = AiSettingsMigration.normalize(parsed);
        final hasServices = decoded['services'] is List;
        final hasBindings = decoded['taskRouteBindings'] is List;
        final rawSchemaVersion = decoded['schemaVersion'];
        final schemaVersion = rawSchemaVersion is num
            ? rawSchemaVersion.toInt()
            : 2;
        if (schemaVersion < AiSettings.currentSchemaVersion ||
            !hasServices ||
            !hasBindings) {
          await write(normalized);
        }
        return normalized;
      }
    } catch (_) {}
    return fallback;
  }

  Future<void> write(AiSettings settings) async {
    final storageKey = _storageKey;
    if (storageKey == null) return;
    final normalized = AiSettingsMigration.normalize(settings);
    await _storage.write(key: storageKey, value: jsonEncode(normalized.toJson()));
  }

  Future<void> clear() async {
    final storageKey = _storageKey;
    if (storageKey == null) return;
    await _storage.delete(key: storageKey);
  }

  Future<AiSettings?> _readLegacy() async {
    final raw = await _storage.read(key: _kLegacyKey);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return AiSettings.fromJson(decoded.cast<String, dynamic>());
      }
    } catch (_) {}
    return null;
  }
}

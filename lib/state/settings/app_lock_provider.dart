import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../application/sync/sync_request.dart';
import '../../data/models/app_lock.dart';
import '../sync/sync_coordinator_provider.dart';
import '../system/session_provider.dart';

export '../../data/models/app_lock.dart';
class AppLockState {
  const AppLockState({
    required this.enabled,
    required this.autoLockTime,
    required this.hasPassword,
    required this.locked,
    required this.loaded,
    this.lastBackgroundAt,
  });

  final bool enabled;
  final AutoLockTime autoLockTime;
  final bool hasPassword;
  final bool locked;
  final bool loaded;
  final DateTime? lastBackgroundAt;

  AppLockState copyWith({
    bool? enabled,
    AutoLockTime? autoLockTime,
    bool? hasPassword,
    bool? locked,
    bool? loaded,
    DateTime? lastBackgroundAt,
    bool clearLastBackgroundAt = false,
  }) {
    return AppLockState(
      enabled: enabled ?? this.enabled,
      autoLockTime: autoLockTime ?? this.autoLockTime,
      hasPassword: hasPassword ?? this.hasPassword,
      locked: locked ?? this.locked,
      loaded: loaded ?? this.loaded,
      lastBackgroundAt: clearLastBackgroundAt ? null : (lastBackgroundAt ?? this.lastBackgroundAt),
    );
  }

  static const AppLockState initial = AppLockState(
    enabled: false,
    autoLockTime: AutoLockTime.immediately,
    hasPassword: false,
    locked: false,
    loaded: false,
  );
}

final appLockRepositoryProvider = Provider<AppLockRepository>((ref) {
  final accountKey = ref.watch(appSessionProvider.select((state) => state.valueOrNull?.currentKey));
  return AppLockRepository(ref.watch(secureStorageProvider), accountKey: accountKey);
});

final appLockProvider = StateNotifierProvider<AppLockController, AppLockState>((ref) {
  return AppLockController(ref, ref.watch(appLockRepositoryProvider));
});

class AppLockController extends StateNotifier<AppLockState> {
  AppLockController(this._ref, this._repo) : super(AppLockState.initial) {
    unawaited(_load());
  }

  final Ref _ref;
  final AppLockRepository _repo;

  Future<void> _load() async {
    final snapshot = await _repo.readSnapshot();
    final settings = snapshot.settings;
    final hasPassword = snapshot.passwordRecord != null;
    state = state.copyWith(
      enabled: settings.enabled,
      autoLockTime: settings.autoLockTime,
      hasPassword: hasPassword,
      locked: settings.enabled && hasPassword,
      loaded: true,
    );
  }

  void setEnabled(bool v) {
    final next = state.copyWith(
      enabled: v,
      locked: v ? state.locked : false,
      clearLastBackgroundAt: !v,
    );
    state = next;
    unawaited(_repo.writeSettings(AppLockSettings(enabled: v, autoLockTime: next.autoLockTime)));
    unawaited(
      _ref.read(syncCoordinatorProvider.notifier).requestSync(
            const SyncRequest(
              kind: SyncRequestKind.webDavSync,
              reason: SyncRequestReason.settings,
            ),
          ),
    );
  }

  void setAutoLockTime(AutoLockTime v) {
    state = state.copyWith(autoLockTime: v);
    unawaited(_repo.writeSettings(AppLockSettings(enabled: state.enabled, autoLockTime: v)));
    unawaited(
      _ref.read(syncCoordinatorProvider.notifier).requestSync(
            const SyncRequest(
              kind: SyncRequestKind.webDavSync,
              reason: SyncRequestReason.settings,
            ),
          ),
    );
  }

  Future<void> setPassword(String password) async {
    await _repo.setPassword(password);
    state = state.copyWith(hasPassword: true);
    unawaited(
      _ref.read(syncCoordinatorProvider.notifier).requestSync(
            const SyncRequest(
              kind: SyncRequestKind.webDavSync,
              reason: SyncRequestReason.settings,
            ),
          ),
    );
  }

  Future<bool> verifyPassword(String password) async {
    final ok = await _repo.verifyPassword(password);
    if (ok) {
      state = state.copyWith(locked: false, clearLastBackgroundAt: true);
    }
    return ok;
  }

  void lock() {
    if (!state.enabled || !state.hasPassword) return;
    state = state.copyWith(locked: true);
  }

  void recordBackgrounded() {
    if (!state.enabled || !state.hasPassword) return;
    final now = DateTime.now();
    final shouldLock = state.autoLockTime == AutoLockTime.immediately;
    state = state.copyWith(lastBackgroundAt: now, locked: shouldLock ? true : state.locked);
  }

  void handleAppResumed() {
    if (!state.enabled || !state.hasPassword) return;
    final last = state.lastBackgroundAt;
    if (last == null) return;
    final shouldLock = state.autoLockTime == AutoLockTime.immediately ||
        DateTime.now().difference(last) >= state.autoLockTime.duration;
    state = state.copyWith(clearLastBackgroundAt: true, locked: shouldLock ? true : state.locked);
  }

  Future<void> setSnapshot(AppLockSnapshot snapshot, {bool triggerSync = true}) async {
    await _repo.writeSnapshot(snapshot);
    final hasPassword = snapshot.passwordRecord != null;
    state = state.copyWith(
      enabled: snapshot.settings.enabled,
      autoLockTime: snapshot.settings.autoLockTime,
      hasPassword: hasPassword,
      locked: snapshot.settings.enabled && hasPassword,
      loaded: true,
      clearLastBackgroundAt: true,
    );
    if (triggerSync) {
      unawaited(
        _ref.read(syncCoordinatorProvider.notifier).requestSync(
              const SyncRequest(
                kind: SyncRequestKind.webDavSync,
                reason: SyncRequestReason.settings,
              ),
            ),
      );
    }
  }
}

class AppLockRepository {
  AppLockRepository(this._storage, {required String? accountKey}) : _accountKey = accountKey;

  static const _kStatePrefix = 'app_lock_state_v2_';
  static const _kPasswordPrefix = 'app_lock_password_v2_';
  static const _kLegacyStateKey = 'app_lock_state_v1';
  static const _kLegacyPasswordKey = 'app_lock_password_v1';

  final FlutterSecureStorage _storage;
  final String? _accountKey;

  String? get _stateKey {
    final key = _accountKey;
    if (key == null || key.trim().isEmpty) return null;
    return '$_kStatePrefix$key';
  }

  String? get _passwordKey {
    final key = _accountKey;
    if (key == null || key.trim().isEmpty) return null;
    return '$_kPasswordPrefix$key';
  }

  Future<AppLockSnapshot> readSnapshot() async {
    final stateKey = _stateKey;
    if (stateKey == null) {
      return const AppLockSnapshot(settings: AppLockSettings.defaults, passwordRecord: null);
    }
    final rawSettings = await _storage.read(key: stateKey);
    final settings = rawSettings == null || rawSettings.trim().isEmpty
        ? null
        : _decodeSettings(rawSettings);
    final password = await _readPasswordRecord();
    if (settings != null) {
      return AppLockSnapshot(settings: settings, passwordRecord: password);
    }
    final legacySettings = await _readLegacySettings();
    final legacyPassword = await _readLegacyPasswordRecord();
    if (legacySettings != null) {
      final snapshot = AppLockSnapshot(settings: legacySettings, passwordRecord: legacyPassword);
      await writeSnapshot(snapshot);
      return snapshot;
    }
    return AppLockSnapshot(settings: AppLockSettings.defaults, passwordRecord: password);
  }

  Future<void> writeSnapshot(AppLockSnapshot snapshot) async {
    await writeSettings(snapshot.settings);
    await writePasswordRecord(snapshot.passwordRecord);
  }

  Future<AppLockSettings> readSettings() async {
    final snapshot = await readSnapshot();
    return snapshot.settings;
  }

  Future<void> writeSettings(AppLockSettings settings) async {
    final stateKey = _stateKey;
    if (stateKey == null) return;
    await _storage.write(key: stateKey, value: jsonEncode(settings.toJson()));
  }

  Future<bool> hasPassword() async {
    return (await _readPasswordRecord()) != null;
  }

  Future<void> setPassword(String password) async {
    final salt = _generateSalt();
    final digest = _hashPassword(password, salt);
    final record = AppLockPasswordRecord(salt: salt, hash: digest);
    await writePasswordRecord(record);
  }

  Future<bool> verifyPassword(String password) async {
    final record = await _readPasswordRecord();
    if (record == null) return false;
    final digest = _hashPassword(password, record.salt);
    return digest == record.hash;
  }

  Future<void> writePasswordRecord(AppLockPasswordRecord? record) async {
    final passwordKey = _passwordKey;
    if (passwordKey == null) return;
    if (record == null) {
      await _storage.delete(key: passwordKey);
      return;
    }
    await _storage.write(key: passwordKey, value: jsonEncode(record.toJson()));
  }

  String _generateSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hashPassword(String password, String salt) {
    return sha256.convert(utf8.encode('$salt:$password')).toString();
  }

  AppLockSettings? _decodeSettings(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return AppLockSettings.fromJson(decoded.cast<String, dynamic>());
      }
    } catch (_) {}
    return null;
  }

  Future<AppLockPasswordRecord?> _readPasswordRecord() async {
    final passwordKey = _passwordKey;
    if (passwordKey == null) return null;
    final raw = await _storage.read(key: passwordKey);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return AppLockPasswordRecord.fromJson(decoded.cast<String, dynamic>());
      }
    } catch (_) {}
    return null;
  }

  Future<AppLockSettings?> _readLegacySettings() async {
    final raw = await _storage.read(key: _kLegacyStateKey);
    if (raw == null || raw.trim().isEmpty) return null;
    return _decodeSettings(raw);
  }

  Future<AppLockPasswordRecord?> _readLegacyPasswordRecord() async {
    final raw = await _storage.read(key: _kLegacyPasswordKey);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return AppLockPasswordRecord.fromJson(decoded.cast<String, dynamic>());
      }
    } catch (_) {}
    return null;
  }
}

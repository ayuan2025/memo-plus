import '../../core/app_localization.dart';
import 'app_preferences.dart';

enum AutoLockTime {
  immediately('legacy.auto_lock_time.immediately'),
  after1Min('legacy.auto_lock_time.after_1_min'),
  after5Min('legacy.auto_lock_time.after_5_min'),
  after15Min('legacy.auto_lock_time.after_15_min');

  const AutoLockTime(this.labelKey);
  final String labelKey;

  String labelFor(AppLanguage language) {
    return trByLanguageKey(language: language, key: labelKey);
  }

  Duration get duration => switch (this) {
        AutoLockTime.immediately => Duration.zero,
        AutoLockTime.after1Min => const Duration(minutes: 1),
        AutoLockTime.after5Min => const Duration(minutes: 5),
        AutoLockTime.after15Min => const Duration(minutes: 15),
      };
}

class AppLockSettings {
  const AppLockSettings({
    required this.enabled,
    required this.autoLockTime,
  });

  final bool enabled;
  final AutoLockTime autoLockTime;

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'autoLockTime': autoLockTime.name,
      };

  factory AppLockSettings.fromJson(Map<String, dynamic> json) {
    final enabled = json['enabled'] is bool ? json['enabled'] as bool : false;
    final raw = json['autoLockTime'];
    AutoLockTime parsed = AutoLockTime.immediately;
    if (raw is String) {
      parsed = AutoLockTime.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => AutoLockTime.immediately,
      );
    }
    return AppLockSettings(enabled: enabled, autoLockTime: parsed);
  }

  static const defaults = AppLockSettings(
    enabled: false,
    autoLockTime: AutoLockTime.immediately,
  );
}

class AppLockPasswordRecord {
  const AppLockPasswordRecord({required this.salt, required this.hash});

  final String salt;
  final String hash;

  Map<String, dynamic> toJson() => {
        'salt': salt,
        'hash': hash,
      };

  factory AppLockPasswordRecord.fromJson(Map<String, dynamic> json) {
    final salt = json['salt'];
    final hash = json['hash'];
    if (salt is! String || hash is! String) {
      throw const FormatException('Invalid password record');
    }
    return AppLockPasswordRecord(salt: salt, hash: hash);
  }
}

class AppLockSnapshot {
  const AppLockSnapshot({
    required this.settings,
    required this.passwordRecord,
  });

  final AppLockSettings settings;
  final AppLockPasswordRecord? passwordRecord;

  Map<String, dynamic> toJson() => {
        'settings': settings.toJson(),
        'password': passwordRecord?.toJson(),
      };

  factory AppLockSnapshot.fromJson(Map<String, dynamic> json) {
    final rawSettings = json['settings'];
    if (rawSettings is! Map) {
      throw const FormatException('Invalid app lock settings');
    }
    final settings =
        AppLockSettings.fromJson(rawSettings.cast<String, dynamic>());
    final rawPassword = json['password'];
    AppLockPasswordRecord? record;
    if (rawPassword is Map) {
      record = AppLockPasswordRecord.fromJson(rawPassword.cast<String, dynamic>());
    }
    return AppLockSnapshot(settings: settings, passwordRecord: record);
  }
}

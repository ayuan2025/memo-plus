import 'package:flutter/material.dart';

import '../../core/app_localization.dart';
import 'app_preferences.dart';

enum ReminderSoundMode { system, silent, custom }

class ReminderSettings {
  static const Object _unset = Object();

  const ReminderSettings({
    required this.enabled,
    required this.notificationTitle,
    required this.notificationBody,
    required this.soundMode,
    required this.soundUri,
    required this.soundTitle,
    required this.vibrationEnabled,
    required this.dndEnabled,
    required this.dndStartMinutes,
    required this.dndEndMinutes,
  });

  final bool enabled;
  final String notificationTitle;
  final String notificationBody;
  final ReminderSoundMode soundMode;
  final String? soundUri;
  final String? soundTitle;
  final bool vibrationEnabled;
  final bool dndEnabled;
  final int dndStartMinutes;
  final int dndEndMinutes;

  static ReminderSettings defaultsFor(AppLanguage language) {
    final title = trByLanguageKey(
      language: language,
      key: 'legacy.reminder.default_title',
    );
    final body = trByLanguageKey(
      language: language,
      key: 'legacy.reminder.default_body',
    );
    return ReminderSettings(
      enabled: false,
      notificationTitle: title,
      notificationBody: body,
      soundMode: ReminderSoundMode.system,
      soundUri: null,
      soundTitle: null,
      vibrationEnabled: true,
      dndEnabled: false,
      dndStartMinutes: 23 * 60,
      dndEndMinutes: 7 * 60,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'notificationTitle': notificationTitle,
        'notificationBody': notificationBody,
        'soundMode': soundMode.name,
        'soundUri': soundUri,
        'soundTitle': soundTitle,
        'vibrationEnabled': vibrationEnabled,
        'dndEnabled': dndEnabled,
        'dndStartMinutes': dndStartMinutes,
        'dndEndMinutes': dndEndMinutes,
      };

  factory ReminderSettings.fromJson(
    Map<String, dynamic> json, {
    required ReminderSettings fallback,
  }) {
    ReminderSoundMode parseSoundMode() {
      final raw = json['soundMode'];
      if (raw is String) {
        return ReminderSoundMode.values.firstWhere(
          (m) => m.name == raw,
          orElse: () => fallback.soundMode,
        );
      }
      return fallback.soundMode;
    }

    bool parseBool(String key, bool fallbackValue) {
      final raw = json[key];
      if (raw is bool) return raw;
      if (raw is num) return raw != 0;
      return fallbackValue;
    }

    String parseString(String key, String fallbackValue) {
      final raw = json[key];
      if (raw is String) return raw;
      return fallbackValue;
    }

    String? parseNullableString(String key) {
      final raw = json[key];
      if (raw is String && raw.trim().isNotEmpty) return raw;
      return null;
    }

    int parseMinutes(String key, int fallbackValue) {
      final raw = json[key];
      if (raw is int) return raw.clamp(0, 24 * 60 - 1);
      if (raw is num) return raw.toInt().clamp(0, 24 * 60 - 1);
      return fallbackValue;
    }

    var soundMode = parseSoundMode();
    final soundUri = parseNullableString('soundUri');
    if (soundMode == ReminderSoundMode.custom && soundUri == null) {
      soundMode = ReminderSoundMode.system;
    }

    return ReminderSettings(
      enabled: parseBool('enabled', fallback.enabled),
      notificationTitle: parseString('notificationTitle', fallback.notificationTitle),
      notificationBody: parseString('notificationBody', fallback.notificationBody),
      soundMode: soundMode,
      soundUri: soundUri,
      soundTitle: parseNullableString('soundTitle') ?? fallback.soundTitle,
      vibrationEnabled: parseBool('vibrationEnabled', fallback.vibrationEnabled),
      dndEnabled: parseBool('dndEnabled', fallback.dndEnabled),
      dndStartMinutes: parseMinutes('dndStartMinutes', fallback.dndStartMinutes),
      dndEndMinutes: parseMinutes('dndEndMinutes', fallback.dndEndMinutes),
    );
  }

  ReminderSettings copyWith({
    bool? enabled,
    String? notificationTitle,
    String? notificationBody,
    ReminderSoundMode? soundMode,
    Object? soundUri = _unset,
    Object? soundTitle = _unset,
    bool? vibrationEnabled,
    bool? dndEnabled,
    int? dndStartMinutes,
    int? dndEndMinutes,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      notificationTitle: notificationTitle ?? this.notificationTitle,
      notificationBody: notificationBody ?? this.notificationBody,
      soundMode: soundMode ?? this.soundMode,
      soundUri: identical(soundUri, _unset) ? this.soundUri : soundUri as String?,
      soundTitle: identical(soundTitle, _unset) ? this.soundTitle : soundTitle as String?,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      dndEnabled: dndEnabled ?? this.dndEnabled,
      dndStartMinutes: dndStartMinutes ?? this.dndStartMinutes,
      dndEndMinutes: dndEndMinutes ?? this.dndEndMinutes,
    );
  }

  TimeOfDay get dndStartTime =>
      TimeOfDay(hour: dndStartMinutes ~/ 60, minute: dndStartMinutes % 60);
  TimeOfDay get dndEndTime =>
      TimeOfDay(hour: dndEndMinutes ~/ 60, minute: dndEndMinutes % 60);
}

import 'dart:async';

import 'package:flutter/services.dart';

enum HomeWidgetType { dailyReview, quickInput, calendar }

class HomeWidgetLaunchPayload {
  const HomeWidgetLaunchPayload({
    required this.widgetType,
    this.memoUid,
    this.dayEpochSec,
  });

  final HomeWidgetType widgetType;
  final String? memoUid;
  final int? dayEpochSec;

  Map<String, Object?> toJson() => <String, Object?>{
    'widgetType': widgetType.name,
    if (memoUid != null && memoUid!.trim().isNotEmpty) 'memoUid': memoUid,
    if (dayEpochSec != null) 'dayEpochSec': dayEpochSec,
  };

  static HomeWidgetLaunchPayload? fromDynamic(dynamic raw) {
    if (raw is String) {
      final type = HomeWidgetService.parseType(raw);
      if (type == null) return null;
      return HomeWidgetLaunchPayload(widgetType: type);
    }
    if (raw is! Map) return null;
    final map = raw.cast<Object?, Object?>();
    final widgetType = HomeWidgetService.parseType(
      map['widgetType'] as String? ?? map['action'] as String?,
    );
    if (widgetType == null) return null;
    final memoUidRaw = (map['memoUid'] as String? ?? '').trim();
    final dayEpochRaw = map['dayEpochSec'];
    final dayEpochSec = switch (dayEpochRaw) {
      int value => value,
      num value => value.toInt(),
      String value => int.tryParse(value.trim()),
      _ => null,
    };
    return HomeWidgetLaunchPayload(
      widgetType: widgetType,
      memoUid: memoUidRaw.isEmpty ? null : memoUidRaw,
      dayEpochSec: dayEpochSec,
    );
  }
}

class DailyReviewWidgetItem {
  const DailyReviewWidgetItem({
    required this.excerpt,
    required this.dateLabel,
    this.memoUid,
  });

  final String excerpt;
  final String dateLabel;
  final String? memoUid;

  Map<String, Object?> toJson() => <String, Object?>{
    'excerpt': excerpt,
    'dateLabel': dateLabel,
    if (memoUid != null && memoUid!.trim().isNotEmpty) 'memoUid': memoUid,
  };
}

class CalendarWidgetDay {
  const CalendarWidgetDay({
    required this.label,
    required this.intensity,
    required this.dayEpochSec,
    required this.isCurrentMonth,
    required this.isToday,
  });

  final String label;
  final int intensity;
  final int? dayEpochSec;
  final bool isCurrentMonth;
  final bool isToday;

  Map<String, Object?> toJson() => <String, Object?>{
    'label': label,
    'intensity': intensity,
    'dayEpochSec': dayEpochSec,
    'isCurrentMonth': isCurrentMonth,
    'isToday': isToday,
  };
}

class CalendarWidgetHeatScore {
  const CalendarWidgetHeatScore({
    required this.dayEpochSec,
    required this.heatScore,
  });

  final int dayEpochSec;
  final int heatScore;

  Map<String, Object?> toJson() => <String, Object?>{
    'dayEpochSec': dayEpochSec,
    'heatScore': heatScore,
  };
}

class CalendarWidgetSnapshot {
  const CalendarWidgetSnapshot({
    required this.monthLabel,
    required this.weekdayLabels,
    required this.days,
    required this.monthStartEpochSec,
    required this.localeTag,
    required this.mondayFirst,
    required this.heatScores,
    required this.themeColorArgb,
  });

  final String monthLabel;
  final List<String> weekdayLabels;
  final List<CalendarWidgetDay> days;
  final int monthStartEpochSec;
  final String localeTag;
  final bool mondayFirst;
  final List<CalendarWidgetHeatScore> heatScores;
  final int themeColorArgb;

  Map<String, Object?> toJson() => <String, Object?>{
    'monthLabel': monthLabel,
    'weekdayLabels': weekdayLabels,
    'days': days.map((day) => day.toJson()).toList(growable: false),
    'monthStartEpochSec': monthStartEpochSec,
    'localeTag': localeTag,
    'mondayFirst': mondayFirst,
    'heatScores': heatScores
        .map((entry) => entry.toJson())
        .toList(growable: false),
    'themeColorArgb': themeColorArgb,
  };
}

class HomeWidgetService {
  static const MethodChannel _channel = MethodChannel('memoflow/widgets');

  static Future<bool> requestPinWidget(HomeWidgetType type) async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPinWidget', {
        'type': type.name,
      });
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static void setLaunchHandler(
    FutureOr<void> Function(HomeWidgetLaunchPayload payload) handler,
  ) {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'openWidget') return;
      final payload = HomeWidgetLaunchPayload.fromDynamic(call.arguments);
      if (payload == null) return;
      await handler(payload);
    });
  }

  static Future<HomeWidgetLaunchPayload?> consumePendingLaunch() async {
    try {
      final raw = await _channel.invokeMethod<dynamic>(
        'getPendingWidgetLaunch',
      );
      final payload = HomeWidgetLaunchPayload.fromDynamic(raw);
      if (payload != null) return payload;
      final legacy = await _channel.invokeMethod<String>(
        'getPendingWidgetAction',
      );
      return HomeWidgetLaunchPayload.fromDynamic(legacy);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  static Future<bool> updateDailyReviewWidget({
    required List<DailyReviewWidgetItem> items,
    required String title,
    required String fallbackBody,
    Uint8List? avatarBytes,
    bool clearAvatar = false,
    String? localeTag,
  }) async {
    try {
      final result = await _channel
          .invokeMethod<bool>('updateDailyReviewWidget', {
            'title': title,
            'fallbackBody': fallbackBody,
            'items': items.map((item) => item.toJson()).toList(growable: false),
            if (avatarBytes != null) 'avatarBytes': avatarBytes,
            if (clearAvatar) 'clearAvatar': true,
            if (localeTag != null && localeTag.trim().isNotEmpty)
              'localeTag': localeTag.trim(),
          });
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> advanceDailyReviewWidget() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'advanceDailyReviewWidget',
      );
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> updateCalendarWidget({
    required CalendarWidgetSnapshot snapshot,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'updateCalendarWidget',
        snapshot.toJson(),
      );
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> updateQuickInputWidget({required String hint}) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'updateQuickInputWidget',
        {'hint': hint},
      );
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> moveTaskToBack() async {
    try {
      final result = await _channel.invokeMethod<bool>('moveTaskToBack');
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> clearHomeWidgets() async {
    try {
      final result = await _channel.invokeMethod<bool>('clearHomeWidgets');
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static HomeWidgetType? parseType(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final normalized = raw.trim();
    if (normalized == 'stats') return HomeWidgetType.calendar;
    for (final type in HomeWidgetType.values) {
      if (type.name == normalized) return type;
    }
    return null;
  }
}

import 'package:intl/intl.dart';

import '../../core/app_localization.dart';
import '../../data/models/app_preferences.dart';
import '../../data/models/local_memo.dart';
import '../../features/review/random_walk_display.dart';
import '../../features/review/random_walk_models.dart';
import '../../features/review/random_walk_providers.dart';
import '../../state/memos/memos_providers.dart' show TagStat;
import '../../state/tags/tag_color_lookup.dart';
import 'home_widget_service.dart';

const int dailyReviewWidgetQueueSize = 12;

List<DailyReviewWidgetItem> buildDailyReviewWidgetItems(
  List<Map<String, dynamic>> rows, {
  required AppLanguage language,
  required DateTime now,
  int limit = dailyReviewWidgetQueueSize,
}) {
  final safeLimit = limit <= 0 ? dailyReviewWidgetQueueSize : limit;
  final bucketSeed =
      now.millisecondsSinceEpoch ~/ const Duration(hours: 6).inMilliseconds;
  final query = RandomWalkQuery(
    source: RandomWalkSourceScope.allMemos,
    selectedTagKeys: const <String>[],
    dateStartSec: null,
    dateEndSecExclusive: null,
    sampleLimit: safeLimit,
    sampleSeed: bucketSeed,
  );
  final entries = buildRandomWalkEntriesFromLocalRows(
    rows,
    query: query,
    tagColors: TagColorLookup(const <TagStat>[]),
  );
  return entries
      .map((entry) => entry.memo)
      .whereType<LocalMemo>()
      .map(
        (memo) => DailyReviewWidgetItem(
          memoUid: memo.uid.trim().isEmpty ? null : memo.uid,
          excerpt: sanitizeMemoPreview(memo),
          dateLabel: _buildRandomWalkHeaderLabel(
            memo.createTime,
            language: language,
            now: now,
          ),
        ),
      )
      .toList(growable: false);
}

String _buildRandomWalkHeaderLabel(
  DateTime createdAt, {
  required AppLanguage language,
  required DateTime now,
}) {
  final days = exactDaysAgo(createdAt, now);
  final daysLabel = formatExactDaysAgo(days, language);
  final periodLabel = _resolveDayPeriodForLanguage(
    createdAt,
    language: language,
  );
  return '$daysLabel • $periodLabel';
}

String _resolveDayPeriodForLanguage(
  DateTime dt, {
  required AppLanguage language,
}) {
  final hour = dt.hour;
  if (hour >= 5 && hour < 8) {
    return trByLanguageKey(
      language: language,
      key: 'legacy.msg_random_walk_day_period_dawn',
    );
  }
  if (hour >= 8 && hour < 11) {
    return trByLanguageKey(
      language: language,
      key: 'legacy.msg_random_walk_day_period_morning',
    );
  }
  if (hour >= 11 && hour < 13) {
    return trByLanguageKey(
      language: language,
      key: 'legacy.msg_random_walk_day_period_noon',
    );
  }
  if (hour >= 13 && hour < 17) {
    return trByLanguageKey(
      language: language,
      key: 'legacy.msg_random_walk_day_period_afternoon',
    );
  }
  if (hour >= 17 && hour < 19) {
    return trByLanguageKey(
      language: language,
      key: 'legacy.msg_random_walk_day_period_dusk',
    );
  }
  return trByLanguageKey(
    language: language,
    key: 'legacy.msg_random_walk_day_period_night',
  );
}

String sanitizeMemoPreview(LocalMemo memo, {int maxLength = 88}) {
  final raw = memo.content
      .replaceAll(RegExp(r'```[\s\S]*?```'), ' ')
      .replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), ' ')
      .replaceAllMapped(
        RegExp(r'\[([^\]]+)\]\([^)]*\)'),
        (match) => match.group(1) ?? ' ',
      )
      .replaceAll(RegExp(r'[#>*`~\-]{1,3}'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (raw.isNotEmpty) {
    if (raw.length <= maxLength) return raw;
    return '${raw.substring(0, maxLength - 3).trimRight()}...';
  }
  if (memo.attachments.isNotEmpty) {
    return memo.attachments.length == 1
        ? 'Attachment memo'
        : 'Attachments memo';
  }
  return 'Empty memo';
}

CalendarWidgetSnapshot buildCalendarWidgetSnapshot({
  required DateTime month,
  required List<Map<String, dynamic>> rows,
  required AppLanguage language,
  required int themeColorArgb,
  DateTime? today,
}) {
  final normalizedMonth = DateTime(month.year, month.month);
  final heatScores = <DateTime, int>{};
  var maxHeatScore = 0;
  for (final row in rows) {
    final memo = LocalMemo.fromDb(row);
    final day = DateTime(
      memo.createTime.year,
      memo.createTime.month,
      memo.createTime.day,
    );
    final nextScore = (heatScores[day] ?? 0) + _memoHeatScore(memo);
    heatScores[day] = nextScore;
    if (nextScore > maxHeatScore) {
      maxHeatScore = nextScore;
    }
  }

  final localeTag = _localeTagForLanguage(language);
  final normalizedToday = _normalizeDay(today ?? DateTime.now());
  final mondayFirst = _startsWeekOnMonday(language);
  final firstDayOfMonth = normalizedMonth;
  final startOffset = mondayFirst
      ? firstDayOfMonth.weekday - DateTime.monday
      : firstDayOfMonth.weekday % DateTime.daysPerWeek;
  final gridStart = firstDayOfMonth.subtract(Duration(days: startOffset));
  final days = List<CalendarWidgetDay>.generate(42, (index) {
    final day = gridStart.add(Duration(days: index));
    final isCurrentMonth =
        day.year == normalizedMonth.year && day.month == normalizedMonth.month;
    final heatScore = isCurrentMonth ? (heatScores[day] ?? 0) : 0;
    return CalendarWidgetDay(
      label: day.day.toString(),
      intensity: _resolveIntensity(
        heatScore: heatScore,
        maxHeatScore: maxHeatScore,
      ),
      dayEpochSec: isCurrentMonth
          ? day.toUtc().millisecondsSinceEpoch ~/ 1000
          : null,
      isCurrentMonth: isCurrentMonth,
      isToday: _normalizeDay(day) == normalizedToday,
    );
  });
  final heatScoreEntries =
      heatScores.entries
          .map(
            (entry) => CalendarWidgetHeatScore(
              dayEpochSec: entry.key.toUtc().millisecondsSinceEpoch ~/ 1000,
              heatScore: entry.value,
            ),
          )
          .toList(growable: false)
        ..sort((a, b) => a.dayEpochSec.compareTo(b.dayEpochSec));

  return CalendarWidgetSnapshot(
    monthLabel: _formatMonthLabel(normalizedMonth, localeTag),
    weekdayLabels: _buildWeekdayLabels(localeTag, mondayFirst: mondayFirst),
    days: days,
    monthStartEpochSec: normalizedMonth.toUtc().millisecondsSinceEpoch ~/ 1000,
    localeTag: localeTag,
    mondayFirst: mondayFirst,
    heatScores: heatScoreEntries,
    themeColorArgb: themeColorArgb,
  );
}

int _resolveIntensity({required int heatScore, required int maxHeatScore}) {
  if (heatScore <= 0 || maxHeatScore <= 0) return 0;
  if (heatScore >= maxHeatScore) return 6;
  final ratio = heatScore / maxHeatScore;
  return (ratio * 6).ceil().clamp(1, 6);
}

int _memoHeatScore(LocalMemo memo) {
  final normalized = memo.content.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.isEmpty) {
    return memo.attachments.isNotEmpty ? 1 : 0;
  }
  return normalized.runes.length;
}

List<String> _buildWeekdayLabels(
  String localeTag, {
  required bool mondayFirst,
}) {
  final sunday = DateTime.utc(2024, 1, 7);
  final labels = () {
    try {
      return List<String>.generate(
        7,
        (index) =>
            DateFormat.E(localeTag).format(sunday.add(Duration(days: index))),
        growable: false,
      );
    } catch (_) {
      return const <String>['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    }
  }();
  if (!mondayFirst) return labels;
  return <String>[...labels.skip(1), labels.first];
}

String _formatMonthLabel(DateTime month, String localeTag) {
  try {
    return DateFormat('yyyy-MM').format(month);
  } catch (_) {
    final mm = month.month.toString().padLeft(2, '0');
    return '${month.year}-$mm';
  }
}

String _localeTagForLanguage(AppLanguage language) {
  return localeTagForAppLanguage(language);
}

bool _startsWeekOnMonday(AppLanguage language) {
  return startsWeekOnMondayForAppLanguage(language);
}

DateTime _normalizeDay(DateTime day) => DateTime(day.year, day.month, day.day);

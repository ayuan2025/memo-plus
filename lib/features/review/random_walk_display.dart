import 'package:flutter/material.dart';

import '../../core/app_localization.dart';
import '../../data/ai/ai_analysis_models.dart';
import '../../data/models/app_preferences.dart';
import '../../i18n/strings.g.dart';

int exactDaysAgo(DateTime target, DateTime now) {
  return DateUtils.dateOnly(now).difference(DateUtils.dateOnly(target)).inDays;
}

String formatExactDaysAgo(int days, AppLanguage language) {
  return trByLanguageKey(
    language: language,
    key: 'legacy.msg_random_walk_days_ago_exact',
    params: {'days': days},
  );
}

String resolveDayPeriod(DateTime dt, BuildContext context) {
  final hour = dt.hour;
  if (hour >= 5 && hour < 8) {
    return context.t.strings.legacy.msg_random_walk_day_period_dawn;
  }
  if (hour >= 8 && hour < 11) {
    return context.t.strings.legacy.msg_random_walk_day_period_morning;
  }
  if (hour >= 11 && hour < 13) {
    return context.t.strings.legacy.msg_random_walk_day_period_noon;
  }
  if (hour >= 13 && hour < 17) {
    return context.t.strings.legacy.msg_random_walk_day_period_afternoon;
  }
  if (hour >= 17 && hour < 19) {
    return context.t.strings.legacy.msg_random_walk_day_period_dusk;
  }
  return context.t.strings.legacy.msg_random_walk_day_period_night;
}

String buildAiHistoryFullBodyText(
  AiSavedAnalysisReport report, {
  required bool isZh,
}) {
  final buffer = StringBuffer();
  final summaryText = report.summary.trim();
  if (summaryText.isNotEmpty) {
    buffer.writeln(summaryText);
  }

  for (final section in report.sections) {
    final body = section.body.trim();
    if (body.isEmpty ||
        section.sectionKey == 'closing' ||
        section.sectionKey == 'leave_space') {
      continue;
    }
    if (buffer.isNotEmpty) {
      buffer.writeln();
    }
    buffer.writeln(body);
  }

  final closing = _resolveClosingText(report);
  if (closing.isNotEmpty) {
    if (buffer.isNotEmpty) {
      buffer.writeln();
    }
    buffer.writeln(closing);
  }

  final references = _referenceEvidences(report);
  if (references.isNotEmpty) {
    if (buffer.isNotEmpty) {
      buffer.writeln();
    }
    buffer.writeln(
      isZh
          ? '\u8fd9\u6b21\u6d1e\u5bdf\u53c2\u8003\u4e86\u8fd9\u4e9b\u7b14\u8bb0\u7247\u6bb5\uff1a'
          : 'This insight drew on these note fragments:',
    );
    for (final evidence in references) {
      buffer.writeln('- "${evidence.quoteText.trim()}"');
    }
  }

  return buffer.toString().trim();
}

bool isZhLanguage(AppLanguage language) {
  return switch (language) {
    AppLanguage.zhHans => true,
    AppLanguage.zhHantTw => true,
    AppLanguage.system => !prefersEnglishFor(language),
    _ => false,
  };
}

String normalizeCreatorFallback(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.contains('/')) {
    final parts = trimmed.split('/');
    final last = parts.isEmpty ? trimmed : parts.last.trim();
    if (last.isNotEmpty) return last;
  }
  return trimmed;
}

List<AiAnalysisEvidenceData> _referenceEvidences(AiSavedAnalysisReport report) {
  final seen = <String>{};
  final result = <AiAnalysisEvidenceData>[];
  for (final evidence in report.evidences) {
    final quote = evidence.quoteText.trim();
    if (quote.isEmpty) continue;
    if (seen.add(evidence.evidenceKey)) {
      result.add(evidence);
    }
    if (result.length >= 6) {
      break;
    }
  }
  return result;
}

String _resolveClosingText(AiSavedAnalysisReport report) {
  for (final section in report.sections) {
    if (section.sectionKey == 'closing' && section.body.trim().isNotEmpty) {
      return section.body.trim();
    }
  }
  for (final suggestion in report.followUpSuggestions) {
    final trimmed = suggestion.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return '';
}

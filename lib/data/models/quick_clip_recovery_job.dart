import 'dart:convert';

import 'package:flutter/foundation.dart';

enum QuickClipRecoveryJobStatus {
  pending,
  running,
  completed,
  failed,
  abandoned,
}

QuickClipRecoveryJobStatus quickClipRecoveryJobStatusFromValue(String? value) {
  return switch ((value ?? '').trim().toLowerCase()) {
    'running' => QuickClipRecoveryJobStatus.running,
    'completed' => QuickClipRecoveryJobStatus.completed,
    'failed' => QuickClipRecoveryJobStatus.failed,
    'abandoned' => QuickClipRecoveryJobStatus.abandoned,
    _ => QuickClipRecoveryJobStatus.pending,
  };
}

String quickClipRecoveryJobStatusValue(QuickClipRecoveryJobStatus status) {
  return switch (status) {
    QuickClipRecoveryJobStatus.pending => 'pending',
    QuickClipRecoveryJobStatus.running => 'running',
    QuickClipRecoveryJobStatus.completed => 'completed',
    QuickClipRecoveryJobStatus.failed => 'failed',
    QuickClipRecoveryJobStatus.abandoned => 'abandoned',
  };
}

@immutable
class QuickClipRecoveryJob {
  const QuickClipRecoveryJob({
    this.id,
    required this.memoUid,
    required this.sourceUrl,
    required this.payloadType,
    required this.payloadText,
    this.payloadTitle,
    this.payloadPaths = const <String>[],
    required this.textOnly,
    required this.titleAndLinkOnly,
    this.tags = const <String>[],
    required this.localeLanguageCode,
    required this.placeholderMarker,
    required this.placeholderLookupContent,
    required this.status,
    required this.attemptCount,
    required this.createdTime,
    required this.updatedTime,
    this.lastAttemptTime,
    this.completedTime,
    this.lastError,
  });

  factory QuickClipRecoveryJob.pending({
    required String memoUid,
    required String sourceUrl,
    required String payloadType,
    required String payloadText,
    String? payloadTitle,
    List<String> payloadPaths = const <String>[],
    required bool textOnly,
    required bool titleAndLinkOnly,
    List<String> tags = const <String>[],
    required String localeLanguageCode,
    required String placeholderMarker,
    required String placeholderLookupContent,
    DateTime? now,
  }) {
    final timestamp = (now ?? DateTime.now()).toUtc();
    return QuickClipRecoveryJob(
      memoUid: memoUid.trim(),
      sourceUrl: sourceUrl.trim(),
      payloadType: payloadType.trim(),
      payloadText: payloadText.trim(),
      payloadTitle: _normalizeNullableText(payloadTitle),
      payloadPaths: _normalizeStringList(payloadPaths),
      textOnly: textOnly,
      titleAndLinkOnly: titleAndLinkOnly,
      tags: _normalizeStringList(tags),
      localeLanguageCode: localeLanguageCode.trim(),
      placeholderMarker: placeholderMarker.trim(),
      placeholderLookupContent: placeholderLookupContent.trim(),
      status: QuickClipRecoveryJobStatus.pending,
      attemptCount: 0,
      createdTime: timestamp,
      updatedTime: timestamp,
    );
  }

  factory QuickClipRecoveryJob.fromDb(Map<String, dynamic> row) {
    return QuickClipRecoveryJob(
      id: _readInt(row['id']),
      memoUid: (row['memo_uid'] as String? ?? '').trim(),
      sourceUrl: (row['source_url'] as String? ?? '').trim(),
      payloadType: (row['payload_type'] as String? ?? '').trim(),
      payloadText: row['payload_text'] as String? ?? '',
      payloadTitle: _normalizeNullableText(row['payload_title'] as String?),
      payloadPaths: _readStringListJson(row['payload_paths_json']),
      textOnly: _readBool(row['text_only']),
      titleAndLinkOnly: _readBool(row['title_and_link_only']),
      tags: _readStringListJson(row['tags_json']),
      localeLanguageCode: (row['locale_language_code'] as String? ?? '').trim(),
      placeholderMarker: (row['placeholder_marker'] as String? ?? '').trim(),
      placeholderLookupContent:
          (row['placeholder_lookup_content'] as String? ?? '').trim(),
      status: quickClipRecoveryJobStatusFromValue(row['status'] as String?),
      attemptCount: _readInt(row['attempt_count']) ?? 0,
      createdTime: _readDateTime(row['created_time']),
      updatedTime: _readDateTime(row['updated_time']),
      lastAttemptTime: _readNullableDateTime(row['last_attempt_time']),
      completedTime: _readNullableDateTime(row['completed_time']),
      lastError: _normalizeNullableText(row['last_error'] as String?),
    );
  }

  final int? id;
  final String memoUid;
  final String sourceUrl;
  final String payloadType;
  final String payloadText;
  final String? payloadTitle;
  final List<String> payloadPaths;
  final bool textOnly;
  final bool titleAndLinkOnly;
  final List<String> tags;
  final String localeLanguageCode;
  final String placeholderMarker;
  final String placeholderLookupContent;
  final QuickClipRecoveryJobStatus status;
  final int attemptCount;
  final DateTime createdTime;
  final DateTime updatedTime;
  final DateTime? lastAttemptTime;
  final DateTime? completedTime;
  final String? lastError;

  bool get isTerminal =>
      status == QuickClipRecoveryJobStatus.completed ||
      status == QuickClipRecoveryJobStatus.failed ||
      status == QuickClipRecoveryJobStatus.abandoned;

  Map<String, Object?> toDbRow() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'memo_uid': memoUid.trim(),
      'source_url': sourceUrl.trim(),
      'payload_type': payloadType.trim(),
      'payload_text': payloadText,
      'payload_title': _normalizeNullableText(payloadTitle),
      'payload_paths_json': jsonEncode(_normalizeStringList(payloadPaths)),
      'text_only': textOnly ? 1 : 0,
      'title_and_link_only': titleAndLinkOnly ? 1 : 0,
      'tags_json': jsonEncode(_normalizeStringList(tags)),
      'locale_language_code': localeLanguageCode.trim(),
      'placeholder_marker': placeholderMarker.trim(),
      'placeholder_lookup_content': placeholderLookupContent.trim(),
      'status': quickClipRecoveryJobStatusValue(status),
      'attempt_count': attemptCount,
      'created_time': _dateTimeToMs(createdTime),
      'updated_time': _dateTimeToMs(updatedTime),
      'last_attempt_time': _nullableDateTimeToMs(lastAttemptTime),
      'completed_time': _nullableDateTimeToMs(completedTime),
      'last_error': _normalizeNullableText(lastError),
    };
  }

  QuickClipRecoveryJob copyWith({
    int? id,
    String? memoUid,
    String? sourceUrl,
    String? payloadType,
    String? payloadText,
    Object? payloadTitle = _copySentinel,
    List<String>? payloadPaths,
    bool? textOnly,
    bool? titleAndLinkOnly,
    List<String>? tags,
    String? localeLanguageCode,
    String? placeholderMarker,
    String? placeholderLookupContent,
    QuickClipRecoveryJobStatus? status,
    int? attemptCount,
    DateTime? createdTime,
    DateTime? updatedTime,
    Object? lastAttemptTime = _copySentinel,
    Object? completedTime = _copySentinel,
    Object? lastError = _copySentinel,
  }) {
    return QuickClipRecoveryJob(
      id: id ?? this.id,
      memoUid: memoUid ?? this.memoUid,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      payloadType: payloadType ?? this.payloadType,
      payloadText: payloadText ?? this.payloadText,
      payloadTitle: identical(payloadTitle, _copySentinel)
          ? this.payloadTitle
          : _normalizeNullableText(payloadTitle as String?),
      payloadPaths: payloadPaths ?? this.payloadPaths,
      textOnly: textOnly ?? this.textOnly,
      titleAndLinkOnly: titleAndLinkOnly ?? this.titleAndLinkOnly,
      tags: tags ?? this.tags,
      localeLanguageCode: localeLanguageCode ?? this.localeLanguageCode,
      placeholderMarker: placeholderMarker ?? this.placeholderMarker,
      placeholderLookupContent:
          placeholderLookupContent ?? this.placeholderLookupContent,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      createdTime: createdTime ?? this.createdTime,
      updatedTime: updatedTime ?? this.updatedTime,
      lastAttemptTime: identical(lastAttemptTime, _copySentinel)
          ? this.lastAttemptTime
          : lastAttemptTime as DateTime?,
      completedTime: identical(completedTime, _copySentinel)
          ? this.completedTime
          : completedTime as DateTime?,
      lastError: identical(lastError, _copySentinel)
          ? this.lastError
          : _normalizeNullableText(lastError as String?),
    );
  }

  static List<String> _readStringListJson(Object? raw) {
    if (raw is! String || raw.trim().isEmpty) return const <String>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <String>[];
      return _normalizeStringList(decoded.whereType<String>());
    } catch (_) {
      return const <String>[];
    }
  }

  static List<String> _normalizeStringList(Iterable<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  static String? _normalizeNullableText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  static bool _readBool(Object? value) {
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is num) return value.toInt() != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == '1' || normalized == 'true';
    }
    return false;
  }

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static DateTime _readDateTime(Object? value) {
    final ms = _readInt(value) ?? 0;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
  }

  static DateTime? _readNullableDateTime(Object? value) {
    final ms = _readInt(value);
    if (ms == null || ms <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
  }

  static int _dateTimeToMs(DateTime value) {
    return value.toUtc().millisecondsSinceEpoch;
  }

  static int? _nullableDateTimeToMs(DateTime? value) {
    if (value == null) return null;
    return _dateTimeToMs(value);
  }
}

const Object _copySentinel = Object();

import 'sync_error.dart';

sealed class MemoSyncResult {
  const MemoSyncResult();
}

class MemoSyncSuccess extends MemoSyncResult {
  const MemoSyncSuccess();
}

class MemoSyncSuccessWithAttention extends MemoSyncResult {
  const MemoSyncSuccessWithAttention(this.attention);

  final SyncAttentionInfo? attention;
}

class MemoSyncSkipped extends MemoSyncResult {
  const MemoSyncSkipped({this.reason});

  final SyncError? reason;
}

class MemoSyncFailure extends MemoSyncResult {
  const MemoSyncFailure(this.error);

  final SyncError error;
}

sealed class WebDavSyncResult {
  const WebDavSyncResult();
}

class WebDavSyncSuccess extends WebDavSyncResult {
  const WebDavSyncSuccess();
}

class WebDavSyncSkipped extends WebDavSyncResult {
  const WebDavSyncSkipped({this.reason});

  final SyncError? reason;
}

class WebDavSyncConflict extends WebDavSyncResult {
  const WebDavSyncConflict(this.conflicts);

  final List<String> conflicts;
}

class WebDavSyncFailure extends WebDavSyncResult {
  const WebDavSyncFailure(this.error);

  final SyncError error;
}

sealed class WebDavBackupResult {
  const WebDavBackupResult();
}

class WebDavBackupSuccess extends WebDavBackupResult {
  const WebDavBackupSuccess();
}

class WebDavBackupSkipped extends WebDavBackupResult {
  const WebDavBackupSkipped({this.reason});

  final SyncError? reason;
}

class WebDavBackupMissingPassword extends WebDavBackupResult {
  const WebDavBackupMissingPassword();
}

class WebDavBackupFailure extends WebDavBackupResult {
  const WebDavBackupFailure(this.error);

  final SyncError error;
}

sealed class WebDavRestoreResult {
  const WebDavRestoreResult();
}

class WebDavRestoreSuccess extends WebDavRestoreResult {
  const WebDavRestoreSuccess({
    this.missingAttachments = 0,
    this.exportPath,
  });

  final int missingAttachments;
  final String? exportPath;
}

class WebDavRestoreSkipped extends WebDavRestoreResult {
  const WebDavRestoreSkipped({this.reason});

  final SyncError? reason;
}

class WebDavRestoreConflict extends WebDavRestoreResult {
  const WebDavRestoreConflict(this.conflicts);

  final List<LocalScanConflict> conflicts;
}

class WebDavRestoreFailure extends WebDavRestoreResult {
  const WebDavRestoreFailure(this.error);

  final SyncError error;
}

class LocalScanConflict {
  const LocalScanConflict({
    required this.memoUid,
    required this.isDeletion,
  });

  final String memoUid;
  final bool isDeletion;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'memoUid': memoUid,
    'isDeletion': isDeletion,
  };

  factory LocalScanConflict.fromJson(Map<String, dynamic> json) {
    bool readBool(Object? raw) {
      if (raw is bool) return raw;
      if (raw is num) return raw != 0;
      if (raw is String) {
        final normalized = raw.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1') return true;
        if (normalized == 'false' || normalized == '0') return false;
      }
      return false;
    }

    return LocalScanConflict(
      memoUid: json['memoUid'] as String? ?? '',
      isDeletion: readBool(json['isDeletion']),
    );
  }
}

sealed class LocalScanResult {
  const LocalScanResult();
}

class LocalScanSuccess extends LocalScanResult {
  const LocalScanSuccess();
}

class LocalScanConflictResult extends LocalScanResult {
  const LocalScanConflictResult(this.conflicts);

  final List<LocalScanConflict> conflicts;
}

class LocalScanFailure extends LocalScanResult {
  const LocalScanFailure(this.error);

  final SyncError error;
}

class SyncAttentionInfo {
  const SyncAttentionInfo({
    required this.outboxId,
    required this.failureCode,
    required this.occurredAt,
    this.memoUid,
    this.message,
  });

  final int outboxId;
  final String failureCode;
  final String? memoUid;
  final String? message;
  final DateTime occurredAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'outboxId': outboxId,
    'failureCode': failureCode,
    'memoUid': memoUid,
    'message': message,
    'occurredAtMs': occurredAt.millisecondsSinceEpoch,
  };

  factory SyncAttentionInfo.fromJson(Map<String, dynamic> json) {
    int readInt(Object? raw) {
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      if (raw is String) return int.tryParse(raw.trim()) ?? 0;
      return 0;
    }

    return SyncAttentionInfo(
      outboxId: readInt(json['outboxId']),
      failureCode: json['failureCode'] as String? ?? '',
      memoUid: json['memoUid'] as String?,
      message: json['message'] as String?,
      occurredAt: DateTime.fromMillisecondsSinceEpoch(
        readInt(json['occurredAtMs']),
      ),
    );
  }
}

class SyncFlowStatus {
  static const Object _attentionUnchanged = Object();

  const SyncFlowStatus({
    required this.running,
    required this.lastSuccessAt,
    required this.lastError,
    required this.hasPendingConflict,
    this.attention,
  });

  final bool running;
  final DateTime? lastSuccessAt;
  final SyncError? lastError;
  final bool hasPendingConflict;
  final SyncAttentionInfo? attention;

  SyncFlowStatus copyWith({
    bool? running,
    DateTime? lastSuccessAt,
    SyncError? lastError,
    bool? hasPendingConflict,
    Object? attention = _attentionUnchanged,
  }) {
    return SyncFlowStatus(
      running: running ?? this.running,
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      lastError: lastError,
      hasPendingConflict: hasPendingConflict ?? this.hasPendingConflict,
      attention: identical(attention, _attentionUnchanged)
          ? this.attention
          : attention as SyncAttentionInfo?,
    );
  }

  static const idle = SyncFlowStatus(
    running: false,
    lastSuccessAt: null,
    lastError: null,
    hasPendingConflict: false,
    attention: null,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'running': running,
    'lastSuccessAtMs': lastSuccessAt?.millisecondsSinceEpoch,
    'lastError': lastError?.toJson(),
    'hasPendingConflict': hasPendingConflict,
    'attention': attention?.toJson(),
  };

  factory SyncFlowStatus.fromJson(Map<String, dynamic> json) {
    bool readBool(Object? raw) {
      if (raw is bool) return raw;
      if (raw is num) return raw != 0;
      if (raw is String) {
        final normalized = raw.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1') return true;
        if (normalized == 'false' || normalized == '0') return false;
      }
      return false;
    }

    DateTime? readDateTime(Object? raw) {
      if (raw is int) {
        return DateTime.fromMillisecondsSinceEpoch(raw);
      }
      if (raw is num) {
        return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
      }
      if (raw is String) {
        final parsed = int.tryParse(raw.trim());
        if (parsed != null) {
          return DateTime.fromMillisecondsSinceEpoch(parsed);
        }
      }
      return null;
    }

    final rawError = json['lastError'];
    final rawAttention = json['attention'];
    return SyncFlowStatus(
      running: readBool(json['running']),
      lastSuccessAt: readDateTime(json['lastSuccessAtMs']),
      lastError: rawError is Map
          ? SyncError.fromJson(
              Map<Object?, Object?>.from(rawError).cast<String, Object?>(),
            )
          : null,
      hasPendingConflict: readBool(json['hasPendingConflict']),
      attention: rawAttention is Map
          ? SyncAttentionInfo.fromJson(
              Map<Object?, Object?>.from(rawAttention).cast<String, dynamic>(),
            )
          : null,
    );
  }
}

sealed class SyncRunResult {
  const SyncRunResult();
}

class SyncRunStarted extends SyncRunResult {
  const SyncRunStarted();
}

class SyncRunQueued extends SyncRunResult {
  const SyncRunQueued();
}

class SyncRunSkipped extends SyncRunResult {
  const SyncRunSkipped({this.reason});

  final SyncError? reason;
}

class SyncRunFailure extends SyncRunResult {
  const SyncRunFailure(this.error);

  final SyncError error;
}

class SyncRunConflict extends SyncRunResult {
  const SyncRunConflict(this.conflicts);

  final List<String> conflicts;
}

Map<String, dynamic> syncRunResultToJson(SyncRunResult result) {
  return switch (result) {
    SyncRunStarted() => <String, dynamic>{'type': 'started'},
    SyncRunQueued() => <String, dynamic>{'type': 'queued'},
    SyncRunSkipped(:final reason) => <String, dynamic>{
      'type': 'skipped',
      'reason': reason?.toJson(),
    },
    SyncRunFailure(:final error) => <String, dynamic>{
      'type': 'failure',
      'error': error.toJson(),
    },
    SyncRunConflict(:final conflicts) => <String, dynamic>{
      'type': 'conflict',
      'conflicts': conflicts,
    },
  };
}

SyncRunResult syncRunResultFromJson(Map<String, dynamic> json) {
  final type = json['type'] as String? ?? '';
  final rawReason = json['reason'];
  final rawError = json['error'];
  return switch (type) {
    'started' => const SyncRunStarted(),
    'queued' => const SyncRunQueued(),
    'skipped' => SyncRunSkipped(
      reason: rawReason is Map
          ? SyncError.fromJson(
              Map<Object?, Object?>.from(rawReason).cast<String, Object?>(),
            )
          : null,
    ),
    'failure' => SyncRunFailure(
      rawError is Map
          ? (SyncError.fromJson(
                  Map<Object?, Object?>.from(rawError).cast<String, Object?>(),
                ) ??
                const SyncError(
                  code: SyncErrorCode.unknown,
                  retryable: true,
                ))
          : const SyncError(code: SyncErrorCode.unknown, retryable: true),
    ),
    'conflict' => SyncRunConflict(
      (json['conflicts'] as List? ?? const <Object?>[])
          .whereType<String>()
          .toList(growable: false),
    ),
    _ => const SyncRunSkipped(),
  };
}

Map<String, dynamic> webDavRestoreResultToJson(WebDavRestoreResult result) {
  return switch (result) {
    WebDavRestoreSuccess(
      :final missingAttachments,
      :final exportPath,
    ) => <String, dynamic>{
      'type': 'success',
      'missingAttachments': missingAttachments,
      'exportPath': exportPath,
    },
    WebDavRestoreSkipped(:final reason) => <String, dynamic>{
      'type': 'skipped',
      'reason': reason?.toJson(),
    },
    WebDavRestoreConflict(:final conflicts) => <String, dynamic>{
      'type': 'conflict',
      'conflicts': conflicts.map((item) => item.toJson()).toList(growable: false),
    },
    WebDavRestoreFailure(:final error) => <String, dynamic>{
      'type': 'failure',
      'error': error.toJson(),
    },
  };
}

WebDavRestoreResult webDavRestoreResultFromJson(Map<String, dynamic> json) {
  final type = json['type'] as String? ?? '';
  final rawReason = json['reason'];
  final rawError = json['error'];
  return switch (type) {
    'success' => WebDavRestoreSuccess(
      missingAttachments: json['missingAttachments'] is num
          ? (json['missingAttachments'] as num).toInt()
          : 0,
      exportPath: json['exportPath'] as String?,
    ),
    'skipped' => WebDavRestoreSkipped(
      reason: rawReason is Map
          ? SyncError.fromJson(
              Map<Object?, Object?>.from(rawReason).cast<String, Object?>(),
            )
          : null,
    ),
    'conflict' => WebDavRestoreConflict(
      (json['conflicts'] as List? ?? const <Object?>[])
          .whereType<Map>()
          .map(
            (item) => LocalScanConflict.fromJson(
              Map<Object?, Object?>.from(item).cast<String, dynamic>(),
            ),
          )
          .toList(growable: false),
    ),
    'failure' => WebDavRestoreFailure(
      rawError is Map
          ? (SyncError.fromJson(
                  Map<Object?, Object?>.from(rawError).cast<String, Object?>(),
                ) ??
                const SyncError(
                  code: SyncErrorCode.unknown,
                  retryable: true,
                ))
          : const SyncError(code: SyncErrorCode.unknown, retryable: true),
    ),
    _ => const WebDavRestoreSkipped(),
  };
}

enum SyncRequestKind {
  memos,
  webDavSync,
  webDavBackup,
  localScan,
  all,
}

enum SyncRequestReason {
  manual,
  launch,
  resume,
  settings,
  auto,
}

class SyncRequest {
  const SyncRequest({
    required this.kind,
    required this.reason,
    this.refreshCurrentUserBeforeSync = false,
    this.showFeedbackToast = false,
    this.forceWidgetUpdate = false,
  });

  final SyncRequestKind kind;
  final SyncRequestReason reason;
  final bool refreshCurrentUserBeforeSync;
  final bool showFeedbackToast;
  final bool forceWidgetUpdate;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'kind': kind.name,
    'reason': reason.name,
    'refreshCurrentUserBeforeSync': refreshCurrentUserBeforeSync,
    'showFeedbackToast': showFeedbackToast,
    'forceWidgetUpdate': forceWidgetUpdate,
  };

  factory SyncRequest.fromJson(Map<String, dynamic> json) {
    SyncRequestKind readKind(Object? raw) {
      if (raw is String) {
        return SyncRequestKind.values.firstWhere(
          (item) => item.name == raw,
          orElse: () => SyncRequestKind.memos,
        );
      }
      return SyncRequestKind.memos;
    }

    SyncRequestReason readReason(Object? raw) {
      if (raw is String) {
        return SyncRequestReason.values.firstWhere(
          (item) => item.name == raw,
          orElse: () => SyncRequestReason.manual,
        );
      }
      return SyncRequestReason.manual;
    }

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

    return SyncRequest(
      kind: readKind(json['kind']),
      reason: readReason(json['reason']),
      refreshCurrentUserBeforeSync: readBool(
        json['refreshCurrentUserBeforeSync'],
      ),
      showFeedbackToast: readBool(json['showFeedbackToast']),
      forceWidgetUpdate: readBool(json['forceWidgetUpdate']),
    );
  }
}

const String appDatabaseWriteCommandType = 'app_database';
const String tagRepositoryWriteCommandType = 'tag_repository';
const String aiAnalysisRepositoryWriteCommandType = 'ai_analysis_repository';

class DbWriteEnvelope {
  const DbWriteEnvelope({
    required this.requestId,
    required this.workspaceKey,
    required this.dbName,
    required this.commandType,
    required this.operation,
    required this.payload,
    required this.originRole,
    required this.originWindowId,
  });

  final String requestId;
  final String workspaceKey;
  final String dbName;
  final String commandType;
  final String operation;
  final Map<String, dynamic> payload;
  final String originRole;
  final int originWindowId;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'requestId': requestId,
    'workspaceKey': workspaceKey,
    'dbName': dbName,
    'commandType': commandType,
    'operation': operation,
    'payload': payload,
    'originRole': originRole,
    'originWindowId': originWindowId,
  };

  factory DbWriteEnvelope.fromJson(Map<Object?, Object?> json) {
    final payload = json['payload'];
    return DbWriteEnvelope(
      requestId: (json['requestId'] as String? ?? '').trim(),
      workspaceKey: (json['workspaceKey'] as String? ?? '').trim(),
      dbName: (json['dbName'] as String? ?? '').trim(),
      commandType: (json['commandType'] as String? ?? '').trim(),
      operation: (json['operation'] as String? ?? '').trim(),
      payload: payload is Map
          ? Map<Object?, Object?>.from(payload).map<String, dynamic>(
              (key, value) => MapEntry(key.toString(), value),
            )
          : const <String, dynamic>{},
      originRole: (json['originRole'] as String? ?? '').trim(),
      originWindowId: (json['originWindowId'] as num?)?.toInt() ?? 0,
    );
  }
}

class DbWriteError {
  const DbWriteError({
    required this.code,
    required this.message,
    required this.retryable,
  });

  final String code;
  final String message;
  final bool retryable;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'code': code,
    'message': message,
    'retryable': retryable,
  };

  factory DbWriteError.fromJson(Map<Object?, Object?> json) {
    return DbWriteError(
      code: (json['code'] as String? ?? 'unknown').trim(),
      message: (json['message'] as String? ?? 'Unknown database write error')
          .trim(),
      retryable: json['retryable'] == true,
    );
  }

  DbWriteException toException() {
    return DbWriteException(code: code, message: message, retryable: retryable);
  }
}

class DbWriteResult {
  const DbWriteResult._({required this.success, this.value, this.error});

  const DbWriteResult.success(Object? value)
    : this._(success: true, value: value, error: null);

  const DbWriteResult.failure(DbWriteError error)
    : this._(success: false, value: null, error: error);

  final bool success;
  final Object? value;
  final DbWriteError? error;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'success': success,
    'value': value,
    'error': error?.toJson(),
  };

  factory DbWriteResult.fromJson(Map<Object?, Object?> json) {
    final rawError = json['error'];
    return DbWriteResult._(
      success: json['success'] == true,
      value: json['value'],
      error: rawError is Map ? DbWriteError.fromJson(rawError) : null,
    );
  }
}

class DbWriteException implements Exception {
  const DbWriteException({
    required this.code,
    required this.message,
    required this.retryable,
  });

  final String code;
  final String message;
  final bool retryable;

  @override
  String toString() => message;
}

class DesktopDbChangeEvent {
  const DesktopDbChangeEvent({
    required this.workspaceKey,
    required this.dbName,
    required this.changeId,
    required this.category,
    required this.originWindowId,
  });

  final String workspaceKey;
  final String dbName;
  final String changeId;
  final String category;
  final int originWindowId;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'workspaceKey': workspaceKey,
    'dbName': dbName,
    'changeId': changeId,
    'category': category,
    'originWindowId': originWindowId,
  };

  factory DesktopDbChangeEvent.fromJson(Map<Object?, Object?> json) {
    return DesktopDbChangeEvent(
      workspaceKey: (json['workspaceKey'] as String? ?? '').trim(),
      dbName: (json['dbName'] as String? ?? '').trim(),
      changeId: (json['changeId'] as String? ?? '').trim(),
      category: (json['category'] as String? ?? '').trim(),
      originWindowId: (json['originWindowId'] as num?)?.toInt() ?? 0,
    );
  }
}

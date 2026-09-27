part of 'memos_providers.dart';

String _extractErrorMessage(dynamic data) {
  if (data is Map) {
    final msg = data['message'] ?? data['error'] ?? data['detail'];
    if (msg is String && msg.trim().isNotEmpty) return msg.trim();
  }
  if (data is String) {
    final s = data.trim();
    if (s.isEmpty) return '';
    // gRPC gateway usually returns JSON, but keep it best-effort.
    try {
      final decoded = jsonDecode(s);
      if (decoded is Map) {
        final msg = decoded['message'] ?? decoded['error'] ?? decoded['detail'];
        if (msg is String && msg.trim().isNotEmpty) return msg.trim();
      }
    } catch (_) {}
    return s;
  }
  return '';
}

SyncError _summarizeHttpError(DioException e) {
  final status = e.response?.statusCode;
  final msg = _extractErrorMessage(e.response?.data);
  final method = e.requestOptions.method;
  final path = e.requestOptions.uri.path;

  if (status == null) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return SyncError(
        code: SyncErrorCode.network,
        retryable: true,
        presentationKey: 'legacy.msg_network_timeout_try',
        requestMethod: method,
        requestPath: path,
      );
    }
    if (e.type == DioExceptionType.connectionError) {
      return SyncError(
        code: SyncErrorCode.network,
        retryable: true,
        presentationKey: 'legacy.msg_network_connection_failed_check_network',
        requestMethod: method,
        requestPath: path,
      );
    }
    final raw = e.message ?? '';
    if (raw.trim().isNotEmpty) {
      return SyncError(
        code: SyncErrorCode.network,
        retryable: true,
        message: raw.trim(),
        requestMethod: method,
        requestPath: path,
      );
    }
    return SyncError(
      code: SyncErrorCode.network,
      retryable: true,
      presentationKey: 'legacy.msg_network_request_failed',
      requestMethod: method,
      requestPath: path,
    );
  }

  final attachmentTooLarge = _looksLikeAttachmentTooLargeHttpError(
    status: status,
    message: msg,
  );
  final baseKey = attachmentTooLarge
      ? 'legacy.msg_attachment_too_large'
      : switch (status) {
          400 => 'legacy.msg_invalid_request_parameters',
          401 => 'legacy.msg_authentication_failed_check_token',
          403 => 'legacy.msg_insufficient_permissions',
          404 => 'legacy.msg_endpoint_not_found_version_mismatch',
          413 => 'legacy.msg_attachment_too_large',
          500 => 'legacy.msg_server_error',
          _ => 'legacy.msg_request_failed',
        };
  final presentationKey = msg.isEmpty ? 'legacy.msg_http_2' : 'legacy.msg_http';
  final code = switch (status) {
    400 => SyncErrorCode.invalidConfig,
    401 => SyncErrorCode.authFailed,
    403 => SyncErrorCode.permission,
    404 => SyncErrorCode.server,
    413 => SyncErrorCode.server,
    >= 500 => SyncErrorCode.server,
    _ => SyncErrorCode.unknown,
  };
  return SyncError(
    code: code,
    retryable: status >= 500,
    message: msg.isEmpty ? null : msg,
    httpStatus: status,
    requestMethod: method,
    requestPath: path,
    presentationKey: presentationKey,
    presentationParams: {
      'baseKey': baseKey,
      'status': status.toString(),
      if (msg.isNotEmpty) 'msg': msg,
    },
  );
}

@visibleForTesting
SyncError summarizeMemosHttpErrorForTesting(DioException e) {
  return _summarizeHttpError(e);
}

bool _looksLikeAttachmentTooLargeHttpError({
  required int status,
  required String message,
}) {
  if (status == 413) return true;
  final normalized = message.toLowerCase();
  if (normalized.trim().isEmpty) return false;
  return normalized.contains('file size exceeds the limit') ||
      normalized.contains('attachment too large') ||
      normalized.contains('payload too large') ||
      normalized.contains('request entity too large') ||
      (normalized.contains('upload') &&
          normalized.contains('size') &&
          normalized.contains('limit'));
}

String _detailHttpError(DioException e) {
  final status = e.response?.statusCode;
  final uri = e.requestOptions.uri;
  final msg = _extractErrorMessage(e.response?.data);
  final reason = (e.message ?? '').trim();
  final lowLevel = (e.error?.toString() ?? '').trim();
  final detail = msg.isNotEmpty
      ? msg
      : (reason.isNotEmpty
            ? reason
            : (lowLevel.isNotEmpty ? lowLevel : 'unknown'));
  final parts = <String>[
    if (status != null) 'HTTP $status' else 'HTTP ?',
    '${e.requestOptions.method} $uri',
    detail,
  ];
  return parts.join(' | ');
}

SyncError _buildSyncError(Object error) {
  if (error is SyncError) return error;
  if (error is DioException) return _summarizeHttpError(error);
  return SyncError(
    code: SyncErrorCode.unknown,
    retryable: false,
    message: error.toString(),
  );
}

SyncError _outboxBlockedError() {
  return const SyncError(
    code: SyncErrorCode.unknown,
    retryable: true,
    message: 'Outbox blocked by pending retryable tasks',
  );
}

bool _isTransientOutboxNetworkError(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return true;
    case DioExceptionType.badCertificate:
    case DioExceptionType.badResponse:
    case DioExceptionType.cancel:
      return false;
    case DioExceptionType.unknown:
      break;
  }

  final texts = <String>[
    e.message ?? '',
    e.error?.toString() ?? '',
    _extractErrorMessage(e.response?.data),
  ];
  final combined = texts.join(' | ').toLowerCase();
  if (combined.trim().isEmpty) return false;

  return combined.contains(
        'connection closed before full header was received',
      ) ||
      combined.contains('connection reset by peer') ||
      combined.contains('connection aborted') ||
      combined.contains('broken pipe') ||
      combined.contains('socketexception') ||
      combined.contains('httpexception');
}

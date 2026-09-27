import 'dart:async';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/services.dart';

import '../../core/desktop_sync_channel.dart';
import '../../data/models/local_library.dart';
import '../../data/models/webdav_backup.dart';
import '../../data/models/webdav_export_status.dart';
import '../../data/models/webdav_sync_meta.dart';
import '../../data/models/webdav_settings.dart';
import 'sync_coordinator.dart';
import 'sync_error.dart';
import 'sync_request.dart';
import 'sync_types.dart';
import 'webdav_backup_service.dart';
import 'webdav_sync_service.dart';

Map<String, dynamic> desktopSyncRpcSuccess(Object? value) => <String, dynamic>{
  'ok': true,
  'value': value,
};

Map<String, dynamic> desktopSyncRpcFailure({
  SyncError? syncError,
  String? code,
  String? message,
  bool retryable = true,
}) => <String, dynamic>{
  'ok': false,
  if (syncError != null) 'syncError': syncError.toJson(),
  if (code != null) 'code': code,
  if (message != null) 'message': message,
  'retryable': retryable,
};

class DesktopRemoteSyncFacade extends DesktopSyncFacade {
  DesktopRemoteSyncFacade({
    required int originWindowId,
    required String? workspaceKey,
  }) : _originWindowId = originWindowId,
       _workspaceKey = workspaceKey?.trim(),
       super(SyncCoordinatorState.initial) {
    unawaited(_bootstrap());
  }

  final int _originWindowId;
  final String? _workspaceKey;
  int _requestSequence = 0;
  WebDavBackupExportIssueHandler? _pendingBackupIssueHandler;
  bool _backupIssueHandlerAwaitingRun = false;
  bool _backupIssueHandlerSawRunning = false;
  WebDavBackupConfigRestorePromptHandler? _pendingBackupConfigPromptHandler;

  static SyncError ownerUnavailableSyncError() {
    return const SyncError(
      code: SyncErrorCode.invalidConfig,
      retryable: true,
      presentationKey: 'legacy.desktop.owner_unavailable',
      message: 'desktop_owner_unavailable',
    );
  }

  static bool _isMainWindowChannelMissing(Object error) {
    if (error is MissingPluginException) return true;
    if (error is! PlatformException) return false;
    final message = (error.message ?? '').toLowerCase();
    return message.contains('target window not found') ||
        message.contains('target window channel not found');
  }

  static Future<dynamic> invokeDesktopMainWindowMethod(
    String method, [
    dynamic arguments,
  ]) async {
    const maxAttempts = 6;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        return await DesktopMultiWindow.invokeMethod(0, method, arguments);
      } catch (error) {
        if (!_isMainWindowChannelMissing(error) || attempt == maxAttempts - 1) {
          rethrow;
        }
        try {
          await WindowController.main().show();
        } catch (_) {}
        await Future<void>.delayed(
          Duration(milliseconds: 120 + (attempt * 120)),
        );
      }
    }
    throw MissingPluginException('Main window channel is not ready.');
  }

  Future<void> _bootstrap() async {
    try {
      final raw = await invokeDesktopMainWindowMethod(
        desktopSyncStateSnapshotMethod,
        <String, dynamic>{'workspaceKey': _workspaceKey},
      );
      if (raw is! Map) return;
      final payload = Map<Object?, Object?>.from(
        raw,
      ).map<String, dynamic>((key, value) => MapEntry(key.toString(), value));
      final value = _unwrapRpcResponse(payload);
      if (value is Map) {
        if (!mounted || !identical(state, SyncCoordinatorState.initial)) {
          return;
        }
        applyRemoteStateSnapshot(
          SyncCoordinatorState.fromJson(
            Map<Object?, Object?>.from(value).map<String, dynamic>(
              (key, item) => MapEntry(key.toString(), item),
            ),
          ),
        );
      }
    } catch (_) {}
  }

  Object? _unwrapRpcResponse(Map<String, dynamic> response) {
    if (response['ok'] == true) {
      return response['value'];
    }
    final rawSyncError = response['syncError'];
    final syncError = rawSyncError is Map
        ? SyncError.fromJson(
            Map<Object?, Object?>.from(rawSyncError).cast<String, Object?>(),
          )
        : null;
    throw _DesktopSyncRpcException(
      syncError:
          syncError ??
          SyncError(
            code: SyncErrorCode.invalidConfig,
            retryable: response['retryable'] != false,
            message:
                response['message'] as String? ?? 'desktop_sync_rpc_failed',
          ),
    );
  }

  void _clearPendingBackupIssueHandler() {
    _pendingBackupIssueHandler = null;
    _backupIssueHandlerAwaitingRun = false;
    _backupIssueHandlerSawRunning = false;
  }

  String _nextRequestId(String operation) {
    _requestSequence += 1;
    return [
      'desktopSync',
      _originWindowId.toString(),
      operation,
      DateTime.now().microsecondsSinceEpoch.toString(),
      _requestSequence.toString(),
    ].join('.');
  }

  String _nextSessionId(String operation) {
    final workspace = (_workspaceKey ?? '').trim().isEmpty
        ? 'unknown'
        : _workspaceKey!.trim();
    return [
      'desktopSyncSession',
      _originWindowId.toString(),
      workspace,
      operation,
      DateTime.now().microsecondsSinceEpoch.toString(),
    ].join('.');
  }

  Future<Object?> _invokeRequest(
    String operation, [
    Map<String, dynamic>? payload,
  ]) async {
    final requestId = _nextRequestId(operation);
    final sessionId = _nextSessionId(operation);
    final raw = await invokeDesktopMainWindowMethod(
      desktopSyncRequestMethod,
      <String, dynamic>{
        'originWindowId': _originWindowId,
        'workspaceKey': _workspaceKey,
        'requestId': requestId,
        'sessionId': sessionId,
        'operation': operation,
        if (payload != null) 'payload': payload,
      },
    );
    if (raw is! Map) {
      throw _DesktopSyncRpcException(syncError: ownerUnavailableSyncError());
    }
    return _unwrapRpcResponse(
      Map<Object?, Object?>.from(
        raw,
      ).map<String, dynamic>((key, value) => MapEntry(key.toString(), value)),
    );
  }

  Map<String, dynamic> _readMap(Object? raw) {
    if (raw is Map) {
      return Map<Object?, Object?>.from(
        raw,
      ).map<String, dynamic>((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }

  @override
  Future<SyncRunResult> requestSync(SyncRequest request) async {
    try {
      final raw = await _invokeRequest('requestSync', <String, dynamic>{
        'request': request.toJson(),
      });
      return syncRunResultFromJson(_readMap(raw));
    } on _DesktopSyncRpcException catch (error) {
      return SyncRunFailure(error.syncError);
    } catch (_) {
      return SyncRunFailure(ownerUnavailableSyncError());
    }
  }

  @override
  Future<SyncRunResult> requestWebDavBackup({
    required SyncRequestReason reason,
    String? password,
    WebDavBackupExportIssueHandler? onExportIssue,
  }) async {
    _pendingBackupIssueHandler = onExportIssue;
    _backupIssueHandlerAwaitingRun = onExportIssue != null;
    _backupIssueHandlerSawRunning = false;
    try {
      final raw = await _invokeRequest('requestWebDavBackup', <String, dynamic>{
        'reason': reason.name,
        'password': password,
      });
      final result = syncRunResultFromJson(_readMap(raw));
      if (result is! SyncRunStarted && result is! SyncRunQueued) {
        _clearPendingBackupIssueHandler();
      }
      return result;
    } on _DesktopSyncRpcException catch (error) {
      _clearPendingBackupIssueHandler();
      return SyncRunFailure(error.syncError);
    } catch (_) {
      _clearPendingBackupIssueHandler();
      return SyncRunFailure(ownerUnavailableSyncError());
    }
  }

  @override
  Future<WebDavSyncMeta?> fetchWebDavSyncMeta() async {
    try {
      final raw = await _invokeRequest('fetchWebDavSyncMeta');
      if (raw is! Map) return null;
      return WebDavSyncMeta.fromJson(
        Map<Object?, Object?>.from(raw).cast<String, dynamic>(),
      );
    } on _DesktopSyncRpcException catch (error) {
      throw error.syncError;
    } catch (_) {
      throw ownerUnavailableSyncError();
    }
  }

  @override
  Future<WebDavSyncMeta?> cleanWebDavDeprecatedPlainFiles() async {
    try {
      final raw = await _invokeRequest('cleanWebDavDeprecatedPlainFiles');
      if (raw is! Map) return null;
      return WebDavSyncMeta.fromJson(
        Map<Object?, Object?>.from(raw).cast<String, dynamic>(),
      );
    } on _DesktopSyncRpcException catch (error) {
      throw error.syncError;
    } catch (_) {
      throw ownerUnavailableSyncError();
    }
  }

  @override
  Future<WebDavConnectionTestResult> testWebDavConnection({
    required WebDavSettings settings,
  }) async {
    try {
      final raw = await _invokeRequest(
        'testWebDavConnection',
        <String, dynamic>{'settings': settings.toJson()},
      );
      return WebDavConnectionTestResult.fromJson(_readMap(raw));
    } on _DesktopSyncRpcException catch (error) {
      return WebDavConnectionTestResult.failure(error.syncError);
    } catch (_) {
      return WebDavConnectionTestResult.failure(ownerUnavailableSyncError());
    }
  }

  @override
  Future<SyncError?> verifyWebDavBackup({
    required String password,
    required bool deep,
  }) async {
    try {
      final raw = await _invokeRequest('verifyWebDavBackup', <String, dynamic>{
        'password': password,
        'deep': deep,
      });
      if (raw is! Map) return null;
      return SyncError.fromJson(
        Map<Object?, Object?>.from(raw).cast<String, Object?>(),
      );
    } on _DesktopSyncRpcException catch (error) {
      return error.syncError;
    } catch (_) {
      return ownerUnavailableSyncError();
    }
  }

  @override
  Future<WebDavExportStatus> fetchWebDavExportStatus() async {
    try {
      final raw = await _invokeRequest('fetchWebDavExportStatus');
      return WebDavExportStatus.fromJson(_readMap(raw));
    } on _DesktopSyncRpcException catch (error) {
      throw error.syncError;
    } catch (_) {
      throw ownerUnavailableSyncError();
    }
  }

  @override
  Future<WebDavExportCleanupStatus> cleanWebDavPlainExport() async {
    try {
      final raw = await _invokeRequest('cleanWebDavPlainExport');
      final name = raw as String? ?? '';
      return WebDavExportCleanupStatus.values.firstWhere(
        (item) => item.name == name,
        orElse: () => WebDavExportCleanupStatus.notFound,
      );
    } on _DesktopSyncRpcException catch (error) {
      throw error.syncError;
    } catch (_) {
      throw ownerUnavailableSyncError();
    }
  }

  @override
  Future<List<WebDavBackupSnapshotInfo>> listWebDavBackupSnapshots({
    required WebDavSettings settings,
    required String? accountKey,
    required String password,
  }) async {
    try {
      final raw = await _invokeRequest(
        'listWebDavBackupSnapshots',
        <String, dynamic>{
          'settings': settings.toJson(),
          'accountKey': accountKey,
          'password': password,
        },
      );
      if (raw is! List) return const <WebDavBackupSnapshotInfo>[];
      return raw
          .whereType<Map>()
          .map(
            (item) => WebDavBackupSnapshotInfo.fromJson(
              Map<Object?, Object?>.from(item).cast<String, dynamic>(),
            ),
          )
          .toList(growable: false);
    } on _DesktopSyncRpcException catch (error) {
      throw error.syncError;
    } catch (_) {
      throw ownerUnavailableSyncError();
    }
  }

  @override
  Future<String> recoverWebDavBackupPassword({
    required WebDavSettings settings,
    required String? accountKey,
    required String recoveryCode,
    required String newPassword,
  }) async {
    try {
      final raw =
          await _invokeRequest('recoverWebDavBackupPassword', <String, dynamic>{
            'settings': settings.toJson(),
            'accountKey': accountKey,
            'recoveryCode': recoveryCode,
            'newPassword': newPassword,
          });
      return raw as String? ?? '';
    } on _DesktopSyncRpcException catch (error) {
      throw error.syncError;
    } catch (_) {
      throw ownerUnavailableSyncError();
    }
  }

  @override
  Future<WebDavRestoreResult> restoreWebDavPlainBackup({
    required WebDavSettings settings,
    required String? accountKey,
    required LocalLibrary? activeLocalLibrary,
    Map<String, bool>? conflictDecisions,
    WebDavBackupConfigRestorePromptHandler? onConfigRestorePrompt,
  }) async {
    _pendingBackupConfigPromptHandler = onConfigRestorePrompt;
    try {
      final raw = await _invokeRequest(
        'restoreWebDavPlainBackup',
        <String, dynamic>{
          'settings': settings.toJson(),
          'accountKey': accountKey,
          'activeLocalLibrary': activeLocalLibrary?.toJson(),
          if (conflictDecisions != null) 'conflictDecisions': conflictDecisions,
        },
      );
      return webDavRestoreResultFromJson(_readMap(raw));
    } on _DesktopSyncRpcException catch (error) {
      return WebDavRestoreFailure(error.syncError);
    } catch (_) {
      return WebDavRestoreFailure(ownerUnavailableSyncError());
    } finally {
      _pendingBackupConfigPromptHandler = null;
    }
  }

  @override
  Future<WebDavRestoreResult> restoreWebDavPlainBackupToDirectory({
    required WebDavSettings settings,
    required String? accountKey,
    required LocalLibrary exportLibrary,
    required String exportPrefix,
    WebDavBackupConfigRestorePromptHandler? onConfigRestorePrompt,
  }) async {
    _pendingBackupConfigPromptHandler = onConfigRestorePrompt;
    try {
      final raw = await _invokeRequest(
        'restoreWebDavPlainBackupToDirectory',
        <String, dynamic>{
          'settings': settings.toJson(),
          'accountKey': accountKey,
          'exportLibrary': exportLibrary.toJson(),
          'exportPrefix': exportPrefix,
        },
      );
      return webDavRestoreResultFromJson(_readMap(raw));
    } on _DesktopSyncRpcException catch (error) {
      return WebDavRestoreFailure(error.syncError);
    } catch (_) {
      return WebDavRestoreFailure(ownerUnavailableSyncError());
    } finally {
      _pendingBackupConfigPromptHandler = null;
    }
  }

  @override
  Future<WebDavRestoreResult> restoreWebDavSnapshot({
    required WebDavSettings settings,
    required String? accountKey,
    required LocalLibrary? activeLocalLibrary,
    required WebDavBackupSnapshotInfo snapshot,
    required String password,
    Map<String, bool>? conflictDecisions,
    WebDavBackupConfigRestorePromptHandler? onConfigRestorePrompt,
  }) async {
    _pendingBackupConfigPromptHandler = onConfigRestorePrompt;
    try {
      final raw = await _invokeRequest(
        'restoreWebDavSnapshot',
        <String, dynamic>{
          'settings': settings.toJson(),
          'accountKey': accountKey,
          'activeLocalLibrary': activeLocalLibrary?.toJson(),
          'snapshot': snapshot.toJson(),
          'password': password,
          if (conflictDecisions != null) 'conflictDecisions': conflictDecisions,
        },
      );
      return webDavRestoreResultFromJson(_readMap(raw));
    } on _DesktopSyncRpcException catch (error) {
      return WebDavRestoreFailure(error.syncError);
    } catch (_) {
      return WebDavRestoreFailure(ownerUnavailableSyncError());
    } finally {
      _pendingBackupConfigPromptHandler = null;
    }
  }

  @override
  Future<WebDavRestoreResult> restoreWebDavSnapshotToDirectory({
    required WebDavSettings settings,
    required String? accountKey,
    required WebDavBackupSnapshotInfo snapshot,
    required String password,
    required LocalLibrary exportLibrary,
    required String exportPrefix,
    WebDavBackupConfigRestorePromptHandler? onConfigRestorePrompt,
  }) async {
    _pendingBackupConfigPromptHandler = onConfigRestorePrompt;
    try {
      final raw = await _invokeRequest(
        'restoreWebDavSnapshotToDirectory',
        <String, dynamic>{
          'settings': settings.toJson(),
          'accountKey': accountKey,
          'snapshot': snapshot.toJson(),
          'password': password,
          'exportLibrary': exportLibrary.toJson(),
          'exportPrefix': exportPrefix,
        },
      );
      return webDavRestoreResultFromJson(_readMap(raw));
    } on _DesktopSyncRpcException catch (error) {
      return WebDavRestoreFailure(error.syncError);
    } catch (_) {
      return WebDavRestoreFailure(ownerUnavailableSyncError());
    } finally {
      _pendingBackupConfigPromptHandler = null;
    }
  }

  @override
  Future<void> resolveWebDavConflicts(Map<String, bool> resolutions) async {
    try {
      await _invokeRequest('resolveWebDavConflicts', <String, dynamic>{
        'resolutions': resolutions,
      });
    } catch (_) {}
  }

  @override
  Future<void> resolveLocalScanConflicts(Map<String, bool> resolutions) async {
    try {
      await _invokeRequest('resolveLocalScanConflicts', <String, dynamic>{
        'resolutions': resolutions,
      });
    } catch (_) {}
  }

  @override
  Future<void> retryPending() async {
    try {
      await _invokeRequest('retryPending');
    } catch (_) {}
  }

  @override
  void applyRemoteStateSnapshot(SyncCoordinatorState next) {
    if (!mounted) return;
    state = next;
    if (_pendingBackupIssueHandler == null) return;
    if (next.webDavBackup.running) {
      _backupIssueHandlerAwaitingRun = false;
      _backupIssueHandlerSawRunning = true;
      return;
    }
    if (_backupIssueHandlerSawRunning || !_backupIssueHandlerAwaitingRun) {
      _clearPendingBackupIssueHandler();
    }
  }

  @override
  Future<WebDavBackupExportResolution> handleBackupExportIssuePrompt(
    WebDavBackupExportIssue issue,
  ) async {
    final handler = _pendingBackupIssueHandler;
    if (handler == null) {
      return const WebDavBackupExportResolution(
        action: WebDavBackupExportAction.abort,
      );
    }
    try {
      return await handler(issue);
    } catch (_) {
      return const WebDavBackupExportResolution(
        action: WebDavBackupExportAction.abort,
      );
    }
  }

  @override
  Future<Set<WebDavBackupConfigType>> handleBackupConfigRestorePrompt(
    Set<WebDavBackupConfigType> candidates,
  ) async {
    final handler = _pendingBackupConfigPromptHandler;
    if (handler == null || candidates.isEmpty) {
      return const <WebDavBackupConfigType>{};
    }
    try {
      return await handler(candidates);
    } catch (_) {
      return const <WebDavBackupConfigType>{};
    }
  }
}

Map<String, dynamic> serializeWebDavBackupExportIssue(
  WebDavBackupExportIssue issue,
) => <String, dynamic>{
  'kind': issue.kind.name,
  'memoUid': issue.memoUid,
  'attachmentFilename': issue.attachmentFilename,
  'error': issue.error.toString(),
};

WebDavBackupExportIssue deserializeWebDavBackupExportIssue(
  Map<String, dynamic> json,
) {
  final kindName = json['kind'] as String? ?? '';
  final kind = WebDavBackupExportIssueKind.values.firstWhere(
    (item) => item.name == kindName,
    orElse: () => WebDavBackupExportIssueKind.memo,
  );
  return WebDavBackupExportIssue(
    kind: kind,
    memoUid: json['memoUid'] as String? ?? '',
    attachmentFilename: json['attachmentFilename'] as String?,
    error: json['error'] as String? ?? '',
  );
}

class DesktopSyncPromptMetadata {
  const DesktopSyncPromptMetadata({
    required this.requestId,
    required this.sessionId,
  });

  final String requestId;
  final String sessionId;

  bool get isEmpty => requestId.isEmpty || sessionId.isEmpty;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'requestId': requestId,
    'sessionId': sessionId,
  };

  factory DesktopSyncPromptMetadata.fromJson(Map<String, dynamic> json) {
    return DesktopSyncPromptMetadata(
      requestId: (json['requestId'] as String? ?? '').trim(),
      sessionId: (json['sessionId'] as String? ?? '').trim(),
    );
  }
}

Map<String, dynamic> serializeWebDavBackupExportResolution(
  WebDavBackupExportResolution resolution,
) => <String, dynamic>{
  'action': resolution.action.name,
  'applyToRemainingFailures': resolution.applyToRemainingFailures,
};

WebDavBackupExportResolution deserializeWebDavBackupExportResolution(
  Map<String, dynamic> json,
) {
  final actionName = json['action'] as String? ?? '';
  final action = WebDavBackupExportAction.values.firstWhere(
    (item) => item.name == actionName,
    orElse: () => WebDavBackupExportAction.abort,
  );
  return WebDavBackupExportResolution(
    action: action,
    applyToRemainingFailures: json['applyToRemainingFailures'] == true,
  );
}

Map<String, dynamic> serializeWebDavBackupExportPromptResponse({
  required DesktopSyncPromptMetadata metadata,
  required WebDavBackupExportResolution resolution,
}) => <String, dynamic>{
  ...metadata.toJson(),
  'resolution': serializeWebDavBackupExportResolution(resolution),
};

WebDavBackupExportResolution deserializeWebDavBackupExportPromptResponse(
  Object? raw, {
  DesktopSyncPromptMetadata? expectedMetadata,
}) {
  if (raw is! Map) {
    return const WebDavBackupExportResolution(
      action: WebDavBackupExportAction.abort,
    );
  }
  final map = Map<Object?, Object?>.from(
    raw,
  ).map<String, dynamic>((key, value) => MapEntry(key.toString(), value));
  final responseMetadata = DesktopSyncPromptMetadata.fromJson(map);
  if (expectedMetadata != null &&
      !responseMetadata.isEmpty &&
      (responseMetadata.requestId != expectedMetadata.requestId ||
          responseMetadata.sessionId != expectedMetadata.sessionId)) {
    throw const FormatException('Desktop sync prompt metadata mismatch.');
  }
  final rawResolution = map['resolution'];
  if (rawResolution is Map) {
    return deserializeWebDavBackupExportResolution(
      Map<Object?, Object?>.from(rawResolution).cast<String, dynamic>(),
    );
  }
  return deserializeWebDavBackupExportResolution(map);
}

List<String> serializeWebDavBackupConfigTypes(
  Iterable<WebDavBackupConfigType> types,
) => types.map((item) => item.name).toList(growable: false);

Set<WebDavBackupConfigType> deserializeWebDavBackupConfigTypes(
  Iterable<Object?> raw,
) {
  final values = <WebDavBackupConfigType>{};
  for (final item in raw) {
    final name = item as String?;
    if (name == null) continue;
    for (final value in WebDavBackupConfigType.values) {
      if (value.name == name) {
        values.add(value);
        break;
      }
    }
  }
  return values;
}

Map<String, dynamic> serializeWebDavBackupConfigPromptResponse({
  required DesktopSyncPromptMetadata metadata,
  required Iterable<WebDavBackupConfigType> selected,
}) => <String, dynamic>{
  ...metadata.toJson(),
  'configTypes': serializeWebDavBackupConfigTypes(selected),
};

Set<WebDavBackupConfigType> deserializeWebDavBackupConfigPromptResponse(
  Object? raw, {
  DesktopSyncPromptMetadata? expectedMetadata,
}) {
  if (raw is List) {
    return deserializeWebDavBackupConfigTypes(raw);
  }
  if (raw is! Map) {
    return const <WebDavBackupConfigType>{};
  }
  final map = Map<Object?, Object?>.from(
    raw,
  ).map<String, dynamic>((key, value) => MapEntry(key.toString(), value));
  final responseMetadata = DesktopSyncPromptMetadata.fromJson(map);
  if (expectedMetadata != null &&
      !responseMetadata.isEmpty &&
      (responseMetadata.requestId != expectedMetadata.requestId ||
          responseMetadata.sessionId != expectedMetadata.sessionId)) {
    throw const FormatException('Desktop sync prompt metadata mismatch.');
  }
  final rawTypes = map['configTypes'];
  if (rawTypes is List) {
    return deserializeWebDavBackupConfigTypes(rawTypes);
  }
  return const <WebDavBackupConfigType>{};
}

class _DesktopSyncRpcException implements Exception {
  const _DesktopSyncRpcException({required this.syncError});

  final SyncError syncError;
}

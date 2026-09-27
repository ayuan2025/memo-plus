import 'dart:async';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/services.dart';

import '../../core/desktop_db_write_channel.dart';
import 'db_write_protocol.dart';
import 'serialized_workspace_write_runner.dart';
import 'workspace_write_host.dart';

abstract class DesktopDbWriteGateway {
  bool get isRemote;

  Future<T> execute<T>({
    required String workspaceKey,
    required String dbName,
    required String commandType,
    required String operation,
    required Map<String, dynamic> payload,
    required Future<Object?> Function() localExecute,
    required T Function(Object? raw) decode,
  });
}

abstract class OwnerDesktopDbWriteGateway implements DesktopDbWriteGateway {
  Future<T> executeEnvelope<T>({
    required DbWriteEnvelope envelope,
    required Future<Object?> Function() localExecute,
    required T Function(Object? raw) decode,
  });
}

class LocalDesktopDbWriteGateway implements OwnerDesktopDbWriteGateway {
  LocalDesktopDbWriteGateway({
    WorkspaceWriteHost? host,
    SerializedWorkspaceWriteRunner? runner,
    DesktopDbChangeBroadcaster? broadcaster,
    required String originRole,
    required int originWindowId,
  }) : assert(
         host != null || (runner != null && broadcaster != null),
         'LocalDesktopDbWriteGateway requires either a WorkspaceWriteHost or '
         'both a runner and broadcaster.',
       ),
       _host =
           host ??
           SerializingWorkspaceWriteHost(
             runner: runner!,
             broadcaster: broadcaster!,
           ),
       _originRole = originRole,
       _originWindowId = originWindowId;

  final WorkspaceWriteHost _host;
  final String _originRole;
  final int _originWindowId;

  @override
  bool get isRemote => false;

  @override
  Future<T> execute<T>({
    required String workspaceKey,
    required String dbName,
    required String commandType,
    required String operation,
    required Map<String, dynamic> payload,
    required Future<Object?> Function() localExecute,
    required T Function(Object? raw) decode,
  }) async {
    final envelope = DbWriteEnvelope(
      requestId:
          '${DateTime.now().microsecondsSinceEpoch}_${commandType}_$operation',
      workspaceKey: workspaceKey,
      dbName: dbName,
      commandType: commandType,
      operation: operation,
      payload: payload,
      originRole: _originRole,
      originWindowId: _originWindowId,
    );
    return executeEnvelope<T>(
      envelope: envelope,
      localExecute: localExecute,
      decode: decode,
    );
  }

  @override
  Future<T> executeEnvelope<T>({
    required DbWriteEnvelope envelope,
    required Future<Object?> Function() localExecute,
    required T Function(Object? raw) decode,
  }) async {
    return _host.execute<T>(
      envelope: envelope,
      localExecute: localExecute,
      decode: decode,
    );
  }
}

class RemoteDesktopDbWriteGateway implements DesktopDbWriteGateway {
  RemoteDesktopDbWriteGateway({
    required String originRole,
    required int originWindowId,
  }) : _originRole = originRole,
       _originWindowId = originWindowId;

  final String _originRole;
  final int _originWindowId;

  @override
  bool get isRemote => true;

  @override
  Future<T> execute<T>({
    required String workspaceKey,
    required String dbName,
    required String commandType,
    required String operation,
    required Map<String, dynamic> payload,
    required Future<Object?> Function() localExecute,
    required T Function(Object? raw) decode,
  }) async {
    final envelope = DbWriteEnvelope(
      requestId:
          '${DateTime.now().microsecondsSinceEpoch}_${commandType}_$operation',
      workspaceKey: workspaceKey,
      dbName: dbName,
      commandType: commandType,
      operation: operation,
      payload: payload,
      originRole: _originRole,
      originWindowId: _originWindowId,
    );
    final raw = await _invokeMainWindowMethod(
      desktopDbWriteMethod,
      envelope.toJson(),
    );
    if (raw is! Map) {
      throw const DbWriteException(
        code: 'invalid_response',
        message: 'Invalid desktop database write response.',
        retryable: true,
      );
    }
    final result = DbWriteResult.fromJson(Map<Object?, Object?>.from(raw));
    if (!result.success) {
      throw (result.error ??
              const DbWriteError(
                code: 'unknown',
                message: 'Database write failed.',
                retryable: true,
              ))
          .toException();
    }
    return decode(result.value);
  }

  static bool _isMainWindowChannelMissing(Object error) {
    if (error is MissingPluginException) return true;
    if (error is! PlatformException) return false;
    final message = (error.message ?? '').toLowerCase();
    return message.contains('target window not found') ||
        message.contains('target window channel not found');
  }

  static Future<dynamic> _invokeMainWindowMethod(
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
    throw const DbWriteException(
      code: 'main_window_unavailable',
      message: 'Main window is unavailable for database writes.',
      retryable: true,
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/hash.dart';

class SingleInstanceResult {
  const SingleInstanceResult({required this.isPrimary});

  final bool isPrimary;
}

class SingleInstanceCoordinator {
  static const String _activationMessage = 'activate';
  static const String _instanceKey = 'memoflow.single_instance';

  static ServerSocket? _server;
  static bool _pendingActivation = false;
  static Future<void> Function()? _activationHandler;

  static void setActivationHandler(Future<void> Function() handler) {
    _activationHandler = handler;
    if (_pendingActivation) {
      _pendingActivation = false;
      unawaited(handler());
    }
  }

  static Future<SingleInstanceResult> ensureSingleInstance({
    required bool enable,
  }) async {
    if (!enable || kIsWeb || !Platform.isWindows) {
      return const SingleInstanceResult(isPrimary: true);
    }
    final port = _resolvePort();
    try {
      await _startServer(port);
      return const SingleInstanceResult(isPrimary: true);
    } catch (_) {
      final notified = await _notifyExistingInstance(port);
      if (notified) {
        return const SingleInstanceResult(isPrimary: false);
      }
      try {
        await _startServer(port);
        return const SingleInstanceResult(isPrimary: true);
      } catch (_) {
        return const SingleInstanceResult(isPrimary: true);
      }
    }
  }

  static Future<void> _startServer(int port) async {
    if (_server != null) return;
    final server = await ServerSocket.bind(
      InternetAddress.loopbackIPv4,
      port,
      shared: true,
    );
    _server = server;
    server.listen((socket) {
      socket.listen(
        (data) {
          final message = utf8.decode(data).trim();
          if (message.contains(_activationMessage)) {
            _handleActivation();
          }
        },
        onDone: () => socket.destroy(),
        onError: (_) => socket.destroy(),
        cancelOnError: true,
      );
    });
  }

  static Future<bool> _notifyExistingInstance(int port) async {
    Socket? socket;
    try {
      socket = await Socket.connect(
        InternetAddress.loopbackIPv4,
        port,
        timeout: const Duration(milliseconds: 800),
      );
      socket.write(_activationMessage);
      await socket.flush();
      return true;
    } catch (_) {
      return false;
    } finally {
      try {
        await socket?.close();
      } catch (_) {}
    }
  }

  static void _handleActivation() {
    final handler = _activationHandler;
    if (handler == null) {
      _pendingActivation = true;
      return;
    }
    unawaited(handler());
  }

  static int _resolvePort() {
    final hex = fnv1a64Hex(_instanceKey);
    final raw = int.parse(hex.substring(0, 4), radix: 16);
    const minPort = 30000;
    const maxPort = 49999;
    final span = maxPort - minPort + 1;
    return minPort + (raw % span);
  }
}

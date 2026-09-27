import 'dart:async';
import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/desktop_quick_input_channel.dart';

const Duration _shareTaskWindowIpcAttemptDelay = Duration(milliseconds: 120);
const int _shareTaskWindowIpcAttempts = 12;

enum DesktopShareTaskWindowOpenStatus { unsupported, opened, failed }

class DesktopShareTaskWindowOpenResult {
  const DesktopShareTaskWindowOpenResult._(
    this.status, {
    this.windowId,
    this.error,
  });

  const DesktopShareTaskWindowOpenResult.unsupported()
    : this._(DesktopShareTaskWindowOpenStatus.unsupported);

  const DesktopShareTaskWindowOpenResult.opened({required int windowId})
    : this._(DesktopShareTaskWindowOpenStatus.opened, windowId: windowId);

  factory DesktopShareTaskWindowOpenResult.failed(Object error) {
    return DesktopShareTaskWindowOpenResult._(
      DesktopShareTaskWindowOpenStatus.failed,
      error: error,
    );
  }

  final DesktopShareTaskWindowOpenStatus status;
  final int? windowId;
  final Object? error;

  bool get opened => status == DesktopShareTaskWindowOpenStatus.opened;
}

/// Desktop share task windows use a common platform gate:
/// macOS is enabled first after explicit sub-window WebView registration;
/// Windows and Linux keep the existing main-window fallback until verified.
bool supportsDesktopShareTaskWindow({TargetPlatform? platform}) {
  if (kIsWeb) return false;
  return switch (platform ?? defaultTargetPlatform) {
    TargetPlatform.macOS => true,
    TargetPlatform.windows || TargetPlatform.linux => false,
    _ => false,
  };
}

Future<DesktopShareTaskWindowOpenResult> openDesktopShareTaskWindow({
  required String requestId,
  required Map<String, dynamic> payloadJson,
  TargetPlatform? platform,
}) async {
  final resolvedPlatform = platform ?? defaultTargetPlatform;
  if (!supportsDesktopShareTaskWindow(platform: resolvedPlatform)) {
    return const DesktopShareTaskWindowOpenResult.unsupported();
  }
  try {
    final window = await DesktopMultiWindow.createWindow(
      jsonEncode(<String, dynamic>{
        desktopWindowTypeKey: desktopWindowTypeShare,
        'requestId': requestId,
        'payload': payloadJson,
      }),
    );
    await window.setTitle('MemoFlow Share');
    final frame = switch (resolvedPlatform) {
      TargetPlatform.macOS => const Offset(0, 0) & Size(760, 720),
      _ => const Offset(0, 0) & Size(860, 760),
    };
    await window.setFrame(frame);
    await window.center();
    await window.show();
    final responsive = await _waitForShareTaskWindowIpc(window.windowId);
    if (!responsive) {
      try {
        await window.close();
      } catch (_) {}
      return DesktopShareTaskWindowOpenResult.failed(
        StateError('Desktop share task window IPC did not become ready.'),
      );
    }
    return DesktopShareTaskWindowOpenResult.opened(windowId: window.windowId);
  } catch (error) {
    return DesktopShareTaskWindowOpenResult.failed(error);
  }
}

Future<bool> _waitForShareTaskWindowIpc(int windowId) async {
  for (var attempt = 0; attempt < _shareTaskWindowIpcAttempts; attempt++) {
    try {
      final result = await DesktopMultiWindow.invokeMethod(
        windowId,
        desktopSharePingMethod,
        null,
      );
      if (result == true) return true;
    } catch (_) {}
    await Future<void>.delayed(_shareTaskWindowIpcAttemptDelay);
  }
  return false;
}

Future<void> foregroundDesktopMainWindowForShareResult({
  TargetPlatform? platform,
}) async {
  if (kIsWeb) return;
  try {
    await WindowController.main().show();
  } catch (_) {}
  final resolvedPlatform = platform ?? defaultTargetPlatform;
  if (resolvedPlatform != TargetPlatform.macOS &&
      resolvedPlatform != TargetPlatform.windows &&
      resolvedPlatform != TargetPlatform.linux) {
    return;
  }
  try {
    await windowManager.ensureInitialized();
    if (await windowManager.isMinimized()) {
      await windowManager.restore();
    }
    await windowManager.show();
    await windowManager.focus();
  } catch (_) {}
}

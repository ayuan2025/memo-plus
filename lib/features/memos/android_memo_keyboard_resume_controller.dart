import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef AndroidMemoKeyboardResumePredicate = bool Function();
typedef AndroidMemoKeyboardShowCallback = FutureOr<void> Function();

class AndroidMemoKeyboardResumeController with WidgetsBindingObserver {
  AndroidMemoKeyboardResumeController({
    required FocusNode focusNode,
    required AndroidMemoKeyboardResumePredicate isSurfaceEligible,
    required AndroidMemoKeyboardResumePredicate isRouteCurrent,
    required AndroidMemoKeyboardResumePredicate isKeyboardVisible,
    AndroidMemoKeyboardResumePredicate? isAndroid,
    AndroidMemoKeyboardShowCallback? showKeyboard,
    Duration restoreDelay = defaultRestoreDelay,
    WidgetsBinding? binding,
  }) : _focusNode = focusNode,
       _isSurfaceEligible = isSurfaceEligible,
       _isRouteCurrent = isRouteCurrent,
       _isKeyboardVisible = isKeyboardVisible,
       _isAndroid = isAndroid ?? (() => Platform.isAndroid),
       _showKeyboard = showKeyboard ?? _showTextInput,
       _restoreDelay = restoreDelay,
       _binding = binding ?? WidgetsBinding.instance {
    _binding.addObserver(this);
  }

  static const defaultRestoreDelay = Duration(milliseconds: 120);

  final FocusNode _focusNode;
  final AndroidMemoKeyboardResumePredicate _isSurfaceEligible;
  final AndroidMemoKeyboardResumePredicate _isRouteCurrent;
  final AndroidMemoKeyboardResumePredicate _isKeyboardVisible;
  final AndroidMemoKeyboardResumePredicate _isAndroid;
  final AndroidMemoKeyboardShowCallback _showKeyboard;
  final Duration _restoreDelay;
  final WidgetsBinding _binding;

  Timer? _restoreTimer;
  bool _restoreKeyboardOnResume = false;
  bool _keyboardVisibleWhileFocused = false;
  bool _disposed = false;

  @visibleForTesting
  bool get debugRestorePending => _restoreKeyboardOnResume;

  void updateKeyboardVisibility() {
    if (_disposed || !_isAndroid()) return;
    if (!_focusNode.hasFocus || !_isSurfaceEligible() || !_isRouteCurrent()) {
      if (!_isKeyboardVisible()) {
        _keyboardVisibleWhileFocused = false;
      }
      return;
    }
    _keyboardVisibleWhileFocused = _isKeyboardVisible();
  }

  @override
  void didChangeMetrics() {
    updateKeyboardVisibility();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _captureRestoreIntent();
        break;
      case AppLifecycleState.resumed:
        _scheduleKeyboardRestore();
        break;
      case AppLifecycleState.detached:
        _clearRestoreIntent();
        break;
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _restoreTimer?.cancel();
    _binding.removeObserver(this);
  }

  void _captureRestoreIntent() {
    if (_canCaptureRestoreIntent()) {
      _restoreKeyboardOnResume = true;
    }
  }

  bool _canCaptureRestoreIntent() {
    if (_disposed || !_isAndroid()) return false;
    if (!_focusNode.hasFocus) return false;
    if (!_isSurfaceEligible() || !_isRouteCurrent()) return false;
    return _isKeyboardVisible() || _keyboardVisibleWhileFocused;
  }

  void _scheduleKeyboardRestore() {
    if (_disposed || !_restoreKeyboardOnResume) return;
    _restoreTimer?.cancel();
    _binding.addPostFrameCallback((_) {
      if (_disposed || !_restoreKeyboardOnResume) return;
      _restoreTimer = Timer(_restoreDelay, _restoreKeyboardIfStillEligible);
    });
    _binding.scheduleFrame();
  }

  void _restoreKeyboardIfStillEligible() {
    _restoreTimer = null;
    if (!_canRestoreKeyboard()) {
      _clearRestoreIntent();
      return;
    }
    _clearRestoreIntent();
    _focusNode.requestFocus();
    unawaited(
      Future<void>.sync(() async {
        await _showKeyboard();
      }),
    );
  }

  bool _canRestoreKeyboard() {
    if (_disposed || !_isAndroid()) return false;
    if (!_focusNode.hasFocus) return false;
    return _isSurfaceEligible() && _isRouteCurrent();
  }

  void _clearRestoreIntent() {
    _restoreKeyboardOnResume = false;
    _restoreTimer?.cancel();
    _restoreTimer = null;
  }
}

Future<void> _showTextInput() async {
  await SystemChannels.textInput.invokeMethod<void>('TextInput.show');
}

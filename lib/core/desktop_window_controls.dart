import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../application/desktop/desktop_exit_coordinator.dart';
import '../i18n/strings.g.dart';
import 'memoflow_palette.dart';

class DesktopWindowControls extends StatefulWidget {
  const DesktopWindowControls({super.key});

  @override
  State<DesktopWindowControls> createState() => _DesktopWindowControlsState();
}

class _DesktopWindowControlsState extends State<DesktopWindowControls>
    with WindowListener {
  var _isMaximized = false;

  bool get _shouldShow =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  @override
  void initState() {
    super.initState();
    if (_shouldShow) {
      windowManager.addListener(this);
      unawaited(_syncMaximizedState());
    }
  }

  @override
  void dispose() {
    if (_shouldShow) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  Future<void> _syncMaximizedState() async {
    final maximized = await windowManager.isMaximized();
    if (!mounted) return;
    setState(() => _isMaximized = maximized);
  }

  Future<void> _minimizeWindow() async {
    await windowManager.minimize();
  }

  Future<void> _toggleMaximizeWindow() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
    await _syncMaximizedState();
  }

  Future<void> _closeWindow() async {
    await DesktopExitCoordinator.requestClose(source: 'window_button');
  }

  @override
  void onWindowMaximize() {
    if (!mounted) return;
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (!mounted) return;
    setState(() => _isMaximized = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DesktopWindowIconButton(
          tooltip: context.t.strings.legacy.msg_minimize,
          onPressed: () => unawaited(_minimizeWindow()),
          icon: Icons.minimize_rounded,
        ),
        _DesktopWindowIconButton(
          tooltip: _isMaximized
              ? context.t.strings.legacy.msg_restore_window
              : context.t.strings.legacy.msg_maximize,
          onPressed: () => unawaited(_toggleMaximizeWindow()),
          icon: _isMaximized
              ? Icons.filter_none_rounded
              : Icons.crop_square_rounded,
        ),
        _DesktopWindowIconButton(
          tooltip: context.t.strings.legacy.msg_close,
          onPressed: () => unawaited(_closeWindow()),
          icon: Icons.close_rounded,
          destructive: true,
        ),
      ],
    );
  }
}

class _DesktopWindowIconButton extends StatelessWidget {
  const _DesktopWindowIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    this.destructive = false,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = destructive
        ? (isDark ? const Color(0xFFFFB4B4) : const Color(0xFFC62828))
        : (isDark ? MemoFlowPalette.textDark : MemoFlowPalette.textLight);
    final hoverColor = destructive
        ? const Color(0x33E53935)
        : (isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06));
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          hoverColor: hoverColor,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 36,
            height: 30,
            child: Icon(icon, size: 18, color: iconColor),
          ),
        ),
      ),
    );
  }
}

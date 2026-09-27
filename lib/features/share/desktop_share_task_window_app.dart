import 'dart:async';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_localization.dart';
import '../../core/app_theme.dart';
import '../../core/desktop/desktop_titlebar_navigation_policy.dart';
import '../../core/desktop_quick_input_channel.dart';
import '../../core/memoflow_palette.dart';
import '../../i18n/strings.g.dart';
import '../../state/settings/device_preferences_provider.dart';
import '../../state/settings/resolved_preferences_provider.dart';
import 'share_clip_models.dart';
import 'share_clip_screen.dart';
import 'share_task_window_codec.dart';

class DesktopShareTaskWindowApp extends ConsumerWidget {
  const DesktopShareTaskWindowApp({
    super.key,
    required this.windowId,
    required this.launchPayload,
  });

  final int windowId;
  final DesktopShareTaskLaunchPayload launchPayload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicePrefs = ref.watch(devicePreferencesProvider);
    final resolvedSettings = ref.watch(resolvedAppSettingsProvider);
    final appLocale = appLocaleForLanguage(devicePrefs.language);
    LocaleSettings.setLocale(appLocale);
    final legacyThemePrefs = resolvedSettings.toLegacyAppPreferences();
    MemoFlowPalette.applyThemeColor(
      resolvedSettings.resolvedThemeColor,
      customTheme: resolvedSettings.resolvedCustomTheme,
    );

    return TranslationProvider(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MemoFlow Share',
        theme: applyPreferencesToTheme(
          buildAppTheme(Brightness.light),
          legacyThemePrefs,
        ),
        darkTheme: applyPreferencesToTheme(
          buildAppTheme(Brightness.dark),
          legacyThemePrefs,
        ),
        themeMode: themeModeFor(devicePrefs.themeMode),
        locale: appLocale.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(textScaleFor(devicePrefs.fontSize)),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: DesktopShareTaskWindowScreen(
          windowId: windowId,
          launchPayload: launchPayload,
        ),
      ),
    );
  }
}

class DesktopShareTaskWindowScreen extends StatefulWidget {
  const DesktopShareTaskWindowScreen({
    super.key,
    required this.windowId,
    required this.launchPayload,
  });

  final int windowId;
  final DesktopShareTaskLaunchPayload launchPayload;

  @override
  State<DesktopShareTaskWindowScreen> createState() =>
      _DesktopShareTaskWindowScreenState();
}

class _DesktopShareTaskWindowScreenState
    extends State<DesktopShareTaskWindowScreen> {
  Future<bool>? _mainWindowChannelProbe;
  bool _windowVisible = true;
  bool _resultAccepted = false;
  bool _cancelNotified = false;
  bool _handoffInProgress = false;

  @override
  void initState() {
    super.initState();
    DesktopMultiWindow.setMethodHandler(_handleMethodCall);
    unawaited(_notifyMainWindowVisibility(true));
    unawaited(_ensureMainWindowChannelReady());
  }

  @override
  void dispose() {
    _windowVisible = false;
    DesktopMultiWindow.setMethodHandler(null);
    unawaited(_notifyMainWindowVisibility(false));
    if (!_resultAccepted) {
      unawaited(_notifyCanceled());
    }
    super.dispose();
  }

  Future<dynamic> _handleMethodCall(MethodCall call, int _) async {
    if (call.method == desktopSharePingMethod) {
      return true;
    }
    if (call.method == desktopSubWindowExitMethod) {
      unawaited(_closeWindow());
      return true;
    }
    if (call.method == desktopSubWindowIsVisibleMethod) {
      return _windowVisible;
    }
    return null;
  }

  bool _isMainWindowChannelMissing(PlatformException error) {
    if (error.code.trim() == '-1') return true;
    final message = (error.message ?? '').toLowerCase();
    return message.contains('target window not found') ||
        message.contains('target window channel not found');
  }

  Future<void> _wakeMainWindow() async {
    try {
      await WindowController.main().show();
    } catch (_) {}
  }

  Future<bool> _probeMainWindowChannel() async {
    const maxAttempts = 10;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        await DesktopMultiWindow.invokeMethod(0, desktopSharePingMethod);
        return true;
      } on MissingPluginException {
        // Main window handler not ready yet. Retry shortly.
      } on PlatformException catch (error) {
        if (!_isMainWindowChannelMissing(error)) {
          return false;
        }
      }
      if (attempt == 1 || attempt == 3 || attempt == 6) {
        await _wakeMainWindow();
      }
      await Future<void>.delayed(Duration(milliseconds: 120 + (attempt * 100)));
    }
    return false;
  }

  Future<bool> _ensureMainWindowChannelReady({bool force = false}) {
    if (!force) {
      final pending = _mainWindowChannelProbe;
      if (pending != null) return pending;
    }
    final future = _probeMainWindowChannel().then((ready) {
      if (!ready) {
        _mainWindowChannelProbe = null;
      }
      return ready;
    });
    _mainWindowChannelProbe = future;
    return future;
  }

  Future<dynamic> _invokeMainWindowMethod(
    String method, [
    dynamic arguments,
  ]) async {
    var ready = await _ensureMainWindowChannelReady();
    if (!ready) {
      ready = await _ensureMainWindowChannelReady(force: true);
    }
    if (!ready) {
      throw MissingPluginException('Main window channel is not ready.');
    }
    return DesktopMultiWindow.invokeMethod(0, method, arguments);
  }

  Future<void> _notifyMainWindowVisibility(bool visible) async {
    try {
      await _invokeMainWindowMethod(
        desktopSubWindowVisibilityMethod,
        <String, dynamic>{'visible': visible},
      );
    } catch (_) {}
  }

  Future<void> _notifyCanceled() async {
    if (_cancelNotified || _resultAccepted) return;
    _cancelNotified = true;
    try {
      await _invokeMainWindowMethod(
        desktopShareCanceledMethod,
        desktopShareTaskCanceledToJson(widget.launchPayload.requestId),
      );
    } catch (_) {}
  }

  Future<void> _closeWindow() async {
    _windowVisible = false;
    try {
      await WindowController.fromWindowId(widget.windowId).close();
    } catch (_) {}
  }

  Future<void> _handleComplete(ShareComposeRequest request) async {
    if (_handoffInProgress || _resultAccepted) return;
    _handoffInProgress = true;
    try {
      final accepted = await _invokeMainWindowMethod(
        desktopShareResultMethod,
        DesktopShareTaskResult(
          requestId: widget.launchPayload.requestId,
          request: request,
        ).toJson(),
      );
      if (accepted == true) {
        _resultAccepted = true;
        await _closeWindow();
      }
    } finally {
      if (mounted && !_resultAccepted) {
        _handoffInProgress = false;
      }
    }
  }

  Future<void> _handleCancel() async {
    await _notifyCanceled();
    await _closeWindow();
  }

  @override
  Widget build(BuildContext context) {
    return ShareClipScreen(
      payload: widget.launchPayload.payload,
      showGenericCancelAction: false,
      desktopNavigationContext:
          DesktopTitlebarNavigationContext.topLevelDestination,
      desktopWindowChromeSafeArea: true,
      onComplete: (request) => unawaited(_handleComplete(request)),
      onCancel: () => unawaited(_handleCancel()),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/sync_feedback.dart';
import '../../core/top_toast.dart';
import '../../data/logs/log_manager.dart';
import '../../data/models/app_preferences.dart';
import '../../state/memos/app_bootstrap_adapter_provider.dart';

class SyncFeedbackPresenter {
  SyncFeedbackPresenter({
    required AppBootstrapAdapter bootstrapAdapter,
    required WidgetRef ref,
    required GlobalKey<NavigatorState> navigatorKey,
    required GlobalKey<State<StatefulWidget>> mainHomePageKey,
    required bool Function() isMounted,
  }) : _bootstrapAdapter = bootstrapAdapter,
       _ref = ref,
       _navigatorKey = navigatorKey,
       _mainHomePageKey = mainHomePageKey,
       _isMounted = isMounted;

  final AppBootstrapAdapter _bootstrapAdapter;
  final WidgetRef _ref;
  final GlobalKey<NavigatorState> _navigatorKey;
  final GlobalKey<State<StatefulWidget>> _mainHomePageKey;
  final bool Function() _isMounted;

  void showAutoSyncFeedbackToast({required bool succeeded}) {
    if (succeeded) {
      return;
    }
    final language = _bootstrapAdapter.readDevicePreferences(_ref).language;
    final message = buildAutoSyncFeedbackMessage(
      language: language,
      succeeded: succeeded,
    );
    var delivered = false;
    var retryScheduled = false;

    void emit({required String phase, bool allowRetry = false}) {
      if (delivered) return;
      final homeContext = _mainHomePageKey.currentContext;
      final navigatorContext = _navigatorKey.currentContext;
      final overlayContext =
          homeContext ??
          navigatorContext ??
          _navigatorKey.currentState?.overlay?.context;
      if (overlayContext == null) {
        LogManager.instance.info(
          'AutoSync: feedback_toast_skipped_no_context',
          context: <String, Object?>{
            'phase': phase,
            'succeeded': succeeded,
            'message': message,
          },
        );
        return;
      }
      final channel = showSyncFeedback(
        overlayContext: overlayContext,
        messengerContext: navigatorContext ?? homeContext,
        language: language,
        succeeded: succeeded,
        message: message,
      );
      final event = switch (channel) {
        SyncFeedbackChannel.snackbar => 'AutoSync: feedback_snackbar_shown',
        SyncFeedbackChannel.toast => 'AutoSync: feedback_toast_shown',
        SyncFeedbackChannel.skipped =>
          'AutoSync: feedback_toast_skipped_no_overlay',
      };
      LogManager.instance.info(
        event,
        context: <String, Object?>{
          'phase': phase,
          'succeeded': succeeded,
          'message': message,
          'hasHomeContext': homeContext != null,
          'hasNavigatorContext': navigatorContext != null,
        },
      );
      if (channel != SyncFeedbackChannel.skipped) {
        delivered = true;
      }
      if (allowRetry &&
          channel == SyncFeedbackChannel.skipped &&
          !retryScheduled) {
        retryScheduled = true;
        Future<void>.delayed(const Duration(milliseconds: 320), () {
          if (!_isMounted()) return;
          emit(phase: 'delayed_retry', allowRetry: false);
        });
      }
    }

    emit(phase: 'immediate', allowRetry: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isMounted()) return;
      emit(phase: 'next_frame', allowRetry: true);
    });
  }

  void showAutoSyncProgressToast() {}
}

SyncFeedbackChannel showSyncFeedback({
  required BuildContext overlayContext,
  required AppLanguage language,
  required bool succeeded,
  String? message,
  BuildContext? messengerContext,
  Duration duration = const Duration(seconds: 3),
}) {
  final resolvedMessage =
      message ??
      buildSyncFeedbackMessage(language: language, succeeded: succeeded);
  // Keep sync feedback consistent with the app's capsule top toast style.
  // Some call sites may provide a context without an attached root Overlay,
  // so we fallback to the secondary context when possible.
  final hasOverlayOnPrimary =
      Overlay.maybeOf(overlayContext, rootOverlay: true) != null;
  final hasOverlayOnSecondary =
      messengerContext != null &&
      Overlay.maybeOf(messengerContext, rootOverlay: true) != null;
  final toastContext = hasOverlayOnPrimary
      ? overlayContext
      : (hasOverlayOnSecondary ? messengerContext : overlayContext);
  final shown = showTopToast(
    toastContext,
    resolvedMessage,
    duration: duration,
    topOffset: 96,
  );
  if (!shown &&
      messengerContext != null &&
      !identical(messengerContext, toastContext)) {
    final shownByFallback = showTopToast(
      messengerContext,
      resolvedMessage,
      duration: duration,
      topOffset: 96,
    );
    return shownByFallback
        ? SyncFeedbackChannel.toast
        : SyncFeedbackChannel.skipped;
  }
  return shown ? SyncFeedbackChannel.toast : SyncFeedbackChannel.skipped;
}

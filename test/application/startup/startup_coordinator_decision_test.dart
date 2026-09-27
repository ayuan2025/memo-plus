import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/application/startup/startup_coordinator.dart';
import 'package:memos_flutter_app/application/updates/announcement_presenter.dart';
import 'package:memos_flutter_app/application/updates/update_announcement_channel_policy.dart';
import 'package:memos_flutter_app/application/updates/update_announcement_runner.dart';
import 'package:memos_flutter_app/core/app_channel.dart';
import 'package:memos_flutter_app/data/models/app_preferences.dart';
import 'package:memos_flutter_app/state/memos/app_bootstrap_adapter_provider.dart';

void main() {
  group('StartupCoordinator decision helpers', () {
    test('selects share before widget and launch action', () {
      final action = StartupCoordinator.debugSelectStartupActionName(
        hasPendingShare: true,
        hasPendingWidget: true,
        launchAction: LaunchAction.quickInput,
      );
      final reason = StartupCoordinator.debugSelectStartupReason(
        hasPendingShare: true,
        hasPendingWidget: true,
        launchAction: LaunchAction.quickInput,
      );

      expect(action, 'share');
      expect(reason, 'pending_share');
    });

    test('selects widget when no pending share exists', () {
      final action = StartupCoordinator.debugSelectStartupActionName(
        hasPendingShare: false,
        hasPendingWidget: true,
        launchAction: LaunchAction.dailyReview,
      );
      final reason = StartupCoordinator.debugSelectStartupReason(
        hasPendingShare: false,
        hasPendingWidget: true,
        launchAction: LaunchAction.dailyReview,
      );

      expect(action, 'widget');
      expect(reason, 'pending_widget');
    });

    test(
      'selects prefs launch action when no pending startup sources exist',
      () {
        final action = StartupCoordinator.debugSelectStartupActionName(
          hasPendingShare: false,
          hasPendingWidget: false,
          launchAction: LaunchAction.quickInput,
        );
        final reason = StartupCoordinator.debugSelectStartupReason(
          hasPendingShare: false,
          hasPendingWidget: false,
          launchAction: LaunchAction.quickInput,
        );

        expect(action, 'launchAction');
        expect(reason, 'prefs_launch_action');
      },
    );

    test('evaluates share block reasons in priority order', () {
      expect(
        StartupCoordinator.debugEvaluateShareBlockReason(
          prefsLoaded: false,
          hasAccount: true,
          hasNavigator: true,
          hasContext: true,
        ),
        'prefs_not_loaded',
      );
      expect(
        StartupCoordinator.debugEvaluateShareBlockReason(
          prefsLoaded: true,
          hasAccount: false,
          hasNavigator: true,
          hasContext: true,
        ),
        'no_account',
      );
      expect(
        StartupCoordinator.debugEvaluateShareBlockReason(
          prefsLoaded: true,
          hasAccount: true,
          hasNavigator: false,
          hasContext: true,
        ),
        'no_navigator',
      );
      expect(
        StartupCoordinator.debugEvaluateShareBlockReason(
          prefsLoaded: true,
          hasAccount: true,
          hasNavigator: true,
          hasContext: false,
        ),
        'no_context',
      );
    });

    test('evaluates widget block reasons', () {
      expect(
        StartupCoordinator.debugEvaluateWidgetBlockReason(
          hasWorkspace: false,
          hasNavigator: true,
          hasContext: true,
        ),
        'no_workspace',
      );
      expect(
        StartupCoordinator.debugEvaluateWidgetBlockReason(
          hasWorkspace: true,
          hasNavigator: false,
          hasContext: true,
        ),
        'no_navigator',
      );
      expect(
        StartupCoordinator.debugEvaluateWidgetBlockReason(
          hasWorkspace: true,
          hasNavigator: true,
          hasContext: false,
        ),
        'no_context',
      );
    });

    test('retries only navigator and context readiness reasons', () {
      expect(
        StartupCoordinator.debugShouldRetryForReason('no_navigator'),
        isTrue,
      );
      expect(
        StartupCoordinator.debugShouldRetryForReason('no_context'),
        isTrue,
      );
      expect(
        StartupCoordinator.debugShouldRetryForReason('prefs_not_loaded'),
        isFalse,
      );
      expect(
        StartupCoordinator.debugShouldRetryForReason('no_account'),
        isFalse,
      );
      expect(
        StartupCoordinator.debugShouldRetryForReason('no_workspace'),
        isFalse,
      );
    });
  });

  group('Startup update announcement channel policy', () {
    test('keeps startup config fetches enabled for Android Play channel', () {
      expect(
        shouldFetchStartupUpdateAnnouncements(
          channel: AppChannel.play,
          targetPlatform: TargetPlatform.android,
        ),
        isTrue,
      );
    });

    test('suppresses startup update prompts for Android Play channel', () {
      expect(
        shouldShowStartupUpdatePrompt(
          channel: AppChannel.play,
          targetPlatform: TargetPlatform.android,
        ),
        isFalse,
      );
    });

    test('allows startup update prompts for Android full channel', () {
      expect(
        shouldShowStartupUpdatePrompt(
          channel: AppChannel.full,
          targetPlatform: TargetPlatform.android,
        ),
        isTrue,
      );
    });

    test(
      'keeps desktop fetches enabled even when channel defaults to Play',
      () {
        expect(
          shouldShowStartupUpdatePrompt(
            channel: AppChannel.play,
            targetPlatform: TargetPlatform.windows,
          ),
          isTrue,
        );
      },
    );

    test('does not treat web as Android Play distribution', () {
      expect(
        shouldShowStartupUpdatePrompt(
          channel: AppChannel.play,
          targetPlatform: TargetPlatform.android,
          isWeb: true,
        ),
        isTrue,
      );
    });
  });

  group('UpdateAnnouncementRunner channel scheduling', () {
    testWidgets(
      'skips startup scheduling when channel routing rejects fetches',
      (tester) async {
        var mountedChecked = false;
        final runner = UpdateAnnouncementRunner(
          bootstrapAdapter: const AppBootstrapAdapter(),
          presenter: const _UnusedAnnouncementPresenter(),
          isMounted: () {
            mountedChecked = true;
            return true;
          },
          shouldFetchStartupUpdateAnnouncements: () => false,
        );

        runner.scheduleIfNeeded(_UnusedWidgetRef());
        tester.binding.scheduleFrame();
        await tester.pump();

        expect(mountedChecked, isFalse);
      },
    );

    testWidgets(
      'keeps startup scheduling when channel routing allows fetches',
      (tester) async {
        await tester.pumpWidget(const SizedBox.shrink());
        var mountedChecked = false;
        final runner = UpdateAnnouncementRunner(
          bootstrapAdapter: const AppBootstrapAdapter(),
          presenter: const _UnusedAnnouncementPresenter(),
          isMounted: () {
            mountedChecked = true;
            return false;
          },
          shouldFetchStartupUpdateAnnouncements: () => true,
        );

        runner.scheduleIfNeeded(_UnusedWidgetRef());
        tester.binding.scheduleFrame();
        await tester.pump();

        expect(mountedChecked, isTrue);
      },
    );
  });
}

class _UnusedWidgetRef implements WidgetRef {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError('WidgetRef should not be used by this test');
  }
}

class _UnusedAnnouncementPresenter implements AnnouncementPresenter {
  const _UnusedAnnouncementPresenter();

  @override
  Future<AnnouncementPresentationResult?> present(
    AnnouncementPresentationRequest request,
  ) {
    throw StateError('AnnouncementPresenter should not be used by this test');
  }
}

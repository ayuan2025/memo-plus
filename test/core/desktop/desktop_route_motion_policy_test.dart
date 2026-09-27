import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/desktop/desktop_route_motion_policy.dart';

void main() {
  test('uses fade slide for non-side-pane destination replacement', () {
    final policy = resolveDesktopDrawerRouteMotion(
      platform: TargetPlatform.windows,
      usesDesktopSidePane: false,
    );

    expect(policy.style, DesktopRouteMotionStyle.fadeSlide);
    expect(policy.enabled, isTrue);
  });

  test('uses Windows shared axis for side-pane destination replacement', () {
    final policy = resolveDesktopDrawerRouteMotion(
      platform: TargetPlatform.windows,
      usesDesktopSidePane: true,
    );

    expect(policy.style, DesktopRouteMotionStyle.sharedAxis);
    expect(policy.enabled, isTrue);
  });

  test('keeps macOS expanded-sidebar destination replacement still', () {
    final policy = resolveDesktopDrawerRouteMotion(
      platform: TargetPlatform.macOS,
      usesDesktopSidePane: true,
    );

    expect(policy.style, DesktopRouteMotionStyle.none);
    expect(policy.enabled, isFalse);
  });

  test('noAnimation overrides platform route motion', () {
    final policy = resolveDesktopDrawerRouteMotion(
      platform: TargetPlatform.windows,
      usesDesktopSidePane: true,
      noAnimation: true,
    );

    expect(policy.style, DesktopRouteMotionStyle.none);
    expect(policy.enabled, isFalse);
  });
}

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/desktop/desktop_layout_policy.dart';
import 'package:memos_flutter_app/core/platform_layout.dart' as platform_layout;

void main() {
  test('resolves Windows desktop layout tiers and navigation modes', () {
    expect(
      resolveDesktopLayoutPolicy(900, platform: TargetPlatform.windows).navMode,
      DesktopNavigationMode.overlay,
    );
    expect(
      resolveDesktopLayoutPolicy(
        1100,
        platform: TargetPlatform.windows,
      ).navMode,
      DesktopNavigationMode.rail,
    );
    expect(
      resolveDesktopLayoutPolicy(
        1280,
        platform: TargetPlatform.windows,
      ).navMode,
      DesktopNavigationMode.expanded,
    );
    expect(
      resolveDesktopLayoutPolicy(
        1360,
        platform: TargetPlatform.windows,
      ).defaultSecondaryPaneVisible,
      isTrue,
    );
  });

  test('resolves macOS desktop layout from the shared policy', () {
    final rail = resolveDesktopLayoutPolicy(
      1000,
      platform: TargetPlatform.macOS,
    );
    final expanded = resolveDesktopLayoutPolicy(
      1200,
      platform: TargetPlatform.macOS,
    );
    final wide = resolveDesktopLayoutPolicy(
      1360,
      platform: TargetPlatform.macOS,
    );

    expect(rail.tier, DesktopLayoutTier.compact);
    expect(rail.navMode, DesktopNavigationMode.rail);
    expect(rail.supportsSecondaryPane, isFalse);

    expect(expanded.tier, DesktopLayoutTier.expanded);
    expect(expanded.navMode, DesktopNavigationMode.expanded);
    expect(expanded.supportsSecondaryPane, isTrue);
    expect(expanded.defaultSecondaryPaneVisible, isFalse);

    expect(wide.tier, DesktopLayoutTier.wide);
    expect(wide.defaultSecondaryPaneVisible, isTrue);
  });

  test('non-adapted desktop platforms fall back to narrow overlay', () {
    final layout = resolveDesktopLayoutPolicy(
      1600,
      platform: TargetPlatform.linux,
    );

    expect(layout.tier, DesktopLayoutTier.narrow);
    expect(layout.navMode, DesktopNavigationMode.overlay);
    expect(layout.supportsSecondaryPane, isFalse);
  });

  test('legacy Windows layout wrapper delegates to shared policy', () {
    final legacy = platform_layout.resolveWindowsDesktopLayout(
      1360,
      platform: TargetPlatform.windows,
    );
    final shared = resolveDesktopLayoutPolicy(
      1360,
      platform: TargetPlatform.windows,
    );

    expect(legacy.tier, shared.tier);
    expect(legacy.navMode, shared.navMode);
    expect(legacy.supportsSecondaryPane, shared.supportsSecondaryPane);
    expect(
      legacy.defaultSecondaryPaneVisible,
      shared.defaultSecondaryPaneVisible,
    );
  });
}

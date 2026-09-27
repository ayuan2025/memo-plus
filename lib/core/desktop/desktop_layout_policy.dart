import 'package:flutter/foundation.dart';

const double kMemoFlowDesktopSidePaneBreakpoint = 1100;
const double kMemoFlowDesktopDrawerWidth = 320;
const double kMemoFlowDesktopContentMaxWidth = 980;
const double kMemoFlowDesktopMemoCardMaxWidth = 760;
const double kMemoFlowDesktopPreviewPaneBreakpoint = 1440;
const double kMemoFlowDesktopPreviewPaneWidth = 460;
const double kMemoFlowDesktopPreviewListMinWidth = 560;
const double kMemoFlowInlineComposeBreakpoint = 760;
const double kWindowsDesktopNarrowBreakpoint = 960;
const double kWindowsDesktopExpandedBreakpoint = 1200;
const double kWindowsDesktopWideBreakpoint = 1360;
const double kDesktopMemoListExpandedBreakpoint =
    kWindowsDesktopExpandedBreakpoint;
const double kDesktopMemoListWideBreakpoint = kWindowsDesktopWideBreakpoint;
const double kWindowsDesktopSidebarWidth = 280;
const double kWindowsDesktopRailWidth = 72;
const double kWindowsDesktopSecondaryPaneDefaultWidth = 420;
const double kWindowsDesktopSecondaryPaneMinWidth = 360;
const double kWindowsDesktopSecondaryPaneMaxWidth = 560;

enum DesktopLayoutTier { narrow, compact, expanded, wide }

enum DesktopNavigationMode { overlay, rail, expanded }

class DesktopLayoutSpec {
  const DesktopLayoutSpec({
    required this.tier,
    required this.navMode,
    required this.supportsSecondaryPane,
    required this.defaultSecondaryPaneVisible,
    required this.defaultSecondaryPaneWidth,
  });

  final DesktopLayoutTier tier;
  final DesktopNavigationMode navMode;
  final bool supportsSecondaryPane;
  final bool defaultSecondaryPaneVisible;
  final double defaultSecondaryPaneWidth;
}

DesktopLayoutSpec resolveDesktopLayoutPolicy(
  double width, {
  TargetPlatform? platform,
}) {
  final resolvedPlatform = platform ?? defaultTargetPlatform;
  if (resolvedPlatform == TargetPlatform.windows) {
    return _resolveWindowsDesktopLayoutPolicy(width);
  }
  if (resolvedPlatform == TargetPlatform.macOS) {
    return _resolveMacosDesktopLayoutPolicy(width);
  }
  return const DesktopLayoutSpec(
    tier: DesktopLayoutTier.narrow,
    navMode: DesktopNavigationMode.overlay,
    supportsSecondaryPane: false,
    defaultSecondaryPaneVisible: false,
    defaultSecondaryPaneWidth: kWindowsDesktopSecondaryPaneDefaultWidth,
  );
}

DesktopLayoutSpec _resolveWindowsDesktopLayoutPolicy(double width) {
  if (width < kWindowsDesktopNarrowBreakpoint) {
    return const DesktopLayoutSpec(
      tier: DesktopLayoutTier.narrow,
      navMode: DesktopNavigationMode.overlay,
      supportsSecondaryPane: false,
      defaultSecondaryPaneVisible: false,
      defaultSecondaryPaneWidth: kWindowsDesktopSecondaryPaneDefaultWidth,
    );
  }

  if (width < kWindowsDesktopExpandedBreakpoint) {
    return const DesktopLayoutSpec(
      tier: DesktopLayoutTier.compact,
      navMode: DesktopNavigationMode.rail,
      supportsSecondaryPane: false,
      defaultSecondaryPaneVisible: false,
      defaultSecondaryPaneWidth: kWindowsDesktopSecondaryPaneDefaultWidth,
    );
  }

  if (width < kWindowsDesktopWideBreakpoint) {
    return const DesktopLayoutSpec(
      tier: DesktopLayoutTier.expanded,
      navMode: DesktopNavigationMode.expanded,
      supportsSecondaryPane: true,
      defaultSecondaryPaneVisible: false,
      defaultSecondaryPaneWidth: kWindowsDesktopSecondaryPaneDefaultWidth,
    );
  }

  return const DesktopLayoutSpec(
    tier: DesktopLayoutTier.wide,
    navMode: DesktopNavigationMode.expanded,
    supportsSecondaryPane: true,
    defaultSecondaryPaneVisible: true,
    defaultSecondaryPaneWidth: kWindowsDesktopSecondaryPaneDefaultWidth,
  );
}

DesktopLayoutSpec _resolveMacosDesktopLayoutPolicy(double width) {
  final tier = _resolveDesktopWidthTier(width);
  final navMode = width >= kMemoFlowDesktopSidePaneBreakpoint
      ? DesktopNavigationMode.expanded
      : DesktopNavigationMode.rail;
  final supportsSecondaryPane = width >= kDesktopMemoListExpandedBreakpoint;

  return DesktopLayoutSpec(
    tier: tier,
    navMode: navMode,
    supportsSecondaryPane: supportsSecondaryPane,
    defaultSecondaryPaneVisible:
        supportsSecondaryPane && width >= kDesktopMemoListWideBreakpoint,
    defaultSecondaryPaneWidth: kWindowsDesktopSecondaryPaneDefaultWidth,
  );
}

DesktopLayoutTier _resolveDesktopWidthTier(double width) {
  if (width < kWindowsDesktopNarrowBreakpoint) {
    return DesktopLayoutTier.narrow;
  }
  if (width < kWindowsDesktopExpandedBreakpoint) {
    return DesktopLayoutTier.compact;
  }
  if (width < kWindowsDesktopWideBreakpoint) {
    return DesktopLayoutTier.expanded;
  }
  return DesktopLayoutTier.wide;
}

import 'package:flutter/foundation.dart';

import 'desktop/desktop_layout_policy.dart';
export 'desktop/desktop_layout_policy.dart'
    show
        DesktopLayoutSpec,
        DesktopLayoutTier,
        DesktopNavigationMode,
        kDesktopMemoListExpandedBreakpoint,
        kDesktopMemoListWideBreakpoint,
        kMemoFlowDesktopContentMaxWidth,
        kMemoFlowDesktopDrawerWidth,
        kMemoFlowDesktopMemoCardMaxWidth,
        kMemoFlowDesktopPreviewListMinWidth,
        kMemoFlowDesktopPreviewPaneBreakpoint,
        kMemoFlowDesktopPreviewPaneWidth,
        kMemoFlowDesktopSidePaneBreakpoint,
        kMemoFlowInlineComposeBreakpoint,
        kWindowsDesktopExpandedBreakpoint,
        kWindowsDesktopNarrowBreakpoint,
        kWindowsDesktopRailWidth,
        kWindowsDesktopSecondaryPaneDefaultWidth,
        kWindowsDesktopSecondaryPaneMaxWidth,
        kWindowsDesktopSecondaryPaneMinWidth,
        kWindowsDesktopSidebarWidth,
        kWindowsDesktopWideBreakpoint,
        resolveDesktopLayoutPolicy;

typedef WindowsDesktopLayoutTier = DesktopLayoutTier;

enum DesktopMemoListLayoutTier { narrow, compact, expanded, wide }

typedef WindowsDesktopNavMode = DesktopNavigationMode;

typedef WindowsDesktopLayoutSpec = DesktopLayoutSpec;

class DesktopMemoListLayoutSpec {
  const DesktopMemoListLayoutSpec({
    required this.tier,
    required this.supportsPreviewPane,
    required this.defaultMemoClickOpensPreview,
  });

  final DesktopMemoListLayoutTier tier;
  final bool supportsPreviewPane;
  final bool defaultMemoClickOpensPreview;
}

bool isDesktopTargetPlatform([TargetPlatform? platform]) {
  final value = platform ?? defaultTargetPlatform;
  return value == TargetPlatform.windows ||
      value == TargetPlatform.macOS ||
      value == TargetPlatform.linux;
}

bool isAlignedDesktopMemoPreviewPlatform([TargetPlatform? platform]) {
  final value = platform ?? defaultTargetPlatform;
  return value == TargetPlatform.windows || value == TargetPlatform.macOS;
}

DesktopMemoListLayoutSpec resolveDesktopMemoListLayout(
  double width, {
  TargetPlatform? platform,
}) {
  if (!isAlignedDesktopMemoPreviewPlatform(platform)) {
    return const DesktopMemoListLayoutSpec(
      tier: DesktopMemoListLayoutTier.narrow,
      supportsPreviewPane: false,
      defaultMemoClickOpensPreview: false,
    );
  }

  if (width < kWindowsDesktopNarrowBreakpoint) {
    return const DesktopMemoListLayoutSpec(
      tier: DesktopMemoListLayoutTier.narrow,
      supportsPreviewPane: false,
      defaultMemoClickOpensPreview: false,
    );
  }

  if (width < kDesktopMemoListExpandedBreakpoint) {
    return const DesktopMemoListLayoutSpec(
      tier: DesktopMemoListLayoutTier.compact,
      supportsPreviewPane: false,
      defaultMemoClickOpensPreview: false,
    );
  }

  if (width < kDesktopMemoListWideBreakpoint) {
    return const DesktopMemoListLayoutSpec(
      tier: DesktopMemoListLayoutTier.expanded,
      supportsPreviewPane: true,
      defaultMemoClickOpensPreview: false,
    );
  }

  return const DesktopMemoListLayoutSpec(
    tier: DesktopMemoListLayoutTier.wide,
    supportsPreviewPane: true,
    defaultMemoClickOpensPreview: true,
  );
}

WindowsDesktopLayoutSpec resolveWindowsDesktopLayout(
  double width, {
  TargetPlatform? platform,
}) {
  final resolvedPlatform = platform ?? defaultTargetPlatform;
  if (resolvedPlatform != TargetPlatform.windows) {
    return resolveDesktopLayoutPolicy(width, platform: TargetPlatform.linux);
  }
  return resolveDesktopLayoutPolicy(width, platform: TargetPlatform.windows);
}

bool shouldUseWindowsOverlayNav(double width, {TargetPlatform? platform}) {
  final resolvedPlatform = platform ?? defaultTargetPlatform;
  if (resolvedPlatform != TargetPlatform.windows) return false;
  return resolveWindowsDesktopLayout(width, platform: platform).navMode ==
      WindowsDesktopNavMode.overlay;
}

bool shouldUseWindowsRailNav(double width, {TargetPlatform? platform}) {
  final resolvedPlatform = platform ?? defaultTargetPlatform;
  if (resolvedPlatform != TargetPlatform.windows) return false;
  return resolveWindowsDesktopLayout(width, platform: platform).navMode ==
      WindowsDesktopNavMode.rail;
}

bool shouldUseWindowsExpandedSidebar(double width, {TargetPlatform? platform}) {
  final resolvedPlatform = platform ?? defaultTargetPlatform;
  if (resolvedPlatform != TargetPlatform.windows) return false;
  return resolveWindowsDesktopLayout(width, platform: platform).navMode ==
      WindowsDesktopNavMode.expanded;
}

bool shouldUseWindowsSecondaryPane(double width, {TargetPlatform? platform}) {
  final resolvedPlatform = platform ?? defaultTargetPlatform;
  if (resolvedPlatform != TargetPlatform.windows) return false;
  return resolveWindowsDesktopLayout(
    width,
    platform: platform,
  ).supportsSecondaryPane;
}

bool shouldUseDesktopSidePaneLayout(
  double width, {
  double breakpoint = kMemoFlowDesktopSidePaneBreakpoint,
}) {
  return isDesktopTargetPlatform() && width >= breakpoint;
}

bool shouldUseDesktopPreviewPaneLayout(
  double width, {
  double breakpoint = kMemoFlowDesktopPreviewPaneBreakpoint,
  TargetPlatform? platform,
}) {
  return isDesktopTargetPlatform(platform) && width >= breakpoint;
}

bool shouldUseInlineComposeLayout(
  double width, {
  double breakpoint = kMemoFlowInlineComposeBreakpoint,
}) {
  // Enable for desktop and wide tablet-like layouts.
  return width >= breakpoint;
}

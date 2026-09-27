import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'desktop_layout_policy.dart';

enum DesktopPanePresentation { inline, overlay, unsupported }

@immutable
class DesktopSecondaryPanePolicy {
  const DesktopSecondaryPanePolicy({
    required this.presentation,
    required this.visible,
    required this.width,
    required this.minWidth,
    required this.maxWidth,
    required this.resizable,
    required this.supportsMotion,
  });

  final DesktopPanePresentation presentation;
  final bool visible;
  final double width;
  final double minWidth;
  final double maxWidth;
  final bool resizable;
  final bool supportsMotion;

  bool get supported => presentation != DesktopPanePresentation.unsupported;
}

@immutable
class DesktopModalSurfacePolicy {
  const DesktopModalSurfacePolicy({
    required this.visible,
    required this.barrierColor,
    required this.barrierBlurSigma,
    required this.supportsMotion,
  });

  final bool visible;
  final Color barrierColor;
  final double barrierBlurSigma;
  final bool supportsMotion;
}

@immutable
class DesktopSurfacePolicy {
  const DesktopSurfacePolicy({
    required this.secondaryPane,
    required this.modalSurface,
  });

  final DesktopSecondaryPanePolicy secondaryPane;
  final DesktopModalSurfacePolicy modalSurface;
}

DesktopSurfacePolicy resolveDesktopSurfacePolicy({
  required TargetPlatform platform,
  required DesktopLayoutSpec layoutSpec,
  required bool secondaryPaneAvailable,
  required bool secondaryPaneVisible,
  required double secondaryPaneWidth,
  required DesktopPanePresentation requestedSecondaryPanePresentation,
  required bool secondaryPaneResizeRequested,
  required bool modalSurfaceAvailable,
  required bool modalSurfaceVisible,
  required Color modalBarrierColor,
  required double modalBarrierBlurSigma,
}) {
  final secondaryPane = _resolveSecondaryPanePolicy(
    platform: platform,
    layoutSpec: layoutSpec,
    available: secondaryPaneAvailable,
    visible: secondaryPaneVisible,
    width: secondaryPaneWidth,
    requestedPresentation: requestedSecondaryPanePresentation,
    resizeRequested: secondaryPaneResizeRequested,
  );

  return DesktopSurfacePolicy(
    secondaryPane: secondaryPane,
    modalSurface: DesktopModalSurfacePolicy(
      visible: modalSurfaceAvailable && modalSurfaceVisible,
      barrierColor: modalBarrierColor,
      barrierBlurSigma: platform == TargetPlatform.windows
          ? modalBarrierBlurSigma
          : 0,
      supportsMotion: platform == TargetPlatform.windows,
    ),
  );
}

DesktopSecondaryPanePolicy _resolveSecondaryPanePolicy({
  required TargetPlatform platform,
  required DesktopLayoutSpec layoutSpec,
  required bool available,
  required bool visible,
  required double width,
  required DesktopPanePresentation requestedPresentation,
  required bool resizeRequested,
}) {
  final clampedWidth = width
      .clamp(
        kWindowsDesktopSecondaryPaneMinWidth,
        kWindowsDesktopSecondaryPaneMaxWidth,
      )
      .toDouble();

  if (platform == TargetPlatform.windows) {
    final supported = layoutSpec.supportsSecondaryPane && available;
    return DesktopSecondaryPanePolicy(
      presentation: supported
          ? requestedPresentation
          : DesktopPanePresentation.unsupported,
      visible: supported && visible,
      width: clampedWidth,
      minWidth: kWindowsDesktopSecondaryPaneMinWidth,
      maxWidth: kWindowsDesktopSecondaryPaneMaxWidth,
      resizable: supported && visible && resizeRequested,
      supportsMotion: true,
    );
  }

  if (platform == TargetPlatform.macOS) {
    final supported =
        available &&
        layoutSpec.supportsSecondaryPane &&
        requestedPresentation == DesktopPanePresentation.inline;
    return DesktopSecondaryPanePolicy(
      presentation: supported
          ? DesktopPanePresentation.inline
          : DesktopPanePresentation.unsupported,
      visible: supported && visible,
      width: clampedWidth,
      minWidth: kWindowsDesktopSecondaryPaneMinWidth,
      maxWidth: kWindowsDesktopSecondaryPaneMaxWidth,
      resizable: false,
      supportsMotion: false,
    );
  }

  return DesktopSecondaryPanePolicy(
    presentation: DesktopPanePresentation.unsupported,
    visible: false,
    width: clampedWidth,
    minWidth: kWindowsDesktopSecondaryPaneMinWidth,
    maxWidth: kWindowsDesktopSecondaryPaneMaxWidth,
    resizable: false,
    supportsMotion: false,
  );
}

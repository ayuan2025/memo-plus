import 'package:flutter/foundation.dart';

enum DesktopRouteMotionStyle { none, fadeSlide, sharedAxis }

class DesktopRouteMotionPolicy {
  const DesktopRouteMotionPolicy({required this.style});

  final DesktopRouteMotionStyle style;

  bool get enabled => style != DesktopRouteMotionStyle.none;
}

DesktopRouteMotionPolicy resolveDesktopDrawerRouteMotion({
  required TargetPlatform platform,
  required bool usesDesktopSidePane,
  bool noAnimation = false,
}) {
  if (noAnimation) {
    return const DesktopRouteMotionPolicy(style: DesktopRouteMotionStyle.none);
  }

  if (!usesDesktopSidePane) {
    return const DesktopRouteMotionPolicy(
      style: DesktopRouteMotionStyle.fadeSlide,
    );
  }

  if (platform == TargetPlatform.windows) {
    return const DesktopRouteMotionPolicy(
      style: DesktopRouteMotionStyle.sharedAxis,
    );
  }

  return const DesktopRouteMotionPolicy(style: DesktopRouteMotionStyle.none);
}

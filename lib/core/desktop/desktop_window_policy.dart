import 'dart:ui';

import 'package:flutter/foundation.dart';

const Size kMemoFlowDesktopMainWindowInitialSize = Size(1360, 860);
const Size kMemoFlowDesktopMainWindowMinimumSize = Size(960, 640);

class DesktopMainWindowPolicy {
  const DesktopMainWindowPolicy({
    required this.initialSize,
    required this.minimumSize,
  });

  final Size initialSize;
  final Size minimumSize;
}

const DesktopMainWindowPolicy kMemoFlowDesktopMainWindowPolicy =
    DesktopMainWindowPolicy(
      initialSize: kMemoFlowDesktopMainWindowInitialSize,
      minimumSize: kMemoFlowDesktopMainWindowMinimumSize,
    );

DesktopMainWindowPolicy resolveDesktopMainWindowPolicy({
  TargetPlatform? platform,
}) {
  final resolvedPlatform = platform ?? defaultTargetPlatform;
  return switch (resolvedPlatform) {
    TargetPlatform.windows ||
    TargetPlatform.macOS => kMemoFlowDesktopMainWindowPolicy,
    _ => kMemoFlowDesktopMainWindowPolicy,
  };
}

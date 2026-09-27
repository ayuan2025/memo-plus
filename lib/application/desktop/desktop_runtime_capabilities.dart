import 'package:flutter/foundation.dart';

bool get isDesktopRuntimePlatform {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

bool get supportsWindowsShellRuntime {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.windows;
}

bool get supportsDesktopTrayRuntime {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

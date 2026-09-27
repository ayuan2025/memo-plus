import 'package:flutter/foundation.dart';

import 'home_navigation_host.dart';

bool isDesktopHomeInlineComposeResizePlatformSupported(
  TargetPlatform platform,
) {
  if (kIsWeb) return false;
  return platform == TargetPlatform.windows || platform == TargetPlatform.macOS;
}

bool shouldEnableDesktopHomeInlineComposeResize({
  required TargetPlatform platform,
  required HomeScreenPresentation presentation,
  required HomeEmbeddedNavigationHost? navigationHost,
}) {
  if (!isDesktopHomeInlineComposeResizePlatformSupported(platform)) {
    return false;
  }
  if (navigationHost != null) return false;
  return presentation == HomeScreenPresentation.standalone;
}

bool shouldEnableDesktopHomeInlineComposeResizeForMemosList({
  required TargetPlatform platform,
  required HomeScreenPresentation presentation,
  required HomeEmbeddedNavigationHost? navigationHost,
  required bool explicitlyEnabled,
  required bool showDrawer,
  required bool enableCompose,
  required String state,
  required String? tag,
  required DateTime? dayFilter,
  bool allowFilteredHomeInlineComposeResize = false,
}) {
  if (!shouldEnableDesktopHomeInlineComposeResize(
    platform: platform,
    presentation: presentation,
    navigationHost: navigationHost,
  )) {
    return false;
  }
  if (explicitlyEnabled) return true;
  return showDrawer &&
      enableCompose &&
      state == 'NORMAL' &&
      (tag == null || tag.trim().isEmpty) &&
      (dayFilter == null || allowFilteredHomeInlineComposeResize);
}

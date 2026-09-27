import 'package:flutter/foundation.dart';

import '../../core/app_channel.dart';

bool shouldFetchStartupUpdateAnnouncementsForCurrentBuild() {
  return shouldFetchStartupUpdateAnnouncements(
    channel: currentAppChannel,
    targetPlatform: defaultTargetPlatform,
    isWeb: kIsWeb,
  );
}

@visibleForTesting
bool shouldFetchStartupUpdateAnnouncements({
  required AppChannel channel,
  required TargetPlatform targetPlatform,
  bool isWeb = false,
}) {
  return true;
}

bool shouldShowStartupUpdatePromptForCurrentBuild() {
  return shouldShowStartupUpdatePrompt(
    channel: currentAppChannel,
    targetPlatform: defaultTargetPlatform,
    isWeb: kIsWeb,
  );
}

@visibleForTesting
bool shouldShowStartupUpdatePrompt({
  required AppChannel channel,
  required TargetPlatform targetPlatform,
  bool isWeb = false,
}) {
  if (isWeb) return true;
  return !(targetPlatform == TargetPlatform.android &&
      channel == AppChannel.play);
}

String startupAnnouncementPlatformKey({
  required TargetPlatform targetPlatform,
  bool isWeb = false,
}) {
  if (isWeb) return 'web';
  return switch (targetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    TargetPlatform.macOS => 'macos',
    TargetPlatform.windows => 'windows',
    TargetPlatform.linux => 'linux',
    TargetPlatform.fuchsia => 'fuchsia',
  };
}

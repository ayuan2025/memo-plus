import 'package:flutter/material.dart';

import '../../application/desktop/desktop_settings_window.dart';
import '../../platform/platform_route.dart';
import 'location_settings_screen.dart';

Future<void> openLocationSettingsSurface(BuildContext context) async {
  final result = await openDesktopSettingsWindow(
    feedbackContext: context,
    target: DesktopSettingsWindowTarget.location,
  );
  if (result.opened || !context.mounted) return;

  await Navigator.of(context).push(
    buildPlatformPageRoute<void>(
      context: context,
      builder: (_) => const LocationSettingsScreen(),
    ),
  );
}

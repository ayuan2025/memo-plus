import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../platform/platform_target.dart';
import '../../state/settings/device_preferences_provider.dart';
import 'desktop_shortcuts_settings_screen.dart';
import 'settings_ui.dart';

bool isDesktopSettingsSupportedTarget(PlatformTarget target) {
  return target == PlatformTarget.windows || target == PlatformTarget.macOS;
}

class DesktopSettingsScreen extends ConsumerWidget {
  const DesktopSettingsScreen({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = resolvePlatformTarget(context);
    final prefs = ref.watch(devicePreferencesProvider);
    final notifier = ref.read(devicePreferencesProvider.notifier);
    final children = <Widget>[
      if (isDesktopSettingsSupportedTarget(target))
        SettingsSection(
          header: Text(context.t.strings.legacy.msg_desktop_settings),
          children: [
            SettingsNavigationRow(
              label: context.t.strings.legacy.msg_shortcut_settings,
              description:
                  context.t.strings.legacy.msg_configure_desktop_shortcuts,
              leading: const Icon(Icons.keyboard_alt_outlined),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DesktopShortcutsSettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      if (target == PlatformTarget.windows) ...[
        const SizedBox(height: 12),
        SettingsSection(
          header: const Text('Windows'),
          children: [
            SettingsToggleRow(
              label: context.t.strings.legacy.msg_close_window_minimize_to_tray,
              description: context
                  .t
                  .strings
                  .legacy
                  .msg_close_window_minimize_to_tray_desc,
              value: prefs.windowsCloseToTray,
              onChanged: notifier.setWindowsCloseToTray,
            ),
          ],
        ),
      ],
      if (target == PlatformTarget.macOS) ...[
        const SizedBox(height: 12),
        SettingsSection(
          header: const Text('macOS'),
          children: [
            SettingsToggleRow(
              label: context.t.strings.legacy.msg_close_window_keep_in_menu_bar,
              description: context
                  .t
                  .strings
                  .legacy
                  .msg_close_window_keep_in_menu_bar_desc,
              value: prefs.macosCloseToMenuBar,
              onChanged: notifier.setMacosCloseToMenuBar,
            ),
          ],
        ),
      ],
    ];

    return SettingsPage(
      showBackButton: showBackButton,
      title: Text(context.t.strings.legacy.msg_desktop_settings),
      contentKey: const ValueKey<String>('desktopSettings.boundedContent'),
      children: children,
    );
  }
}

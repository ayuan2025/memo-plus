import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_localization.dart';
import '../../data/models/home_navigation_preferences.dart';
import '../../i18n/strings.g.dart';
import '../../platform/platform_route.dart';
import '../../state/settings/workspace_preferences_provider.dart';
import 'bottom_navigation_mode_settings_screen.dart';
import 'settings_ui.dart';

class NavigationModeScreen extends ConsumerWidget {
  const NavigationModeScreen({super.key});

  static const classicOptionKey = ValueKey<String>(
    'navigation-mode-classic-option',
  );
  static const bottomSelectKey = ValueKey<String>(
    'navigation-mode-bottom-select',
  );
  static const bottomSettingsKey = ValueKey<String>(
    'navigation-mode-bottom-settings',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationPrefs = ref.watch(
      currentWorkspacePreferencesProvider.select(
        (prefs) => prefs.homeNavigationPreferences,
      ),
    );
    final bottomBarSelected =
        navigationPrefs.mode == HomeNavigationMode.bottomBar;

    void selectMode(HomeNavigationMode mode) {
      if (mode == navigationPrefs.mode) return;
      ref
          .read(currentWorkspacePreferencesProvider.notifier)
          .setHomeNavigationMode(mode);
    }

    Future<void> openBottomSettings() async {
      if (!bottomBarSelected) return;
      await Navigator.of(context).push(
        buildPlatformPageRoute<void>(
          context: context,
          builder: (context) => const BottomNavigationModeSettingsScreen(),
        ),
      );
    }

    return SettingsPage(
      title: Text(context.t.strings.legacy.msg_navigation_mode),
      children: [
        SettingsSection(
          footer: Text(
            context.tr(
              zh: '\u6B64\u8BBE\u7F6E\u4F1A\u5F71\u54CD\u9996\u9875\u5BFC\u822A\u6837\u5F0F\uFF1B\u8FD4\u56DE\u9996\u9875\u540E\u53EF\u770B\u5230\u5B9E\u9645\u6548\u679C\u3002',
              en: 'This changes the Home screen navigation style; go back to Home to preview it.',
            ),
          ),
          children: [
            SettingsSelectableItemRow(
              key: classicOptionKey,
              selected: navigationPrefs.mode == HomeNavigationMode.classic,
              title: context.t.strings.legacy.msg_navigation_mode_classic,
              subtitle: context.tr(
                zh: '\u4F7F\u7528\u7ECF\u5178\u9996\u9875\u5BFC\u822A\u5E03\u5C40\u3002',
                en: 'Use the classic Home navigation layout.',
              ),
              onTap: () => selectMode(HomeNavigationMode.classic),
            ),
            SettingsSelectableItemRow(
              key: bottomSelectKey,
              selected: bottomBarSelected,
              title: context.t.strings.legacy.msg_navigation_mode_bottom_bar,
              subtitle: context.tr(
                zh: '\u4F7F\u7528\u5E95\u90E8\u5BFC\u822A\u680F\uFF0C\u5E76\u53EF\u81EA\u5B9A\u4E49\u5DE6\u53F3\u5165\u53E3\u3002',
                en: 'Use the bottom navigation bar and customize the side entries.',
              ),
              onTap: () => selectMode(HomeNavigationMode.bottomBar),
            ),
            SettingsNavigationRow(
              key: bottomSettingsKey,
              label: context.t.strings.legacy.msg_settings,
              description: context.tr(
                zh: '\u9009\u4E2D\u5E95\u90E8\u5BFC\u822A\u680F\u540E\u53EF\u81EA\u5B9A\u4E49\u5165\u53E3\u3002',
                en: 'Select bottom bar mode before customizing entries.',
              ),
              enabled: bottomBarSelected,
              leading: const Icon(Icons.tune_rounded),
              onTap: openBottomSettings,
            ),
          ],
        ),
      ],
    );
  }
}

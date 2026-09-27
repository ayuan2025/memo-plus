import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../platform/platform_route.dart';
import 'customize_home_shortcuts_screen.dart';
import 'customize_drawer_screen.dart';
import 'navigation_mode_screen.dart';
import 'shortcuts_settings_screen.dart';
import 'webhooks_settings_screen.dart';
import '../../i18n/strings.g.dart';
import 'settings_ui.dart';

class LaboratoryScreen extends StatelessWidget {
  const LaboratoryScreen({super.key, this.showBackButton = true});

  final bool showBackButton;

  static final Future<PackageInfo> _packageInfoFuture =
      PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final tokens = settingsPageTokens(context);
    final entries = <_LabEntry>[
      _LabEntry(
        label: context.t.strings.legacy.msg_customize_sidebar,
        builder: (_) => const CustomizeDrawerScreen(),
      ),
      _LabEntry(
        label: context.t.strings.legacy.msg_navigation_mode,
        builder: (_) => const NavigationModeScreen(),
      ),
      _LabEntry(
        label: context.t.strings.legacy.msg_customize_quick_entries,
        builder: (_) => const CustomizeHomeShortcutsScreen(),
      ),
      _LabEntry(
        label: context.t.strings.legacy.msg_shortcuts,
        builder: (_) => const ShortcutsSettingsScreen(),
      ),
      _LabEntry(
        label: context.t.strings.legacy.msg_webhooks,
        builder: (_) => const WebhooksSettingsScreen(),
      ),
    ];

    return SettingsPage(
      showBackButton: showBackButton,
      title: Text(context.t.strings.legacy.msg_laboratory),
      children: [
        SettingsSection(
          children: [
            for (final entry in entries)
              SettingsNavigationRow(
                label: entry.label,
                onTap: () => Navigator.of(context).push(
                  buildPlatformPageRoute<void>(
                    context: context,
                    builder: entry.builder,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 22),
        _LaboratoryVersionFooter(tokens: tokens),
      ],
    );
  }
}

class _LabEntry {
  const _LabEntry({required this.label, required this.builder});

  final String label;
  final WidgetBuilder builder;
}

class _LaboratoryVersionFooter extends StatelessWidget {
  const _LaboratoryVersionFooter({required this.tokens});

  final SettingsPageTokens tokens;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        const SettingsContentHeader(
          title: 'MemoFlow',
          textAlign: TextAlign.center,
          prominent: true,
        ),
        const SizedBox(height: 4),
        FutureBuilder<PackageInfo>(
          future: LaboratoryScreen._packageInfoFuture,
          builder: (context, snapshot) {
            final version = snapshot.data?.version.trim() ?? '';
            return Text(
              version.isEmpty ? 'VERSION' : 'VERSION $version',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: accent.withValues(alpha: tokens.isDark ? 0.55 : 0.7),
              ),
            );
          },
        ),
      ],
    );
  }
}

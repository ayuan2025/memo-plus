import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform/platform_route.dart';
import '../../i18n/strings.g.dart';
import '../../state/settings/device_preferences_provider.dart';
import '../import/import_flow_screens.dart';
import 'export_memos_screen.dart';
import 'local_network_migration_screen.dart';
import 'scan_reindex_screen.dart';
import 'settings_ui.dart';

class ImportExportScreen extends ConsumerWidget {
  const ImportExportScreen({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hapticsEnabled = ref.watch(
      devicePreferencesProvider.select((p) => p.hapticsEnabled),
    );

    void haptic() {
      if (hapticsEnabled) {
        HapticFeedback.selectionClick();
      }
    }

    return SettingsPage(
      title: Text(context.t.strings.legacy.msg_import_export),
      showBackButton: showBackButton,
      children: [
        SettingsSection(
          header: Text(context.t.strings.legacy.msg_export),
          children: [
            SettingsNavigationRow(
              leading: const Icon(Icons.download_outlined),
              label: context.t.strings.legacy.msg_export,
              value: 'Markdown + ZIP',
              onTap: () {
                haptic();
                Navigator.of(context).push(
                  buildPlatformPageRoute<void>(
                    context: context,
                    builder: (_) => const ExportMemosScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        SettingsSection(
          header: Text(context.t.strings.legacy.msg_reindex_scans),
          children: [
            SettingsNavigationRow(
              leading: const Icon(Icons.document_scanner_outlined),
              label: context.t.strings.legacy.msg_reindex_scans,
              value: context.t.strings.legacy.msg_reindex_scans_summary,
              onTap: () {
                haptic();
                Navigator.of(context).push(
                  buildPlatformPageRoute<void>(
                    context: context,
                    builder: (_) => const ScanReindexScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        SettingsSection(
          header: Text(context.t.strings.legacy.msg_import),
          children: [
            SettingsNavigationRow(
              leading: const Icon(Icons.file_upload_outlined),
              label: context.t.strings.legacy.msg_import_file_2,
              value: context.t.strings.legacy.msg_html_zip,
              onTap: () {
                haptic();
                Navigator.of(context).push(
                  buildPlatformPageRoute<void>(
                    context: context,
                    builder: (_) => const ImportSourceScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        SettingsSection(
          header: Text(context.t.strings.legacy.msg_local_network_migration),
          children: [
            SettingsNavigationRow(
              leading: const Icon(Icons.devices_outlined),
              label: context.t.strings.legacy.msg_local_network_migration,
              value: context
                  .t
                  .strings
                  .legacy
                  .msg_memoflow_migration_targets_summary,
              onTap: () {
                haptic();
                Navigator.of(context).push(
                  buildPlatformPageRoute<void>(
                    context: context,
                    builder: (_) => const LocalNetworkMigrationScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

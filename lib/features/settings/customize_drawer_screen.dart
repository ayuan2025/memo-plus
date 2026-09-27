import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/settings/workspace_preferences_provider.dart';
import '../../i18n/strings.g.dart';
import 'settings_ui.dart';

class CustomizeDrawerScreen extends ConsumerWidget {
  const CustomizeDrawerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(currentWorkspacePreferencesProvider);

    return SettingsPage(
      title: Text(context.t.strings.legacy.msg_customize_sidebar),
      children: [
        SettingsSection(
          children: [
            SettingsToggleRow(
              label: context.t.strings.legacy.msg_explore,
              value: prefs.showDrawerExplore,
              onChanged: (v) => ref
                  .read(currentWorkspacePreferencesProvider.notifier)
                  .setShowDrawerExplore(v),
            ),
            SettingsToggleRow(
              label: context.t.strings.legacy.msg_random_review,
              value: prefs.showDrawerDailyReview,
              onChanged: (v) => ref
                  .read(currentWorkspacePreferencesProvider.notifier)
                  .setShowDrawerDailyReview(v),
            ),
            SettingsToggleRow(
              label: context.t.strings.legacy.msg_ai_summary,
              value: prefs.showDrawerAiSummary,
              onChanged: (v) => ref
                  .read(currentWorkspacePreferencesProvider.notifier)
                  .setShowDrawerAiSummary(v),
            ),
            SettingsToggleRow(
              label: context.t.strings.collections.drawerLabel,
              value: prefs.showDrawerCollections,
              onChanged: (v) => ref
                  .read(currentWorkspacePreferencesProvider.notifier)
                  .setShowDrawerCollections(v),
            ),
            SettingsToggleRow(
              label: context.t.strings.legacy.msg_draft_box_title,
              value: prefs.showDrawerDraftBox,
              onChanged: (v) => ref
                  .read(currentWorkspacePreferencesProvider.notifier)
                  .setShowDrawerDraftBox(v),
            ),
            SettingsToggleRow(
              label: context.t.strings.legacy.msg_attachments,
              value: prefs.showDrawerResources,
              onChanged: (v) => ref
                  .read(currentWorkspacePreferencesProvider.notifier)
                  .setShowDrawerResources(v),
            ),
            SettingsToggleRow(
              label: context.t.strings.legacy.msg_archive,
              value: prefs.showDrawerArchive,
              onChanged: (v) => ref
                  .read(currentWorkspacePreferencesProvider.notifier)
                  .setShowDrawerArchive(v),
            ),
          ],
        ),
      ],
    );
  }
}

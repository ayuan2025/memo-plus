import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/windows_adaptive_surface.dart';
import '../../state/settings/device_preferences_provider.dart';
import '../../i18n/strings.g.dart';
import 'settings_ui.dart';

class UserGuideScreen extends ConsumerWidget {
  const UserGuideScreen({super.key, this.showBackButton = true});

  final bool showBackButton;

  Future<void> _openBackendDocs(BuildContext context) async {
    final uri = Uri.parse('https://usememos.com/docs');
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.t.strings.legacy.msg_unable_open_browser_try),
          ),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.strings.legacy.msg_failed_open_try)),
      );
    }
  }

  Future<void> _showInfo(
    BuildContext context, {
    required String title,
    required String body,
  }) async {
    Widget buildInfoContent(BuildContext surfaceContext) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          children: [
            Text(title, style: Theme.of(surfaceContext).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(
              body,
              style: Theme.of(
                surfaceContext,
              ).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ),
      );
    }

    if (shouldUseWindowsAdaptiveSurface(context)) {
      await showWindowsAdaptiveSurface<void>(
        context: context,
        kind: WindowsAdaptiveSurfaceKind.dialog,
        maxWidth: 560,
        builder: buildInfoContent,
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: buildInfoContent,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = settingsPageTokens(context);
    final hapticsEnabled = ref.watch(
      devicePreferencesProvider.select((p) => p.hapticsEnabled),
    );

    void haptic() {
      if (hapticsEnabled) {
        HapticFeedback.selectionClick();
      }
    }

    return SettingsPage(
      showBackButton: showBackButton,
      title: Text(context.t.strings.legacy.msg_user_guide),
      children: [
        SettingsSection(
          children: [
            SettingsNavigationRow(
              leading: Icon(
                Icons.menu_book_outlined,
                size: 20,
                color: tokens.textMuted,
              ),
              label: context.t.strings.legacy.msg_memos_backend_docs,
              description: 'usememos.com/docs',
              trailingIcon: Icons.open_in_new,
              onTap: () async {
                haptic();
                await _openBackendDocs(context);
              },
            ),
            SettingsNavigationRow(
              leading: Icon(Icons.refresh, size: 20, color: tokens.textMuted),
              label: context.t.strings.legacy.msg_pull_refresh,
              description: context.t.strings.legacy.msg_sync_recent_content,
              onTap: () async {
                haptic();
                await _showInfo(
                  context,
                  title: context.t.strings.legacy.msg_pull_refresh,
                  body: context
                      .t
                      .strings
                      .legacy
                      .msg_pull_memo_list_refresh_sync_sync,
                );
              },
            ),
            SettingsNavigationRow(
              leading: Icon(
                Icons.cloud_off_outlined,
                size: 20,
                color: tokens.textMuted,
              ),
              label: context.t.strings.legacy.msg_offline_ready,
              description: context.t.strings.legacy.msg_local_db_pending_queue,
              onTap: () async {
                haptic();
                await _showInfo(
                  context,
                  title: context.t.strings.legacy.msg_offline_ready,
                  body: context
                      .t
                      .strings
                      .legacy
                      .msg_create_edit_delete_actions_offline_stored,
                );
              },
            ),
            SettingsNavigationRow(
              leading: Icon(Icons.search, size: 20, color: tokens.textMuted),
              label: context.t.strings.legacy.msg_full_text_search,
              description: context.t.strings.legacy.msg_content_tags,
              onTap: () async {
                haptic();
                await _showInfo(
                  context,
                  title: context.t.strings.legacy.msg_full_text_search,
                  body: context
                      .t
                      .strings
                      .legacy
                      .msg_enter_keywords_search_box_query_local,
                );
              },
            ),
            SettingsNavigationRow(
              leading: Icon(
                Icons.graphic_eq,
                size: 20,
                color: tokens.textMuted,
              ),
              label: context.t.strings.legacy.msg_voice_memos,
              description: context.t.strings.legacy.msg_record_create_memos,
              onTap: () async {
                haptic();
                await _showInfo(
                  context,
                  title: context.t.strings.legacy.msg_voice_memos,
                  body: context
                      .t
                      .strings
                      .legacy
                      .msg_after_recording_audio_added_current_draft,
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          context.t.strings.legacy.msg_note_most_features_offline_stats_ai,
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: tokens.textMuted.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_localization.dart';
import '../../core/top_toast.dart';
import '../../data/models/user_setting.dart';
import '../../platform/widgets/platform_list_section.dart';
import '../../state/memos/memos_providers.dart';
import '../../state/settings/device_preferences_provider.dart';
import '../../state/settings/user_settings_provider.dart';
import '../../i18n/strings.g.dart';
import 'settings_ui.dart';

class WebhooksSettingsScreen extends ConsumerStatefulWidget {
  const WebhooksSettingsScreen({super.key});

  @override
  ConsumerState<WebhooksSettingsScreen> createState() =>
      _WebhooksSettingsScreenState();
}

class _WebhooksSettingsScreenState
    extends ConsumerState<WebhooksSettingsScreen> {
  var _saving = false;

  Future<void> _openEditor({UserWebhook? webhook}) async {
    final nameController = TextEditingController(
      text: webhook?.displayName ?? '',
    );
    final urlController = TextEditingController(text: webhook?.url ?? '');
    final isEditing = webhook != null;

    final result = await showDialog<_WebhookDraft>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isEditing
              ? context.t.strings.legacy.msg_edit_webhook
              : context.t.strings.legacy.msg_add_webhook,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: context.t.strings.legacy.msg_display_name,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: context.t.strings.legacy.msg_url,
                hintText: 'https://example.com/webhook',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.safePop(),
            child: Text(context.t.strings.legacy.msg_cancel_2),
          ),
          FilledButton(
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isEmpty) return;
              context.safePop(
                _WebhookDraft(
                  displayName: nameController.text.trim(),
                  url: url,
                ),
              );
            },
            child: Text(context.t.strings.legacy.msg_save),
          ),
        ],
      ),
    );

    if (result == null) return;
    await _saveWebhook(
      webhook: webhook,
      displayName: result.displayName,
      url: result.url,
    );
  }

  Future<void> _saveWebhook({
    required UserWebhook? webhook,
    required String displayName,
    required String url,
  }) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final api = ref.read(memosApiProvider);
      if (webhook == null) {
        await api.createUserWebhook(displayName: displayName, url: url);
      } else {
        await api.updateUserWebhook(
          webhook: webhook,
          displayName: displayName,
          url: url,
        );
      }
      ref.invalidate(userWebhooksProvider);
      if (!mounted) return;
      showTopToast(context, context.t.strings.legacy.msg_saved_2);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t.strings.legacy.msg_save_failed_3(e: e)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _deleteWebhook(UserWebhook webhook) async {
    if (_saving) return;
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.t.strings.legacy.msg_delete_webhook),
            content: Text(
              context.t.strings.legacy.msg_sure_want_delete_webhook,
            ),
            actions: [
              TextButton(
                onPressed: () => context.safePop(false),
                child: Text(context.t.strings.legacy.msg_cancel_2),
              ),
              FilledButton(
                onPressed: () => context.safePop(true),
                child: Text(context.t.strings.legacy.msg_delete),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    setState(() => _saving = true);
    try {
      await ref.read(memosApiProvider).deleteUserWebhook(webhook: webhook);
      ref.invalidate(userWebhooksProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t.strings.legacy.msg_delete_failed(e: e)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _displayName(UserWebhook webhook) {
    final displayName = webhook.displayName.trim();
    if (displayName.isNotEmpty) return displayName;
    final name = webhook.name.trim();
    if (name.isNotEmpty) return name;
    return webhook.url;
  }

  String _formatLoadError(BuildContext context, Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode ?? 0;
      if (status == 404 || status == 405) {
        return context.t.strings.legacy.msg_webhooks_not_supported_server;
      }
    }
    return context.t.strings.legacy.msg_failed_load_try;
  }

  @override
  Widget build(BuildContext context) {
    final hapticsEnabled = ref.watch(
      devicePreferencesProvider.select((p) => p.hapticsEnabled),
    );

    void maybeHaptic() {
      if (hapticsEnabled) {
        HapticFeedback.selectionClick();
      }
    }

    final webhooksAsync = ref.watch(userWebhooksProvider);

    return SettingsPage(
      title: Text(context.t.strings.legacy.msg_webhooks),
      actions: [
        IconButton(
          tooltip: context.t.strings.legacy.msg_add,
          icon: const Icon(Icons.add),
          onPressed: _saving
              ? null
              : () {
                  maybeHaptic();
                  _openEditor();
                },
        ),
      ],
      children: [
        SettingsSection(
          children: webhooksAsync.when(
            data: (webhooks) {
              if (webhooks.isEmpty) {
                return [
                  SettingsInfoRow(
                    description:
                        context.t.strings.legacy.msg_no_webhooks_configured,
                  ),
                ];
              }

              return [
                for (final webhook in webhooks)
                  _WebhookRow(
                    title: _displayName(webhook),
                    url: webhook.url,
                    onEdit: () {
                      maybeHaptic();
                      _openEditor(webhook: webhook);
                    },
                    onDelete: () {
                      maybeHaptic();
                      _deleteWebhook(webhook);
                    },
                  ),
              ];
            },
            loading: () => [
              const PlatformListSectionRow(
                title: Center(child: CircularProgressIndicator.adaptive()),
                denseOnDesktop: false,
              ),
            ],
            error: (error, _) => [
              PlatformListSectionRow(
                title: SettingsRowTitle(
                  context.t.strings.legacy.msg_failed_load_2,
                ),
                subtitle: SettingsRowDescription(
                  _formatLoadError(context, error),
                ),
                trailing: TextButton(
                  onPressed: () => ref.invalidate(userWebhooksProvider),
                  child: Text(context.t.strings.legacy.msg_retry),
                ),
                denseOnDesktop: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WebhookRow extends StatelessWidget {
  const _WebhookRow({
    required this.title,
    required this.url,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String url;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final tokens = settingsPageTokens(context);
    return PlatformListSectionRow(
      title: SettingsRowTitle(title),
      subtitle: SettingsRowDescription(url),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: context.t.strings.legacy.msg_edit,
            icon: Icon(Icons.edit_outlined, size: 18, color: tokens.textMuted),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: context.t.strings.legacy.msg_delete,
            icon: Icon(Icons.delete_outline, size: 18, color: tokens.textMuted),
            onPressed: onDelete,
          ),
        ],
      ),
      denseOnDesktop: false,
    );
  }
}

class _WebhookDraft {
  const _WebhookDraft({required this.displayName, required this.url});

  final String displayName;
  final String url;
}

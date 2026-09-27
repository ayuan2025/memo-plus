import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/sync/migration/memoflow_migration_models.dart';
import '../../../core/app_localization.dart';
import '../../../i18n/strings.g.dart';
import '../../../platform/widgets/platform_primary_action.dart';
import '../../../state/migration/memoflow_migration_providers.dart';
import '../../../state/migration/memoflow_migration_sender_controller.dart';
import '../../../state/migration/memoflow_migration_state.dart';
import '../settings_ui.dart';
import 'memoflow_migration_result_screen.dart';
import 'memoflow_migration_send_method_screen.dart';

class MemoFlowMigrationSenderScreen extends ConsumerWidget {
  const MemoFlowMigrationSenderScreen({
    super.key,
    this.initialReceiverQrPayload,
  });

  final String? initialReceiverQrPayload;

  Future<void> _prepareAndContinue(
    BuildContext context,
    WidgetRef ref,
    MemoFlowMigrationSenderController controller,
  ) async {
    await controller.buildPackage();
    if (!context.mounted) return;
    final nextState = ref.read(memoFlowMigrationSenderControllerProvider);
    if (nextState.packageResult == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemoFlowMigrationSendMethodScreen(
          initialReceiverQrPayload: initialReceiverQrPayload,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(memoFlowMigrationSenderControllerProvider);
    final controller = ref.read(
      memoFlowMigrationSenderControllerProvider.notifier,
    );
    final tr = context.t.strings.legacy;

    return SettingsPage(
      title: Text(tr.msg_memoflow_migration_sender),
      children: [
        if (!state.isLocalLibraryMode) ...[
          SettingsSection(
            children: [
              SettingsWarningRow(
                message: tr.msg_memoflow_migration_sender_only_local_mode,
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        SettingsSection(
          header: Text(tr.msg_memoflow_migration_select_content),
          children: [
            CheckboxListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(tr.msg_memoflow_migration_notes),
              subtitle: Text(tr.msg_memoflow_migration_notes_desc),
              value: state.includeMemos,
              onChanged: state.isLocalLibraryMode
                  ? (value) => controller.setIncludeMemos(value ?? false)
                  : null,
            ),
            CheckboxListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(tr.msg_memoflow_migration_settings),
              subtitle: Text(tr.msg_memoflow_migration_settings_desc),
              value: state.includeSettings,
              onChanged: (value) =>
                  controller.setIncludeSettings(value ?? false),
            ),
          ],
        ),
        if (state.includeSettings) ...[
          const SizedBox(height: 14),
          SettingsSection(
            header: Text(tr.msg_memoflow_migration_safe_config),
            children: [
              ...memoFlowMigrationSafeConfigDefaults.map(
                (type) => CheckboxListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(_configTypeLabel(context, type)),
                  value: state.selectedConfigTypes.contains(type),
                  onChanged: (value) =>
                      controller.toggleConfigType(type, value ?? false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SettingsSection(
            header: Text(tr.msg_memoflow_migration_sensitive_config),
            children: [
              ...memoFlowMigrationSensitiveConfigDefaults.map(
                (type) => CheckboxListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(_configTypeLabel(context, type)),
                  value: state.selectedConfigTypes.contains(type),
                  onChanged: (value) =>
                      controller.toggleConfigType(type, value ?? false),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SettingsAction(
            onPressed: state.canBuildPackage
                ? () => _prepareAndContinue(context, ref, controller)
                : null,
            icon: const Icon(Icons.send_outlined),
            label: Text(tr.msg_memoflow_migration_prepare_send),
          ),
        ),
        if (state.phase == MemoFlowMigrationSenderPhase.buildingPackage) ...[
          const SizedBox(height: 14),
          SettingsSection(
            children: [
              SettingsInfoRow(description: state.statusMessage ?? ''),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: LinearProgressIndicator(),
              ),
            ],
          ),
        ],
        if ((state.errorMessage ?? '').isNotEmpty) ...[
          const SizedBox(height: 14),
          SettingsSection(
            children: [SettingsWarningRow(message: state.errorMessage!)],
          ),
        ],
        if (state.result != null) ...[
          const SizedBox(height: 14),
          SettingsSection(
            children: [
              SettingsInfoRow(description: tr.msg_memoflow_migration_completed),
              if ((state.statusMessage ?? '').isNotEmpty)
                SettingsInfoRow(description: state.statusMessage!),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SettingsAction(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MemoFlowMigrationResultScreen(
                      result: state.result!,
                      title: tr.msg_memoflow_migration_result,
                    ),
                  ),
                );
              },
              variant: PlatformPrimaryActionVariant.tonal,
              label: Text(tr.msg_memoflow_migration_view_result),
            ),
          ),
        ],
        const SizedBox(height: 14),
        SettingsSection(
          children: [
            SettingsInfoRow(
              description: tr.msg_memoflow_migration_foreground_notice,
            ),
          ],
        ),
      ],
    );
  }

  String _configTypeLabel(
    BuildContext context,
    MemoFlowMigrationConfigType type,
  ) {
    final tr = context.t.strings.legacy;
    return switch (type) {
      MemoFlowMigrationConfigType.preferences => tr.msg_preferences,
      MemoFlowMigrationConfigType.reminderSettings => tr.msg_reminder_settings,
      MemoFlowMigrationConfigType.templateSettings => tr.msg_template,
      MemoFlowMigrationConfigType.locationSettings => tr.msg_location,
      MemoFlowMigrationConfigType.imageCompressionSettings =>
        tr.msg_restore_config_item_image_compression,
      MemoFlowMigrationConfigType.draftBox => context.tr(
        zh: '草稿箱',
        en: 'Draft box',
      ),
      MemoFlowMigrationConfigType.aiSettings => tr.msg_restore_config_item_ai,
      MemoFlowMigrationConfigType.imageBedSettings =>
        tr.msg_restore_config_item_image_bed,
      MemoFlowMigrationConfigType.appLock =>
        tr.msg_restore_config_item_app_lock,
      MemoFlowMigrationConfigType.webdavSettings =>
        tr.msg_restore_config_item_webdav,
    };
  }
}

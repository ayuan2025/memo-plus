import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_preferences.dart';
import '../../state/settings/workspace_preferences_provider.dart';
import '../../state/system/session_provider.dart';
import '../memos/home_quick_actions.dart';
import '../../i18n/strings.g.dart';
import 'settings_ui.dart';

class CustomizeHomeShortcutsScreen extends ConsumerWidget {
  const CustomizeHomeShortcutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(currentWorkspacePreferencesProvider);
    final hasAccount =
        ref.watch(appSessionProvider).valueOrNull?.currentAccount != null;
    final resolvedActions = resolveHomeQuickActions(
      rawPrimary: prefs.homeQuickActionPrimary,
      rawSecondary: prefs.homeQuickActionSecondary,
      rawTertiary: prefs.homeQuickActionTertiary,
      hasAccount: hasAccount,
    );

    final tokens = settingsPageTokens(context);
    final slotLabels = [
      context.t.strings.legacy.msg_quick_entry_slot_1,
      context.t.strings.legacy.msg_quick_entry_slot_2,
      context.t.strings.legacy.msg_quick_entry_slot_3,
    ];

    Future<void> pickAction(int index) async {
      final options = buildVisibleHomeQuickActions(hasAccount: hasAccount);
      final selected = await showDialog<HomeQuickAction>(
        context: context,
        builder: (dialogContext) {
          final colorScheme = Theme.of(dialogContext).colorScheme;
          return AlertDialog(
            backgroundColor: tokens.card,
            surfaceTintColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            contentPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: SettingsContentHeader(title: slotLabels[index]),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 420,
                maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.6,
              ),
              child: SingleChildScrollView(
                child: RadioGroup<HomeQuickAction>(
                  groupValue: resolvedActions[index],
                  onChanged: (value) {
                    Navigator.of(dialogContext).pop(value);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final action in options)
                        RadioListTile<HomeQuickAction>(
                          value: action,
                          enabled: !isHomeQuickActionUsedByOtherSlot(
                            action: action,
                            selectedActions: resolvedActions,
                            editingIndex: index,
                          ),
                          activeColor: colorScheme.primary,
                          secondary: Icon(
                            homeQuickActionIcon(action),
                            color: homeQuickActionIconColor(
                              action,
                              isDark: tokens.isDark,
                            ),
                          ),
                          title: Text(
                            homeQuickActionLabel(dialogContext, action),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
      if (selected == null || selected == resolvedActions[index]) {
        return;
      }

      final next = List<HomeQuickAction>.of(resolvedActions);
      next[index] = selected;
      ref
          .read(currentWorkspacePreferencesProvider.notifier)
          .setHomeQuickActions(
            primary: next[0],
            secondary: next[1],
            tertiary: next[2],
          );
    }

    return SettingsPage(
      title: Text(context.t.strings.legacy.msg_customize_quick_entries),
      children: [
        SettingsSection(
          children: [
            for (var index = 0; index < slotLabels.length; index++)
              _ActionRow(
                label: slotLabels[index],
                action: resolvedActions[index],
                tokens: tokens,
                onTap: () => pickAction(index),
              ),
          ],
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.label,
    required this.action,
    required this.tokens,
    required this.onTap,
  });

  final String label;
  final HomeQuickAction action;
  final SettingsPageTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final actionLabel = homeQuickActionLabel(context, action);
    final iconColor = homeQuickActionIconColor(action, isDark: tokens.isDark);

    return SettingsNavigationRow(
      leading: Icon(homeQuickActionIcon(action), color: iconColor, size: 20),
      label: label,
      value: actionLabel,
      onTap: onTap,
    );
  }
}

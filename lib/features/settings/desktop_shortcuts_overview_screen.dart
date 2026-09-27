import 'package:flutter/material.dart';

import '../../core/desktop/shortcuts.dart';
import '../../i18n/strings.g.dart';
import 'settings_ui.dart';

String _desktopShortcutActionLabel(
  BuildContext context,
  DesktopShortcutAction action,
) {
  switch (action) {
    case DesktopShortcutAction.search:
      return context.t.strings.legacy.msg_search;
    case DesktopShortcutAction.quickRecord:
      return context.t.strings.legacy.msg_quick_record;
    case DesktopShortcutAction.quickInput:
      return context.t.strings.legacy.msg_focus_input_area;
    case DesktopShortcutAction.toggleSidebar:
      return context.t.strings.legacy.msg_toggle_sidebar;
    case DesktopShortcutAction.refresh:
      return context.t.strings.legacy.msg_refresh;
    case DesktopShortcutAction.backHome:
      return context.t.strings.legacy.msg_back_home;
    case DesktopShortcutAction.openSettings:
      return context.t.strings.legacy.msg_open_settings;
    case DesktopShortcutAction.enableAppLock:
      return context.t.strings.legacy.msg_enable_app_lock;
    case DesktopShortcutAction.toggleFlomo:
      return context.t.strings.legacy.msg_show_hide_memoflow;
    case DesktopShortcutAction.shortcutOverview:
      return context.t.strings.legacy.msg_shortcuts_overview;
    case DesktopShortcutAction.previousPage:
      return context.t.strings.legacy.msg_previous_page;
    case DesktopShortcutAction.nextPage:
      return context.t.strings.legacy.msg_next_page;
    case DesktopShortcutAction.publishMemo:
      return context.t.strings.legacy.msg_publish_memo;
    case DesktopShortcutAction.bold:
      return context.t.strings.legacy.msg_bold;
    case DesktopShortcutAction.underline:
      return context.t.strings.legacy.msg_underline;
    case DesktopShortcutAction.highlight:
      return context.t.strings.legacy.msg_highlight;
    case DesktopShortcutAction.unorderedList:
      return context.t.strings.legacy.msg_unordered_list;
    case DesktopShortcutAction.orderedList:
      return context.t.strings.legacy.msg_ordered_list;
    case DesktopShortcutAction.undo:
      return context.t.strings.legacy.msg_undo;
    case DesktopShortcutAction.redo:
      return context.t.strings.legacy.msg_redo;
  }
}

class DesktopShortcutsOverviewScreen extends StatelessWidget {
  const DesktopShortcutsOverviewScreen({super.key, required this.bindings});

  final Map<DesktopShortcutAction, DesktopShortcutBinding> bindings;

  @override
  Widget build(BuildContext context) {
    final resolved = normalizeDesktopShortcutBindings(bindings);
    final tokens = settingsPageTokens(context);
    final textMain = tokens.textMain;
    final textMuted = tokens.textMuted;
    final primary = desktopPrimaryShortcutLabel();

    List<Widget> buildRows(List<({String action, String key})> items) {
      return [
        for (var i = 0; i < items.length; i++)
          _OverviewRow(
            action: items[i].action,
            shortcut: items[i].key,
            textMain: textMain,
            textMuted: textMuted,
          ),
      ];
    }

    final editorItems = <({String action, String key})>[
      (action: context.t.strings.legacy.msg_copy, key: '$primary + C'),
      (action: context.t.strings.legacy.msg_paste, key: '$primary + V'),
      (action: context.t.strings.legacy.msg_cut, key: '$primary + X'),
      for (final action in desktopShortcutEditorActions)
        (
          action: _desktopShortcutActionLabel(context, action),
          key: action == DesktopShortcutAction.publishMemo
              ? '${desktopShortcutBindingLabel(resolved[action]!)} / '
                    '${context.t.strings.legacy.msg_shift_enter_supported(binding: desktopShiftEnterShortcutLabel())}'
              : desktopShortcutBindingLabel(resolved[action]!),
        ),
    ];

    final globalItems = <({String action, String key})>[
      for (final action in desktopShortcutGlobalActionsForPlatform())
        (
          action: _desktopShortcutActionLabel(context, action),
          key: action == DesktopShortcutAction.shortcutOverview
              ? '${desktopShortcutBindingLabel(resolved[action]!)} / F1'
              : desktopShortcutBindingLabel(resolved[action]!),
        ),
    ];

    return SettingsPage(
      title: Text(context.t.strings.legacy.msg_shortcuts_overview),
      children: [
        SettingsInfoRow(
          description: context.t.strings.legacy.msg_action_shortcut,
        ),
        const SizedBox(height: 12),
        SettingsSection(
          header: SettingsSectionHeader(
            title: context.t.strings.legacy.msg_editor,
          ),
          children: buildRows(editorItems),
        ),
        const SizedBox(height: 12),
        SettingsSection(
          header: SettingsSectionHeader(
            title: context.t.strings.legacy.msg_global,
          ),
          children: buildRows(globalItems),
        ),
      ],
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({
    required this.action,
    required this.shortcut,
    required this.textMain,
    required this.textMuted,
  });

  final String action;
  final String shortcut;
  final Color textMain;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              action,
              style: TextStyle(fontWeight: FontWeight.w600, color: textMain),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 3,
            child: Text(
              shortcut,
              textAlign: TextAlign.end,
              style: TextStyle(fontWeight: FontWeight.w600, color: textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

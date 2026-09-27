import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/memoflow_palette.dart';
import '../../../i18n/strings.g.dart';
import '../../../state/memos/memos_list_providers.dart';
import '../../../state/settings/user_settings_provider.dart';

enum MemosListTitleMenuActionType {
  selectShortcut,
  clearShortcut,
  createShortcut,
  openAccountSwitcher,
}

class MemosListTitleMenuAction {
  const MemosListTitleMenuAction._(this.type, {this.shortcutId});

  const MemosListTitleMenuAction.selectShortcut(String id)
    : this._(MemosListTitleMenuActionType.selectShortcut, shortcutId: id);
  const MemosListTitleMenuAction.clearShortcut()
    : this._(MemosListTitleMenuActionType.clearShortcut);
  const MemosListTitleMenuAction.createShortcut()
    : this._(MemosListTitleMenuActionType.createShortcut);
  const MemosListTitleMenuAction.openAccountSwitcher()
    : this._(MemosListTitleMenuActionType.openAccountSwitcher);

  final MemosListTitleMenuActionType type;
  final String? shortcutId;
}

class DesktopWindowIconButton extends StatelessWidget {
  const DesktopWindowIconButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    this.destructive = false,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = destructive
        ? (isDark ? const Color(0xFFFFB4B4) : const Color(0xFFC62828))
        : (isDark ? MemoFlowPalette.textDark : MemoFlowPalette.textLight);
    final hoverColor = destructive
        ? const Color(0x33E53935)
        : (isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06));
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          hoverColor: hoverColor,
          onTap: onPressed,
          child: SizedBox(
            width: 38,
            height: 32,
            child: Icon(icon, size: 18, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class MemosListTitleMenuDropdown extends ConsumerWidget {
  const MemosListTitleMenuDropdown({
    super.key,
    required this.selectedShortcutId,
    required this.showShortcuts,
    required this.showAccountSwitcher,
    required this.maxHeight,
    required this.formatShortcutError,
  });

  final String? selectedShortcutId;
  final bool showShortcuts;
  final bool showAccountSwitcher;
  final double maxHeight;
  final String Function(BuildContext, Object) formatShortcutError;

  static const _shortcutIcons = [
    Icons.folder_outlined,
    Icons.lightbulb_outline,
    Icons.edit_note,
    Icons.bookmark_border,
    Icons.label_outline,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortcutHints = ref.watch(memosListShortcutHintsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? MemoFlowPalette.cardDark : MemoFlowPalette.cardLight;
    final border = isDark
        ? MemoFlowPalette.borderDark
        : MemoFlowPalette.borderLight;
    final textMain = isDark
        ? MemoFlowPalette.textDark
        : MemoFlowPalette.textLight;
    final textMuted = textMain.withValues(alpha: isDark ? 0.55 : 0.6);
    final dividerColor = border.withValues(alpha: 0.6);

    final shortcutsAsync = showShortcuts ? ref.watch(shortcutsProvider) : null;
    final canCreateShortcut = shortcutHints.canCreateShortcut;
    final items = <Widget>[];

    void addRow(Widget row) {
      if (items.isNotEmpty) {
        items.add(Divider(height: 1, color: dividerColor));
      }
      items.add(row);
    }

    if (showShortcuts && shortcutsAsync != null) {
      shortcutsAsync.when(
        data: (shortcuts) {
          final hasSelection =
              selectedShortcutId != null &&
              selectedShortcutId!.isNotEmpty &&
              shortcuts.any(
                (shortcut) => shortcut.shortcutId == selectedShortcutId,
              );
          addRow(
            MemosListTitleMenuItem(
              icon: Icons.note_outlined,
              label: context.t.strings.legacy.msg_all_memos_2,
              selected: !hasSelection,
              onTap: () => Navigator.of(
                context,
              ).pop(const MemosListTitleMenuAction.clearShortcut()),
            ),
          );

          if (shortcuts.isEmpty) {
            addRow(
              MemosListTitleMenuItem(
                icon: Icons.info_outline,
                label: context.t.strings.legacy.msg_no_shortcuts,
                enabled: false,
                textColor: textMuted,
                iconColor: textMuted,
              ),
            );
          } else {
            for (var index = 0; index < shortcuts.length; index++) {
              final shortcut = shortcuts[index];
              final label = shortcut.title.trim().isNotEmpty
                  ? shortcut.title.trim()
                  : context.t.strings.legacy.msg_untitled;
              addRow(
                MemosListTitleMenuItem(
                  icon: _shortcutIcons[index % _shortcutIcons.length],
                  label: label,
                  selected: shortcut.shortcutId == selectedShortcutId,
                  onTap: () => Navigator.of(context).pop(
                    MemosListTitleMenuAction.selectShortcut(
                      shortcut.shortcutId,
                    ),
                  ),
                ),
              );
            }
          }

          if (canCreateShortcut) {
            addRow(
              MemosListTitleMenuItem(
                icon: Icons.add_circle_outline,
                label: context.t.strings.legacy.msg_shortcut,
                accent: true,
                onTap: () => Navigator.of(
                  context,
                ).pop(const MemosListTitleMenuAction.createShortcut()),
              ),
            );
          }
        },
        loading: () {
          addRow(
            MemosListTitleMenuItem(
              icon: Icons.note_outlined,
              label: context.t.strings.legacy.msg_all_memos_2,
              selected:
                  selectedShortcutId == null || selectedShortcutId!.isEmpty,
              onTap: () => Navigator.of(
                context,
              ).pop(const MemosListTitleMenuAction.clearShortcut()),
            ),
          );
          addRow(
            MemosListTitleMenuItem(
              icon: Icons.hourglass_bottom,
              label: context.t.strings.legacy.msg_loading,
              enabled: false,
              textColor: textMuted,
              iconColor: textMuted,
            ),
          );
          if (canCreateShortcut) {
            addRow(
              MemosListTitleMenuItem(
                icon: Icons.add_circle_outline,
                label: context.t.strings.legacy.msg_shortcut,
                accent: true,
                onTap: () => Navigator.of(
                  context,
                ).pop(const MemosListTitleMenuAction.createShortcut()),
              ),
            );
          }
        },
        error: (error, _) {
          addRow(
            MemosListTitleMenuItem(
              icon: Icons.note_outlined,
              label: context.t.strings.legacy.msg_all_memos_2,
              selected:
                  selectedShortcutId == null || selectedShortcutId!.isEmpty,
              onTap: () => Navigator.of(
                context,
              ).pop(const MemosListTitleMenuAction.clearShortcut()),
            ),
          );
          addRow(
            MemosListTitleMenuItem(
              icon: Icons.info_outline,
              label: formatShortcutError(context, error),
              enabled: false,
              textColor: textMuted,
              iconColor: textMuted,
            ),
          );
          if (canCreateShortcut) {
            addRow(
              MemosListTitleMenuItem(
                icon: Icons.add_circle_outline,
                label: context.t.strings.legacy.msg_shortcut,
                accent: true,
                onTap: () => Navigator.of(
                  context,
                ).pop(const MemosListTitleMenuAction.createShortcut()),
              ),
            );
          }
        },
      );
    }

    if (showAccountSwitcher) {
      addRow(
        MemosListTitleMenuItem(
          icon: Icons.swap_horiz,
          label: context.t.strings.legacy.msg_switch_account,
          onTap: () => Navigator.of(
            context,
          ).pop(const MemosListTitleMenuAction.openAccountSwitcher()),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              offset: const Offset(0, 6),
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : 240.0;
                return SingleChildScrollView(
                  primary: false,
                  child: SizedBox(
                    width: width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: items,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class MemosListTitleMenuItem extends StatelessWidget {
  const MemosListTitleMenuItem({
    super.key,
    required this.icon,
    required this.label,
    this.selected = false,
    this.accent = false,
    this.enabled = true,
    this.onTap,
    this.textColor,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool accent;
  final bool enabled;
  final VoidCallback? onTap;
  final Color? textColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark
        ? MemoFlowPalette.textDark
        : MemoFlowPalette.textLight;
    final baseMuted = textMain.withValues(alpha: 0.6);
    final accentColor = MemoFlowPalette.primary;
    final labelColor =
        textColor ??
        (accent
            ? accentColor
            : selected
            ? textMain
            : baseMuted);
    final resolvedIconColor =
        iconColor ??
        (accent
            ? accentColor
            : selected
            ? accentColor
            : baseMuted);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: resolvedIconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check, size: 16, color: accentColor)
              else
                const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/memos/theme/memo_card_theme.dart';
import '../../state/settings/note_display_theme_settings_provider.dart';
import 'settings_ui.dart';

/// 外观主题设置：全局统一选择一套主题，应用于整个 App。
class NoteDisplayThemeSettingsScreen extends ConsumerWidget {
  const NoteDisplayThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(
      noteDisplayThemeSettingsProvider.select((value) => value.themeId),
    );

    return SettingsPage(
      title: const Text('外观主题'),
      children: [
        SettingsSection(
          header: const SettingsSectionHeader(title: '主题'),
          footer: const SettingsRowDescription(
            '所选主题应用于整个 App：列表、工具栏、对话框、笔记正文与编辑器。深色纸面的主题会让全 App 变成深色。',
          ),
          children: [
            for (final theme in kMemoCardThemes)
              SettingsSelectableItemRow(
                selected: theme.id == selectedId,
                title: theme.label,
                subtitle: _subtitle(theme),
                onTap: () => ref
                    .read(noteDisplayThemeSettingsProvider.notifier)
                    .setThemeId(theme.id),
                leading: _ThemePreviewSwatch(theme: theme),
              ),
          ],
        ),
      ],
    );
  }

  static String _subtitle(MemoCardTheme theme) =>
      theme.isDark ? '深色' : '浅色';
}

/// 主题预览：照 App 真实的层次画——底色打底、卡片浮在上面、强调色一点。
/// 只画一个纸面色块看不出浅色主题之间的差别，而那正是用户要挑的。
class _ThemePreviewSwatch extends StatelessWidget {
  const _ThemePreviewSwatch({required this.theme});

  final MemoCardTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: theme.appBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.border, width: 1.2),
      ),
      padding: const EdgeInsets.all(3),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.appCard,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: theme.accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

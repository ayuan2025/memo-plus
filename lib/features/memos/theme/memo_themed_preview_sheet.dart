import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../state/settings/note_display_theme_settings_provider.dart';
import 'memo_card_theme.dart';
import 'memo_theme_picker.dart';
import 'memo_themed_preview.dart';

/// 「美化预览」页：在编辑器与阅读页里就地预览一条内容的纸面卡片效果。
///
/// 与「分享卡片」页不同，这里**不导出图片**，只把当前主题实时渲染出来给人看，
/// 底部主题条选择后立即写回全局主题（[NoteDisplayThemeSettingsController.setThemeId]），
/// 因此编辑器和阅读页看到的是同一套外观。
///
/// - [content] 要预览的 Markdown 正文（编辑器传草稿，阅读页传笔记全文）。
/// - [time] 卡片上显示的时间。
/// - [allowPersist] 为 false 时只做本地上临时预览（不写全局主题）。
class MemoThemedPreviewSheet extends ConsumerStatefulWidget {
  const MemoThemedPreviewSheet({
    super.key,
    required this.content,
    required this.time,
    this.title = '美化预览',
    this.allowPersist = true,
  });

  final String content;
  final DateTime time;
  final String title;

  /// 是否把所选主题写回全局。临时预览传 false。
  final bool allowPersist;

  /// 打开预览页；返回所选主题（可能被临时改过）。
  static Future<MemoCardTheme?> show(
    BuildContext context, {
    required String content,
    required DateTime time,
    String title = '美化预览',
    bool allowPersist = true,
  }) {
    return Navigator.of(context).push<MemoCardTheme>(
      MaterialPageRoute<MemoCardTheme>(
        builder: (_) => MemoThemedPreviewSheet(
          content: content,
          time: time,
          title: title,
          allowPersist: allowPersist,
        ),
      ),
    );
  }

  @override
  ConsumerState<MemoThemedPreviewSheet> createState() =>
      _MemoThemedPreviewSheetState();
}

class _MemoThemedPreviewSheetState
    extends ConsumerState<MemoThemedPreviewSheet> {
  /// 用户在本页临时改选的主题；为空时跟随全局。
  MemoCardTheme? _override;

  @override
  Widget build(BuildContext context) {
    final globalTheme = ref.watch(selectedMemoCardThemeProvider);
    final theme = _override ?? globalTheme;
    final hasContent = widget.content.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          if (hasContent && widget.allowPersist)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '当前主题：${theme.label}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: hasContent
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: MemoThemedPreview(
                        content: widget.content,
                        time: widget.time,
                        theme: theme,
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      '还没有内容可预览',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
          ),
          SafeArea(
            top: false,
            child: MemoThemePickerStrip(
              current: theme,
              onSelected: (next) {
                setState(() => _override = next);
                if (widget.allowPersist) {
                  // 写回全局，编辑器/阅读页与导出卡片保持同一外观。
                  ref
                      .read(noteDisplayThemeSettingsProvider.notifier)
                      .setThemeId(next.id);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
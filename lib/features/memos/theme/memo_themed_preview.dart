import 'package:flutter/material.dart';

import 'memo_card_theme.dart';
import 'memo_share_card.dart';

/// 「美化预览」：把一段纯文本按卡片主题渲染成纸面卡片，供编辑器与阅读页内嵌预览。
///
/// 与导出图片用的 [MemoShareCard] 共用同一套排版/配色（[MemoCardPaper]），
/// 但这里只需要**内容 + 时间**，不要求先有落库的笔记——编辑器里的草稿也能直接预览。
/// 导出仍走 `MemoShareCard` + `captureWidgetPng`。
///
/// 卡片顶部只显示日期时间，**不显示标题**（正文首行不再被抽出来重复展示）。
class MemoThemedPreview extends StatelessWidget {
  const MemoThemedPreview({
    super.key,
    required this.content,
    required this.time,
    required this.theme,
    this.width = 360,
    this.showFooter = true,
  });

  /// 卡片正文（Markdown 源文本）。
  final String content;

  /// 卡片上显示的时间；编辑器可传当前时间，阅读页传笔记时间。
  final DateTime time;

  /// 卡片主题（[kMemoCardThemes] 之一）。
  final MemoCardTheme theme;

  /// 卡片宽度（逻辑像素）。
  final double width;

  /// 是否显示底部品牌页脚。
  final bool showFooter;

  @override
  Widget build(BuildContext context) {
    return MemoCardPaper(
      timeText: formatCardTime(time),
      body: content,
      theme: theme,
      width: width,
      showFooter: showFooter,
    );
  }
}
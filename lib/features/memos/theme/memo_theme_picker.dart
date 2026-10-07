import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'memo_card_theme.dart';

/// 横向卡片主题选择条：点一颗 chip 即切换纸面主题。
///
/// 分享卡片页、编辑器预览、阅读页预览共用这一个组件，保证三处选择器行为一致。
class MemoThemePickerStrip extends StatelessWidget {
  const MemoThemePickerStrip({
    super.key,
    required this.current,
    required this.onSelected,
    this.height = 52,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  /// 当前选中的主题。
  final MemoCardTheme current;

  /// 选中主题后的回调。
  final ValueChanged<MemoCardTheme> onSelected;

  final double height;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: kMemoCardThemes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final theme = kMemoCardThemes[index];
          final selected = identical(theme, current);
          return ChoiceChip(
            label: Text(theme.label),
            selected: selected,
            showCheckmark: false,
            onSelected: (_) {
              HapticFeedback.selectionClick();
              onSelected(theme);
            },
          );
        },
      ),
    );
  }
}
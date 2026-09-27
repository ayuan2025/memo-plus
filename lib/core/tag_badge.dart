import 'package:flutter/material.dart';

import 'memoflow_palette.dart';
import 'tag_colors.dart';

class TagBadge extends StatelessWidget {
  const TagBadge({
    super.key,
    required this.label,
    this.colors,
    this.compact = false,
  });

  final String label;
  final TagChipColors? colors;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        colors?.background ??
        (isDark ? MemoFlowPalette.cardDark : MemoFlowPalette.cardLight);
    final border =
        colors?.border ??
        (isDark
            ? MemoFlowPalette.borderDark.withValues(alpha: 0.7)
            : MemoFlowPalette.borderLight);
    final text =
        colors?.text ??
        (isDark ? MemoFlowPalette.textDark : MemoFlowPalette.textLight);
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 6);
    final fontSize = compact ? 11.5 : 12.0;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }
}

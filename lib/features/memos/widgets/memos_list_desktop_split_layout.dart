import 'package:flutter/material.dart';

import '../../../core/app_motion.dart';
import '../../../core/platform_layout.dart';

const Key memosListDesktopSplitLayoutKey = ValueKey<String>(
  'memos-list-desktop-split-layout',
);
const Key memosListDesktopPreviewPaneSlotKey = ValueKey<String>(
  'memos-list-desktop-preview-pane-slot',
);

class MemosListDesktopSplitLayout extends StatelessWidget {
  const MemosListDesktopSplitLayout({
    super.key = memosListDesktopSplitLayoutKey,
    required this.drawerPanel,
    required this.body,
    this.previewPane,
    this.previewVisible = false,
    this.previewPaneWidth = kMemoFlowDesktopPreviewPaneWidth,
  });

  final Widget drawerPanel;
  final Widget body;
  final Widget? previewPane;
  final bool previewVisible;
  final double previewPaneWidth;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);
    final showPreview = previewVisible && previewPane != null;
    final previewPaneDuration = AppMotion.effectiveDuration(
      context,
      showPreview ? AppMotion.desktopContent : AppMotion.desktopOverlayExit,
    );

    return Row(
      children: [
        SizedBox(width: kMemoFlowDesktopDrawerWidth, child: drawerPanel),
        VerticalDivider(width: 1, thickness: 1, color: dividerColor),
        Expanded(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: showPreview ? kMemoFlowDesktopPreviewListMinWidth : 0,
            ),
            child: body,
          ),
        ),
        AnimatedContainer(
          duration: previewPaneDuration,
          curve: AppMotion.standardCurve,
          width: showPreview ? 1 : 0,
          child: ColoredBox(color: dividerColor),
        ),
        AnimatedContainer(
          key: memosListDesktopPreviewPaneSlotKey,
          duration: previewPaneDuration,
          curve: AppMotion.emphasizedEnterCurve,
          width: showPreview ? previewPaneWidth : 0,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: previewPaneWidth,
              maxWidth: previewPaneWidth,
              child: SizedBox(
                width: previewPaneWidth,
                child: AnimatedOpacity(
                  duration: previewPaneDuration,
                  curve: AppMotion.emphasizedEnterCurve,
                  opacity: showPreview ? 1 : 0,
                  child: AnimatedSlide(
                    duration: previewPaneDuration,
                    curve: AppMotion.emphasizedEnterCurve,
                    offset: showPreview ? Offset.zero : const Offset(0.04, 0),
                    child: AnimatedScale(
                      duration: previewPaneDuration,
                      curve: AppMotion.emphasizedEnterCurve,
                      scale: showPreview ? 1 : 0.985,
                      alignment: Alignment.centerLeft,
                      child: previewPane ?? const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

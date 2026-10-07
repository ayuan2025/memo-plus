import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/memoflow_palette.dart';
import '../../../i18n/strings.g.dart';
import '../compose_toolbar_shared.dart';

class MemoComposeFullscreenSurface extends StatelessWidget {
  const MemoComposeFullscreenSurface({
    super.key,
    required this.isDark,
    required this.sheetColor,
    required this.toolbarPreferences,
    required this.toolbarActions,
    required this.metadataChildren,
    required this.editor,
    required this.primaryAction,
    required this.closeKey,
    required this.toolbarRowKey,
    required this.visibilityButtonKey,
    required this.visibilityLabel,
    required this.visibilityIcon,
    required this.visibilityColor,
    required this.busy,
    required this.onClose,
    required this.onVisibilityPressed,
    this.expandCollapseKey,
    this.onCollapse,
    this.trailingAction,
  });

  final bool isDark;
  final Color sheetColor;
  final MemoToolbarPreferences toolbarPreferences;
  final List<MemoComposeToolbarActionSpec> toolbarActions;
  final List<Widget> metadataChildren;
  final Widget editor;
  final Widget primaryAction;
  /// 收起（还原窗口）键。为 null 时头部不渲染收起按钮——
  /// 编辑页已全局使用全屏界面，没有可回退的普通模式。
  final Key? expandCollapseKey;
  final Key closeKey;
  final Key toolbarRowKey;
  final GlobalKey visibilityButtonKey;
  final String visibilityLabel;
  final IconData visibilityIcon;
  final Color visibilityColor;
  final bool busy;
  final VoidCallback? onCollapse;
  final VoidCallback onClose;
  final VoidCallback onVisibilityPressed;

  /// 头部右侧常驻动作按钮（当前用于编辑器「美化预览」）。透传给头部。
  final Widget? trailingAction;

  @override
  Widget build(BuildContext context) {
    final background = isDark
        ? MemoFlowPalette.backgroundDark
        : MemoFlowPalette.backgroundLight;
    final borderColor = isDark
        ? MemoFlowPalette.borderDark
        : MemoFlowPalette.borderLight;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isDark ? 4 : 2,
          sigmaY: isDark ? 4 : 2,
        ),
        child: ColoredBox(
          color: background.withValues(alpha: 0.96),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Container(
                color: sheetColor,
                child: Column(
                  children: [
                    MemoComposeFullscreenHeader(
                      isDark: isDark,
                      sheetColor: sheetColor,
                      collapseKey: expandCollapseKey,
                      closeKey: closeKey,
                      busy: busy,
                      onCollapse: onCollapse,
                      onClose: onClose,
                      trailingAction: trailingAction,
                    ),
                    Divider(height: 1, color: borderColor),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...metadataChildren,
                            Expanded(child: editor),
                          ],
                        ),
                      ),
                    ),
                    Divider(height: 1, color: borderColor),
                    MemoComposeFullscreenBottomToolbar(
                      isDark: isDark,
                      sheetColor: sheetColor,
                      preferences: toolbarPreferences,
                      actions: toolbarActions,
                      toolbarRowKey: toolbarRowKey,
                      visibilityLabel: visibilityLabel,
                      visibilityIcon: visibilityIcon,
                      visibilityColor: visibilityColor,
                      visibilityButtonKey: visibilityButtonKey,
                      busy: busy,
                      primaryAction: primaryAction,
                      onVisibilityPressed: onVisibilityPressed,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MemoComposeFullscreenHeader extends StatelessWidget {
  const MemoComposeFullscreenHeader({
    super.key,
    required this.isDark,
    required this.sheetColor,
    required this.closeKey,
    required this.busy,
    required this.onClose,
    this.collapseKey,
    this.onCollapse,
    this.trailingAction,
  });

  final bool isDark;
  final Color sheetColor;
  final Key? collapseKey;
  final Key closeKey;
  final bool busy;
  final VoidCallback? onCollapse;
  final VoidCallback onClose;

  /// 头部右侧的自定义动作按钮（渲染在收起键之前）。为 null 时不渲染。
  /// 用于「美化预览」这类不属于可自定义工具栏的常驻入口。
  final Widget? trailingAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
      color: sheetColor,
      child: Row(
        children: [
          IconButton(
            key: closeKey,
            tooltip: context.t.strings.legacy.msg_close,
            onPressed: busy ? null : onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            splashRadius: 16,
            icon: Icon(
              Icons.close_rounded,
              size: 20,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const Spacer(),
          if (trailingAction != null) trailingAction!,
          // 收起按钮仅在存在回退目标时渲染（记一笔可收回底部面板；
          // 编辑页没有普通模式，保持右侧只有一个占位空隙）。
          if (onCollapse != null)
            IconButton(
              key: collapseKey,
              tooltip: context.t.strings.legacy.msg_restore_window,
              onPressed: busy ? null : onCollapse,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              splashRadius: 16,
              icon: Icon(
                Icons.fullscreen_exit_rounded,
                size: 20,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
        ],
      ),
    );
  }
}

class MemoComposeFullscreenBottomToolbar extends StatelessWidget {
  const MemoComposeFullscreenBottomToolbar({
    super.key,
    required this.isDark,
    required this.sheetColor,
    required this.preferences,
    required this.actions,
    required this.toolbarRowKey,
    required this.visibilityLabel,
    required this.visibilityIcon,
    required this.visibilityColor,
    required this.visibilityButtonKey,
    required this.busy,
    required this.primaryAction,
    required this.onVisibilityPressed,
  });

  final bool isDark;
  final Color sheetColor;
  final MemoToolbarPreferences preferences;
  final List<MemoComposeToolbarActionSpec> actions;
  /// 键区所在行的 key。原先 top/bottom 各有一个 key；合并成单行后只留这一个，
  /// 供测试断言工具栏位于输入框下方。
  final Key toolbarRowKey;
  final String visibilityLabel;
  final IconData visibilityIcon;
  final Color visibilityColor;
  final GlobalKey visibilityButtonKey;
  final bool busy;
  final Widget primaryAction;
  final VoidCallback onVisibilityPressed;

  @override
  Widget build(BuildContext context) {
    // 一行放不下全部键时，这行可以横向滚动；键数超出手宽时不会挤压编辑区高度。
    final rowActions = <MemoComposeToolbarActionSpec>[
      ..._visibleToolbarActionsForRow(
        preferences: preferences,
        actions: actions,
        row: MemoToolbarRow.top,
      ),
      ..._visibleToolbarActionsForRow(
        preferences: preferences,
        actions: actions,
        row: MemoToolbarRow.bottom,
      ),
    ];

    return Container(
      // 压缩后的单行高度：2 + 28(键) + 2 = 32（v1.0.58 为 4+30+4=38），
      // 给正文再让出 6px。
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
      color: sheetColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 键区可横向滚动：默认布局 6 个键在窄屏上也能保持单行，编辑区因此
          // 始终拿到剩余的全部高度（原先上下两行 + 右侧竖排按钮共占三行）。
          Expanded(
            child: SingleChildScrollView(
              key: toolbarRowKey,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < rowActions.length; i++) ...[
                    if (i != 0) const SizedBox(width: 2),
                    _FullscreenToolbarActionButton(
                      isDark: isDark,
                      action: rowActions[i],
                      preferences: preferences,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          // 可见性开关与主操作也并入这一行右侧，不再另起一行。
          MemoComposeFullscreenVisibilityButton(
            isDark: isDark,
            visibilityLabel: visibilityLabel,
            visibilityIcon: visibilityIcon,
            visibilityColor: visibilityColor,
            visibilityButtonKey: visibilityButtonKey,
            busy: busy,
            onPressed: onVisibilityPressed,
          ),
          const SizedBox(width: 6),
          primaryAction,
        ],
      ),
    );
  }
}

class _FullscreenToolbarActionButton extends StatelessWidget {
  const _FullscreenToolbarActionButton({
    required this.isDark,
    required this.action,
    required this.preferences,
  });

  final bool isDark;
  final MemoComposeToolbarActionSpec action;
  final MemoToolbarPreferences preferences;

  @override
  Widget build(BuildContext context) {
    final iconColor = isDark ? Colors.white70 : Colors.black54;
    final tooltip = action.label ?? action.id.resolveLabel(context, preferences);
    final actionIcon = action.icon ?? action.id.resolveIcon(preferences);
    return IconButton(
      key: action.buttonKey,
      tooltip: tooltip,
      onPressed: action.enabled ? action.onPressed : null,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      splashRadius: 14,
      icon: Icon(
        actionIcon,
        size: 17,
        color: action.enabled
            ? iconColor
            : iconColor.withValues(alpha: 0.45),
      ),
    );
  }
}

class MemoComposeFullscreenVisibilityButton extends StatelessWidget {
  const MemoComposeFullscreenVisibilityButton({
    super.key,
    required this.isDark,
    required this.visibilityLabel,
    required this.visibilityIcon,
    required this.visibilityColor,
    required this.visibilityButtonKey,
    required this.busy,
    required this.onPressed,
  });

  final bool isDark;
  final String visibilityLabel;
  final IconData visibilityIcon;
  final Color visibilityColor;
  final GlobalKey visibilityButtonKey;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.t.strings.legacy.msg_visibility_2(
        visibilityLabel: visibilityLabel,
      ),
      child: InkResponse(
        key: visibilityButtonKey,
        onTap: busy ? null : onPressed,
        radius: 14,
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(visibilityIcon, size: 16, color: visibilityColor),
        ),
      ),
    );
  }
}

List<MemoComposeToolbarActionSpec> _visibleToolbarActionsForRow({
  required MemoToolbarPreferences preferences,
  required List<MemoComposeToolbarActionSpec> actions,
  required MemoToolbarRow row,
}) {
  final actionMap = <MemoToolbarItemId, MemoComposeToolbarActionSpec>{
    for (final action in actions) action.id: action,
  };
  final supportedItems = actions
      .where((action) => action.supported)
      .map((action) => action.id)
      .toSet();
  return preferences
      .visibleItemIdsForRow(row, supportedItems: supportedItems)
      .map((id) => actionMap[id])
      .whereType<MemoComposeToolbarActionSpec>()
      .toList(growable: false);
}

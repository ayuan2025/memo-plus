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
    required this.expandCollapseKey,
    required this.closeKey,
    required this.topToolbarKey,
    required this.bottomToolbarKey,
    required this.visibilityButtonKey,
    required this.visibilityLabel,
    required this.visibilityIcon,
    required this.visibilityColor,
    required this.busy,
    required this.onCollapse,
    required this.onClose,
    required this.onVisibilityPressed,
  });

  final bool isDark;
  final Color sheetColor;
  final MemoToolbarPreferences toolbarPreferences;
  final List<MemoComposeToolbarActionSpec> toolbarActions;
  final List<Widget> metadataChildren;
  final Widget editor;
  final Widget primaryAction;
  final Key expandCollapseKey;
  final Key closeKey;
  final Key topToolbarKey;
  final Key bottomToolbarKey;
  final GlobalKey visibilityButtonKey;
  final String visibilityLabel;
  final IconData visibilityIcon;
  final Color visibilityColor;
  final bool busy;
  final VoidCallback onCollapse;
  final VoidCallback onClose;
  final VoidCallback onVisibilityPressed;

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
                      topRowKey: topToolbarKey,
                      bottomRowKey: bottomToolbarKey,
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
    required this.collapseKey,
    required this.closeKey,
    required this.busy,
    required this.onCollapse,
    required this.onClose,
  });

  final bool isDark;
  final Color sheetColor;
  final Key collapseKey;
  final Key closeKey;
  final bool busy;
  final VoidCallback onCollapse;
  final VoidCallback onClose;

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
    required this.topRowKey,
    required this.bottomRowKey,
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
  final Key topRowKey;
  final Key bottomRowKey;
  final String visibilityLabel;
  final IconData visibilityIcon;
  final Color visibilityColor;
  final GlobalKey visibilityButtonKey;
  final bool busy;
  final Widget primaryAction;
  final VoidCallback onVisibilityPressed;

  @override
  Widget build(BuildContext context) {
    final hasTopActions = _hasVisibleToolbarActionsForRow(
      preferences: preferences,
      actions: actions,
      row: MemoToolbarRow.top,
    );
    final hasBottomActions = _hasVisibleToolbarActionsForRow(
      preferences: preferences,
      actions: actions,
      row: MemoToolbarRow.bottom,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      color: sheetColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasTopActions)
                  MemoComposeFullscreenToolbarStrip(
                    isDark: isDark,
                    preferences: preferences,
                    actions: actions,
                    row: MemoToolbarRow.top,
                    rowKey: topRowKey,
                  ),
                if (hasTopActions && hasBottomActions)
                  const SizedBox(height: 2),
                if (hasBottomActions)
                  MemoComposeFullscreenToolbarStrip(
                    isDark: isDark,
                    preferences: preferences,
                    actions: actions,
                    row: MemoToolbarRow.bottom,
                    rowKey: bottomRowKey,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MemoComposeFullscreenVisibilityButton(
                isDark: isDark,
                visibilityLabel: visibilityLabel,
                visibilityIcon: visibilityIcon,
                visibilityColor: visibilityColor,
                visibilityButtonKey: visibilityButtonKey,
                busy: busy,
                onPressed: onVisibilityPressed,
              ),
              const SizedBox(height: 2),
              primaryAction,
            ],
          ),
        ],
      ),
    );
  }
}

class MemoComposeFullscreenToolbarStrip extends StatelessWidget {
  const MemoComposeFullscreenToolbarStrip({
    super.key,
    required this.isDark,
    required this.preferences,
    required this.actions,
    required this.row,
    required this.rowKey,
  });

  final bool isDark;
  final MemoToolbarPreferences preferences;
  final List<MemoComposeToolbarActionSpec> actions;
  final MemoToolbarRow row;
  final Key rowKey;

  @override
  Widget build(BuildContext context) {
    final rowActions = _visibleToolbarActionsForRow(
      preferences: preferences,
      actions: actions,
      row: row,
    );
    if (rowActions.isEmpty) {
      return const SizedBox.shrink();
    }

    final iconColor = isDark ? Colors.white70 : Colors.black54;
    final disabledColor = iconColor.withValues(alpha: 0.45);

    Widget buildActionButton(MemoComposeToolbarActionSpec action) {
      final tooltip =
          action.label ?? action.id.resolveLabel(context, preferences);
      final actionIcon = action.icon ?? action.id.resolveIcon(preferences);
      return IconButton(
        key: action.buttonKey,
        tooltip: tooltip,
        onPressed: action.enabled ? action.onPressed : null,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 30, height: 30),
        splashRadius: 16,
        icon: Icon(
          actionIcon,
          size: 18,
          color: action.enabled ? iconColor : disabledColor,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        key: rowKey,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rowActions.length; i++) ...[
            buildActionButton(rowActions[i]),
            if (i != rowActions.length - 1) const SizedBox(width: 2),
          ],
        ],
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
        radius: 17,
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(visibilityIcon, size: 16, color: visibilityColor),
        ),
      ),
    );
  }
}

bool _hasVisibleToolbarActionsForRow({
  required MemoToolbarPreferences preferences,
  required List<MemoComposeToolbarActionSpec> actions,
  required MemoToolbarRow row,
}) {
  return _visibleToolbarActionsForRow(
    preferences: preferences,
    actions: actions,
    row: row,
  ).isNotEmpty;
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

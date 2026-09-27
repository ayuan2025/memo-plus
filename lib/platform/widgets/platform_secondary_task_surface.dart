import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../platform_target.dart';

enum PlatformSecondaryTaskSurfaceSize { standard, large }

bool shouldUsePlatformSecondaryTaskSurface(BuildContext context) {
  if (kIsWeb) return false;
  final target = resolvePlatformTarget(context);
  return target == PlatformTarget.macOS ||
      target == PlatformTarget.windows ||
      target == PlatformTarget.linux;
}

Future<T?> showPlatformSecondaryTaskSurface<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  PlatformSecondaryTaskSurfaceSize size =
      PlatformSecondaryTaskSurfaceSize.large,
  double? maxWidth,
  double? maxHeightFactor,
  EdgeInsets insetPadding = const EdgeInsets.symmetric(
    horizontal: 32,
    vertical: 24,
  ),
  bool barrierDismissible = false,
  bool useRootNavigator = false,
  Color? backgroundColor,
  ShapeBorder? shape,
}) {
  final resolvedMaxWidth =
      maxWidth ??
      switch (size) {
        PlatformSecondaryTaskSurfaceSize.standard => 640.0,
        PlatformSecondaryTaskSurfaceSize.large => 860.0,
      };
  final resolvedMaxHeightFactor =
      maxHeightFactor ??
      switch (size) {
        PlatformSecondaryTaskSurfaceSize.standard => 0.82,
        PlatformSecondaryTaskSurfaceSize.large => 0.88,
      };

  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    useRootNavigator: useRootNavigator,
    builder: (dialogContext) {
      return Dialog(
        key: const ValueKey<String>('platform-secondary-task-surface-dialog'),
        insetPadding: insetPadding,
        backgroundColor:
            backgroundColor ?? Theme.of(dialogContext).colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        shape:
            shape ??
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: resolvedMaxWidth,
            maxHeight:
                MediaQuery.sizeOf(dialogContext).height *
                resolvedMaxHeightFactor,
          ),
          child: builder(dialogContext),
        ),
      );
    },
  );
}

class PlatformSecondaryTaskFrame extends StatelessWidget {
  const PlatformSecondaryTaskFrame({
    super.key,
    required this.title,
    required this.body,
    this.actions = const <Widget>[],
    this.bottomBar,
    this.onClose,
    this.closeTooltip,
    this.backgroundColor,
  });

  final Widget title;
  final Widget body;
  final List<Widget> actions;
  final Widget? bottomBar;
  final VoidCallback? onClose;
  final String? closeTooltip;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final resolvedBackground = backgroundColor ?? colors.surface;

    return Material(
      color: resolvedBackground,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: DefaultTextStyle(
                      style:
                          theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colors.onSurface,
                          ) ??
                          TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: colors.onSurface,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child: title,
                    ),
                  ),
                  for (final action in actions) action,
                  IconButton(
                    tooltip:
                        closeTooltip ??
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed:
                        onClose ?? () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.outlineVariant),
            Flexible(child: body),
            if (bottomBar != null) bottomBar!,
          ],
        ),
      ),
    );
  }
}

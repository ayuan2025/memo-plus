import 'package:flutter/material.dart';

import 'platform_popover_or_sheet.dart';

Future<T?> showPlatformActionSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool useSafeArea = true,
  Color? backgroundColor,
  Color? barrierColor,
  bool showDragHandle = true,
  bool barrierDismissible = true,
  String? barrierLabel,
  double desktopMaxWidth = 420,
  EdgeInsets desktopInsetPadding = const EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 24,
  ),
}) {
  return showPlatformPopoverOrSheet<T>(
    context: context,
    builder: builder,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    backgroundColor: backgroundColor,
    barrierColor: barrierColor,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    showDragHandle: showDragHandle,
    desktopMaxWidth: desktopMaxWidth,
    desktopInsetPadding: desktopInsetPadding,
  );
}

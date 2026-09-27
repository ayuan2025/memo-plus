import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../platform_target.dart';

Future<T?> showPlatformPopoverOrSheet<T>({
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
  final target = resolvePlatformTarget(context);
  if (target == PlatformTarget.iPhone || target == PlatformTarget.iPad) {
    return showCupertinoModalPopup<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? kCupertinoModalBarrierColor,
      builder: (context) =>
          Material(type: MaterialType.transparency, child: builder(context)),
    );
  }

  if (target == PlatformTarget.macOS ||
      target == PlatformTarget.windows ||
      target == PlatformTarget.linux) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      barrierColor: barrierColor,
      useSafeArea: useSafeArea,
      builder: (dialogContext) => Dialog(
        backgroundColor: backgroundColor,
        insetPadding: desktopInsetPadding,
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: desktopMaxWidth),
          child: builder(dialogContext),
        ),
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    backgroundColor: backgroundColor,
    barrierColor: barrierColor,
    barrierLabel: barrierLabel,
    showDragHandle: showDragHandle,
    isDismissible: barrierDismissible,
    builder: builder,
  );
}

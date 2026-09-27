import 'package:flutter/material.dart';

import 'platform_popover_or_sheet.dart';

enum PlatformPickerPresentation { platformDefault, centeredDialog }

Future<T?> showPlatformPicker<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double desktopMaxWidth = 420,
  PlatformPickerPresentation presentation =
      PlatformPickerPresentation.platformDefault,
  double centeredMaxHeightFactor = 0.72,
}) {
  if (presentation == PlatformPickerPresentation.centeredDialog) {
    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final media = MediaQuery.sizeOf(dialogContext);
        final maxHeight = media.height * centeredMaxHeightFactor;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: desktopMaxWidth,
              maxHeight: maxHeight,
            ),
            child: builder(dialogContext),
          ),
        );
      },
    );
  }

  return showPlatformPopoverOrSheet<T>(
    context: context,
    builder: builder,
    desktopMaxWidth: desktopMaxWidth,
  );
}

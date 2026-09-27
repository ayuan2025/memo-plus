import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../platform_target.dart';

enum PlatformPrimaryActionVariant { filled, tonal, outlined, text }

class PlatformPrimaryAction extends StatelessWidget {
  const PlatformPrimaryAction({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.variant = PlatformPrimaryActionVariant.filled,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.desktopAlignment = AlignmentDirectional.centerEnd,
    this.desktopMinWidth = 112,
    this.desktopMaxWidth = 320,
    this.narrowDesktopBreakpoint = 520,
    this.expandOnMobile = true,
    this.expandOnNarrowDesktop = true,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final PlatformPrimaryActionVariant variant;
  final ButtonStyle? style;
  final FocusNode? focusNode;
  final bool autofocus;
  final AlignmentGeometry desktopAlignment;
  final double desktopMinWidth;
  final double desktopMaxWidth;
  final double narrowDesktopBreakpoint;
  final bool expandOnMobile;
  final bool expandOnNarrowDesktop;

  @override
  Widget build(BuildContext context) {
    final target = resolvePlatformTarget(context);
    final isDesktop =
        target == PlatformTarget.macOS ||
        target == PlatformTarget.windows ||
        target == PlatformTarget.linux;
    final button = _buildButton();

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedWidth = constraints.hasBoundedWidth;
        final shouldExpand =
            (!isDesktop && expandOnMobile) ||
            (isDesktop &&
                expandOnNarrowDesktop &&
                hasBoundedWidth &&
                constraints.maxWidth < narrowDesktopBreakpoint);

        if (shouldExpand && hasBoundedWidth) {
          return SizedBox(width: double.infinity, child: button);
        }

        if (!isDesktop) {
          return button;
        }

        final resolvedMaxWidth = math.max(desktopMinWidth, desktopMaxWidth);
        final maxWidth = hasBoundedWidth
            ? math.min(resolvedMaxWidth, constraints.maxWidth)
            : resolvedMaxWidth;
        final minWidth = math.min(desktopMinWidth, maxWidth);

        return Align(
          alignment: desktopAlignment,
          widthFactor: hasBoundedWidth ? null : 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: minWidth, maxWidth: maxWidth),
            child: button,
          ),
        );
      },
    );
  }

  Widget _buildButton() {
    return switch (variant) {
      PlatformPrimaryActionVariant.filled =>
        icon == null
            ? FilledButton(
                onPressed: onPressed,
                style: style,
                focusNode: focusNode,
                autofocus: autofocus,
                child: child,
              )
            : FilledButton.icon(
                onPressed: onPressed,
                style: style,
                focusNode: focusNode,
                autofocus: autofocus,
                icon: icon!,
                label: child,
              ),
      PlatformPrimaryActionVariant.tonal =>
        icon == null
            ? FilledButton.tonal(
                onPressed: onPressed,
                style: style,
                focusNode: focusNode,
                autofocus: autofocus,
                child: child,
              )
            : FilledButton.tonalIcon(
                onPressed: onPressed,
                style: style,
                focusNode: focusNode,
                autofocus: autofocus,
                icon: icon!,
                label: child,
              ),
      PlatformPrimaryActionVariant.outlined =>
        icon == null
            ? OutlinedButton(
                onPressed: onPressed,
                style: style,
                focusNode: focusNode,
                autofocus: autofocus,
                child: child,
              )
            : OutlinedButton.icon(
                onPressed: onPressed,
                style: style,
                focusNode: focusNode,
                autofocus: autofocus,
                icon: icon!,
                label: child,
              ),
      PlatformPrimaryActionVariant.text =>
        icon == null
            ? TextButton(
                onPressed: onPressed,
                style: style,
                focusNode: focusNode,
                autofocus: autofocus,
                child: child,
              )
            : TextButton.icon(
                onPressed: onPressed,
                style: style,
                focusNode: focusNode,
                autofocus: autofocus,
                icon: icon!,
                label: child,
              ),
    };
  }
}

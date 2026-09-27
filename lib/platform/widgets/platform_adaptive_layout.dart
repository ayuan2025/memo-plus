import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../platform_target.dart';

class PlatformBoundedContent extends StatelessWidget {
  const PlatformBoundedContent({
    super.key,
    required this.child,
    this.desktopMaxWidth = 980,
    this.tabletMaxWidth = 760,
    this.padding,
    this.alignment = Alignment.topCenter,
    this.expandOnMobile = true,
  });

  final Widget child;
  final double desktopMaxWidth;
  final double tabletMaxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;
  final bool expandOnMobile;

  @override
  Widget build(BuildContext context) {
    final target = resolvePlatformTarget(context);
    final maxWidth = switch (target) {
      PlatformTarget.macOS ||
      PlatformTarget.windows ||
      PlatformTarget.linux => desktopMaxWidth,
      PlatformTarget.iPad => tabletMaxWidth,
      _ => null,
    };
    final padded = Padding(padding: padding ?? EdgeInsets.zero, child: child);

    if (maxWidth == null) {
      return expandOnMobile
          ? SizedBox(width: double.infinity, child: padded)
          : padded;
    }

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padded,
      ),
    );
  }
}

class PlatformMasterDetail extends StatelessWidget {
  const PlatformMasterDetail({
    super.key,
    required this.master,
    this.detail,
    this.emptyDetail,
    this.forceDetailVisible,
    this.breakpoint = 1100,
    this.detailWidth = 420,
    this.minMasterWidth = 360,
    this.divider,
  });

  final Widget master;
  final Widget? detail;
  final Widget? emptyDetail;
  final bool? forceDetailVisible;
  final double breakpoint;
  final double detailWidth;
  final double minMasterWidth;
  final Widget? divider;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final target = resolvePlatformTarget(context);
        final isDesktop =
            target == PlatformTarget.macOS ||
            target == PlatformTarget.windows ||
            target == PlatformTarget.linux;
        final availableWidth = constraints.maxWidth;
        final canShowDetail =
            isDesktop &&
            availableWidth.isFinite &&
            availableWidth >= breakpoint &&
            availableWidth - detailWidth >= minMasterWidth;
        final showDetail = forceDetailVisible ?? canShowDetail;

        if (!showDetail) {
          return master;
        }

        final resolvedDetailWidth = math.min(
          detailWidth,
          math.max(0.0, availableWidth - minMasterWidth),
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: master),
            divider ?? const VerticalDivider(width: 1),
            SizedBox(
              width: resolvedDetailWidth,
              child: detail ?? emptyDetail ?? const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}

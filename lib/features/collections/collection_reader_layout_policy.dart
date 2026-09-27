import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/desktop/window_chrome_safe_area.dart';
import '../../data/models/collection_reader.dart';

const double kCollectionReaderNarrowContentWidth = 680;
const double kCollectionReaderStandardContentWidth = 820;
const double kCollectionReaderWideContentWidth = 1040;
const double kCollectionReaderControlWidthExtra = 160;

class CollectionReaderResolvedLayout {
  const CollectionReaderResolvedLayout({
    required this.viewportSize,
    required this.readableViewportSize,
    required this.contentWidth,
    required this.horizontalGutter,
    required this.topChromeInset,
    required this.controlMaxWidth,
    required this.isDesktop,
  });

  final Size viewportSize;
  final Size readableViewportSize;
  final double contentWidth;
  final double horizontalGutter;
  final double topChromeInset;
  final double controlMaxWidth;
  final bool isDesktop;
}

CollectionReaderResolvedLayout resolveCollectionReaderLayout({
  required TargetPlatform platform,
  required Size viewportSize,
  required CollectionReaderContentWidthMode contentWidthMode,
  bool contentExtendsIntoTitleBar = true,
}) {
  final safeViewportWidth = math.max(0, viewportSize.width).toDouble();
  final safeViewportHeight = math.max(0, viewportSize.height).toDouble();
  final isDesktop = _isDesktopPlatform(platform);
  final chromeInsets = isDesktop
      ? resolveDesktopWindowChromeInsets(
          platform: platform,
          contentExtendsIntoTitleBar: contentExtendsIntoTitleBar,
        )
      : const DesktopWindowChromeInsets.none();
  final readableHeight = math
      .max(0, safeViewportHeight - chromeInsets.top)
      .toDouble();
  final contentMaxWidth = isDesktop
      ? _contentMaxWidthForMode(contentWidthMode)
      : double.infinity;
  final contentWidth = math.min(safeViewportWidth, contentMaxWidth).toDouble();
  final horizontalGutter = math
      .max(0, (safeViewportWidth - contentWidth) / 2)
      .toDouble();
  final controlMaxWidth = math
      .min(
        safeViewportWidth,
        contentWidthMode == CollectionReaderContentWidthMode.full || !isDesktop
            ? safeViewportWidth
            : contentWidth + kCollectionReaderControlWidthExtra,
      )
      .toDouble();

  return CollectionReaderResolvedLayout(
    viewportSize: Size(safeViewportWidth, safeViewportHeight),
    readableViewportSize: Size(contentWidth, readableHeight),
    contentWidth: contentWidth,
    horizontalGutter: horizontalGutter,
    topChromeInset: chromeInsets.top,
    controlMaxWidth: controlMaxWidth,
    isDesktop: isDesktop,
  );
}

bool _isDesktopPlatform(TargetPlatform platform) {
  return platform == TargetPlatform.macOS ||
      platform == TargetPlatform.windows ||
      platform == TargetPlatform.linux;
}

double _contentMaxWidthForMode(CollectionReaderContentWidthMode mode) {
  return switch (mode) {
    CollectionReaderContentWidthMode.narrow =>
      kCollectionReaderNarrowContentWidth,
    CollectionReaderContentWidthMode.standard =>
      kCollectionReaderStandardContentWidth,
    CollectionReaderContentWidthMode.wide => kCollectionReaderWideContentWidth,
    CollectionReaderContentWidthMode.full => double.infinity,
  };
}

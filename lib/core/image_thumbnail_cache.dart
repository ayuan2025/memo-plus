class ImageThumbnailCacheTarget {
  const ImageThumbnailCacheTarget({this.width, this.height});

  static const empty = ImageThumbnailCacheTarget();

  final int? width;
  final int? height;

  bool get hasSize => width != null || height != null;
}

int? resolveThumbnailCacheExtent(
  double logicalExtent,
  double devicePixelRatio, {
  double overscan = 1.5,
  int maxDecodePx = 1024,
}) {
  if (!logicalExtent.isFinite || logicalExtent <= 0) return null;
  if (!devicePixelRatio.isFinite || devicePixelRatio <= 0) return null;
  if (maxDecodePx <= 0) return null;
  final normalizedOverscan = overscan.isFinite && overscan > 0 ? overscan : 1.0;
  final pixels = (logicalExtent * devicePixelRatio * normalizedOverscan)
      .round();
  if (pixels <= 0) return null;
  return pixels > maxDecodePx ? maxDecodePx : pixels;
}

ImageThumbnailCacheTarget resolveAspectSafeThumbnailCacheTarget({
  required double tileWidth,
  required double tileHeight,
  required double devicePixelRatio,
  int? sourceWidth,
  int? sourceHeight,
  double overscan = 1.5,
  int maxDecodePx = 1024,
}) {
  if (maxDecodePx <= 0) return ImageThumbnailCacheTarget.empty;

  final targetWidth = _resolveThumbnailPixels(
    tileWidth,
    devicePixelRatio,
    overscan: overscan,
  );
  final targetHeight = _resolveThumbnailPixels(
    tileHeight,
    devicePixelRatio,
    overscan: overscan,
  );
  if (targetWidth == null || targetHeight == null) {
    return ImageThumbnailCacheTarget.empty;
  }

  final sourceHasSize =
      sourceWidth != null &&
      sourceHeight != null &&
      sourceWidth > 0 &&
      sourceHeight > 0;
  if (!sourceHasSize) {
    return _unknownAspectRatioTarget(
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      maxDecodePx: maxDecodePx,
    );
  }

  final sourceAspectRatio = sourceWidth / sourceHeight;
  final tileAspectRatio = targetWidth / targetHeight;
  if (!sourceAspectRatio.isFinite ||
      sourceAspectRatio <= 0 ||
      !tileAspectRatio.isFinite ||
      tileAspectRatio <= 0) {
    return _unknownAspectRatioTarget(
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      maxDecodePx: maxDecodePx,
    );
  }

  final int width;
  final int height;
  if (sourceAspectRatio > tileAspectRatio) {
    height = targetHeight;
    width = (height * sourceAspectRatio).ceil();
  } else {
    width = targetWidth;
    height = (width / sourceAspectRatio).ceil();
  }

  return _capAspectRatioTarget(
    width: width,
    height: height,
    maxDecodePx: maxDecodePx,
  );
}

int? _resolveThumbnailPixels(
  double logicalExtent,
  double devicePixelRatio, {
  required double overscan,
}) {
  if (!logicalExtent.isFinite || logicalExtent <= 0) return null;
  if (!devicePixelRatio.isFinite || devicePixelRatio <= 0) return null;
  final normalizedOverscan = overscan.isFinite && overscan > 0 ? overscan : 1.0;
  final pixels = (logicalExtent * devicePixelRatio * normalizedOverscan)
      .round();
  return pixels > 0 ? pixels : null;
}

ImageThumbnailCacheTarget _unknownAspectRatioTarget({
  required int targetWidth,
  required int targetHeight,
  required int maxDecodePx,
}) {
  if (targetWidth >= targetHeight) {
    return ImageThumbnailCacheTarget(
      width: _capDecodeExtent(targetWidth, maxDecodePx),
    );
  }
  return ImageThumbnailCacheTarget(
    height: _capDecodeExtent(targetHeight, maxDecodePx),
  );
}

ImageThumbnailCacheTarget _capAspectRatioTarget({
  required int width,
  required int height,
  required int maxDecodePx,
}) {
  if (width <= 0 || height <= 0) return ImageThumbnailCacheTarget.empty;
  if (width <= maxDecodePx && height <= maxDecodePx) {
    return ImageThumbnailCacheTarget(width: width, height: height);
  }

  if (width >= height) {
    return ImageThumbnailCacheTarget(
      width: maxDecodePx,
      height: _capDecodeExtent(
        (height * maxDecodePx / width).round(),
        maxDecodePx,
      ),
    );
  }

  return ImageThumbnailCacheTarget(
    width: _capDecodeExtent(
      (width * maxDecodePx / height).round(),
      maxDecodePx,
    ),
    height: maxDecodePx,
  );
}

int _capDecodeExtent(int value, int maxDecodePx) {
  if (value <= 0) return 1;
  return value > maxDecodePx ? maxDecodePx : value;
}

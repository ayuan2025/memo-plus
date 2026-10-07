// Vendored from OpenScan v3.0.0 — https://github.com/ethereal-developers/OpenScan
// BSD 3-Clause License, Copyright (c) 2021, Vijay T S and Vikram H.
// See `third_party/openscan_cv/` for the full license text and the list of
// local adaptations.

import '../full_frame_page.dart';
import 'quad.dart';

/// Result of running document-boundary detection on an image. An explicit
/// three-way outcome, so the UI can never be left waiting forever on a
/// detection that silently produced nothing.
sealed class DetectionResult {
  const DetectionResult();
}

/// A convex document-shaped quadrilateral was found.
class DetectionSuccess extends DetectionResult {
  const DetectionSuccess(
    this.quad,
    this.imageWidth,
    this.imageHeight, {
    this.fullPageReason,
  });

  final Quad quad;
  final int imageWidth;
  final int imageHeight;

  /// Set when [quad] is the frame itself because the capture was judged to be a
  /// page already — see the types in `full_frame_page.dart`.
  final FullPageReason? fullPageReason;

  /// Whether nothing was cut to and the whole capture stands as the page.
  bool get isFullPage => fullPageReason != null;
}

/// Detection ran without error, but no suitable quad was found.
class DetectionNotFound extends DetectionResult {
  const DetectionNotFound(
    this.imageWidth,
    this.imageHeight, {
    this.fullPageReason,
  });

  final int imageWidth;
  final int imageHeight;

  /// Set when "nothing found" was read as "already a page, nothing to cut".
  final FullPageReason? fullPageReason;

  bool get isFullPage => fullPageReason != null;
}

/// Detection threw (corrupt image, decode failure, etc).
class DetectionFailure extends DetectionResult {
  const DetectionFailure(this.message);

  final String message;

  @override
  String toString() => 'DetectionFailure($message)';
}

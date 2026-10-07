import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../../core/scan/document_scan.dart';

/// Longest edge a scanned page is stored at, and the JPEG quality it is encoded
/// at. Re-exported here so the scan feature has one place to look, while the
/// numbers themselves stay owned by the vendored scanner code.
const int kScanPageMaxEdge = kStoredPageMaxEdge;
const int kScanPageQuality = kStoredPageQuality;

/// Outcome of looking for a document boundary in a capture.
@immutable
class ScanBoundaryDetection {
  const ScanBoundaryDetection({
    required this.imageWidth,
    required this.imageHeight,
    required this.quad,
    this.fullPageReason,
  });

  /// Size of the capture the quad is expressed in — always known, even when no
  /// boundary was found, because the caller needs it to lay the crop handles out
  /// over the image.
  final int imageWidth;
  final int imageHeight;

  /// The detected boundary in the capture's pixel coordinates, or null when the
  /// detector ran and found nothing it trusted.
  final Quad? quad;

  /// Set when [quad] is the whole frame because the capture already *is* the
  /// page — an import from the gallery, a screenshot, anything trimmed
  /// elsewhere. Detection looks for a paper edge against its surroundings, and
  /// an already-trimmed page has none: the strongest rectangle in it is some
  /// block of its own content, and cutting to that would lose everything
  /// around it.
  final FullPageReason? fullPageReason;

  bool get found => quad != null;

  /// Whether the capture is being passed through without a crop.
  bool get isFullPage => fullPageReason != null;
}

/// Looks for a document boundary in the encoded capture [encoded].
///
/// Runs on a worker isolate: the pure-Dart detector decodes the full-resolution
/// capture and runs Sobel/contour passes over it, which is comfortably long
/// enough to drop frames if it ran on the UI isolate.
///
/// Returns null when the bytes could not be decoded at all — a caller should
/// treat that as "this capture cannot be scanned", not as "no boundary found".
Future<ScanBoundaryDetection?> detectScanBoundary(Uint8List encoded) async {
  final result = await compute(detectDocumentInBytes, encoded);
  return switch (result) {
    DetectionSuccess(
      :final quad,
      :final imageWidth,
      :final imageHeight,
      :final fullPageReason,
    ) =>
      ScanBoundaryDetection(
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        quad: quad,
        fullPageReason: fullPageReason,
      ),
    DetectionNotFound(
      :final imageWidth,
      :final imageHeight,
      :final fullPageReason,
    ) =>
      ScanBoundaryDetection(
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        quad: null,
        fullPageReason: fullPageReason,
      ),
    DetectionFailure() => null,
  };
}

/// Everything one scan page needs to become a storable file.
@immutable
class ScanPageRequest {
  const ScanPageRequest({
    required this.encoded,
    required this.quad,
    required this.filterName,
    this.quarterTurns = 0,
    this.maxEdge = kScanPageMaxEdge,
    this.quality = kScanPageQuality,
  });

  /// The untouched capture.
  final Uint8List encoded;

  /// The boundary to crop to, in [encoded]'s pixel coordinates, or null to keep
  /// the capture whole.
  final Quad? quad;

  /// Id from [documentFiltersList]; an unknown id falls back to the default
  /// filter rather than failing.
  final String filterName;

  /// Clockwise quarter turns to apply to the cropped page.
  final int quarterTurns;

  final int maxEdge;
  final int quality;
}

/// The finished page plus whether the pipeline actually got to run.
@immutable
class ScanPageResult {
  const ScanPageResult({required this.bytes, required this.processed});

  final Uint8List bytes;

  /// False means the capture could not be decoded, so [bytes] is the input
  /// passed through untouched and the caller must not assume it is a page.
  final bool processed;
}

/// Renders one scan page: crop to the boundary, cap the long edge, rotate,
/// filter, encode as JPEG — all in a single worker-isolate pass.
///
/// Kept as one entry point rather than a method per step because every step
/// shares the same need for a decoded image, and decoding a multi-megapixel
/// capture is the expensive part.
Future<ScanPageResult> renderScanPage(ScanPageRequest request) =>
    compute(_renderScanPageEntry, request);

ScanPageResult _renderScanPageEntry(ScanPageRequest request) {
  try {
    final page = renderScannedPage(
      request.encoded,
      quad: request.quad,
      maxEdge: request.maxEdge,
      quality: request.quality,
    );
    if (!page.decoded) {
      return ScanPageResult(bytes: page.bytes, processed: false);
    }

    var bytes = page.bytes;
    if (request.quarterTurns % 4 != 0) {
      bytes = _rotateJpeg(bytes, request.quarterTurns, request.quality);
    }
    bytes = filterDocumentBytes(
      bytes,
      filterName: request.filterName,
      maxEdge: request.maxEdge,
    );
    return ScanPageResult(bytes: bytes, processed: true);
  } catch (error, stackTrace) {
    // A scan that cannot be finished must not take the compose flow down with
    // it: hand back the untouched capture and let the caller decide.
    if (kDebugMode) {
      debugPrint('renderScanPage failed: $error\n$stackTrace');
    }
    return ScanPageResult(bytes: request.encoded, processed: false);
  }
}

Uint8List _rotateJpeg(Uint8List jpeg, int quarterTurns, int quality) {
  final decoded = img.decodeImage(jpeg);
  if (decoded == null) return jpeg;
  final rotated = img.copyRotate(decoded, angle: 90 * (quarterTurns % 4));
  return img.encodeJpg(rotated, quality: quality);
}

/// The largest quad a user can start from when detection finds nothing: the
/// capture's full frame, inset slightly so every handle is grabbable rather than
/// sitting on the screen edge.
Quad defaultScanBoundary(int imageWidth, int imageHeight) {
  const inset = 0.04;
  final w = imageWidth.toDouble();
  final h = imageHeight.toDouble();
  return Quad(
    topLeft: Pt(w * inset, h * inset),
    topRight: Pt(w * (1 - inset), h * inset),
    bottomRight: Pt(w * (1 - inset), h * (1 - inset)),
    bottomLeft: Pt(w * inset, h * (1 - inset)),
  );
}

/// [quad] clamped so every corner stays inside the capture.
///
/// The crop handles are dragged in view space, and rounding plus a fingertip's
/// width of slop can put a corner a hair outside the image; a homography built
/// from out-of-bounds corners still produces a plausible-looking page, just one
/// sampled from nowhere, so the clamp is what keeps a drag at the edge from
/// quietly smuggling in blank margins.
Quad clampQuadToImage(Quad quad, int imageWidth, int imageHeight) {
  Pt clampPt(Pt p) => Pt(
    p.x.clamp(0, imageWidth.toDouble()),
    p.y.clamp(0, imageHeight.toDouble()),
  );
  return Quad(
    topLeft: clampPt(quad.topLeft),
    topRight: clampPt(quad.topRight),
    bottomRight: clampPt(quad.bottomRight),
    bottomLeft: clampPt(quad.bottomLeft),
  );
}

/// A quad in fractional [0,1] coordinates of the *image* scaled onto its pixel
/// grid.
///
/// Deliberately not `quadInPixelsOf`: that one exists for viewfinder overlays
/// and rotates the quad when the photo decoded landscape. The scan editor holds
/// its boundary in the capture's own orientation already, so rotating it here
/// would turn a portrait-orientation page out of the landscape capture it came
/// from.
Quad scaleNormalizedQuad(Quad normalized, int imageWidth, int imageHeight) =>
    normalized.scaled(imageWidth.toDouble(), imageHeight.toDouble());

/// The quad scaled into [0,1] image coordinates, the space the editor stores.
Quad normalizeQuad(Quad quad, int imageWidth, int imageHeight) {
  if (imageWidth <= 0 || imageHeight <= 0) return quad;
  return quad.scaled(1 / imageWidth, 1 / imageHeight);
}

/// Longest edge of a quad, used to decide whether a dragged shape is still a
/// page rather than a collapsed sliver.
double quadLongestEdge(Quad quad) {
  double distance(Pt a, Pt b) => sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));
  final tl = quad.topLeft, tr = quad.topRight;
  final br = quad.bottomRight, bl = quad.bottomLeft;
  return [
    distance(tl, tr),
    distance(tr, br),
    distance(br, bl),
    distance(bl, tl),
  ].reduce(max);
}

// Vendored from OpenScan v3.0.0 — https://github.com/ethereal-developers/OpenScan
// BSD 3-Clause License, Copyright (c) 2021, Vijay T S and Vikram H.
// See `third_party/openscan_cv/` for the full license text and the list of
// local adaptations.

import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'contours.dart';
import 'corner_refinement.dart';
import 'edge_detection.dart';
import 'models/detection_result.dart';
import 'models/quad.dart';

/// Longest edge (px) that detection runs at. Keeps the pure-Dart edge/contour
/// pipeline fast on full-resolution camera photos; the resulting quad is scaled
/// back up to the original image size before being returned, since
/// [DetectionSuccess.quad] is always in original-image coordinates.
const int kDetectionMaxDimension = 700;

/// Detects the document boundary in an encoded image (JPEG/PNG/…).
///
/// Adapted from OpenScan's `detectDocumentIsolateEntry`: it took a file path and
/// read the bytes itself, which drags `dart:io` into every caller and makes the
/// pipeline unusable on web. Taking the encoded bytes instead keeps this
/// function a pure, platform-neutral entry point that can be handed straight to
/// `compute()`.
///
/// Never throws, so a caller can always resolve the returned future without
/// needing to guard against an unhandled isolate exception.
DetectionResult detectDocumentInBytes(Uint8List encoded) {
  try {
    final decoded = img.decodeImage(encoded);
    if (decoded == null) {
      return const DetectionFailure('Could not decode image');
    }

    final originalWidth = decoded.width;
    final originalHeight = decoded.height;

    final longestEdge = max(originalWidth, originalHeight).toDouble();
    final workingScale = longestEdge > kDetectionMaxDimension
        ? kDetectionMaxDimension / longestEdge
        : 1.0;
    final workWidth = max(1, (originalWidth * workingScale).round());
    final workHeight = max(1, (originalHeight * workingScale).round());

    final rgba = _downscaleRgba(
      decoded.getBytes(order: img.ChannelOrder.rgba),
      originalWidth,
      originalHeight,
      workWidth,
      workHeight,
    );

    final gray = rgbaToGrayscale(rgba, workWidth, workHeight);
    final quad = detectQuadFromGrayscale(gray, workWidth, workHeight);
    if (quad == null) {
      return DetectionNotFound(originalWidth, originalHeight);
    }

    final scaleBackX = originalWidth / workWidth;
    final scaleBackY = originalHeight / workHeight;
    return DetectionSuccess(
      quad.scaled(scaleBackX, scaleBackY),
      originalWidth,
      originalHeight,
    );
  } catch (e) {
    return DetectionFailure(e.toString());
  }
}

/// Multipliers applied to the Otsu threshold to build several binarized edge
/// masks per frame instead of trusting a single one. Otsu recomputes its
/// threshold fresh from each frame's own gradient-magnitude histogram, so it can
/// shift slightly frame-to-frame under sensor noise/lighting flicker even when
/// the scene hasn't changed — a single mask's contour search can then land on a
/// visibly different quad purely because the threshold moved. Mirrors the
/// reference document-scanner app's approach of trying multiple
/// thresholds/channels per frame and scoring the pooled results
/// ([pickBestQuad]) instead of committing to one strategy's output.
const List<double> _thresholdMultipliers = [0.7, 1.0, 1.3];

/// Runs the grayscale->blur->sobel->(multi-threshold)->dilate->quad pipeline on
/// an already-grayscale buffer. Pure function, no I/O — shared by the one-shot
/// byte entry point above and any live-scan caller, so the edge/contour logic
/// only exists in one place.
///
/// Unlike a single-threshold pipeline, this binarizes the Sobel magnitude at
/// several thresholds around the Otsu-computed one (see
/// [_thresholdMultipliers]), pools every valid candidate quad found across all of
/// them, and picks the best via [pickBestQuad]'s area/squareness scoring.
///
/// [previousQuad], when supplied, nudges [pickBestQuad] toward whichever
/// candidate best corresponds to it — see that function's doc comment. Always
/// null for the one-shot path above (no "previous frame" concept there); a
/// live-scan caller supplies its own last-seen quad.
Quad? detectQuadFromGrayscale(
  Uint8List gray,
  int width,
  int height, {
  Quad? previousQuad,
}) {
  final blurred = gaussianBlur3(gray, width, height);
  final magnitude = sobelMagnitude(blurred, width, height);
  final baseThreshold = _resolveEdgeThreshold(magnitude);

  final candidates = <Quad>[];
  Uint8List? strongest;
  for (final multiplier in _thresholdMultipliers) {
    final t = (baseThreshold * multiplier).round().clamp(0, 255);
    final binary = threshold(magnitude, t);
    final dilated = dilate(binary, width, height, 4);
    strongest ??= dilated;
    candidates.addAll(findDocumentQuadCandidates(dilated, width, height));
  }

  final best = pickBestQuad(candidates, width, height, previousQuad: previousQuad);
  if (best == null || strongest == null) return best;
  // Contour simplification keeps a corner where the silhouette happens to
  // bend, which is not where the paper's edge turns. Re-fitting the sides
  // against the gradient magnitudes puts the corners back on the paper.
  return refineQuadCorners(best, magnitude, width, height, baseThreshold);
}

/// Fraction of the frame allowed to exceed the edge threshold.
///
/// Otsu assumes a bimodal histogram, but a photographed page's Sobel
/// magnitudes are right-skewed — most of the frame sits near zero and the
/// paper's own edges are a thin bright tail. Otsu can therefore land below the
/// paper and let sensor noise compete with it. The percentile value is used as
/// a *floor* for Otsu rather than as a replacement: it only ever raises the
/// threshold, so a frame where the paper genuinely fills the view (and thus
/// contributes more than this fraction of strong gradients) still binarizes
/// the same way it did before.
const double _maxEdgeFraction = 0.06;

/// Threshold for [detectQuadFromGrayscale], floored so a skewed magnitude
/// histogram can't drag it below the paper's own edges.
int _resolveEdgeThreshold(Uint8List magnitude) {
  final floor = percentileThreshold(magnitude, percentile: 1 - _maxEdgeFraction);
  return max(otsuThreshold(magnitude), floor);
}

/// Nearest-neighbor downsample of an RGBA buffer (stride 4).
Uint8List _downscaleRgba(
  Uint8List src,
  int srcW,
  int srcH,
  int dstW,
  int dstH,
) {
  if (srcW == dstW && srcH == dstH) return src;

  final dst = Uint8List(dstW * dstH * 4);
  for (int y = 0; y < dstH; y++) {
    final sy = (y * srcH / dstH).floor().clamp(0, srcH - 1);
    for (int x = 0; x < dstW; x++) {
      final sx = (x * srcW / dstW).floor().clamp(0, srcW - 1);
      final srcIdx = (sy * srcW + sx) * 4;
      final dstIdx = (y * dstW + x) * 4;
      dst[dstIdx] = src[srcIdx];
      dst[dstIdx + 1] = src[srcIdx + 1];
      dst[dstIdx + 2] = src[srcIdx + 2];
      dst[dstIdx + 3] = src[srcIdx + 3];
    }
  }
  return dst;
}

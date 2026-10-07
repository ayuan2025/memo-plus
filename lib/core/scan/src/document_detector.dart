// Vendored from OpenScan v3.0.0 — https://github.com/ethereal-developers/OpenScan
// BSD 3-Clause License, Copyright (c) 2021, Vijay T S and Vikram H.
// See `third_party/openscan_cv/` for the full license text and the list of
// local adaptations.

import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'boundary_color_step.dart';
import 'contours.dart';
import 'corner_refinement.dart';
import 'edge_detection.dart';
import 'full_frame_page.dart';
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

    // The full-resolution buffer stays alive: the colour-separation guard
    // measures on it, not on the working frame — see the note at `usable`.
    final fullRgba = decoded.getBytes(order: img.ChannelOrder.rgba);

    final rgba = _downscaleRgba(
      fullRgba,
      originalWidth,
      originalHeight,
      workWidth,
      workHeight,
    );

    // Two gradient fields, deliberately: the two questions this function asks
    // need different ones.
    //
    // Finding the paper needs the coarse-scale, chroma-fused field — see
    // `documentEdgeMagnitude` for why: at 3x3 the page edge loses to wood grain
    // and to the page's own text.
    final boundary = documentEdgeMagnitude(rgba, workWidth, workHeight);
    final quad = detectQuadFromMagnitude(
      boundary,
      workWidth,
      workHeight,
    );

    // Deciding whether that quad is the page or a box drawn inside one is a
    // question about *written material*, and writing is a fine-scale
    // phenomenon: a stroke is a couple of pixels wide, so the coarse field has
    // deliberately smoothed it away. Running the full-page guard on the coarse
    // field would read a page of text as blank and change the guard's answer
    // for reasons unrelated to the decision it is making, so it keeps the
    // fine-scale luminance field it was designed and tuned against.
    final magnitude = sobelMagnitude(
      gaussianBlur3(
        rgbaToGrayscale(rgba, workWidth, workHeight),
        workWidth,
        workHeight,
      ),
      workWidth,
      workHeight,
    );
    // A rectangle only counts as a page boundary if the two sides of it are
    // actually different things. Coarse-scale detection made one new failure
    // mode reachable: a solid block of dense text survives the blur as a single
    // blob whose outline is a very convincing rectangle, so a form's text block
    // can now beat the page it sits on. Such a block's perimeter separates text
    // from blank paper, not paper from desk — see `kMinBoundaryColorStep`.
    //
    // That check is measured at FULL resolution, not on the working buffer.
    // The band `boundaryColorStep` samples is a fixed fraction of the image
    // diagonal, so on the ~700px working frame it is four times narrower than
    // it was on the photos the threshold was calibrated from — and bandwidth
    // is not a technicality here. A text block's perimeter alternates ink and
    // bare paper; a wide band averages that alternation away and the fake
    // boundary's colour step collapses below the threshold, while a real page
    // edge separates two uniform regions and holds its step at any bandwidth.
    // The narrow working-frame band is precisely what let a photographed ID
    // card's title block slip through at ~25 where the full-resolution
    // measurement reads ~12. The scale-back happens here rather than inside
    // the guard so the guard stays a pure measurement over whatever frame it
    // is handed.
    //
    // A quad that already fills the frame is exempt: its outside band falls
    // outside the picture, there is nothing to sample, and absence of
    // evidence must not read as evidence of absence — the contract is that
    // a found rectangle near the frame is trusted. Fakes big enough to
    // matter, like the 90%-of-frame texture rectangle on granite, still leave
    // a measurable sliver and are owned by the full-page guard behind this
    // check.
    final usable = quad != null &&
        (isFullFrameQuad(quad, workWidth, workHeight) ||
            quadSeparatesRegions(
              fullRgba,
              originalWidth,
              originalHeight,
              quad.scaled(originalWidth / workWidth, originalHeight / workHeight),
            ));
    // The guard's verdict, not the mere existence of a candidate, decides what
    // gets reported: a rejected candidate must flow downstream exactly like no
    // candidate at all.
    final usableQuad = usable ? quad : null;
    final decision = resolveDocumentBoundary(
      magnitude: magnitude,
      width: workWidth,
      height: workHeight,
      detected: usableQuad,
    );

    final scaleBackX = originalWidth / workWidth;
    final scaleBackY = originalHeight / workHeight;
    final resolved = decision.quad.scaled(scaleBackX, scaleBackY);

    if (usableQuad == null) {
      // Nothing usable was found — either the detector returned no candidate
      // or the colour guard rejected the one it did. On a picture that is
      // already the page, the full-frame answer with its reason is right.
      // Otherwise report not-found: resolveDocumentBoundary's fallback here is
      // a generic inset rectangle, and returning it as a reason-less success
      // dressed a placeholder up as a detected boundary — the caller would cut
      // to a rectangle nothing actually measured. Not-found lets the caller
      // keep the whole frame instead.
      return decision.isFullPage
          ? DetectionSuccess(
              resolved,
              originalWidth,
              originalHeight,
              fullPageReason: decision.reason,
            )
          : DetectionNotFound(originalWidth, originalHeight);
    }

    return DetectionSuccess(
      resolved,
      originalWidth,
      originalHeight,
      fullPageReason: decision.reason,
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

/// Runs the blur->sobel->(multi-threshold)->dilate->quad pipeline on a frame's
/// grayscale buffer, at the fine 3x3 scale.
///
/// This is the historical entry point, kept because it is the one that takes a
/// plain luminance buffer and therefore needs nothing to have been computed
/// beforehand. The one-shot detector in this file no longer goes through it:
/// [detectQuadFromMagnitude] does, with a gradient measured at
/// [kBoundaryBlurFraction] and fused with chroma, because the 3x3 luminance
/// gradient is what loses the paper to wood grain and to the page's own text.
/// Kept working, and kept exported, so any other caller of this primitive keeps
/// the behaviour it was written against.
Quad? detectQuadFromGrayscale(
  Uint8List gray,
  int width,
  int height, {
  Quad? previousQuad,
}) {
  final magnitude = sobelMagnitude(
    gaussianBlur3(gray, width, height),
    width,
    height,
  );
  return detectQuadFromMagnitude(
    magnitude,
    width,
    height,
    previousQuad: previousQuad,
  );
}

/// Runs the (multi-threshold)->dilate->contour->quad pipeline on an
/// already-computed gradient magnitude. Pure function, no I/O — shared by the
/// one-shot byte entry point above and any live-scan caller, so the
/// edge/contour logic only exists in one place.
///
/// Unlike a single-threshold pipeline, this binarizes [magnitude] at several
/// thresholds around the Otsu-computed one (see [_thresholdMultipliers]), pools
/// every valid candidate quad found across all of them, and picks the best via
/// [pickBestQuad]'s area/squareness scoring.
///
/// [previousQuad], when supplied, nudges [pickBestQuad] toward whichever
/// candidate best corresponds to it — see that function's doc comment. Always
/// null for the one-shot path above (no "previous frame" concept there); a
/// live-scan caller supplies its own last-seen quad.
Quad? detectQuadFromMagnitude(
  Uint8List magnitude,
  int width,
  int height, {
  Quad? previousQuad,
}) {
  final baseThreshold = documentEdgeThreshold(magnitude);

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

/// At or above the floor (see `documentEdgeThreshold`) nothing changes; below
/// it, a skewed histogram can no longer drag the threshold under the writing.

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

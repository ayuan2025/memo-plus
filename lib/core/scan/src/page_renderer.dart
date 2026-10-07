// Vendored from OpenScan v3.0.0 — https://github.com/ethereal-developers/OpenScan
// BSD 3-Clause License, Copyright (c) 2021, Vijay T S and Vikram H.
// See `third_party/openscan_cv/` for the full license text and the list of
// local adaptations.
//
// Local adaptation: OpenScan's `compress.dart` and `capture_pipeline.dart` both
// took a source path and a destination path and did their own file I/O, splitting
// "crop + downscale + encode" across several entry points. Here the same work is
// one byte-in/byte-out call, so a captured page is decoded exactly once and no
// layer outside this package has to know about temporary files.

import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'models/quad.dart';
import 'deskew.dart' show deskewPage;
import 'perspective_crop.dart' show warpToPage;

/// Long edge, in pixels, a stored page is capped at. 2400px is ~200 DPI across
/// an A4 page — the resolution document scanners settle on, and past which a
/// photo of paper carries no more readable detail, only bytes. Corresponds to
/// OpenScan's `kStoredPageMaxEdge`.
const int kStoredPageMaxEdge = 2400;

/// JPEG quality a stored page is encoded at. OpenScan's `kStoredPageQuality`.
const int kStoredPageQuality = 85;

/// What [renderScannedPage] produced.
typedef ScannedPage = ({
  /// The page to store. JPEG-encoded unless the input could not be decoded, in
  /// which case this is the input bytes passed through untouched.
  Uint8List bytes,

  /// Whether the perspective crop actually ran.
  bool cropped,

  /// False means the bytes went through untouched and nothing has confirmed
  /// they are a readable image, so the caller has to check before keeping the
  /// page.
  bool decoded,
});

/// Turns a captured or picked image into a page ready for storage, in a single
/// decode: crop to [quad] (when given), cap the long edge at [maxEdge], and
/// re-encode as JPEG at [quality].
///
/// [quad] is in the **pixel coordinates of the image in [encoded]** — the same
/// space `DetectionSuccess.quad` is reported in, so a detect-then-render flow
/// passes the quad straight through. A quad in fractional [0,1] portrait-overlay
/// coordinates (what a live-viewfinder overlay works in) MUST be converted first
/// with `quadInPixelsOf`, since that conversion rotates the quad when the photo
/// decoded landscape.
///
/// Doing all three steps in one pass matters: the separate steps a scanner app
/// usually has — warp the capture, decode that again to downscale it, decode the
/// untouched capture a third time — are three decodes and three encodes of a
/// multi-megapixel photo, which is most of the wait between finishing a scan and
/// seeing the page.
///
/// Never throws. A capture that cannot be decoded or re-encoded is passed
/// through as-is, since an oversized page — or one in a format `package:image`
/// cannot read, like HEIC — is worth far more than no page at all.
ScannedPage renderScannedPage(
  Uint8List encoded, {
  Quad? quad,
  int maxEdge = kStoredPageMaxEdge,
  int quality = kStoredPageQuality,
}) {
  try {
    final decoded = img.decodeImage(encoded);
    if (decoded == null) {
      return (bytes: encoded, cropped: false, decoded: false);
    }

    img.Image? page;
    if (quad != null) {
      page = warpToPage(decoded, quad, maxEdge: maxEdge);
    }
    final cropped = page != null;
    if (!cropped) {
      // A page that passes through whole — a gallery import, a screenshot —
      // carries whatever tilt it was trimmed with. Warping would straighten it
      // but also resample it against some guessed rectangle; a projection
      // sweep finds the text's own angle instead and turns just that much.
      // Pages already upright come back untouched, and a page on its side is
      // left for the orientation step, which reads the text to decide.
      page = deskewPage(fitToMaxEdge(decoded, maxEdge));
    }

    return (
      bytes: img.encodeJpg(page, quality: quality),
      cropped: cropped,
      decoded: true,
    );
  } catch (_) {
    return (bytes: encoded, cropped: false, decoded: false);
  }
}

/// [image] scaled down so its long edge is at most [maxEdge], or [image] itself
/// when it already fits or [maxEdge] is null. Never enlarges: a page smaller
/// than the cap is left as it is rather than interpolated up to a size it has no
/// detail for.
img.Image fitToMaxEdge(img.Image image, int? maxEdge) {
  if (maxEdge == null) return image;
  final longEdge = image.width > image.height ? image.width : image.height;
  if (longEdge <= maxEdge) return image;
  return img.copyResize(
    image,
    width: image.width >= image.height ? maxEdge : null,
    height: image.height > image.width ? maxEdge : null,
    interpolation: img.Interpolation.average,
  );
}

/// [image] scaled down to fit [maxEdge] on its long side, or itself if it
/// already does — a stored page is never upscaled to meet the cap.
img.Image fitPageToMaxEdge(img.Image image, int maxEdge) {
  final longest = max(image.width, image.height);
  if (maxEdge <= 0 || longest <= maxEdge) return image;
  final scale = maxEdge / longest;
  return img.copyResize(
    image,
    width: max(1, (image.width * scale).round()),
    height: max(1, (image.height * scale).round()),
    interpolation: img.Interpolation.average,
  );
}

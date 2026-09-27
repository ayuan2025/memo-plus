// Vendored from OpenScan v3.0.0 — https://github.com/ethereal-developers/OpenScan
// BSD 3-Clause License, Copyright (c) 2021, Vijay T S and Vikram H.
// See `third_party/openscan_cv/` for the full license text and the list of
// local adaptations.
//
// Local adaptation: OpenScan's entry points took a file path and overwrote the
// file in place. Everything here works on encoded bytes and hands encoded bytes
// back instead, so the pipeline carries no `dart:io` dependency and stays usable
// in an isolate and on web.

import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'contours.dart';
import 'models/point.dart';
import 'models/quad.dart';

/// Outcome of a perspective crop.
sealed class CropResult {
  const CropResult();
}

class CropSuccess extends CropResult {
  const CropSuccess(this.bytes);

  /// The warped page, JPEG-encoded.
  final Uint8List bytes;

  @override
  String toString() => 'CropSuccess(${bytes.length} bytes)';
}

class CropFailure extends CropResult {
  const CropFailure(this.message);

  final String message;

  @override
  String toString() => 'CropFailure($message)';
}

/// Warps the [quad] region of the image in [encoded] into an upright rectangle
/// and returns it as JPEG bytes.
///
/// [quarterTurns], when given, turns the warped result clockwise that many
/// quarter turns — the crop screen shows a rotation without touching the image,
/// so this is where that rotation is actually made real.
///
/// Replaces `Imgproc.getPerspectiveTransform` + `Imgproc.warpPerspective` with a
/// hand-rolled direct-linear-transform homography solve and bilinear-sampled
/// inverse warp.
CropResult cropToQuadBytes(
  Uint8List encoded,
  Quad quad, {
  int quarterTurns = 0,
  int quality = 100,
}) {
  try {
    final decoded = img.decodeImage(encoded);
    if (decoded == null) {
      return const CropFailure('Could not decode image');
    }

    var warped = _warp(decoded, quad, null, null);
    if (warped == null) return const CropFailure('Could not warp image');
    if (quarterTurns % 4 != 0) {
      warped = img.copyRotate(warped, angle: 90 * (quarterTurns % 4));
    }
    return CropSuccess(img.encodeJpg(warped, quality: quality));
  } catch (e) {
    return CropFailure(e.toString());
  }
}

/// Warps [quad] into an upright rectangle and returns it, capped at [maxEdge] on
/// its long side, or null if the warp failed.
///
/// The cap is applied to the warp itself rather than by resizing afterwards: the
/// warp samples the source once per *output* pixel, so asking it for a
/// page-sized result directly is both faster than warping at capture resolution
/// and free of the extra decode/encode round trip a separate downscale would
/// cost. Where that means throwing away more than half the detail, the source is
/// box-filtered down first, so the result is averaged rather than point-sampled.
img.Image? warpToPage(img.Image decoded, Quad quad, {int? maxEdge}) {
  var source = decoded;
  var pixels = quad;

  final natural = outputSize(pixels);
  var outWidth = natural.width;
  var outHeight = natural.height;

  if (maxEdge != null && maxEdge > 0) {
    final longest = max(outWidth, outHeight);
    if (longest > maxEdge) {
      final scale = maxEdge / longest;
      outWidth = max(1, (outWidth * scale).round());
      outHeight = max(1, (outHeight * scale).round());
      if (scale <= 0.5) {
        source = img.copyResize(
          decoded,
          width: max(1, (decoded.width * scale).round()),
          height: max(1, (decoded.height * scale).round()),
          interpolation: img.Interpolation.average,
        );
        pixels = pixels.scaled(scale, scale);
      }
    }
  }

  return _warp(source, pixels, outWidth, outHeight);
}

/// Maps a quad in fractional [0,1] *portrait overlay* coordinates onto
/// [decoded]'s own pixel grid, rotating it back into the photo's orientation
/// first if the photo decoded landscape — otherwise the overlay's corners would
/// be stretched across the wrong axes.
Quad quadInPixels(Quad normalized, img.Image decoded) =>
    quadInPixelsOf(normalized, decoded.width, decoded.height);

/// [quadInPixels] against bare dimensions, for the callers that know how big the
/// image is before there is an image to ask — working out how far a capture can
/// be scaled down while decoding needs the quad's size in pixels, and the decode
/// is what the answer decides.
Quad quadInPixelsOf(Quad normalized, int width, int height) {
  var quad = normalized;
  if (width > height) {
    // Inverse of the fixed 90-degree rotation the portrait overlay works in, in
    // normalized space: portrait (x, y) came from sensor (y, 1 - x).
    quad = sortCorners(quad.points.map((p) => Pt(p.y, 1 - p.x)).toList());
  }
  return quad.scaled(width.toDouble(), height.toDouble());
}

/// The size an unscaled warp of [quad] produces: the longest of each pair of
/// opposite edges, so no part of the page is squeezed.
({int width, int height}) outputSize(Quad quad) {
  final tl = quad.topLeft, tr = quad.topRight;
  final br = quad.bottomRight, bl = quad.bottomLeft;
  final width = max(
    _dist(tl.x, tl.y, tr.x, tr.y),
    _dist(bl.x, bl.y, br.x, br.y),
  );
  final height = max(
    _dist(tl.x, tl.y, bl.x, bl.y),
    _dist(tr.x, tr.y, br.x, br.y),
  );
  return (
    width: width.round().clamp(1, 1 << 16),
    height: height.round().clamp(1, 1 << 16),
  );
}

/// Inverse-samples [quad] out of [source] into an upright [outWidth] x
/// [outHeight] rectangle. Both dimensions default to the quad's own size.
img.Image? _warp(img.Image decoded, Quad quad, int? width, int? height) {
  try {
    final srcWidth = decoded.width;
    final srcHeight = decoded.height;
    final srcRgba = decoded.getBytes(order: img.ChannelOrder.rgba);

    final tl = quad.topLeft, tr = quad.topRight;
    final br = quad.bottomRight, bl = quad.bottomLeft;

    final natural = outputSize(quad);
    final outWidth = width ?? natural.width;
    final outHeight = height ?? natural.height;

    // Homography mapping output-rectangle coordinates -> source quad
    // coordinates, used to inverse-sample the source for each output pixel.
    final h = _solveHomography(
      outWidth.toDouble(),
      outHeight.toDouble(),
      tl,
      tr,
      br,
      bl,
    );

    final outRgba = Uint8List(outWidth * outHeight * 4);
    for (int y = 0; y < outHeight; y++) {
      for (int x = 0; x < outWidth; x++) {
        final srcPoint = _applyHomography(h, x.toDouble(), y.toDouble());
        final sampled = _bilinearSample(
          srcRgba,
          srcWidth,
          srcHeight,
          srcPoint[0],
          srcPoint[1],
        );
        final dstIdx = (y * outWidth + x) * 4;
        outRgba[dstIdx] = sampled[0];
        outRgba[dstIdx + 1] = sampled[1];
        outRgba[dstIdx + 2] = sampled[2];
        outRgba[dstIdx + 3] = 255;
      }
    }

    return img.Image.fromBytes(
      width: outWidth,
      height: outHeight,
      bytes: outRgba.buffer,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );
  } catch (e) {
    return null;
  }
}

double _dist(double x1, double y1, double x2, double y2) =>
    sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2));

/// Solves the 8-parameter homography mapping the destination rectangle
/// `(0,0)-(w,0)-(w,h)-(0,h)` onto the `(tl,tr,br,bl)` source quad, via a direct
/// linear transform — the same underlying math `getPerspectiveTransform` used,
/// solved in the direction needed for inverse-mapping (output pixel -> source
/// sample point).
List<double> _solveHomography(double w, double h, Pt tl, Pt tr, Pt br, Pt bl) {
  final dst = [
    [0.0, 0.0],
    [w, 0.0],
    [w, h],
    [0.0, h],
  ];
  final src = [
    [tl.x, tl.y],
    [tr.x, tr.y],
    [br.x, br.y],
    [bl.x, bl.y],
  ];

  // 8x8 linear system A*p = b for unknowns [a, b, c, d, e, f, g, h] where:
  //   x = (a*u + b*v + c) / (g*u + h*v + 1)
  //   y = (d*u + e*v + f) / (g*u + h*v + 1)
  final a = List.generate(8, (_) => List<double>.filled(8, 0.0));
  final bVec = List<double>.filled(8, 0.0);

  for (int i = 0; i < 4; i++) {
    final u = dst[i][0], v = dst[i][1];
    final x = src[i][0], y = src[i][1];

    a[2 * i] = [u, v, 1, 0, 0, 0, -u * x, -v * x];
    bVec[2 * i] = x;

    a[2 * i + 1] = [0, 0, 0, u, v, 1, -u * y, -v * y];
    bVec[2 * i + 1] = y;
  }

  final p = _solveLinearSystem(a, bVec);
  return [...p, 1.0];
}

/// Gaussian elimination with partial pivoting for a small dense system.
List<double> _solveLinearSystem(List<List<double>> a, List<double> b) {
  final n = b.length;
  for (int col = 0; col < n; col++) {
    int pivot = col;
    for (int row = col + 1; row < n; row++) {
      if (a[row][col].abs() > a[pivot][col].abs()) pivot = row;
    }
    final tmpRow = a[col];
    a[col] = a[pivot];
    a[pivot] = tmpRow;
    final tmpB = b[col];
    b[col] = b[pivot];
    b[pivot] = tmpB;

    final pivotVal = a[col][col];
    if (pivotVal.abs() < 1e-12) continue;

    for (int row = 0; row < n; row++) {
      if (row == col) continue;
      final factor = a[row][col] / pivotVal;
      if (factor == 0) continue;
      for (int c = col; c < n; c++) {
        a[row][c] -= factor * a[col][c];
      }
      b[row] -= factor * b[col];
    }
  }

  return List.generate(n, (i) => a[i][i].abs() < 1e-12 ? 0.0 : b[i] / a[i][i]);
}

List<double> _applyHomography(List<double> h, double u, double v) {
  final denom = h[6] * u + h[7] * v + 1;
  final x = (h[0] * u + h[1] * v + h[2]) / denom;
  final y = (h[3] * u + h[4] * v + h[5]) / denom;
  return [x, y];
}

List<int> _bilinearSample(
  Uint8List rgba,
  int width,
  int height,
  double x,
  double y,
) {
  final cx = x.clamp(0.0, width - 1.0);
  final cy = y.clamp(0.0, height - 1.0);

  final x0 = cx.floor();
  final y0 = cy.floor();
  final x1 = (x0 + 1).clamp(0, width - 1);
  final y1 = (y0 + 1).clamp(0, height - 1);

  final fx = cx - x0;
  final fy = cy - y0;

  List<int> pixel(int px, int py) {
    final idx = (py * width + px) * 4;
    return [rgba[idx], rgba[idx + 1], rgba[idx + 2], rgba[idx + 3]];
  }

  final p00 = pixel(x0, y0);
  final p10 = pixel(x1, y0);
  final p01 = pixel(x0, y1);
  final p11 = pixel(x1, y1);

  List<int> lerp(List<int> a, List<int> b, double t) =>
      List.generate(4, (i) => (a[i] + (b[i] - a[i]) * t).round());

  final top = lerp(p00, p10, fx);
  final bottom = lerp(p01, p11, fx);
  return lerp(top, bottom, fy);
}

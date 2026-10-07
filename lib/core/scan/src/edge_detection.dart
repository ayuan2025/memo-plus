// Vendored from OpenScan v3.0.0 — https://github.com/ethereal-developers/OpenScan
// BSD 3-Clause License, Copyright (c) 2021, Vijay T S and Vikram H.
// See `third_party/openscan_cv/` for the full license text and the list of
// local adaptations.

import 'dart:math';
import 'dart:typed_data';

import 'image_ops.dart';

/// Pure-Dart replacements for the OpenCV grayscale/blur/edge/dilate/threshold
/// steps OpenScan used to run natively via
/// `Imgproc.cvtColor`/`GaussianBlur`/`Canny`/`dilate`/`threshold`.
///
/// All functions operate on flat byte buffers rather than package-specific
/// image objects, so they stay cheap to run inside an isolate and easy to unit
/// test.

/// Converts an RGBA buffer (stride 4) to a single-channel luminance buffer.
Uint8List rgbaToGrayscale(Uint8List rgba, int width, int height) {
  final gray = Uint8List(width * height);
  for (int i = 0, p = 0; p < gray.length; i += 4, p++) {
    final r = rgba[i], g = rgba[i + 1], b = rgba[i + 2];
    gray[p] = (0.2126 * r + 0.7152 * g + 0.0722 * b).round().clamp(0, 255);
  }
  return gray;
}

/// A 3x3 Gaussian blur (approximating OpenCV's `GaussianBlur(3x3)`).
Uint8List gaussianBlur3(Uint8List gray, int width, int height) {
  final out = Uint8List(width * height);
  const kernel = [1, 2, 1, 2, 4, 2, 1, 2, 1];
  const kernelSum = 16;

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      int sum = 0;
      int k = 0;
      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          final sx = (x + dx).clamp(0, width - 1);
          final sy = (y + dy).clamp(0, height - 1);
          sum += gray[sy * width + sx] * kernel[k++];
        }
      }
      out[y * width + x] = (sum / kernelSum).round().clamp(0, 255);
    }
  }
  return out;
}

/// Sobel gradient magnitude, clamped to 0-255. Stands in for OpenCV's `Canny`
/// step: rather than reproducing full non-max-suppression plus hysteresis, the
/// magnitude image is thresholded (see [otsuThreshold]) and then
/// dilated/closed, which is sufficient to find the outer boundary of a
/// photographed document.
Uint8List sobelMagnitude(Uint8List gray, int width, int height) {
  final out = Uint8List(width * height);

  int at(int x, int y) {
    final cx = x.clamp(0, width - 1);
    final cy = y.clamp(0, height - 1);
    return gray[cy * width + cx];
  }

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final gx =
          -at(x - 1, y - 1) -
          2 * at(x - 1, y) -
          at(x - 1, y + 1) +
          at(x + 1, y - 1) +
          2 * at(x + 1, y) +
          at(x + 1, y + 1);
      final gy =
          -at(x - 1, y - 1) -
          2 * at(x, y - 1) -
          at(x + 1, y - 1) +
          at(x - 1, y + 1) +
          2 * at(x, y + 1) +
          at(x + 1, y + 1);
      final mag = sqrt((gx * gx + gy * gy).toDouble());
      out[y * width + x] = mag.clamp(0.0, 255.0).round();
    }
  }
  return out;
}

/// Otsu's method: picks a global threshold that best separates a bimodal
/// histogram, standing in for OpenCV's `THRESH_TRIANGLE`.
int otsuThreshold(Uint8List image) {
  final hist = List<int>.filled(256, 0);
  for (final v in image) {
    hist[v]++;
  }

  final total = image.length;
  double sum = 0;
  for (int i = 0; i < 256; i++) {
    sum += i * hist[i];
  }

  double sumB = 0;
  int wB = 0;
  double maxVariance = -1;
  int threshold = 128;

  for (int t = 0; t < 256; t++) {
    wB += hist[t];
    if (wB == 0) continue;
    final wF = total - wB;
    if (wF == 0) break;

    sumB += t * hist[t];
    final mB = sumB / wB;
    final mF = (sum - sumB) / wF;
    final between = wB * wF * (mB - mF) * (mB - mF);
    if (between > maxVariance) {
      maxVariance = between;
      threshold = t;
    }
  }
  return threshold;
}

/// Robust threshold for a Sobel gradient-magnitude buffer.
///
/// Otsu's method is built for a bimodal histogram: it looks for the split that
/// maximises between-class variance, which only means something when the data
/// really is two modes. A gradient-magnitude buffer is not two modes, it is one
/// spike near zero with a long tail of text and paper-crease edges running out
/// of it. Otsu still returns something usable on that distribution — it lands
/// near the top of the spike — but it is sensitive to exactly the wrong input:
/// a frame with a reflection washing over it shifts the spike, and the
/// threshold shifts with it, frame to frame, even though the scene never moved.
///
/// A quantile of the magnitudes does not care how much of the image is flat
/// background. It answers the question actually being asked — "magnitude high
/// enough to be an edge?" — directly, and it stays put when the flat regions
/// brighten or darken.
///
/// [percentile] is the share of pixels allowed to fall *below* the returned
/// value, so 0.85 means "the top 15% of the frame's gradients are edges".
///
/// Reading the histogram from the top down finds the largest value that still
/// has at least [percentile] of the data beneath it, which is precisely the
/// quantile — scanning up from zero would return the smallest such value.
int percentileThreshold(Uint8List image, {double percentile = 0.85}) {
  if (image.isEmpty) return 0;

  final hist = List<int>.filled(256, 0);
  for (final v in image) {
    hist[v]++;
  }

  final target = image.length * percentile.clamp(0.0, 1.0);
  var cumulative = 0;
  for (var v = 255; v > 0; v--) {
    cumulative += hist[v];
    if (cumulative >= target) return v;
  }
  // Fewer than 1/255 of the pixels are non-zero: nothing in the frame has an
  // edge worth outlining, and any threshold is as good as another.
  return 0;
}

/// Binarizes [image] against threshold [t]: returns a 0/1 mask.
Uint8List threshold(Uint8List image, int t) {
  final out = Uint8List(image.length);
  for (int i = 0; i < image.length; i++) {
    out[i] = image[i] >= t ? 1 : 0;
  }
  return out;
}

/// Binary dilation with a roughly `(2*radius+1)` square structuring element,
/// implemented as two separable max-filter passes (O(n*radius) instead of
/// O(n*radius^2)) — stands in for OpenCV's `dilate(9x9)`.
Uint8List dilate(Uint8List mask, int width, int height, int radius) {
  final rowPass = Uint8List(width * height);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      int v = 0;
      for (int dx = -radius; dx <= radius && v == 0; dx++) {
        final sx = x + dx;
        if (sx < 0 || sx >= width) continue;
        if (mask[y * width + sx] == 1) v = 1;
      }
      rowPass[y * width + x] = v;
    }
  }

  final out = Uint8List(width * height);
  for (int x = 0; x < width; x++) {
    for (int y = 0; y < height; y++) {
      int v = 0;
      for (int dy = -radius; dy <= radius && v == 0; dy++) {
        final sy = y + dy;
        if (sy < 0 || sy >= height) continue;
        if (rowPass[sy * width + x] == 1) v = 1;
      }
      out[y * width + x] = v;
    }
  }
  return out;
}

/// Scale the boundary gradient is measured at, as a fraction of the work
/// image's longest side.
///
/// This is the single most consequential number in the detector. At the 3x3
/// scale the pipeline used to work at, a photographed page's edge competes with
/// everything else that produces a luminance step a few pixels wide: wood
/// grain, marble speckling, leather creases, and the document's own text. On
/// the sample photos that motivated this parameter those fine textures won and
/// the paper lost, so detection latched either onto a block of text well inside
/// the sheet or onto the picture's own border.
///
/// A page's boundary is a step that survives smoothing; the textures above are
/// not. Measuring the gradient after a blur of roughly 0.8% of the frame's
/// longest side keeps the step and drops the texture.
const double kBoundaryBlurFraction = 0.008;

/// Weight given to the chroma gradient when it is fused with the luminance one.
///
/// Both terms are Sobel magnitudes over a Rec.601 plane. Rec.601 is close
/// enough to perceptually uniform that a unit of Cb costs roughly what a unit
/// of Y does, so equal weight is the neutral choice rather than a number picked
/// to make one sample pass: chroma then only ever wins where the luminance step
/// genuinely is smaller than the colour step — a pale sheet on a pale surface
/// of a different hue — which is exactly the case luminance alone cannot see.
const double kChromaGradientWeight = 1.0;

/// Boundary-detection gradient magnitude: luminance *and* chroma, measured at
/// [kBoundaryBlurFraction] of the frame rather than at 3x3.
///
/// [rgbaToGrayscale] + [sobelMagnitude] is the fine-scale, luminance-only
/// gradient; this is the gradient for finding *where a sheet of paper ends*,
/// and differs in both respects:
///
/// * **Chroma.** A page usually differs from the surface under it in hue before
///   it differs in brightness — a cream receipt on a warm wood table, a pale
///   blue ID card on an off-white tile, a yellow sticky note on a white desk.
///   Rec.601 Cb/Cr carry that difference; a single luminance number cannot.
/// * **Scale.** See [kBoundaryBlurFraction] for why 3x3 is the wrong scale to
///   ask the question at.
///
/// Takes the RGBA buffer rather than a grayscale one precisely because of the
/// chroma term: by the time luminance has been reduced to one plane the hue
/// information is gone.
Uint8List documentEdgeMagnitude(
  Uint8List rgba,
  int width,
  int height, {
  double chromaWeight = kChromaGradientWeight,
}) {
  if (width <= 0 || height <= 0) return Uint8List(0);

  final radius = max(1, (max(width, height) * kBoundaryBlurFraction).round());

  final luma = Uint8List(width * height);
  final blue = Uint8List(width * height);
  final red = Uint8List(width * height);
  for (int i = 0, p = 0; p < luma.length; i += 4, p++) {
    final r = rgba[i], g = rgba[i + 1], b = rgba[i + 2];
    luma[p] = (0.299 * r + 0.587 * g + 0.114 * b).round().clamp(0, 255);
    blue[p] =
        (128 - 0.168736 * r - 0.331264 * g + 0.5 * b).round().clamp(0, 255);
    red[p] =
        (128 + 0.5 * r - 0.418688 * g - 0.081312 * b).round().clamp(0, 255);
  }

  final smoothLuma = boxBlurGray(luma, width, height, radius);
  final smoothBlue = boxBlurGray(blue, width, height, radius);
  final smoothRed = boxBlurGray(red, width, height, radius);

  int at(int x, int y) =>
      y.clamp(0, height - 1) * width + x.clamp(0, width - 1);

  double gx(Uint8List plane, int x, int y) =>
      (-plane[at(x - 1, y - 1)] -
              2 * plane[at(x - 1, y)] -
              plane[at(x - 1, y + 1)] +
              plane[at(x + 1, y - 1)] +
              2 * plane[at(x + 1, y)] +
              plane[at(x + 1, y + 1)])
          .toDouble();

  double gy(Uint8List plane, int x, int y) =>
      (-plane[at(x - 1, y - 1)] -
              2 * plane[at(x, y - 1)] -
              plane[at(x + 1, y - 1)] +
              plane[at(x - 1, y + 1)] +
              2 * plane[at(x, y + 1)] +
              plane[at(x + 1, y + 1)])
          .toDouble();

  final out = Uint8List(width * height);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final luminance =
          sqrt(pow(gx(smoothLuma, x, y), 2) + pow(gy(smoothLuma, x, y), 2));
      final chroma = sqrt(
        pow(gx(smoothBlue, x, y), 2) +
            pow(gy(smoothBlue, x, y), 2) +
            pow(gx(smoothRed, x, y), 2) +
            pow(gy(smoothRed, x, y), 2),
      );
      out[y * width + x] =
          max(luminance, chromaWeight * chroma).clamp(0.0, 255.0).round();
    }
  }
  return out;
}

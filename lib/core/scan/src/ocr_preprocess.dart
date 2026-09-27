// Makes a scanned page easier for an on-device text recogniser to read.
//
// A photo of paper is not a scan of paper: it carries whatever light the room
// had, and the phone's own shadow usually crosses part of it. A recogniser sees
// that gradient as meaningful — ink gets lighter in the bright third and
// disappears, background gets darker in the shadowed third and turns into
// strokes. This file removes the *illumination* and keeps the *reflectance*,
// which is the thing the ink actually encodes.
//
// Deliberately Flutter-free so it is unit-testable without a widget tree.

import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Longest edge the recogniser's input is capped at, in pixels.
///
/// Deliberately above the edge a rendered page is stored at (see
/// `kStoredPageMaxEdge`, 2400). Capping below that would resample every glyph a
/// second time on its way to the recogniser, and a Chinese glyph is the worst
/// possible thing to resample: a dozen strokes packed into a couple of dozen
/// pixels, where averaging two neighbouring strokes together is the difference
/// between 日 and 目. The cap still exists to bound a pathological input, it
/// just no longer bites the ordinary one.
const int kOcrInputMaxEdge = 3000;

/// Short edge, in pixels, that the illumination estimate is computed at.
///
/// Illumination is a low-frequency signal by definition — that is what makes it
/// separable from ink — so estimating it at a fraction of full resolution costs
/// a fraction of the time and changes nothing about the result.
const int kOcrBackgroundSampleShortEdge = 320;

/// How much of the darkest/brightest distribution each level discards when
/// stretching levels, as a fraction of pixels.
///
/// A single dust speck or a blown highlight would otherwise pin the whole
/// range. The `aggressive` variant clips harder: it gives up faithfulness to
/// the original tone in exchange for pushing faint ink further from the paper.
/// Balanced clips gently because it is no longer the first thing to touch the
/// levels: the page reaching this file has usually been through the scanner's
/// `Auto` filter, which already auto-levelled every channel. Stretching a
/// second time takes what was a light stroke and drives it to solid black, and
/// on dense CJK that thickens each stroke until neighbouring ones meet.
const double kBalancedClipFraction = 0.005;
const double kAggressiveClipFraction = 0.02;

/// Linear contrast boost applied after stretching, for the `aggressive` level.
const double kAggressiveContrast = 1.25;

/// Brightest level the background estimate is allowed to fall to.
///
/// Dividing by a near-black background amplifies sensor noise faster than it
/// recovers ink, so very dark regions are treated as merely dark. This is what
/// stops a page photographed against something black from turning into static.
const int kBackgroundFloor = 40;

/// How strongly to trade faithfulness for legibility.
enum OcrPreprocessLevel {
  /// Removes the illumination gradient and adjusts levels mildly. Safe to run
  /// on every page, including well-lit ones, which it barely changes.
  balanced,

  /// Clips the levels harder and boosts contrast. Used when the first pass
  /// read nothing — the page was probably faint, grey or unevenly lit.
  aggressive,

  /// Removes the illumination and leaves the levels alone.
  ///
  /// Every other level trades faithfulness for legibility by pushing ink
  /// towards black. That is the right trade for faint print and the wrong one
  /// for dense small type: a Chinese glyph at contract-font size already has
  /// strokes two or three pixels apart, and thickening them is what turns 未
  /// into 末. When a page reads poorly it is worth asking whether the levels
  /// were the problem before assuming the print was.
  flat,
}

/// Per-level tuning resolved from an [OcrPreprocessLevel].
typedef OcrPreprocessTuning = ({double clipFraction, double contrast});

OcrPreprocessTuning _tuningFor(OcrPreprocessLevel level) => switch (level) {
  OcrPreprocessLevel.balanced => (
    clipFraction: kBalancedClipFraction,
    contrast: 1.0,
  ),
  OcrPreprocessLevel.aggressive => (
    clipFraction: kAggressiveClipFraction,
    contrast: kAggressiveContrast,
  ),
  // A zero clip makes the stretch a no-op: the search for the low bound stops
  // on the first bin it meets, which is level 0, and the high bound likewise
  // stops at 255, so the scale comes out as exactly 1.
  OcrPreprocessLevel.flat => (
    clipFraction: 0.0,
    contrast: 1.0,
  ),
};

/// Returns [encoded] re-encoded as the grey page a recogniser reads best, or
/// [encoded] unchanged when it could not be processed.
///
/// Never throws: a scan that cannot be preprocessed is still worth sending to
/// the recogniser as it stands, which is what returning the input achieves.
Uint8List preprocessPageForOcr(
  Uint8List encoded, {
  OcrPreprocessLevel level = OcrPreprocessLevel.balanced,
}) {
  try {
    final decoded = img.decodeImage(encoded);
    if (decoded == null) return encoded;

    final page = _capToInputSize(decoded);
    final gray = _readLuminance(page);
    final flat = _flattenIllumination(gray, page.width, page.height);

    final tuning = _tuningFor(level);
    final stretched = _adjustLevels(
      flat,
      clipFraction: tuning.clipFraction,
      contrast: tuning.contrast,
    );

    return _encodeGrayPng(stretched, page.width, page.height);
  } catch (_) {
    return encoded;
  }
}

/// [image] scaled down so its long edge fits the recogniser's input cap.
///
/// Reuses the averaging the scanner already needs elsewhere so a page is never
/// resampled twice on its way to being read.
img.Image _capToInputSize(img.Image image) {
  final longest = max(image.width, image.height);
  if (longest <= kOcrInputMaxEdge) return image;
  final scale = kOcrInputMaxEdge / longest;
  return img.copyResize(
    image,
    width: max(1, (image.width * scale).round()),
    height: max(1, (image.height * scale).round()),
    interpolation: img.Interpolation.average,
  );
}

/// The page's luminance as one tight row-major buffer.
///
/// Read through [img.grayscale] rather than a hand-rolled weighting so the
/// transfer function matches what the rest of the scanner uses. After that
/// every channel holds the same value, so which channel is read is irrelevant
/// and no assumption is made about the decoded channel order.
Uint8List _readLuminance(img.Image source) {
  final gray = img.grayscale(source);
  final out = Uint8List(gray.width * gray.height);
  var index = 0;
  for (final pixel in gray) {
    if (index >= out.length) break;
    out[index++] = pixel.r.toInt().clamp(0, 255);
  }
  return out;
}

/// Divides [gray] by its own illumination so only local darkness — the ink —
/// survives.
///
/// The illumination is estimated by blurring a downscaled copy. Blurring keeps
/// only frequencies too low to have been drawn by a pen; downscaling first is
/// what makes that blur cheap, and the estimate is bilinearly resampled back
/// up to full resolution once per pixel rather than ever being materialised at
/// full size.
Uint8List _flattenIllumination(Uint8List gray, int width, int height) {
  final shortEdge = min(width, height);
  if (shortEdge < 8 || width <= 0 || height <= 0) return gray;

  final factor = max(1, (shortEdge / kOcrBackgroundSampleShortEdge).ceil());
  final smallWidth = ((width + factor - 1) ~/ factor).clamp(1, width);
  final smallHeight = ((height + factor - 1) ~/ factor).clamp(1, height);

  final small = _boxDownsample(gray, width, height, factor, smallWidth, smallHeight);
  final background = _boxBlurGray(
    small,
    smallWidth,
    smallHeight,
    max(1, (shortEdge / 24 / factor).round()),
  );

  final out = Uint8List(width * height);
  for (int y = 0; y < height; y++) {
    final sourceY = y / factor;
    for (int x = 0; x < width; x++) {
      final level = _bilinearAt(background, smallWidth, smallHeight, x / factor, sourceY);
      final denominator = level < kBackgroundFloor ? kBackgroundFloor : level;
      final value = (gray[y * width + x] * 255) ~/ denominator;
      out[y * width + x] = value.clamp(0, 255);
    }
  }
  return out;
}

/// Average-downsamples [src] by [factor] into a `smallWidth`x`smallHeight`
/// buffer.
Uint8List _boxDownsample(
  Uint8List src,
  int width,
  int height,
  int factor,
  int smallWidth,
  int smallHeight,
) {
  final out = Uint8List(smallWidth * smallHeight);
  final count = factor * factor;
  for (int sy = 0; sy < smallHeight; sy++) {
    for (int sx = 0; sx < smallWidth; sx++) {
      var sum = 0;
      for (int dy = 0; dy < factor; dy++) {
        final y = sy * factor + dy;
        if (y >= height) break;
        final row = y * width;
        for (int dx = 0; dx < factor; dx++) {
          final x = sx * factor + dx;
          if (x >= width) break;
          sum += src[row + x];
        }
      }
      out[sy * smallWidth + sx] = (sum / count).round().clamp(0, 255);
    }
  }
  return out;
}

/// Separable box blur, run twice so the result approximates a Gaussian.
///
/// A box kernel is O(1) per pixel regardless of [radius] because it keeps a
/// running sum; two passes are enough here because what matters is only that
/// nothing the size of a stroke can survive.
Uint8List _boxBlurGray(Uint8List src, int width, int height, int radius) {
  if (radius <= 0 || width <= 0 || height <= 0) return src;
  var current = _boxBlurPass(src, width, height, radius);
  current = _boxBlurPass(current, width, height, radius);
  return current;
}

/// One separable pass: vertical then horizontal.
Uint8List _boxBlurPass(Uint8List src, int width, int height, int radius) {
  final vertical = Uint8List(width * height);
  for (int x = 0; x < width; x++) {
    var sum = 0;
    var count = 0;
    for (int y = -radius; y <= radius; y++) {
      if (y < 0 || y >= height) continue;
      sum += src[y * width + x];
      count++;
    }
    for (int y = 0; y < height; y++) {
      vertical[y * width + x] = count == 0 ? src[y * width + x] : (sum ~/ count);
      final outgoing = y - radius;
      final incoming = y + radius + 1;
      if (outgoing >= 0 && outgoing < height) {
        sum -= src[outgoing * width + x];
        count--;
      }
      if (incoming >= 0 && incoming < height) {
        sum += src[incoming * width + x];
        count++;
      }
      if (count == 0) {
        final nextY = (incoming).clamp(0, height - 1);
        sum = src[nextY * width + x];
        count = 1;
      }
    }
  }

  final out = Uint8List(width * height);
  for (int y = 0; y < height; y++) {
    final row = y * width;
    var sum = 0;
    var count = 0;
    for (int x = -radius; x <= radius; x++) {
      if (x < 0 || x >= width) continue;
      sum += vertical[row + x];
      count++;
    }
    for (int x = 0; x < width; x++) {
      out[row + x] = count == 0 ? vertical[row + x] : (sum ~/ count);
      final outgoing = x - radius;
      final incoming = x + radius + 1;
      if (outgoing >= 0 && outgoing < width) {
        sum -= vertical[row + outgoing];
        count--;
      }
      if (incoming >= 0 && incoming < width) {
        sum += vertical[row + incoming];
        count++;
      }
      if (count == 0) {
        sum = vertical[row + (incoming).clamp(0, width - 1)];
        count = 1;
      }
    }
  }
  return out;
}

/// [buffer] sampled at the fractional coordinate (`x`, `y`).
int _bilinearAt(Uint8List buffer, int width, int height, double x, double y) {
  final x0 = x.floor().clamp(0, width - 1);
  final y0 = y.floor().clamp(0, height - 1);
  final x1 = (x0 + 1).clamp(0, width - 1);
  final y1 = (y0 + 1).clamp(0, height - 1);
  final fx = x - x0;
  final fy = y - y0;

  final top = buffer[y0 * width + x0] * (1 - fx) + buffer[y0 * width + x1] * fx;
  final bottom = buffer[y1 * width + x0] * (1 - fx) + buffer[y1 * width + x1] * fx;
  return (top * (1 - fy) + bottom * fy).round().clamp(0, 255);
}

/// Maps [`clipFraction`, 1-`clipFraction`] of the histogram onto full range,
/// then optionally boosts contrast around mid grey.
Uint8List _adjustLevels(
  Uint8List gray, {
  required double clipFraction,
  required double contrast,
}) {
  if (gray.isEmpty) return gray;

  final histogram = List<int>.filled(256, 0);
  for (final value in gray) {
    histogram[value]++;
  }

  final clipCount = (gray.length * clipFraction).round().clamp(0, gray.length);
  var low = 0;
  var high = 255;
  var seen = 0;
  for (int level = 0; level < 256; level++) {
    seen += histogram[level];
    if (seen >= clipCount) {
      low = level;
      break;
    }
  }
  seen = 0;
  for (int level = 255; level >= 0; level--) {
    seen += histogram[level];
    if (seen >= clipCount) {
      high = level;
      break;
    }
  }
  if (high <= low) {
    high = min(255, low + 1);
  }

  final scale = 255.0 / (high - low);
  final out = Uint8List(gray.length);
  for (int i = 0; i < gray.length; i++) {
    var value = (gray[i] - low) * scale;
    if (contrast != 1.0) {
      value = (value - 128) * contrast + 128;
    }
    out[i] = value.round().clamp(0, 255);
  }
  return out;
}

/// Encodes single-channel samples as a grey PNG.
///
/// PNG rather than JPEG because JPEG's 8x8 blocks leave ringing along the hard
/// vertical edges of every glyph, and it is exactly those edges the recogniser
/// reads. The cost is a larger temp file, which is not a cost worth optimising
/// for a file that is deleted a moment later.
Uint8List _encodeGrayPng(Uint8List gray, int width, int height) {
  final page = img.Image.fromBytes(
    width: width,
    height: height,
    bytes: gray.buffer,
    numChannels: 1,
    order: img.ChannelOrder.red,
  );
  return img.encodePng(page);
}

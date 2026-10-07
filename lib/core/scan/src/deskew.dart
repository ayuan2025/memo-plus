// Vendored-from-OpenScan neighbours handle the hard geometry — a photographed
// page gets warped to its detected quad, which straightens it by construction.
// What nothing else in this package straightens is the page that arrives
// already trimmed: a gallery import or a screenshot carries no paper edge to
// find, so it passes through whole (see `full_frame_page.dart`), tilt and all.
// This file is the straightener for exactly that case.

import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Skew angles below this are left alone.
///
/// A rotation is a resample: it costs sharpness even with a good filter, so a
/// page that is upright to within half a degree — the accuracy of this
/// estimator itself — is better kept exactly as it was.
const double kDeskewMinAngleDegrees = 0.5;

/// Skew angles beyond this are treated as orientation, not skew.
///
/// A page on its side does not need straightening, it needs a quarter turn,
/// and that decision needs to read the text (see the scan orientation
/// detector). An estimator that happily "straightened" a sideways page by 87°
/// would leave it cropped from corner to corner.
const double kDeskewMaxAngleDegrees = 15;

/// Long edge of the copy the angle is measured on.
///
/// The estimator only needs text rows to be distinguishable from gaps, which
/// survives heavy downscaling; measuring on a full-resolution page would
/// multiply the work by the pixel count for no extra accuracy.
const int kDeskewAnalysisMaxEdge = 480;

/// Step between candidate angles, in degrees.
///
/// With a ±15° window this is 121 candidates. The accumulation per candidate is
/// one fused multiply-add per analysed pixel, so the whole sweep stays in the
/// tens of milliseconds on the isolate even at this step size.
const double kDeskewStepDegrees = 0.25;

/// Fraction of the page that has to be ink for tilt to mean anything.
///
/// A page whose binarised copy is almost all one value has no text rows to
/// align — a photo of a wall, a blank margin — and any "angle" found there is
/// noise. Below this ink fraction the estimate is reported as upright.
const double kDeskewMinInkFraction = 0.01;

/// Estimates how far the text on [page] is tilted, in degrees.
///
/// Positive means the text runs downhill to the right — the page would have to
/// be rotated counter-clockwise to straighten it. Returns 0 when the page has
/// no readable text structure, is already upright to within
/// [kDeskewMinAngleDegrees], or is tilted beyond [kDeskewMaxAngleDegrees] (that
/// is a quarter-turn problem, not a skew problem).
///
/// The method is a projection-profile sweep: for each candidate angle the
/// binarised page's ink is accumulated into row bins along `y − x·tan(angle)`,
/// and the angle whose profile is the *spikiest* — text rows concentrating into
/// few bins, gaps into the rest — is the tilt. No per-candidate rotation of the
/// image is needed; the shear is done in the accumulation index, which is what
/// keeps the whole sweep cheap enough to run on every full-page import.
double estimatePageSkewAngle(
  img.Image page, {
  double minAngle = -kDeskewMaxAngleDegrees,
  double maxAngle = kDeskewMaxAngleDegrees,
  double stepDegrees = kDeskewStepDegrees,
}) {
  if (page.width < 24 || page.height < 24) return 0;

  // The measurement copy: grayscale, small enough that the sweep is a few
  // million integer operations rather than a few hundred million.
  final longEdge = math.max(page.width, page.height);
  final scale = longEdge > kDeskewAnalysisMaxEdge
      ? kDeskewAnalysisMaxEdge / longEdge
      : 1.0;
  final small = scale < 1.0
      ? img.copyResize(
          page,
          width: (page.width * scale).round(),
          height: (page.height * scale).round(),
          interpolation: img.Interpolation.average,
        )
      : page;
  final gray = img.grayscale(small);

  final width = gray.width;
  final height = gray.height;
  final pixels = width * height;

  // Text on paper is a minority of the page: binarise with the midpoint as a
  // cheap adaptive threshold — darker than the average luminance is ink.
  var sum = 0;
  final luma = List<int>.filled(pixels, 0);
  var index = 0;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final pixel = gray.getPixel(x, y);
      final l = pixel.luminance.toInt();
      luma[index++] = l;
      sum += l;
    }
  }
  final mean = sum / pixels;

  // Ink coordinates, in analysis space, kept once: every candidate angle reads
  // the same list with a different shear index.
  final inkX = <int>[];
  final inkY = <int>[];
  for (var i = 0; i < pixels; i++) {
    if (luma[i] < mean * 0.75) {
      inkX.add(i % width);
      inkY.add(i ~/ width);
    }
  }
  final inkCount = inkX.length;
  // Not enough structure to align, or too much (the binarisation collapsed the
  // whole page to ink — a dark photo): neither says anything about tilt.
  if (inkCount < 64 || inkCount > pixels * 0.5) return 0;
  if (inkCount < pixels * kDeskewMinInkFraction) return 0;

  // Sweep candidate angles, scoring each by the variance of its row profile.
  // A correctly aligned angle puts every text row's ink into one bin and the
  // gaps between rows into neighbours, which maximises the spread of bin sums.
  var bestAngle = 0.0;
  var bestScore = -1.0;
  final binCount = height;
  final bins = List<double>.filled(binCount, 0);
  for (var angle = minAngle; angle <= maxAngle + 1e-9; angle += stepDegrees) {
    // A tilt is an angle, so it survives the uniform downscale unchanged: the
    // shear applied to the analysis copy's coordinates is simply tan(angle).
    final shear = math.tan(angle * math.pi / 180.0);
    bins.fillRange(0, binCount, 0);

    for (var i = 0; i < inkCount; i++) {
      final shifted = inkY[i] - inkX[i] * shear;
      final bin = shifted.round();
      if (bin >= 0 && bin < binCount) bins[bin] += 1;
    }

    var total = 0.0;
    var squared = 0.0;
    for (final value in bins) {
      total += value;
      squared += value * value;
    }
    final meanBin = total / binCount;
    // Variance without allocating a second list: Σv²/n − mean².
    final variance = squared / binCount - meanBin * meanBin;
    if (variance > bestScore) {
      bestScore = variance;
      bestAngle = angle;
    }
  }

  // A confident tilt should beat the no-rotation profile by a clear margin;
  // otherwise the page is upright and the resample is not worth it.
  final uprightShear = 0.0;
  bins.fillRange(0, binCount, 0);
  for (var i = 0; i < inkCount; i++) {
    final bin = (inkY[i] - inkX[i] * uprightShear).round();
    if (bin >= 0 && bin < binCount) bins[bin] += 1;
  }
  var total = 0.0;
  var squared = 0.0;
  for (final value in bins) {
    total += value;
    squared += value * value;
  }
  final meanBin = total / binCount;
  final uprightVariance = squared / binCount - meanBin * meanBin;
  if (bestScore <= uprightVariance * 1.15) return 0;

  if (bestAngle.abs() < kDeskewMinAngleDegrees) return 0;
  if (bestAngle.abs() > kDeskewMaxAngleDegrees) return 0;
  return bestAngle;
}

/// Returns [page] rotated so its text runs horizontally, or the page itself
/// when [estimatePageSkewAngle] finds nothing worth correcting.
img.Image deskewPage(img.Image page) {
  final angle = estimatePageSkewAngle(page);
  if (angle == 0) return page;
  // The estimate is "how far the text runs downhill": the fix is the opposite
  // rotation. `copyRotate`'s positive direction is clockwise, and text running
  // downhill (positive estimate) is page content that was rotated clockwise —
  // so the correction is a counter-clockwise turn, i.e. a negative angle.
  return img.copyRotate(page, angle: -angle, interpolation: img.Interpolation.cubic);
}

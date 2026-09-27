import 'dart:math' as math;
import 'dart:typed_data';

import 'models/point.dart';
import 'models/quad.dart';

/// Refines the corners of a detected document boundary by fitting a line
/// through the edge pixels on each side of it.
///
/// Contours are simplified before their corners are read, and what a
/// simplification keeps is a *vertex worth keeping* — a bump or a notch in the
/// outline — not necessarily the point where the paper's edge really turns.
/// Running the corner search on such a vertex puts the box a couple of pixels
/// off each side, and a couple of pixels is enough to shave the corner of the
/// sheet or leave a sliver of desk in the crop.
///
/// Each of the four sides is therefore re-fitted: the ridge of strong gradient
/// lying alongside it is sampled along its whole length, a line is fitted
/// through those samples with total least squares (so a near-vertical edge,
/// where fitting `y` as a function of `x` would be ill-conditioned, behaves
/// like any other), and the four fitted lines are intersected pairwise to give
/// the corners. The result is the paper's geometry rather than the silhouette's
/// jaggedness.
///
/// Pure and isolate-safe: no I/O, no platform channels.

/// How far either side of a side's own chord edge pixels are allowed to sit and
/// still count as belonging to it, as a fraction of that side's length. Wide
/// enough to swallow a corner that the simplification nudged, tight enough that
/// the opposite side of the page can't contribute.
const double kRefineBandFraction = 0.12;

/// Share of each end of a side left out of its own fit.
///
/// Close to a corner, the neighbouring side's edge pixels are within the band
/// too, and folding them into this side's fit rotates it towards that
/// neighbour — which is how one bad side used to drag the whole box off.
const double kEndMargin = 0.15;

/// Half-width of the second pass's cross-sections, in pixels. Once the wide
/// pass has said roughly where the ridge is, this is all it takes to settle it.
const double kTightBand = 3.0;

/// How far a refined corner may sit from the coarse one before the refinement
/// is thrown away for that corner, as a fraction of the quad's diagonal.
///
/// Refinement assumes the contour search was close but not exact. When it was
/// wrong outright — a reflection, the desk's own edge — the "refined" answer is
/// confidently wrong, and the user sees the box leap across the frame.
/// Anything beyond this distance keeps the corner the search originally found.
///
/// Deliberately loose: a simplification that cut a corner short can legitimately
/// ask for several percent of the diagonal back, and rejecting those would cost
/// more than the rare wild fit this is here to stop.
const double kMaxCornerShiftFraction = 0.10;

/// Refits the four corners of [coarse] against the edges in [magnitude], which
/// is the Sobel gradient magnitude the boundary was found in.
///
/// [threshold] is the value the magnitude was already binarized at.
///
/// The returned quad is in the same coordinate space as [coarse]. If a fitted
/// line turns out to be unusable — parallel neighbours, no gradient at all, or
/// a corner that lands implausibly far from where the search put it — the
/// corresponding corner is kept as it was rather than invented.
Quad refineQuadCorners(
  Quad coarse,
  Uint8List magnitude,
  int width,
  int height,
  int threshold,
) {
  final sides = <(Pt from, Pt to)>[
    (coarse.topLeft, coarse.topRight),
    (coarse.topRight, coarse.bottomRight),
    (coarse.bottomRight, coarse.bottomLeft),
    (coarse.bottomLeft, coarse.topLeft),
  ];

  final fitted = <_Line>[];
  for (final side in sides) {
    fitted.add(_fitSide(side.$1, side.$2, magnitude, width, height, threshold));
  }

  final diagonal = math.sqrt(
    math.pow(coarse.bottomRight.x - coarse.topLeft.x, 2) +
        math.pow(coarse.bottomRight.y - coarse.topLeft.y, 2),
  );
  final maxShift = diagonal * kMaxCornerShiftFraction;

  // Corner i belongs to side i-1 and side i *both*, so the corner itself is
  // where those two fitted lines cross — not side i and its neighbour, which
  // would hand back the same four points under the wrong labels.
  final corners = <Pt>[];
  for (var i = 0; i < 4; i++) {
    final previous = (i + 3) % 4;
    final intersection = _intersect(fitted[previous], fitted[i]);
    final fallback = _cornerOf(coarse, i);
    if (intersection == null) {
      corners.add(fallback);
      continue;
    }
    final moved = _distance(intersection, fallback);
    if (moved > maxShift) {
      corners.add(fallback);
      continue;
    }
    corners.add(_clampToFrame(intersection, width, height));
  }

  return Quad(
    topLeft: corners[0],
    topRight: corners[1],
    bottomRight: corners[2],
    bottomLeft: corners[3],
  );
}

Pt _cornerOf(Quad coarse, int index) {
  return switch (index) {
    0 => coarse.topLeft,
    1 => coarse.topRight,
    2 => coarse.bottomRight,
    _ => coarse.bottomLeft,
  };
}

Pt _clampToFrame(Pt p, int width, int height) => Pt(
  p.x.clamp(0.0, width - 1.0),
  p.y.clamp(0.0, height - 1.0),
);

double _distance(Pt a, Pt b) =>
    math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));

/// A line as `a*x + b*y + c = 0` with `a*a + b*b == 1`.
class _Line {
  const _Line(this.a, this.b, this.c);

  final double a;
  final double b;
  final double c;
}

/// Fits a line through the ridge of strong gradient lying alongside the segment
/// [from]-[to], or returns a line through the segment itself when there is too
/// little gradient to fit anything confident.
///
/// Two things make this robust against the clutter printed on a page. Each
/// station along the side contributes the *strongest* gradient pixel in its
/// narrow cross-section rather than every pixel above the threshold, so a row
/// of text running parallel to the edge contributes one point like any other
/// instead of dragging the fit towards itself. And the fit runs twice: the
/// second time over cross-sections centred on what the first pass found, which
/// drops whatever the wide band let in.
_Line _fitSide(
  Pt from,
  Pt to,
  Uint8List magnitude,
  int width,
  int height,
  int threshold,
) {
  final dx = to.x - from.x;
  final dy = to.y - from.y;
  final length = math.sqrt(dx * dx + dy * dy);
  if (length <= 0) {
    // A side with no length carries no direction, so the only line available
    // is a vertical one through the corner.
    return _Line(1, 0, -from.x);
  }

  // Unit direction along the side, and its unit normal — the direction the
  // cross-sections are cut in. Using the normal rather than fitting `y` as a
  // function of `x` is what keeps a near-vertical side well conditioned.
  final ux = dx / length;
  final uy = dy / length;
  final nx = -uy;
  final ny = ux;

  final midX = (from.x + to.x) / 2;
  final midY = (from.y + to.y) / 2;
  final safeX = from.x + dx * kEndMargin;
  final safeY = from.y + dy * kEndMargin;
  final safeSpan = length * (1 - 2 * kEndMargin);
  final fallback = _Line(nx, ny, -(nx * midX + ny * midY));

  final wideBand = (length * kRefineBandFraction).clamp(3.0, 24.0);
  final first = _ridgeToLine(
    baseX: safeX,
    baseY: safeY,
    directionX: ux,
    directionY: uy,
    span: safeSpan,
    normalX: nx,
    normalY: ny,
    band: wideBand,
    magnitude: magnitude,
    width: width,
    height: height,
    threshold: threshold,
  );
  if (first == null) return fallback;

  // Slide onto the line the first pass found and repeat over a much tighter
  // window. An error of several pixels in the first fit is normal; repeating
  // the measurement where it says the ridge is settles it to well under one.
  final shift = first.a * safeX + first.b * safeY + first.c;
  final second = _ridgeToLine(
    baseX: safeX - nx * shift,
    baseY: safeY - ny * shift,
    directionX: ux,
    directionY: uy,
    span: safeSpan,
    normalX: nx,
    normalY: ny,
    band: kTightBand,
    magnitude: magnitude,
    width: width,
    height: height,
    threshold: threshold,
  );
  return second ?? first;
}

/// Walks [span] pixels along a side, one station at a time, keeping at each
/// station whichever pixel in the cross-section has the strongest gradient,
/// and fits a line through the points so collected.
///
/// Returns null when too few stations contributed a point for a line through
/// them to mean anything.
_Line? _ridgeToLine({
  required double baseX,
  required double baseY,
  required double directionX,
  required double directionY,
  required double span,
  required double normalX,
  required double normalY,
  required double band,
  required Uint8List magnitude,
  required int width,
  required int height,
  required int threshold,
}) {
  final stations = math.min(math.max((span / 2).floor(), 8), 240);
  final xs = <double>[];
  final ys = <double>[];

  for (var i = 0; i <= stations; i++) {
    final along = span * i / stations;
    final cx = baseX + directionX * along;
    final cy = baseY + directionY * along;

    var bestValue = threshold - 1;
    double bestX = 0;
    double bestY = 0;
    var found = false;
    for (var off = -band; off <= band; off += 1) {
      final x = (cx + normalX * off).round();
      final y = (cy + normalY * off).round();
      if (x < 0 || y < 0 || x >= width || y >= height) continue;
      final value = magnitude[y * width + x];
      if (value <= bestValue) continue;
      bestValue = value;
      bestX = x + 0.5;
      bestY = y + 0.5;
      found = true;
    }
    if (!found) continue;
    xs.add(bestX);
    ys.add(bestY);
  }

  if (xs.length < 8) return null;
  return _totalLeastSquares(xs, ys);
}

/// Total least squares: the direction of greatest spread. Unlike fitting y as
/// a function of x this does not blow up on a vertical edge.
_Line _totalLeastSquares(List<double> xs, List<double> ys) {
  var meanX = 0.0;
  var meanY = 0.0;
  for (var i = 0; i < xs.length; i++) {
    meanX += xs[i];
    meanY += ys[i];
  }
  meanX /= xs.length;
  meanY /= ys.length;

  var sxx = 0.0;
  var syy = 0.0;
  var sxy = 0.0;
  for (var i = 0; i < xs.length; i++) {
    final vx = xs[i] - meanX;
    final vy = ys[i] - meanY;
    sxx += vx * vx;
    syy += vy * vy;
    sxy += vx * vy;
  }
  sxx /= xs.length;
  syy /= xs.length;
  sxy /= xs.length;

  // Eigenvector of the larger eigenvalue of [[sxx, sxy], [sxy, syy]].
  final theta = 0.5 * math.atan2(2 * sxy, sxx - syy);
  final lineX = math.cos(theta);
  final lineY = math.sin(theta);
  // Unit normal to that direction.
  final a = -lineY;
  final b = lineX;

  return _Line(a, b, -(a * meanX + b * meanY));
}

/// Intersection of two lines, or null when they are (near) parallel and the
/// point of intersection would be meaningless.
Pt? _intersect(_Line p, _Line q) {
  final det = p.a * q.b - q.a * p.b;
  if (det.abs() < 1e-9) return null;
  final x = (p.b * q.c - q.b * p.c) / det;
  final y = (q.a * p.c - p.a * q.c) / det;
  return Pt(x, y);
}

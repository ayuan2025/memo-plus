// Local addition to the vendored OpenScan pipeline (not part of upstream).
//
// Tells an already-trimmed page apart from a photo of a page. Detection looks
// for the *edge of the paper against its surroundings*, so on a capture that is
// already the finished page — imported from the gallery, screenshotted, or
// cropped elsewhere — there is no paper edge to find: the strongest rectangle
// in the frame is whatever block of text or table happens to form one, and
// cutting to it silently throws away the rest of the page. Everything here
// exists to recognise that case and hand the whole frame back untouched.

import 'dart:math';
import 'dart:typed_data';

import 'edge_detection.dart';
import 'models/point.dart';
import 'models/quad.dart';

/// How much edge activity outside a boundary, relative to inside it, means the
/// boundary was drawn *inside* the page rather than around it.
///
/// A page photographed on a desk has its content on the inside and little
/// beyond a soft gradient on the outside, so the two densities differ by an
/// order of magnitude. An already-cropped page has content running right up to
/// its own edges, so whatever the detector landed on — a heading band, a
/// table's rules — has as much written material outside it as within.
const double kContentSpillRatio = 0.45;

/// Absolute floor below which the outside is read as empty whatever the ratio
/// above says.
///
/// The ratio alone is untrustworthy wherever the inside is mostly blank: a page
/// holding one line of text divides two small numbers by each other, and a
/// couple of stray pixels beyond the corner then looks like half the page. This
/// floor insists the outside actually carry something — a desk photographed
/// beside the paper lands well below it, text carried to the frame edge lands
/// well above.
const double kMinOutsideStrongFraction = 0.02;

/// Smallest share of the frame that has to lie outside a quad before what is
/// out there is judged meaningful.
///
/// Quads that nearly fill the frame leave only a thin gutter around
/// themselves, and a handful of pixels there — one speckled line of text —
/// produces a wildly unstable density. Below this size the outside is treated
/// as unknowable and the frame is asked instead.
const double kMinOutsideAreaFraction = 0.10;

/// Area share of the frame above which a quad counts as the frame for the
/// purposes of deciding what can be cut away.
const double kFullFrameAreaRatio = 0.92;

/// Width of the band either side of a quad no statistic is collected from.
///
/// Detection lands *on* the transition it found, so the pixels immediately
/// around it are the edge itself. Sampling them would put part of the very
/// edge being judged into both the inside and the outside columns.
const double kQuadEdgeSkipFraction = 0.012;

/// Width of the strip along each frame edge that is sampled to ask whether the
/// writing reaches the edge of the picture.
///
/// Wide enough to hold several rows of text and so return a density rather than
/// a coin toss; narrow enough that a margin of a few pixels around a
/// photographed page does not read as the page bleeding off frame.
const double kFrameBandFraction = 0.02;

/// Fraction of the frame allowed to exceed the edge threshold, used to floor
/// the Otsu threshold exactly the way the detector floors its own.
const double _maxEdgeFraction = 0.06;

/// The whole image, as a boundary: the answer whenever nothing better is known.
///
/// Returned by the analysis below for captures that were trimmed already, so
/// the rest of the pipeline keeps running against a single representation of
/// "what to crop to" instead of growing a nullable no-crop mode.
Quad fullFrameQuad(int width, int height) => Quad(
  topLeft: const Pt(0, 0),
  topRight: Pt(width.toDouble(), 0),
  bottomRight: Pt(width.toDouble(), height.toDouble()),
  bottomLeft: Pt(0, height.toDouble()),
);

/// The quad inset by [fraction] of each side.
///
/// Used as the stand-in boundary when the detector found nothing and something
/// still has to be measured or laid out.
Quad insetFrameQuad(int width, int height, {double fraction = 0.04}) {
  final dx = width * fraction;
  final dy = height * fraction;
  return Quad(
    topLeft: Pt(dx, dy),
    topRight: Pt(width - dx, dy),
    bottomRight: Pt(width - dx, height - dy),
    bottomLeft: Pt(dx, height - dy),
  );
}

/// Whether [quad] covers effectively the entire image.
bool isFullFrameQuad(Quad quad, int width, int height) {
  final frameArea = width * height;
  if (frameArea <= 0) return false;
  return quadArea(quad) / frameArea >= kFullFrameAreaRatio;
}

/// Area of [quad] by the shoelace formula.
///
/// Magnitude only, so a quad whose corners were stored clockwise measures the
/// same as one stored anticlockwise.
double quadArea(Quad quad) {
  final points = quad.points;
  var sum = 0.0;
  for (var i = 0; i < points.length; i++) {
    final a = points[i];
    final b = points[(i + 1) % points.length];
    sum += a.x * b.y - b.x * a.y;
  }
  return sum.abs() / 2;
}

/// The threshold above which a Sobel magnitude counts as an edge, floored the
/// same way the detector floors its own so the two agree about what an edge is.
///
/// Otsu alone trusts every frame to have a bimodal histogram, which a page of
/// text does not — most of the frame sits near zero with a thin bright tail —
/// and the resulting threshold can land below the writing itself.
int documentEdgeThreshold(Uint8List magnitude) {
  final floor = percentileThreshold(magnitude, percentile: 1 - _maxEdgeFraction);
  return max(otsuThreshold(magnitude), floor);
}

/// What was written along the frame edge relative to the middle of the picture.
class FrameMarginEvidence {
  const FrameMarginEvidence({
    required this.borderStrongFraction,
    required this.coreStrongFraction,
  });

  /// Share of the frame-edge strip's pixels that clear the edge threshold.
  final double borderStrongFraction;

  /// The same share over the rest of the picture.
  final double coreStrongFraction;

  /// Whether whatever fills the picture carries on into its edge strip.
  ///
  /// A page photographed against a desk has its writing in the middle and only
  /// desk at the edges, so the two shares differ by an order of magnitude. A
  /// picture that already *is* the page has no such fall-off. This is what
  /// separates "no margin was left, so there is nothing to cut away" from "no
  /// edge was found, so nothing can be cut away".
  bool get contentReachesFrameEdge =>
      borderStrongFraction >= kMinOutsideStrongFraction &&
      borderStrongFraction >= kContentSpillRatio * coreStrongFraction;

  static const FrameMarginEvidence empty = FrameMarginEvidence(
    borderStrongFraction: 0,
    coreStrongFraction: 0,
  );
}

/// Measures the strip along the frame edges against everything inside it.
FrameMarginEvidence measureFrameMargin(
  Uint8List magnitude,
  int width,
  int height, {
  int? threshold,
}) {
  if (width <= 0 || height <= 0) return FrameMarginEvidence.empty;
  if (magnitude.length < width * height) return FrameMarginEvidence.empty;

  final edge = threshold ?? documentEdgeThreshold(magnitude);
  final band = max(3.0, min(width, height) * kFrameBandFraction);

  var borderTotal = 0;
  var borderStrong = 0;
  var coreTotal = 0;
  var coreStrong = 0;

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final index = y * width + x;
      final strong = magnitude[index] > edge;
      final toFrame = min(min(x, y), min(width - 1 - x, height - 1 - y));
      if (toFrame < band) {
        borderTotal++;
        if (strong) borderStrong++;
      } else {
        coreTotal++;
        if (strong) coreStrong++;
      }
    }
  }

  return FrameMarginEvidence(
    borderStrongFraction: borderTotal == 0 ? 0 : borderStrong / borderTotal,
    coreStrongFraction: coreTotal == 0 ? 0 : coreStrong / coreTotal,
  );
}

/// What sits inside a candidate boundary versus outside it.
class PageBoundaryEvidence {
  const PageBoundaryEvidence({
    required this.insideStrongFraction,
    required this.outsideStrongFraction,
    required this.outsideAreaFraction,
  });

  /// Share of pixels inside the quad that clear the edge threshold.
  final double insideStrongFraction;

  /// Share of pixels between the quad and the frame edge that clear it.
  final double outsideStrongFraction;

  /// The outside area, as a fraction of the whole frame.
  final double outsideAreaFraction;

  /// Whether there is as much written material outside the quad as inside it.
  ///
  /// That is the signature of a boundary drawn inside a page — a block of text,
  /// a table's rule — rather than around one. See [kContentSpillRatio].
  bool get hasWrittenMaterialOutside =>
      outsideStrongFraction >= kMinOutsideStrongFraction &&
      outsideStrongFraction >= kContentSpillRatio * insideStrongFraction;

  /// [hasWrittenMaterialOutside] plus enough outside area for the measurement
  /// to mean anything. See [kMinOutsideAreaFraction].
  bool get contentSpillsOutside =>
      hasWrittenMaterialOutside &&
      outsideAreaFraction >= kMinOutsideAreaFraction;

  static const PageBoundaryEvidence empty = PageBoundaryEvidence(
    insideStrongFraction: 0,
    outsideStrongFraction: 0,
    outsideAreaFraction: 0,
  );
}

/// Measures [quad] against the frame: how much of it is left outside, and how
/// much strong-edge material that outside holds compared with the inside.
///
/// [magnitude] is the Sobel magnitude of the image the quad came from, so this
/// can run on the same downscaled buffer detection itself worked on.
PageBoundaryEvidence measurePageBoundary(
  Uint8List magnitude,
  int width,
  int height,
  Quad quad, {
  int? threshold,
  double skipFraction = kQuadEdgeSkipFraction,
}) {
  if (width <= 0 || height <= 0) return PageBoundaryEvidence.empty;
  if (magnitude.length < width * height) return PageBoundaryEvidence.empty;

  final edge = threshold ?? documentEdgeThreshold(magnitude);
  final diagonal = sqrt(width * width + height * height);
  final skip = max(1.0, diagonal * skipFraction);

  var insideTotal = 0;
  var insideStrong = 0;
  var outsideTotal = 0;
  var outsideStrong = 0;

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final index = y * width + x;
      final point = Pt(x + 0.5, y + 0.5);
      final strong = magnitude[index] > edge;
      final distance = _distanceToQuadEdges(point, quad);
      if (distance < skip) {
        // On the boundary itself — see [kQuadEdgeSkipFraction].
        continue;
      }
      if (_isInsideQuad(point, quad)) {
        insideTotal++;
        if (strong) insideStrong++;
      } else {
        outsideTotal++;
        if (strong) outsideStrong++;
      }
    }
  }

  final area = width * height;
  return PageBoundaryEvidence(
    insideStrongFraction: insideTotal == 0 ? 0 : insideStrong / insideTotal,
    outsideStrongFraction: outsideTotal == 0 ? 0 : outsideStrong / outsideTotal,
    outsideAreaFraction: outsideTotal / area,
  );
}

/// Why a capture is being handed through as the whole frame.
enum FullPageReason {
  /// Writing runs right up to the edge of the picture: either it is cropped
  /// already or the page fills the view, and cutting again can only lose some
  /// of it.
  contentAtFrameEdge,

  /// A rectangle was found, but there is as much writing outside it as inside
  /// it — it is a box drawn within the page, not the page itself.
  contentOutsideQuad,
}

/// The boundary to crop to, and why.
class FullPageDecision {
  const FullPageDecision(this.quad, {this.reason});

  /// The boundary, in the same coordinates [width]/[height] are given in: the
  /// whole frame when the capture is already a page, otherwise the detection.
  final Quad quad;

  /// Set exactly when [quad] is the whole frame. Null means a real edge was
  /// found and should be cut to.
  final FullPageReason? reason;

  bool get isFullPage => reason != null;
}

/// Decides whether [detected] is the edge of a page in a scene or a rectangle
/// drawn inside one, against the Sobel [magnitude] of the same image.
///
/// Two questions are asked, because each catches what the other misses:
///
/// * Does writing reach the edge of the picture ([measureFrameMargin])? That is
///   the shape of anything already trimmed, whatever the detector said.
/// * Is there writing beyond the quad it did find
///   ([measurePageBoundary])? That is the shape of a rectangle drawn inside a
///   page, which is what detection tends to settle on when there is no page
///   edge to find.
///
/// [detected] may be null — the detector admitting defeat — which on an
/// already-trimmed page is the *expected* answer rather than a failure.
FullPageDecision resolveDocumentBoundary({
  required Uint8List magnitude,
  required int width,
  required int height,
  required Quad? detected,
  int? threshold,
}) {
  final margin = measureFrameMargin(
    magnitude,
    width,
    height,
    threshold: threshold,
  );
  if (margin.contentReachesFrameEdge) {
    return FullPageDecision(
      fullFrameQuad(width, height),
      reason: FullPageReason.contentAtFrameEdge,
    );
  }

  if (detected == null) {
    return FullPageDecision(insetFrameQuad(width, height));
  }

  final evidence = measurePageBoundary(
    magnitude,
    width,
    height,
    detected,
    threshold: threshold,
    // A quad already covering most of the frame leaves no statistically
    // comfortable outside sample, so the ratios are read on their own and a
    // thinner transition band is skipped to leave anything at all to measure.
    skipFraction: isFullFrameQuad(detected, width, height)
        ? kQuadEdgeSkipFraction / 2
        : kQuadEdgeSkipFraction,
  );
  final spills = isFullFrameQuad(detected, width, height)
      ? evidence.hasWrittenMaterialOutside
      : evidence.contentSpillsOutside;

  return spills
      ? FullPageDecision(
          fullFrameQuad(width, height),
          reason: FullPageReason.contentOutsideQuad,
        )
      : FullPageDecision(detected);
}

/// Whether [point] lies inside the convex [quad], by consistent winding.
bool _isInsideQuad(Pt point, Quad quad) {
  final points = quad.points;
  var winding = 0;
  for (var i = 0; i < points.length; i++) {
    final a = points[i];
    final b = points[(i + 1) % points.length];
    final cross = (b.x - a.x) * (point.y - a.y) - (b.y - a.y) * (point.x - a.x);
    if (cross.abs() < 1e-9) continue;
    final sign = cross > 0 ? 1 : -1;
    if (winding == 0) {
      winding = sign;
    } else if (winding != sign) {
      return false;
    }
  }
  return true;
}

/// Distance from [point] to the nearest edge of [quad].
double _distanceToQuadEdges(Pt point, Quad quad) {
  final points = quad.points;
  var nearest = double.infinity;
  for (var i = 0; i < points.length; i++) {
    final a = points[i];
    final b = points[(i + 1) % points.length];
    final distance = _distanceToSegment(point, a, b);
    if (distance < nearest) nearest = distance;
  }
  return nearest;
}

double _distanceToSegment(Pt p, Pt a, Pt b) {
  final dx = b.x - a.x;
  final dy = b.y - a.y;
  final squared = dx * dx + dy * dy;
  if (squared < 1e-12) {
    return sqrt(pow(p.x - a.x, 2) + pow(p.y - a.y, 2));
  }
  var t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / squared;
  t = t.clamp(0.0, 1.0);
  final projection = Pt(a.x + t * dx, a.y + t * dy);
  return sqrt(pow(p.x - projection.x, 2) + pow(p.y - projection.y, 2));
}

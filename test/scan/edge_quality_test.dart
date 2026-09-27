import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/scan/src/contours.dart';
import 'package:memos_flutter_app/core/scan/src/corner_refinement.dart';
import 'package:memos_flutter_app/core/scan/src/edge_detection.dart';
import 'package:memos_flutter_app/core/scan/src/models/point.dart';
import 'package:memos_flutter_app/core/scan/src/models/quad.dart';

/// Regression guard for the two ways page detection has broken before:
///
/// 1. The box landing somewhere other than the paper (accuracy).
/// 2. The box moving between frames that differ only by sensor noise
///    (jitter) — what a user sees as the outline "dancing".
///
/// Both are measured against a synthetic page with a known outline, using the
/// same primitives `detectQuadFromGrayscale` runs, with refinement applied and
/// withheld so the two can be compared rather than merely bounded.
const int _width = 480;
const int _height = 640;

/// The page as actually laid on the desk — the ground truth.
Quad _truth() => Quad(
  topLeft: Pt(120, 90),
  topRight: Pt(360, 110),
  bottomRight: Pt(340, 540),
  bottomLeft: Pt(105, 500),
);

class _Rng {
  _Rng(this._seed);

  int _seed;

  double next() {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return _seed / 0x7fffffff;
  }
}

bool _insideQuad(double x, double y, Quad q) {
  final pts = [q.topLeft, q.topRight, q.bottomRight, q.bottomLeft];
  var sign = 0;
  for (var i = 0; i < 4; i++) {
    final a = pts[i];
    final b = pts[(i + 1) % 4];
    final cross = (b.x - a.x) * (y - a.y) - (b.y - a.y) * (x - a.x);
    if (cross.abs() < 1e-9) continue;
    final s = cross > 0 ? 1 : -1;
    if (sign == 0) {
      sign = s;
    } else if (sign != s) {
      return false;
    }
  }
  return true;
}

/// Desk, page, rows of text inside it, and sensor noise from [rng].
Uint8List _renderScene(_Rng rng) {
  final gray = Uint8List(_width * _height);
  final page = _truth();
  for (var y = 0; y < _height; y++) {
    for (var x = 0; x < _width; x++) {
      final desk = 78 + 34 * math.sin((x + y) / 190.0) + (rng.next() - 0.5) * 14;
      final value = _insideQuad(x + 0.5, y + 0.5, page)
          ? 214 + (rng.next() - 0.5) * 16
          : desk;
      gray[y * _width + x] = value.clamp(0, 255).round();
    }
  }

  // Rows of "text", clipped to the page: strong local gradients, which is what
  // separates the edge of the sheet from its surface.
  var y = 150.0;
  while (y < 500) {
    final x0 = 130.0 + rng.next() * 10;
    final runWidth = 150.0 + rng.next() * 90;
    for (var ty = y; ty < y + 7; ty++) {
      for (var tx = x0; tx < x0 + runWidth; tx++) {
        final xi = tx.round();
        final yi = ty.round();
        if (xi < 0 || yi < 0 || xi >= _width || yi >= _height) continue;
        if (!_insideQuad(tx + 0.5, ty + 0.5, page)) continue;
        gray[yi * _width + xi] = ((tx - x0) % 9) < 5 ? 96 : 210;
      }
    }
    y += 26;
  }
  return gray;
}

class _Detection {
  const _Detection({required this.coarse, required this.refined});

  final Quad coarse;
  final Quad? refined;
}

_Detection? _detect(Uint8List gray) {
  final blurred = gaussianBlur3(gray, _width, _height);
  final magnitude = sobelMagnitude(blurred, _width, _height);
  final base = math
      .max(
        otsuThreshold(magnitude),
        percentileThreshold(magnitude, percentile: 0.94),
      )
      .round();

  final candidates = <Quad>[];
  for (final multiplier in const [0.7, 1.0, 1.3]) {
    final t = (base * multiplier).round().clamp(0, 255);
    final binary = threshold(magnitude, t);
    candidates.addAll(
      findDocumentQuadCandidates(
        dilate(binary, _width, _height, 4),
        _width,
        _height,
      ),
    );
  }

  final coarse = pickBestQuad(candidates, _width, _height);
  if (coarse == null) return null;
  return _Detection(
    coarse: coarse,
    refined: refineQuadCorners(coarse, magnitude, _width, _height, base),
  );
}

/// Mean distance from each corner to the nearest ground-truth corner.
///
/// Nearest rather than by label: a label mix-up is a different bug with its own
/// test, and it would otherwise swamp this measurement.
double _cornerError(Quad detected, Quad truth) {
  final detectedPoints = [
    detected.topLeft,
    detected.topRight,
    detected.bottomRight,
    detected.bottomLeft,
  ];
  final truthPoints = [
    truth.topLeft,
    truth.topRight,
    truth.bottomRight,
    truth.bottomLeft,
  ];
  var total = 0.0;
  for (final p in detectedPoints) {
    var best = double.infinity;
    for (final q in truthPoints) {
      final d = math.sqrt((p.x - q.x) * (p.x - q.x) + (p.y - q.y) * (p.y - q.y));
      if (d < best) best = d;
    }
    total += best;
  }
  return total / 4;
}

double _jitter(Quad a, Quad b) {
  final pa = [a.topLeft, a.topRight, a.bottomRight, a.bottomLeft];
  final pb = [b.topLeft, b.topRight, b.bottomRight, b.bottomLeft];
  var total = 0.0;
  for (final p in pa) {
    var best = double.infinity;
    for (final q in pb) {
      final d = math.sqrt((p.x - q.x) * (p.x - q.x) + (p.y - q.y) * (p.y - q.y));
      if (d < best) best = d;
    }
    total += best;
  }
  return total / 4;
}

double _areaOf(Quad q) {
  final pts = [q.topLeft, q.topRight, q.bottomRight, q.bottomLeft];
  var sum = 0.0;
  for (var i = 0; i < 4; i++) {
    final a = pts[i];
    final b = pts[(i + 1) % 4];
    sum += a.x * b.y - b.x * a.y;
  }
  return sum.abs() / 2;
}

void main() {
  test('refining corners lands closer to the page than leaving them be', () {
    final truth = _truth();
    final coarseFrames = <Quad>[];
    final refinedFrames = <Quad>[];

    for (var frame = 0; frame < 12; frame++) {
      final detection = _detect(_renderScene(_Rng(9001 + frame * 7919)));
      if (detection == null) continue;
      coarseFrames.add(detection.coarse);
      final refined = detection.refined;
      if (refined != null) refinedFrames.add(refined);
    }

    expect(coarseFrames.length, 12, reason: 'the page has to be found at all');
    expect(refinedFrames.length, 12);

    double meanOf(List<Quad> frames, double Function(Quad) measure) =>
        frames.map(measure).reduce((a, b) => a + b) / frames.length;

    final coarseError = meanOf(coarseFrames, (q) => _cornerError(q, truth));
    final refinedError = meanOf(refinedFrames, (q) => _cornerError(q, truth));

    // The point of the refinement: it has to beat doing nothing.
    expect(refinedError, lessThan(coarseError));
    expect(refinedError, lessThan(2.0));

    var jitterTotal = 0.0;
    for (var i = 1; i < refinedFrames.length; i++) {
      jitterTotal += _jitter(refinedFrames[i], refinedFrames[i - 1]);
    }
    final refinedJitter = jitterTotal / (refinedFrames.length - 1);

    // An earlier revision sampled only a small patch at the middle of each
    // side, which fitted a different line every frame: the box danced about
    // 19px between frames that differed by nothing but noise.
    expect(refinedJitter, lessThan(1.0));

    // And it should still cover the whole sheet rather than a part of it.
    final refinedArea = meanOf(refinedFrames, _areaOf);
    expect(refinedArea, closeTo(_areaOf(truth), 3000));
  });
}

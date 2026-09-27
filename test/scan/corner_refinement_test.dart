import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/scan/src/corner_refinement.dart';
import 'package:memos_flutter_app/core/scan/src/models/point.dart';
import 'package:memos_flutter_app/core/scan/src/models/quad.dart';

/// Paint a set of 1px-wide lines into [magnitude], standing in for the Sobel
/// magnitude of a page's edges.
Uint8List _paintEdges(List<(int x, int y)> lines, int width, int height) {
  final magnitude = Uint8List(width * height);
  for (final (x, y) in lines) {
    if (x < 0 || y < 0 || x >= width || y >= height) continue;
    magnitude[y * width + x] = 255;
  }
  return magnitude;
}

Quad _rect(double left, double top, double right, double bottom) => Quad(
  topLeft: Pt(left, top),
  topRight: Pt(right, top),
  bottomRight: Pt(right, bottom),
  bottomLeft: Pt(left, bottom),
);

void main() {
  test('pulls nudged corners back onto the real edge lines', () {
    const width = 200;
    const height = 260;
    const top = 30;
    const left = 40;
    const right = 160;
    const bottom = 230;

    final magnitude = _paintEdges([
      for (var x = left; x <= right; x++) (x, top),
      for (var y = top; y <= bottom; y++) (right, y),
      for (var x = left; x <= right; x++) (x, bottom),
      for (var y = top; y <= bottom; y++) (left, y),
    ], width, height);

    // As a simplification would leave it: the corners sit 2px inside the
    // lines, and only the sides are in the right place.
    final coarse = _rect(left + 2, top + 2, right - 2, bottom - 2);
    final refined = refineQuadCorners(coarse, magnitude, width, height, 200);

    expect(refined.topLeft.x, closeTo(left, 1.5));
    expect(refined.topLeft.y, closeTo(top, 1.5));
    expect(refined.topRight.x, closeTo(right, 1.5));
    expect(refined.topRight.y, closeTo(top, 1.5));
    expect(refined.bottomRight.x, closeTo(right, 1.5));
    expect(refined.bottomRight.y, closeTo(bottom, 1.5));
    expect(refined.bottomLeft.x, closeTo(left, 1.5));
    expect(refined.bottomLeft.y, closeTo(bottom, 1.5));
  });

  test('handles a slanted page without collapsing the near-vertical sides', () {
    const width = 240;
    const height = 240;
    final magnitude = Uint8List(width * height);

    // A parallelogram: the left and right sides are steeply slanted, so a fit
    // of y as a function of x would be ill-conditioned here.
    void line(int x0, int y0, int x1, int y1) {
      const steps = 200;
      for (var i = 0; i <= steps; i++) {
        final x = (x0 + (x1 - x0) * i / steps).round();
        final y = (y0 + (y1 - y0) * i / steps).round();
        if (x >= 0 && y >= 0 && x < width && y < height) {
          magnitude[y * width + x] = 255;
        }
      }
    }

    line(50, 40, 70, 200); // left, leaning right as it goes down
    line(210, 60, 190, 210); // right
    line(50, 40, 210, 60); // top
    line(70, 200, 190, 210); // bottom

    final coarse = _rect(52, 42, 208, 198);
    final refined = refineQuadCorners(coarse, magnitude, width, height, 200);

    // The page slants, so top-right sits to the *right* of bottom-right: the
    // point is that all four corners land on the real lines, slant and all.
    expect(refined.topLeft.x, closeTo(50, 3));
    expect(refined.topLeft.y, closeTo(40, 3));
    expect(refined.topRight.x, closeTo(210, 3));
    expect(refined.topRight.y, closeTo(60, 3));
    expect(refined.bottomRight.x, closeTo(190, 3));
    expect(refined.bottomRight.y, closeTo(210, 3));
    expect(refined.bottomLeft.x, closeTo(70, 3));
    expect(refined.bottomLeft.y, closeTo(200, 3));
    // Still a quad, still ordered.
    expect(refined.topLeft.x, lessThan(refined.topRight.x));
    expect(refined.topLeft.y, lessThan(refined.bottomLeft.y));
    expect(refined.topRight.x, greaterThan(refined.bottomRight.x));
    expect(refined.topRight.y, lessThan(refined.bottomRight.y));
  });

  test('falls back to the coarse corners when there is no edge to fit', () {
    const width = 120;
    const height = 120;
    final coarse = _rect(20, 20, 100, 100);
    final refined = refineQuadCorners(coarse, Uint8List(width * height), width, height, 200);
    expect(refined.topLeft.x, coarse.topLeft.x);
    expect(refined.topLeft.y, coarse.topLeft.y);
    expect(refined.topRight.x, coarse.topRight.x);
    expect(refined.topRight.y, coarse.topRight.y);
    expect(refined.bottomRight.x, coarse.bottomRight.x);
    expect(refined.bottomRight.y, coarse.bottomRight.y);
    expect(refined.bottomLeft.x, coarse.bottomLeft.x);
    expect(refined.bottomLeft.y, coarse.bottomLeft.y);
  });

  test('stays inside the frame', () {
    const width = 100;
    const height = 100;
    final magnitude = _paintEdges([
      for (var y = 0; y < height; y++) (1, y),
      for (var y = 0; y < height; y++) (width - 2, y),
    ], width, height);

    final refined = refineQuadCorners(_rect(1, 0, width - 2, height - 1), magnitude, width, height, 200);
    for (final corner in [
      refined.topLeft,
      refined.topRight,
      refined.bottomRight,
      refined.bottomLeft,
    ]) {
      expect(corner.x, greaterThanOrEqualTo(0));
      expect(corner.y, greaterThanOrEqualTo(0));
      expect(corner.x, lessThanOrEqualTo(width - 1));
      expect(corner.y, lessThanOrEqualTo(height - 1));
    }
  });
}

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:memos_flutter_app/core/scan/document_scan.dart';

/// Builds a solid-colour encoded JPEG of [width] x [height].
Uint8List _solid(int width, int height, int r, int g, int b) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(r, g, b));
  return img.encodeJpg(image, quality: 95);
}

/// Builds an image whose left half is [left] and right half is [right], both
/// given as (r, g, b).
Uint8List _twoTone(
  int width,
  int height,
  (int, int, int) left,
  (int, int, int) right,
) {
  final image = img.Image(width: width, height: height);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final c = x < width ~/ 2 ? left : right;
      image.setPixelRgb(x, y, c.$1, c.$2, c.$3);
    }
  }
  return img.encodeJpg(image, quality: 95);
}

double _distance(Pt a, Pt b) => sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));

/// Asserts the axis-aligned bounds of an already upright quad. Compared with a
/// tolerance rather than by set equality: the portrait/landscape conversion
/// computes `1 - x`, so an exact 0.1 comes back as 0.09999999999999998.
void _expectBounds(
  Quad quad, {
  required double left,
  required double right,
  required double top,
  required double bottom,
}) {
  final xs = quad.points.map((p) => p.x).toList()..sort();
  final ys = quad.points.map((p) => p.y).toList()..sort();

  expect(xs.first, closeTo(left, 1e-6));
  expect(xs.last, closeTo(right, 1e-6));
  expect(ys.first, closeTo(top, 1e-6));
  expect(ys.last, closeTo(bottom, 1e-6));
}

void main() {
  group('sortCorners', () {
    test('labels an unlabelled quad top-left first, clockwise', () {
      // A slightly tilted page whose corners arrive in no particular order.
      final quad = sortCorners([
        const Pt(10, 100), // bottom-left
        const Pt(200, 20), // top-right
        const Pt(240, 300), // bottom-right
        const Pt(30, 15), // top-left
      ]);

      expect(quad.topLeft.x, closeTo(30, 1e-9));
      expect(quad.topLeft.y, closeTo(15, 1e-9));
      expect(quad.topRight.x, closeTo(200, 1e-9));
      expect(quad.topRight.y, closeTo(20, 1e-9));
      expect(quad.bottomRight.x, closeTo(240, 1e-9));
      expect(quad.bottomRight.y, closeTo(300, 1e-9));
      expect(quad.bottomLeft.x, closeTo(10, 1e-9));
      expect(quad.bottomLeft.y, closeTo(100, 1e-9));
    });

    test('never duplicates or drops a corner, at any rotation', () {
      const corners = [Pt(100, 0), Pt(200, 100), Pt(100, 200), Pt(0, 100)];
      for (int i = 0; i < corners.length; i++) {
        final rotated = [...corners.skip(i), ...corners.take(i)];
        final quad = sortCorners(rotated);
        expect(
          quad.points.map((p) => '${p.x},${p.y}').toSet(),
          corners.map((p) => '${p.x},${p.y}').toSet(),
          reason: 'rotation $i produced a different set of points',
        );
      }
    });

    test('a 45-degree rotation still yields four distinct points', () {
      final quad = sortCorners([
        const Pt(100, 0),
        const Pt(200, 100),
        const Pt(100, 200),
        const Pt(0, 100),
      ]);
      expect(quad.points.toSet().length, 4);
    });
  });

  group('isPlausibleQuad', () {
    test('rejects a quad that is too small a fraction of the frame', () {
      const tiny = Quad(
        topLeft: Pt(0, 0),
        topRight: Pt(10, 0),
        bottomRight: Pt(10, 10),
        bottomLeft: Pt(0, 10),
      );
      expect(isPlausibleQuad(tiny, 1000, 1000), isFalse);
    });

    test('rejects a collapsed sliver', () {
      const sliver = Quad(
        topLeft: Pt(0, 0),
        topRight: Pt(900, 0),
        bottomRight: Pt(901, 1),
        bottomLeft: Pt(0, 1),
      );
      expect(isPlausibleQuad(sliver, 1000, 1000), isFalse);
    });

    test('accepts a page-sized rectangle', () {
      const page = Quad(
        topLeft: Pt(100, 100),
        topRight: Pt(900, 100),
        bottomRight: Pt(900, 900),
        bottomLeft: Pt(100, 900),
      );
      expect(isPlausibleQuad(page, 1000, 1000), isTrue);
    });
  });

  group('quadInPixelsOf', () {
    test('scales a normalized quad onto a portrait image unchanged', () {
      const normalized = Quad(
        topLeft: Pt(0.1, 0.2),
        topRight: Pt(0.9, 0.2),
        bottomRight: Pt(0.9, 0.8),
        bottomLeft: Pt(0.1, 0.8),
      );

      final quad = quadInPixelsOf(normalized, 400, 800);

      _expectBounds(quad, left: 40, right: 360, top: 160, bottom: 640);
    });

    test('rotates a portrait overlay quad onto a landscape photo', () {
      const normalized = Quad(
        topLeft: Pt(0.1, 0.2),
        topRight: Pt(0.9, 0.2),
        bottomRight: Pt(0.9, 0.8),
        bottomLeft: Pt(0.1, 0.8),
      );

      // Portrait (x, y) -> sensor (y, 1 - x), then scaled by (width, height).
      // Rotating rather than stretching is the point: the overlay's short axis
      // must stay the photo's short axis.
      final quad = quadInPixelsOf(normalized, 800, 600);

      _expectBounds(quad, left: 160, right: 640, top: 60, bottom: 540);
    });
  });

  group('outputSize', () {
    test('takes the longest of each pair of opposite edges', () {
      const quad = Quad(
        topLeft: Pt(0, 0),
        topRight: Pt(300, 0),
        bottomRight: Pt(300, 400),
        bottomLeft: Pt(0, 400),
      );
      final size = outputSize(quad);
      expect(size.width, 300);
      expect(size.height, 400);
    });

    test('never returns a zero dimension for a degenerate quad', () {
      const quad = Quad(
        topLeft: Pt(0, 0),
        topRight: Pt(0, 0),
        bottomRight: Pt(0, 0),
        bottomLeft: Pt(0, 0),
      );
      final size = outputSize(quad);
      expect(size.width, greaterThanOrEqualTo(1));
      expect(size.height, greaterThanOrEqualTo(1));
    });
  });

  group('cropToQuadBytes', () {
    test('samples the requested region, keeping its orientation', () {
      final encoded = _twoTone(400, 300, (220, 30, 30), (20, 40, 220));

      // Crop the right-hand (blue) half plus a small margin of red.
      final result = cropToQuadBytes(
        encoded,
        const Quad(
          topLeft: Pt(200, 0),
          topRight: Pt(400, 0),
          bottomRight: Pt(400, 300),
          bottomLeft: Pt(200, 300),
        ),
      );

      expect(result, isA<CropSuccess>());
      final warped = img.decodeImage((result as CropSuccess).bytes)!;
      expect(warped.width, 200);
      expect(warped.height, 300);

      // Everything sampled from x >= 200 is blue; the warp must not mirror or
      // transpose the source.
      int blue = 0;
      for (int y = 0; y < warped.height; y++) {
        for (int x = 0; x < warped.width; x++) {
          final p = warped.getPixel(x, y);
          if (p.b.toInt() > 150 && p.r.toInt() < 110) blue++;
        }
      }
      expect(blue / (warped.width * warped.height), greaterThan(0.95));
    });

    test('a quarter turn swaps the output dimensions', () {
      final encoded = _solid(400, 300, 200, 200, 200);
      final result = cropToQuadBytes(
        encoded,
        const Quad(
          topLeft: Pt(0, 0),
          topRight: Pt(400, 0),
          bottomRight: Pt(400, 300),
          bottomLeft: Pt(0, 300),
        ),
        quarterTurns: 1,
      );

      final warped = img.decodeImage((result as CropSuccess).bytes)!;
      expect(warped.width, 300);
      expect(warped.height, 400);
    });

    test('reports a failure instead of throwing on undecodable bytes', () {
      final result = cropToQuadBytes(
        Uint8List.fromList(List<int>.filled(64, 7)),
        const Quad(
          topLeft: Pt(0, 0),
          topRight: Pt(10, 0),
          bottomRight: Pt(10, 10),
          bottomLeft: Pt(0, 10),
        ),
      );

      expect(result, isA<CropFailure>());
    });
  });

  group('renderScannedPage', () {
    test('crops and caps the long edge', () {
      final encoded = _twoTone(3000, 2000, (10, 10, 10), (240, 240, 240));

      final page = renderScannedPage(
        encoded,
        quad: const Quad(
          topLeft: Pt(1500, 0),
          topRight: Pt(3000, 0),
          bottomRight: Pt(3000, 2000),
          bottomLeft: Pt(1500, 2000),
        ),
        maxEdge: 600,
        quality: 90,
      );

      expect(page.decoded, isTrue);
      expect(page.cropped, isTrue);
      final decoded = img.decodeImage(page.bytes)!;
      expect(max(decoded.width, decoded.height), 600);
      // The crop was 1500x2000, so the cap binds on the height.
      expect(decoded.width, 450);
      expect(decoded.height, 600);
    });

    test('leaves an image under the cap at its own size', () {
      final encoded = _solid(320, 240, 120, 120, 120);

      final page = renderScannedPage(encoded, maxEdge: 2400);

      final decoded = img.decodeImage(page.bytes)!;
      expect(decoded.width, 320);
      expect(decoded.height, 240);
      expect(page.cropped, isFalse);
    });

    test('passes undecodable bytes through untouched', () {
      final garbage = Uint8List.fromList(List<int>.filled(32, 3));

      final page = renderScannedPage(garbage);

      expect(page.decoded, isFalse);
      expect(page.cropped, isFalse);
      expect(page.bytes, same(garbage));
    });
  });

  group('detectDocumentInBytes', () {
    test('finds a light page on a dark background', () {
      const expected = Quad(
        topLeft: Pt(80, 120),
        topRight: Pt(520, 90),
        bottomRight: Pt(540, 700),
        bottomLeft: Pt(70, 730),
      );
      final encoded = _photoWithPage(expected, 600, 800);

      final result = detectDocumentInBytes(encoded);

      expect(result, isA<DetectionSuccess>());
      final detected = (result as DetectionSuccess).quad;
      expect(detected.points.length, 4);
      for (final corner in expected.points) {
        final nearest = detected.points
            .map((p) => _distance(p, corner))
            .reduce(min);
        expect(
          nearest,
          lessThan(25),
          reason: 'no detected corner near $corner (closest $nearest)',
        );
      }
    });

    test('reports not-found on a featureless image', () {
      final encoded = _solid(600, 800, 70, 70, 70);

      expect(detectDocumentInBytes(encoded), isA<DetectionNotFound>());
    });

    test('reports a failure instead of throwing on undecodable bytes', () {
      final garbage = Uint8List.fromList(List<int>.filled(64, 9));

      expect(detectDocumentInBytes(garbage), isA<DetectionFailure>());
    });

    test('returns the original image dimensions with the quad', () {
      const page = Quad(
        topLeft: Pt(80, 120),
        topRight: Pt(520, 90),
        bottomRight: Pt(540, 700),
        bottomLeft: Pt(70, 730),
      );
      final encoded = _photoWithPage(page, 600, 800);

      final result = detectDocumentInBytes(encoded) as DetectionSuccess;

      expect(result.imageWidth, 600);
      expect(result.imageHeight, 800);
    });
  });
}

/// A dark background with a light quadrilateral [page] drawn onto it, JPEG
/// encoded — the synthetic stand-in for a photo of a sheet of paper.
Uint8List _photoWithPage(Quad page, int width, int height) {
  final image = img.Image(width: width, height: height);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final inside = _insideQuad(
        page.points,
        x.toDouble() + 0.5,
        y.toDouble() + 0.5,
      );
      if (inside) {
        image.setPixelRgb(x, y, 235, 233, 228);
      } else {
        image.setPixelRgb(x, y, 42, 45, 48);
      }
    }
  }
  return img.encodeJpg(image, quality: 95);
}

/// Convex point-in-polygon test: every edge cross product shares a sign.
bool _insideQuad(List<Pt> corners, double x, double y) {
  bool? positive;
  for (int i = 0; i < corners.length; i++) {
    final a = corners[i];
    final b = corners[(i + 1) % corners.length];
    final cross = (b.x - a.x) * (y - a.y) - (b.y - a.y) * (x - a.x);
    if (cross == 0) continue;
    if (positive == null) {
      positive = cross > 0;
    } else if (positive != (cross > 0)) {
      return false;
    }
  }
  return true;
}

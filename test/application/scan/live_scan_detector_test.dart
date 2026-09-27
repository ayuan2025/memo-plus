import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/application/scan/live_scan_detector.dart';
import 'package:memos_flutter_app/core/scan/document_scan.dart';

/// The live viewfinder's frame plumbing.
///
/// This is everything between "the camera handed us a frame" and "the edge
/// pipeline has a grey image to search": the platform's row padding has to come
/// off, the frame has to be narrowed to something a phone can search per frame,
/// and the answer has to be turned back into the orientation the user is
/// looking at. None of it is observable on a device without a camera, so it is
/// pinned down here instead.
void main() {
  void expectPoint(Pt actual, double x, double y) {
    expect(actual.x, closeTo(x, 1e-9));
    expect(actual.y, closeTo(y, 1e-9));
  }

  group('grayFromLumaPlane', () {
    test('keeps the row width and drops the padding after it', () {
      // 3x2 of real pixels, every row padded out to 4 bytes.
      final plane = Uint8List.fromList(<int>[
        1, 2, 3, 99, //
        4, 5, 6, 99,
      ]);

      final read = grayFromLumaPlane(
        plane,
        width: 3,
        height: 2,
        bytesPerRow: 4,
        maxDimension: 1000,
      );

      expect(read, isNotNull);
      expect(read!.width, 3);
      expect(read.height, 2);
      expect(read.gray, <int>[1, 2, 3, 4, 5, 6]);
    });

    test('hands back a copy, not a window onto the camera buffer', () {
      final plane = Uint8List.fromList(<int>[1, 2, 3, 4, 5, 6]);

      final read = grayFromLumaPlane(
        plane,
        width: 3,
        height: 2,
        bytesPerRow: 3,
        maxDimension: 1000,
      )!;

      // The camera reuses its buffer for the next frame, so a view would be
      // rewritten while the detector was still reading it.
      plane[0] = 200;
      expect(read.gray[0], 1);
    });

    test('narrows the frame to the working size, keeping the shape', () {
      final plane = Uint8List(6 * 4)..fillRange(0, 24, 7);

      final read = grayFromLumaPlane(
        plane,
        width: 6,
        height: 4,
        bytesPerRow: 6,
        maxDimension: 3,
      )!;

      expect(read.width, 3);
      expect(read.height, 2);
      expect(read.gray.length, 6);
    });

    test('refuses a buffer shorter than the size it claims', () {
      expect(
        grayFromLumaPlane(
          Uint8List(5),
          width: 3,
          height: 2,
          bytesPerRow: 3,
          maxDimension: 1000,
        ),
        isNull,
      );
    });

    test('refuses a stride narrower than a row', () {
      expect(
        grayFromLumaPlane(
          Uint8List(6),
          width: 3,
          height: 2,
          bytesPerRow: 2,
          maxDimension: 1000,
        ),
        isNull,
      );
    });
  });

  group('grayFromBgraPlane', () {
    test('weights the colour channels into a luminance', () {
      // BGRA: black, white, pure green.
      final plane = Uint8List.fromList(<int>[
        0, 0, 0, 255, //
        255, 255, 255, 255, //
        0, 255, 0, 255,
      ]);

      final read = grayFromBgraPlane(
        plane,
        width: 3,
        height: 1,
        bytesPerRow: 12,
        maxDimension: 1000,
      )!;

      expect(read.gray, <int>[0, 255, 150]);
    });

    test('drops the row padding too', () {
      final plane = Uint8List.fromList(<int>[
        0, 0, 0, 255, 0, 0, 0, 255, //
        255, 255, 255, 255, 255, 255, 255, 255,
      ]);

      final read = grayFromBgraPlane(
        plane,
        width: 2,
        height: 2,
        bytesPerRow: 8,
        maxDimension: 1000,
      )!;

      expect(read.gray, <int>[0, 0, 255, 255]);
    });

    test('refuses a stride that cannot hold four bytes per pixel', () {
      expect(
        grayFromBgraPlane(
          Uint8List(8),
          width: 2,
          height: 1,
          bytesPerRow: 6,
          maxDimension: 1000,
        ),
        isNull,
      );
    });
  });

  group('framePointToPreview', () {
    test('leaves a frame that is already upright alone', () {
      expectPoint(framePointToPreview(const Pt(0.2, 0.7), 0), 0.2, 0.7);
    });

    test('turns a landscape frame a quarter turn clockwise for 90', () {
      expectPoint(framePointToPreview(const Pt(0.2, 0.7), 90), 0.3, 0.2);
    });

    test('turns it all the way round for 180', () {
      expectPoint(framePointToPreview(const Pt(0.2, 0.7), 180), 0.8, 0.3);
    });

    test('turns a quarter turn the other way for 270', () {
      expectPoint(framePointToPreview(const Pt(0.2, 0.7), 270), 0.7, 0.8);
    });
  });

  group('frameQuadToPreview', () {
    // A page down the left of a landscape frame — deliberately not a square, so
    // that a turn that went the wrong way, or did nothing at all, cannot pass.
    const leftOfFrame = Quad(
      topLeft: Pt(0.1, 0.1),
      topRight: Pt(0.6, 0.1),
      bottomRight: Pt(0.6, 0.9),
      bottomLeft: Pt(0.1, 0.9),
    );

    test('hands back the same quad when there is no turn to make', () {
      expect(
        identical(frameQuadToPreview(leftOfFrame, 0), leftOfFrame),
        isTrue,
      );
    });

    test('re-labels the corners so the quad still reads top-left first', () {
      final turned = frameQuadToPreview(leftOfFrame, 90);

      // The turn moves every corner somewhere else, but the result still has to
      // be top-left, top-right, bottom-right, bottom-left: the crop pipeline
      // reads that order as meaning, not as a hint. Turning a page that ran
      // down the left of the frame makes it run across the top.
      expectPoint(turned.topLeft, 0.1, 0.1);
      expectPoint(turned.topRight, 0.9, 0.1);
      expectPoint(turned.bottomRight, 0.9, 0.6);
      expectPoint(turned.bottomLeft, 0.1, 0.6);
    });

    test('keeps the corners in clockwise order for every turn', () {
      for (final orientation in <int>[0, 90, 180, 270]) {
        final turned = frameQuadToPreview(leftOfFrame, orientation);
        final points = turned.points;

        // A convex, clockwise-wound quad: every turn of the same shape lands on
        // one, and inverting the winding is what a mis-signed rotation does.
        double cross(Pt a, Pt b, Pt c) =>
            (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);

        for (int i = 0; i < 4; i++) {
          expect(
            cross(points[i], points[(i + 1) % 4], points[(i + 2) % 4]),
            greaterThan(0),
            reason: 'orientation $orientation turns the winding inside out',
          );
        }
      }
    });
  });

  group('normalizedFrameQuad', () {
    const quad = Quad(
      topLeft: Pt(10, 20),
      topRight: Pt(90, 20),
      bottomRight: Pt(90, 80),
      bottomLeft: Pt(10, 80),
    );

    test('expresses the corners as fractions of the frame', () {
      final normalized = normalizedFrameQuad(quad, 100, 100);

      expectPoint(normalized.topLeft, 0.1, 0.2);
      expectPoint(normalized.bottomRight, 0.9, 0.8);
    });

    test('leaves the quad alone when the frame has no size to divide by', () {
      expect(identical(normalizedFrameQuad(quad, 0, 0), quad), isTrue);
    });
  });
}

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:memos_flutter_app/core/scan/document_scan.dart';

/// A horizontal luminance ramp, so every filter has something to stretch,
/// threshold and divide against.
Uint8List _ramp(int width, int height) {
  final image = img.Image(width: width, height: height);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final v = (x * 255 / (width - 1)).round();
      image.setPixelRgb(x, y, v, (v * 0.9).round(), (v * 0.8).round());
    }
  }
  return img.encodeJpg(image, quality: 95);
}

void main() {
  group('filter primitives', () {
    test('integralImage and boxBlur leave a constant buffer alone', () {
      final gray = Uint8List.fromList(List<int>.filled(12 * 9, 100));

      final table = integralImage(gray, 12, 9);
      expect(boxSum(table, 12, 0, 0, 11, 8), 100 * 12 * 9);

      final blurred = boxBlur(gray, 12, 9, 3);
      expect(blurred.length, gray.length);
      expect(blurred.every((v) => v == 100), isTrue);
    });

    test('percentileBounds finds the populated range of a histogram', () {
      final histogram = List<int>.filled(256, 0);
      for (int v = 60; v <= 200; v++) {
        histogram[v] = 10;
      }

      final bounds = percentileBounds(histogram, 0.005, 0.005);

      expect(bounds[0], greaterThanOrEqualTo(60));
      expect(bounds[0], lessThan(70));
      expect(bounds[1], lessThanOrEqualTo(200));
      expect(bounds[1], greaterThan(190));
    });

    test('stretchLut spans the full range between its bounds', () {
      final lut = stretchLut(50, 150);
      expect(lut[50], 0);
      expect(lut[150], 255);
      expect(lut[100], closeTo(128, 2));
      expect(lut[0], 0);
      expect(lut[255], 255);
    });

    test('otsuThreshold splits a bimodal buffer between its two modes', () {
      // Two modes with real width, and an empty gap between them. Otsu has no
      // strict maximum anywhere inside the gap, so it tie-breaks onto the top of
      // the lower mode; what matters is that the split lands in the gap and
      // separates the modes, not which end of the gap it picks.
      final buffer = Uint8List(2000);
      for (int i = 0; i < 1000; i++) {
        buffer[i] = 20 + (i % 20); // dark mode, 20..39
        buffer[1000 + i] = 200 + (i % 20); // bright mode, 200..219
      }

      final split = otsuThreshold(buffer);

      expect(split, greaterThanOrEqualTo(39));
      expect(split, lessThanOrEqualTo(200));

      final mask = threshold(buffer, split);
      final marked = mask.where((v) => v == 1).length;
      // The 1000 bright pixels, plus at most the single dark value the
      // tie-break landed on.
      expect(marked, greaterThanOrEqualTo(1000));
      expect(marked, lessThanOrEqualTo(1050));
    });
  });

  group('documentFiltersList', () {
    test('exposes the six scanner modes with stable ids', () {
      expect(documentFiltersList.map((f) => f.name).toList(), [
        'Original',
        'Auto',
        'Lighten',
        'Grayscale',
        'B&W',
        'Whiteboard',
      ]);
    });

    test('falls back to the default filter for an unknown id', () {
      expect(documentFilterByName(null), same(defaultDocumentFilter));
      expect(documentFilterByName('Nope'), same(defaultDocumentFilter));
      expect(documentFilterByName('Auto').name, 'Auto');
    });

    test('a page starts as a scan rather than as the capture', () {
      // A camera frame is a photo of paper — the room's light is still in it.
      // Shipping that as-is is what makes a scan look like a snapshot, so the
      // starting filter has to be one that levels the page.
      expect(defaultDocumentFilter.name, 'Auto');
      expect(defaultDocumentFilter, isNot(isA<OriginalFilter>()));
      // The untouched capture must still be reachable, for the page that
      // should be kept exactly as it was shot.
      expect(documentFiltersList.map((f) => f.name), contains('Original'));
    });
  });

  group('filterDocumentBytes', () {
    test('every mode returns a decodable image of the same size', () {
      final encoded = _ramp(64, 48);

      for (final filter in documentFiltersList) {
        final filtered = filterDocumentBytes(encoded, filterName: filter.name);
        final decoded = img.decodeImage(filtered);

        expect(decoded, isNotNull, reason: '${filter.name} produced no image');
        expect(decoded!.width, 64, reason: '${filter.name} changed the width');
        expect(decoded.height, 48, reason: '${filter.name} changed the height');
      }
    });

    test('B&W binarizes the page', () {
      final encoded = _ramp(64, 48);

      final decoded = img.decodeImage(
        filterDocumentBytes(encoded, filterName: 'B&W'),
      )!;

      int extremes = 0;
      final total = decoded.width * decoded.height;
      for (int y = 0; y < decoded.height; y++) {
        for (int x = 0; x < decoded.width; x++) {
          final p = decoded.getPixel(x, y);
          expect(p.r.toInt(), p.g.toInt());
          expect(p.g.toInt(), p.b.toInt());
          final v = p.r.toInt();
          if (v < 32 || v > 223) extremes++;
        }
      }
      // JPEG ringing stops this being a strict 0/255 check; the point is that
      // the page ends up with no midtones left.
      expect(extremes / total, greaterThan(0.9));
    });

    test('an unknown filter id behaves exactly like the default filter', () {
      final encoded = _ramp(64, 48);

      final unknown = filterDocumentBytes(
        encoded,
        filterName: 'does-not-exist',
      );
      final fallback = filterDocumentBytes(
        encoded,
        filterName: defaultDocumentFilter.name,
      );

      // A page saved by a build that offered a mode this one does not still has
      // to open looking like something, and "the way a page starts" is the
      // answer — not "untouched", which is now a mode the user picks.
      expect(unknown, orderedEquals(fallback));
    });

    test('maxEdge downscales the working image', () {
      final encoded = _ramp(400, 200);

      final decoded = img.decodeImage(
        filterDocumentBytes(encoded, filterName: 'Auto', maxEdge: 100),
      )!;

      expect(decoded.width, 100);
      expect(decoded.height, 50);
    });

    test('throws a StateError on undecodable bytes', () {
      final garbage = Uint8List.fromList(List<int>.filled(32, 4));

      expect(
        () => filterDocumentBytes(garbage, filterName: 'Auto'),
        throwsA(isA<StateError>()),
      );
    });
  });
}

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:memos_flutter_app/core/scan/src/deskew.dart';

/// A synthetic "page of text": horizontal ink bars on white, which is what the
/// projection-profile estimator aligns on. Real text has the same structure —
/// dark rows separated by light gaps — with noisier edges.
img.Image _textPage({int width = 800, int height = 1000}) {
  final page = img.Image(width: width, height: height, numChannels: 3);
  img.fill(page, color: img.ColorRgb8(255, 255, 255));
  final random = math.Random(7);
  for (var y = 60; y < height - 60; y += 26) {
    final left = 60 + random.nextInt(40);
    final right = width - 60 - random.nextInt(120);
    img.fillRect(
      page,
      x1: left,
      y1: y,
      x2: right,
      y2: y + 7,
      color: img.ColorRgb8(20, 20, 20),
    );
  }
  return page;
}

double _angleOf(img.Image page) => estimatePageSkewAngle(page);

void main() {
  group('estimatePageSkewAngle', () {
    test('an upright page reports no tilt', () {
      final angle = _angleOf(_textPage());
      expect(angle, lessThan(0.5));
    });

    test('a page tilted clockwise by 6° is reported as +6°', () {
      final tilted = img.copyRotate(_textPage(), angle: 6);
      final angle = _angleOf(tilted);
      expect(angle, closeTo(6, 0.75));
    });

    test('a page tilted counter-clockwise by 6° is reported as −6°', () {
      final tilted = img.copyRotate(_textPage(), angle: -6);
      final angle = _angleOf(tilted);
      expect(angle, closeTo(-6, 0.75));
    });

    test('a blank page reports no tilt', () {
      final blank = img.Image(width: 600, height: 800, numChannels: 3);
      img.fill(blank, color: img.ColorRgb8(245, 245, 245));
      expect(_angleOf(blank), 0);
    });

    test('a sideways page is refused — that is a quarter-turn, not a skew', () {
      final sideways = img.copyRotate(_textPage(), angle: 90);
      expect(_angleOf(sideways), 0);
    });

    test('a tiny page reports no tilt rather than dividing by nothing', () {
      final tiny = img.Image(width: 10, height: 10, numChannels: 3);
      img.fill(tiny, color: img.ColorRgb8(255, 255, 255));
      expect(_angleOf(tiny), 0);
    });
  });

  group('deskewPage', () {
    test('an upright page is returned as-is — no resample of a good page', () {
      final page = _textPage();
      expect(identical(deskewPage(page), page), isTrue);
    });

    test('a tilted page comes back with its text running horizontally', () {
      final tilted = img.copyRotate(_textPage(), angle: 6);
      final straightened = deskewPage(tilted);
      expect(_angleOf(straightened).abs(), lessThan(0.75));
    });

    test('the correction rotates against the tilt, whichever way it runs', () {
      for (final tilt in const [-9.0, -4.0, 4.0, 9.0]) {
        final tilted = img.copyRotate(_textPage(), angle: tilt);
        final straightened = deskewPage(tilted);
        expect(
          _angleOf(straightened).abs(),
          lessThan(0.75),
          reason: 'tilt $tilt should straighten out',
        );
      }
    });
  });
}

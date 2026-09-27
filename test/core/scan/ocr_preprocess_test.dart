import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:memos_flutter_app/core/scan/src/ocr_preprocess.dart';

/// A synthetic page: bright paper carrying a strong left-to-right lighting
/// gradient, with dark bars standing in for lines of text.
///
/// Everything is drawn rather than photographed so the test asserts against
/// known ground truth — this is the failure mode real scans hit most often,
/// and a fixture with a small picture attached would only ever prove it once.
img.Image _pageWithGradient({
  int width = 400,
  int height = 300,
  double litLevel = 235,
  double shadowedLevel = 110,
  double inkRatio = 0.15,
}) {
  final page = img.Image(width: width, height: height, numChannels: 3);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final illumination =
          litLevel - (litLevel - shadowedLevel) * (x / (width - 1));
      final isInk = y % 40 < 12 && x > 20 && x < width - 20;
      final value = (isInk ? illumination * inkRatio : illumination)
          .round()
          .clamp(0, 255);
      page.setPixelRgb(x, y, value, value, value);
    }
  }
  return page;
}

/// The brightness of one pixel.
///
/// Read from the first channel directly rather than as an RGB weighting: the
/// preprocessor emits a single-channel PNG, whose `g`/`b` read as 0 and would
/// make any weighted luminance three times too dark. Every fixture here is
/// grey anyway, so channel 0 is the value.
double _luminanceAt(img.Image image, int x, int y) =>
    image.getPixel(x, y).r.toDouble();

bool _isPng(Uint8List bytes) =>
    bytes.length > 3 &&
    bytes[0] == 0x89 &&
    bytes[1] == 0x50 &&
    bytes[2] == 0x4e &&
    bytes[3] == 0x47;

void main() {
  group('preprocessPageForOcr', () {
    test('keeps the page grey-scale encoded as PNG', () {
      final source = Uint8List.fromList(
        img.encodeJpg(_pageWithGradient(width: 240, height: 320), quality: 95),
      );
      final result = preprocessPageForOcr(source);

      expect(_isPng(result), isTrue);

      final decoded = img.decodeImage(result);
      expect(decoded, isNotNull);
      expect(decoded!.width, 240);
      expect(decoded.height, 320);
    });

    test('removes the lighting gradient across the paper', () {
      const width = 400;
      const height = 300;
      final source = Uint8List.fromList(
        img.encodeJpg(
          _pageWithGradient(width: width, height: height),
          quality: 95,
        ),
      );

      // Ground truth: the same row of paper is 125 levels darker at the far
      // edge than at the near one. Nothing about the paper changed — only the
      // light did, and that is exactly what should not survive.
      final original = _pageWithGradient(width: width, height: height);
      final originalGap =
          (_luminanceAt(original, 6, 20) - _luminanceAt(original, width - 7, 20))
              .abs();
      expect(originalGap, greaterThan(90));

      final result = img.decodeImage(preprocessPageForOcr(source))!;
      final flatGap =
          (_luminanceAt(result, 6, 20) - _luminanceAt(result, width - 7, 20))
              .abs();
      expect(flatGap, lessThan(45));
    });

    test('keeps the ink dark against the flattened paper', () {
      const width = 400;
      const height = 300;
      final source = Uint8List.fromList(
        img.encodeJpg(
          _pageWithGradient(width: width, height: height),
          quality: 95,
        ),
      );
      final result = img.decodeImage(preprocessPageForOcr(source))!;

      // y=5 is inside a text bar, y=30 is the paper between two bars.
      final ink = _luminanceAt(result, 200, 5);
      final paper = _luminanceAt(result, 200, 30);
      expect(paper, greaterThan(200));
      expect(paper - ink, greaterThan(60));
    });

    test('lifts ink that was barely distinguishable from paper', () {
      const width = 400;
      const height = 300;
      // Faint print in deep shadow: 12% contrast at ~110 brightness is about
      // 13 levels, which is around where a recogniser starts losing strokes.
      final faint = Uint8List.fromList(
        img.encodeJpg(
          _pageWithGradient(
            width: width,
            height: height,
            litLevel: 200,
            shadowedLevel: 110,
            inkRatio: 0.88,
          ),
          quality: 95,
        ),
      );

      final before = img.decodeImage(faint)!;
      final beforeContrast =
          _luminanceAt(before, 380, 30) - _luminanceAt(before, 380, 5);
      final afterContrast = () {
        final result = img.decodeImage(preprocessPageForOcr(faint))!;
        return _luminanceAt(result, 380, 30) - _luminanceAt(result, 380, 5);
      }();

      expect(afterContrast, greaterThan(beforeContrast * 3));
    });

    test('a pitch-black region stays black instead of blowing up to white', () {
      // This is what [kBackgroundFloor] is for. Dividing by a zero background
      // would either throw or, clamped, flip the whole region to white paper —
      // turning a shadow into a page-wide flood of false strokes.
      const size = 160;
      final black = img.Image(width: size, height: size, numChannels: 3);
      for (int y = 0; y < size; y++) {
        for (int x = 0; x < size; x++) {
          black.setPixelRgb(x, y, 0, 0, 0);
        }
      }

      final result = img.decodeImage(
        preprocessPageForOcr(Uint8List.fromList(img.encodePng(black))),
      )!;

      for (int i = 0; i < size; i += 17) {
        expect(_luminanceAt(result, i, i), lessThan(20));
      }
    });

    test('caps the long edge so oversized pages are not processed in full', () {
      final oversized = img.Image(width: 3200, height: 2400, numChannels: 3);
      for (int y = 0; y < 2400; y += 4) {
        for (int x = 0; x < 3200; x += 4) {
          oversized.setPixelRgb(x, y, 250, 250, 250);
        }
      }
      final result = img.decodeImage(
        preprocessPageForOcr(Uint8List.fromList(img.encodePng(oversized))),
      );

      expect(result, isNotNull);
      expect(
        max(result!.width, result.height),
        lessThanOrEqualTo(kOcrInputMaxEdge),
      );
    });

    test('flat flattens the light without driving the ink to black', () {
      const width = 400;
      const height = 300;
      final source = Uint8List.fromList(
        img.encodeJpg(
          _pageWithGradient(width: width, height: height),
          quality: 95,
        ),
      );

      final flat = img.decodeImage(
        preprocessPageForOcr(source, level: OcrPreprocessLevel.flat),
      )!;
      final aggressive = img.decodeImage(
        preprocessPageForOcr(source, level: OcrPreprocessLevel.aggressive),
      )!;

      // It is still a flattened page — the room's lighting has gone.
      final flatGap =
          (_luminanceAt(flat, 6, 20) - _luminanceAt(flat, width - 7, 20)).abs();
      expect(flatGap, lessThan(45));

      // But the ink was left where it was instead of being pushed to solid
      // black. That is the whole point of the level: a dense Chinese glyph has
      // strokes a couple of pixels apart, and thickening them is what makes
      // neighbouring strokes run together.
      expect(
        _luminanceAt(flat, 200, 5),
        greaterThan(_luminanceAt(aggressive, 200, 5)),
      );
      expect(_luminanceAt(flat, 200, 5), greaterThan(0));
    });

    test('hands back undecodable bytes untouched rather than failing', () {
      final junk = Uint8List.fromList(<int>[0x01, 0x02, 0x03, 0x04]);
      expect(preprocessPageForOcr(junk), same(junk));
    });

    test('aggressive pushes the levels harder than balanced', () {
      final source = Uint8List.fromList(
        img.encodeJpg(_pageWithGradient(width: 320, height: 240), quality: 95),
      );

      final balanced = img.decodeImage(
        preprocessPageForOcr(source, level: OcrPreprocessLevel.balanced),
      )!;
      final aggressive = img.decodeImage(
        preprocessPageForOcr(source, level: OcrPreprocessLevel.aggressive),
      )!;

      // Higher contrast means the paper is whiter and the ink blacker than the
      // same pixel under `balanced`.
      final balancedPaper = _luminanceAt(balanced, 160, 30);
      final aggressivePaper = _luminanceAt(aggressive, 160, 30);
      final balancedInk = _luminanceAt(balanced, 160, 5);
      final aggressiveInk = _luminanceAt(aggressive, 160, 5);

      expect(aggressivePaper, greaterThanOrEqualTo(balancedPaper - 1));
      expect(aggressiveInk, lessThanOrEqualTo(balancedInk + 1));
    });
  });
}

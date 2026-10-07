import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/scan/src/boundary_color_step.dart';
import 'package:memos_flutter_app/core/scan/src/edge_detection.dart';
import 'package:memos_flutter_app/core/scan/src/image_ops.dart';
import 'package:memos_flutter_app/core/scan/src/models/point.dart';
import 'package:memos_flutter_app/core/scan/src/models/quad.dart';

/// Guards for the two boundary-detection changes ported in from STACK.
///
/// Both were ported together because they are two halves of one idea: the
/// detector now measures the gradient at a coarse scale ([kBoundaryBlurFraction])
/// and fuses chroma into it, which is what makes a pale page on a differently
/// coloured surface findable at all — and that same coarse field makes a solid
/// block of dense text survive as one convincing rectangle, so the candidate now
/// has to prove it separates two differently-coloured regions before it is
/// trusted. Neither half is testable in isolation: enabling chroma without the
/// guard, or the guard without chroma, leaves the detector worse off than
/// before the port rather than neutral.

const int _w = 300;
const int _h = 400;

Uint8List _fill(int width, int height, int r, int g, int b) {
  final out = Uint8List(width * height * 4);
  for (var p = 0; p < width * height; p++) {
    out[p * 4] = r;
    out[p * 4 + 1] = g;
    out[p * 4 + 2] = b;
    out[p * 4 + 3] = 255;
  }
  return out;
}

void _setPixel(Uint8List buf, int x, int y, int r, int g, int b) {
  final p = (y * _w + x) * 4;
  buf[p] = r;
  buf[p + 1] = g;
  buf[p + 2] = b;
  buf[p + 3] = 255;
}

/// A page inset by [margin] inside a background of the given colour, with
/// [inkLines] rows of text-like marks on it so the page is not blank.
Uint8List _page(
  int margin, {
  required int bgR,
  required int bgG,
  required int bgB,
  required int paperR,
  required int paperG,
  required int paperB,
  int inkLines = 12,
}) {
  final buf = _fill(_w, _h, bgR, bgG, bgB);
  for (var y = margin; y < _h - margin; y++) {
    for (var x = margin; x < _w - margin; x++) {
      _setPixel(buf, x, y, paperR, paperG, paperB);
    }
  }
  for (var i = 0; i < inkLines; i++) {
    final y = margin + 12 + i * 12;
    if (y >= _h - margin - 6) break;
    for (var x = margin + 10; x < _w - margin - 10; x++) {
      // Dashes, not a solid rule: a real text line is mostly bare paper, which
      // is the whole point of the coarse field smoothing ink away.
      if ((x - margin) ~/ 7 % 2 == 0) continue;
      _setPixel(buf, x, y, 20, 20, 20);
    }
  }
  return buf;
}

double _edgeEnergyOnBoundary(
  Uint8List magnitude,
  Quad quad,
) {
  // Average magnitude sampled along the quad's own edges — the signal the
  // contour search actually scores candidates on.
  final pts = [quad.topLeft, quad.topRight, quad.bottomRight, quad.bottomLeft];
  var sum = 0.0;
  var n = 0;
  for (var e = 0; e < 4; e++) {
    final a = pts[e];
    final b = pts[(e + 1) % 4];
    final steps = 200;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = (a.x + (b.x - a.x) * t).round().clamp(0, _w - 1);
      final y = (a.y + (b.y - a.y) * t).round().clamp(0, _h - 1);
      sum += magnitude[y * _w + x];
      n++;
    }
  }
  return n == 0 ? 0 : sum / n;
}

void main() {
  group('boxBlurGray', () {
    test('radius 0 returns the source unchanged', () {
      final src = Uint8List.fromList(List<int>.generate(16, (i) => i * 7 % 256));
      final out = boxBlurGray(src, 4, 4, 0);
      expect(out, src);
    });

    test('a flat field is unchanged by any blur — the invariant that lets the '
        'boundary scale be raised without touching interior texture', () {
      final flat = _fill(32, 32, 200, 200, 200);
      final out = boxBlurGray(
        Uint8List.fromList(List<int>.generate(32 * 32, (i) => flat[i * 4])),
        32,
        32,
        5,
      );
      for (final v in out) {
        expect(v, closeTo(200, 1));
      }
    });

    test('a single bright pixel is spread out, not left as an outlier', () {
      final src = Uint8List(16 * 16);
      for (var p = 0; p < src.length; p++) {
        src[p] = 30;
      }
      src[8 * 16 + 8] = 255;
      final out = boxBlurGray(src, 16, 16, 2);
      expect(out[8 * 16 + 8], lessThan(255));
      expect(out[8 * 16 + 8], greaterThan(30));
      // Energy is conserved in the interior: the mean is unchanged.
      var srcSum = 0, outSum = 0;
      for (var p = 0; p < src.length; p++) {
        srcSum += src[p];
        outSum += out[p];
      }
      expect(outSum / src.length, closeTo(srcSum / src.length, 1.5));
    });
  });

  group('documentEdgeMagnitude', () {
    test('degenerate frames are refused rather than throwing', () {
      expect(documentEdgeMagnitude(Uint8List(0), 0, 0), isEmpty);
      expect(documentEdgeMagnitude(Uint8List(16), 0, 4), isEmpty);
      expect(documentEdgeMagnitude(Uint8List(16), 4, 0), isEmpty);
    });

    test('a pale page on a same-brightness surface of a different hue is found '
        '— the case luminance alone cannot see', () {
      // Luminance difference here is under 3 levels: Rec.601 gives the surface
      // 200.0 and the page 202.5, so a luminance-only gradient has almost
      // nothing to stand on. The hue difference is large (the page is markedly
      // blue), which is what the chroma term picks up. A larger luminance gap
      // would make this test pass for the wrong reason — the coarse field
      // deliberately smooths weak steps away, so the test has to be built where
      // only chroma can carry the boundary.
      final buf = _page(
        40,
        bgR: 200,
        bgG: 200,
        bgB: 200,
        paperR: 200,
        paperG: 189,
        paperB: 255,
      );
      final magnitude = documentEdgeMagnitude(buf, _w, _h);
      final quad = Quad(
        topLeft: Pt(40, 40),
        topRight: Pt(_w - 40, 40),
        bottomRight: Pt(_w - 40, _h - 40),
        bottomLeft: Pt(40, _h - 40),
      );

      // Rec.601 luminance of the surface is 200.0 and of the page 199.8 —
      // equal to within a fifth of a level. The green channel is pulled *down*
      // precisely so the blue channel can go up without dragging luminance
      // along with it; that is the only way to build a frame where the
      // luminance-only field has nothing to stand on. Cb differs by ~31.
      final fused = _edgeEnergyOnBoundary(magnitude, quad);
      final luminanceOnly = _edgeEnergyOnBoundary(
        sobelMagnitude(rgbaToGrayscale(buf, _w, _h), _w, _h),
        quad,
      );

      // Chroma fusion must be what carries the boundary here, not a tie.
      expect(luminanceOnly, lessThan(30));
      expect(fused, greaterThan(luminanceOnly * 1.5));
    });

    test('the fine-scale field still resolves individual strokes — the '
        'full-page guard depends on it', () {
      final buf = _page(
        40,
        bgR: 20,
        bgG: 20,
        bgB: 20,
        paperR: 245,
        paperG: 245,
        paperB: 245,
        inkLines: 12,
      );
      final fine = sobelMagnitude(rgbaToGrayscale(buf, _w, _h), _w, _h);
      final coarse = documentEdgeMagnitude(buf, _w, _h);

      // Somewhere on the page's interior the strokes are strong in the fine
      // field. The coarse field is *supposed* to have smoothed them away — that
      // is why the full-page check keeps using the fine one.
      var finePeak = 0, coarsePeak = 0;
      for (var y = 50; y < _h - 50; y++) {
        for (var x = 50; x < _w - 50; x++) {
          final fineV = fine[y * _w + x];
          final coarseV = coarse[y * _w + x];
          if (fineV > finePeak) finePeak = fineV;
          if (coarseV > coarsePeak) coarsePeak = coarseV;
        }
      }
      expect(finePeak, greaterThan(60));
      expect(coarsePeak, lessThan(finePeak));
    });

    test('a page edge survives the coarse field — the blur must not erase it', () {
      final buf = _page(
        40,
        bgR: 25,
        bgG: 25,
        bgB: 30,
        paperR: 240,
        paperG: 238,
        paperB: 232,
        inkLines: 0,
      );
      final coarse = documentEdgeMagnitude(buf, _w, _h);
      var edgePeak = 0;
      // The left edge sits at x=40.
      for (var y = 60; y < _h - 60; y++) {
        final v = coarse[y * _w + 40];
        if (v > edgePeak) edgePeak = v;
      }
      expect(edgePeak, greaterThan(40));
    });

    test('a frame already filled to the border reports no boundary — no '
        'contrast anywhere means no page to find', () {
      final flat = _fill(_w, _h, 128, 128, 128);
      final magnitude = documentEdgeMagnitude(flat, _w, _h);
      var peak = 0;
      for (final v in magnitude) {
        if (v > peak) peak = v;
      }
      expect(peak, lessThanOrEqualTo(1));
    });
  });

  group('boundaryColorStep', () {
    test('a real page edge separates two different colours', () {
      final buf = _page(
        40,
        bgR: 60,
        bgG: 45,
        bgB: 35,
        paperR: 244,
        paperG: 240,
        paperB: 230,
        inkLines: 0,
      );
      final quad = Quad(
        topLeft: Pt(40, 40),
        topRight: Pt(_w - 40, 40),
        bottomRight: Pt(_w - 40, _h - 40),
        bottomLeft: Pt(40, _h - 40),
      );
      final step = boundaryColorStep(buf, _w, _h, quad);
      expect(step, greaterThan(kMinBoundaryColorStep));
      expect(quadSeparatesRegions(buf, _w, _h, quad), isTrue);
    });

    test('a box drawn *inside* a blank page is rejected — the failure mode the '
        'guard exists for', () {
      final buf = _page(
        20,
        bgR: 40,
        bgG: 40,
        bgB: 45,
        paperR: 250,
        paperG: 248,
        paperB: 242,
        inkLines: 0,
      );
      // Both sides of this rectangle are the same paper.
      final inner = Quad(
        topLeft: Pt(100, 140),
        topRight: Pt(210, 140),
        bottomRight: Pt(210, 260),
        bottomLeft: Pt(100, 260),
      );
      final step = boundaryColorStep(buf, _w, _h, inner);
      expect(step, lessThan(kMinBoundaryColorStep));
      expect(quadSeparatesRegions(buf, _w, _h, inner), isFalse);
    });

    test('a weak *luminance* edge with a strong colour difference still passes '
        '— this is a colour check, not a brightness one', () {
      // Surface luminance 204.6, page luminance 207.0 — a ~2 level difference,
      // which a brightness threshold would call "the same thing". The blue
      // channel differs by 50, which YCbCr distance reports plainly. This is
      // the guard's whole reason for existing as a *colour* measurement.
      final buf = _page(
        40,
        bgR: 200,
        bgG: 200,
        bgB: 200,
        paperR: 200,
        paperG: 202,
        paperB: 250,
        inkLines: 0,
      );
      final quad = Quad(
        topLeft: Pt(40, 40),
        topRight: Pt(_w - 40, 40),
        bottomRight: Pt(_w - 40, _h - 40),
        bottomLeft: Pt(40, _h - 40),
      );
      expect(quadSeparatesRegions(buf, _w, _h, quad), isTrue);
    });

    test('a degenerate frame yields 0 rather than throwing', () {
      final quad = Quad(
        topLeft: Pt(0, 0),
        topRight: Pt(10, 0),
        bottomRight: Pt(10, 10),
        bottomLeft: Pt(0, 10),
      );
      expect(boundaryColorStep(Uint8List(0), 0, 0, quad), 0);
      expect(boundaryColorStep(Uint8List(4), 4, 4, quad), 0);
    });

    test('a quad entirely outside the frame yields 0 — nothing was sampled', () {
      final buf = _fill(_w, _h, 10, 10, 10);
      final outside = Quad(
        topLeft: Pt(5000, 5000),
        topRight: Pt(5100, 5000),
        bottomRight: Pt(5100, 5100),
        bottomLeft: Pt(5000, 5100),
      );
      expect(boundaryColorStep(buf, _w, _h, outside), 0);
      expect(quadSeparatesRegions(buf, _w, _h, outside), isFalse);
    });
  });
}

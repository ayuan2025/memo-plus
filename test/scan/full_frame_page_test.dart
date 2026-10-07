import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/scan/src/edge_detection.dart';
import 'package:memos_flutter_app/core/scan/src/full_frame_page.dart';
import 'package:memos_flutter_app/core/scan/src/models/point.dart';
import 'package:memos_flutter_app/core/scan/src/models/quad.dart';

/// Regression guard for the case that made the scanner destructive rather than
/// merely unhelpful: a picture that is *already* the finished page — imported
/// from the gallery, screenshotted, cropped elsewhere — has no paper edge for
/// detection to find, and machinery built to find one will instead lock onto
/// some rectangle inside the page and cut everything around it away.
///
/// Synthetic scenes below are deliberately cheap (no real glyphs): the question
/// being asked is whether written material exists beyond a candidate boundary,
/// which sharpness of detail is irrelevant to.
const int _width = 240;
const int _height = 320;

/// Row spacing of the fake lines of text.
const int _linePitch = 11;

Pt _pt(num x, num y) => Pt(x.toDouble(), y.toDouble());

bool _insideQuad(double x, double y, Quad q) {
  final pts = q.points;
  var winding = 0;
  for (var i = 0; i < 4; i++) {
    final a = pts[i];
    final b = pts[(i + 1) % 4];
    final cross = (b.x - a.x) * (y - a.y) - (b.y - a.y) * (x - a.x);
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

Uint8List _magnitudeOf(Uint8List gray) =>
    sobelMagnitude(gaussianBlur3(gray, _width, _height), _width, _height);

/// Writes rows of (fake) prose into [gray] over [x0]..[x1], [y0]..[y1].
void _writeLines(Uint8List gray, int x0, int x1, int y0, int y1) {
  for (var y = y0; y < y1; y++) {
    for (var x = x0; x < x1; x++) {
      if (x < 0 || x >= _width || y < 0 || y >= _height) continue;
      final rowIndex = (y - y0) ~/ _linePitch;
      final inRow =
          ((y - y0) % _linePitch) >= 3 && ((y - y0) % _linePitch) <= 6;
      final wordBreak = ((x + rowIndex * 5) % 9) < 6;
      gray[y * _width + x] = (inRow && wordBreak) ? 40 : 236;
    }
  }
}

Uint8List _blankPage() {
  final gray = Uint8List(_width * _height);
  gray.fillRange(0, gray.length, 236);
  return gray;
}

/// The paper lying on a desk, as its photo has it.
Quad _deskPage() => Quad(
  topLeft: _pt(52, 44),
  topRight: _pt(190, 50),
  bottomRight: _pt(184, 272),
  bottomLeft: _pt(48, 266),
);

/// An already-trimmed page whose writing runs to every edge — an export, a
/// screenshot, or a crop done in another app. Nothing of the page was left out,
/// so nothing is left to cut away.
Uint8List _renderTrimmedPage() {
  final gray = _blankPage();
  _writeLines(gray, 0, _width, 0, _height);
  return _magnitudeOf(gray);
}

/// The same page with a few pixels of margin kept around it: still already
/// trimmed, but now there is a border of nothing between the writing and the
/// frame, which is how detection comes to mistake a block *within* the page for
/// the page.
Uint8List _renderTrimmedPageWithMargin() {
  final gray = _blankPage();
  _writeLines(gray, 10, _width - 10, 10, _height - 10);
  return _magnitudeOf(gray);
}

/// A photo of a page: paper lying on a desk, surrounded by nothing that reads,
/// the prose confined to the paper and stopping well short of the frame edge.
Uint8List _renderDeskPhoto(Quad page) {
  final gray = Uint8List(_width * _height);
  for (var y = 0; y < _height; y++) {
    for (var x = 0; x < _width; x++) {
      final desk =
          78 + 30 * math.sin((x + y) / 90.0) + math.sin(x / 40.0) * 6;
      gray[y * _width + x] = _insideQuad(x + 0.5, y + 0.5, page)
          ? 236
          : desk.clamp(0, 255).round();
    }
  }
  final left = page.points.map((p) => p.x).reduce(math.min).ceil() + 10;
  final right = page.points.map((p) => p.x).reduce(math.max).floor() - 10;
  final top = page.points.map((p) => p.y).reduce(math.min).ceil() + 10;
  final bottom = page.points.map((p) => p.y).reduce(math.max).floor() - 10;
  _writeLines(gray, left, right, top, bottom);
  return _magnitudeOf(gray);
}

Quad _fullFrame() => fullFrameQuad(_width, _height);

/// A rectangle detection plausibly lands on inside a full page: a heading band
/// with rules under it, nowhere near the page's own extent.
Quad _bandInsidePage() => Quad(
  topLeft: _pt(20, 150),
  topRight: _pt(220, 150),
  bottomRight: _pt(220, 260),
  bottomLeft: _pt(20, 260),
);

void main() {
  group('isFullFrameQuad', () {
    test('recognises a quad covering essentially the whole frame', () {
      final quad = Quad(
        topLeft: _pt(1, 2),
        topRight: _pt(_width - 2, 1),
        bottomRight: _pt(_width - 1, _height - 2),
        bottomLeft: _pt(2, _height - 1),
      );
      expect(isFullFrameQuad(quad, _width, _height), isTrue);
    });

    test('leaves a page with its surround alone', () {
      expect(isFullFrameQuad(_deskPage(), _width, _height), isFalse);
    });
  });

  group('quadArea', () {
    test('measures the same whichever way round the corners are stored', () {
      final page = _deskPage();
      final reversed = Quad(
        topLeft: page.bottomLeft,
        topRight: page.bottomRight,
        bottomRight: page.topRight,
        bottomLeft: page.topLeft,
      );
      expect(quadArea(page), closeTo(quadArea(reversed), 0.5));
    });
  });

  group('measureFrameMargin', () {
    test('writing reaching the frame edge is reported', () {
      final evidence = measureFrameMargin(
        _renderTrimmedPage(),
        _width,
        _height,
      );
      expect(evidence.contentReachesFrameEdge, isTrue);
    });

    test('a page photographed on a desk is not', () {
      final evidence = measureFrameMargin(
        _renderDeskPhoto(_deskPage()),
        _width,
        _height,
      );
      expect(evidence.borderStrongFraction, lessThan(0.02));
      expect(evidence.contentReachesFrameEdge, isFalse);
    });
  });

  group('measurePageBoundary', () {
    test('a page on a desk has content inside and nothing beyond it', () {
      final page = _deskPage();
      final evidence = measurePageBoundary(
        _renderDeskPhoto(page),
        _width,
        _height,
        page,
      );
      expect(evidence.outsideStrongFraction, lessThan(0.02));
      expect(evidence.contentSpillsOutside, isFalse);
    });

    test('a rectangle inside a page has as much beyond it as within', () {
      final evidence = measurePageBoundary(
        _renderTrimmedPageWithMargin(),
        _width,
        _height,
        _bandInsidePage(),
      );
      expect(evidence.contentSpillsOutside, isTrue);
    });
  });

  group('resolveDocumentBoundary', () {
    test('writing at the frame edge, and nothing found: keep it all', () {
      final decision = resolveDocumentBoundary(
        magnitude: _renderTrimmedPage(),
        width: _width,
        height: _height,
        detected: null,
      );
      expect(decision.isFullPage, isTrue);
      expect(decision.reason, FullPageReason.contentAtFrameEdge);
      expect(decision.quad.topLeft.x, 0); expect(decision.quad.topLeft.y, 0);
      expect(decision.quad.bottomRight.x, _width.toDouble()); expect(decision.quad.bottomRight.y, _height.toDouble());
    });

    test('a rectangle found inside the content is not the page', () {
      final decision = resolveDocumentBoundary(
        magnitude: _renderTrimmedPageWithMargin(),
        width: _width,
        height: _height,
        detected: _bandInsidePage(),
      );
      expect(decision.isFullPage, isTrue);
      expect(decision.reason, FullPageReason.contentOutsideQuad);
      expect(decision.quad.topLeft.x, 0); expect(decision.quad.topLeft.y, 0);
    });

    test('a real page photographed on a desk is still cropped to', () {
      final page = _deskPage();
      final decision = resolveDocumentBoundary(
        magnitude: _renderDeskPhoto(page),
        width: _width,
        height: _height,
        detected: page,
      );
      expect(decision.isFullPage, isFalse);
      expect(decision.reason, isNull);
      expect(decision.quad.topLeft.x, page.topLeft.x);
      expect(decision.quad.topLeft.y, page.topLeft.y);
      expect(decision.quad.bottomRight.x, page.bottomRight.x);
      expect(decision.quad.bottomRight.y, page.bottomRight.y);
    });

    test('nothing found and nothing at the edge stays "nothing found"', () {
      final decision = resolveDocumentBoundary(
        magnitude: _renderDeskPhoto(_deskPage()),
        width: _width,
        height: _height,
        detected: null,
      );
      expect(decision.isFullPage, isFalse);
      // The hand-back is the inset guess, which is what the caller puts its
      // drag handles on — not the frame, which would leave nothing to pull.
      expect(decision.quad.topLeft.x, greaterThan(0));
      expect(decision.quad.topLeft.y, greaterThan(0));
    });

    test('a near-full-frame find over a full page is snapped to the frame', () {
      final decision = resolveDocumentBoundary(
        magnitude: _renderTrimmedPage(),
        width: _width,
        height: _height,
        detected: Quad(
          topLeft: _pt(3, 2),
          topRight: _pt(_width - 2, 3),
          bottomRight: _pt(_width - 3, _height - 2),
          bottomLeft: _pt(2, _height - 3),
        ),
      );
      expect(decision.isFullPage, isTrue);
      expect(decision.quad.topLeft.x, 0); expect(decision.quad.topLeft.y, 0);
    });

    test('an empty canvas has nothing worth deciding about', () {
      final decision = resolveDocumentBoundary(
        magnitude: _magnitudeOf(_blankPage()),
        width: _width,
        height: _height,
        detected: null,
      );
      expect(decision.isFullPage, isFalse);
    });
  });

  group('fullFrameQuad', () {
    test('spans exactly the image', () {
      final quad = _fullFrame();
      expect(quad.topLeft.x, 0); expect(quad.topLeft.y, 0);
      expect(quad.bottomRight.x, _width.toDouble()); expect(quad.bottomRight.y, _height.toDouble());
      expect(isFullFrameQuad(quad, _width, _height), isTrue);
    });
  });
}

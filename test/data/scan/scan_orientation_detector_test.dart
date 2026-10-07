import 'dart:math' show Point;
import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:memos_flutter_app/data/scan/scan_orientation_detector.dart';

/// Builds a recognition result whose [lineCorners] are each a line's four
/// corner points — top-left, top-right, bottom-right, bottom-left **in the
/// text's own reading orientation**, which is the contract the detector leans
/// on: the coordinates live in image space, the ordering follows the reading.
RecognizedText _recognized(
  List<List<Point<int>>> lineCorners, {
  String text = '这是一段足够长的页面文字，用来越过字符数门槛一二三四五六七八九十',
}) {
  final lines = [
    for (final corners in lineCorners)
      TextLine(
        text: '字 词',
        elements: const [],
        boundingBox: Rect.zero,
        recognizedLanguages: const [],
        cornerPoints: corners,
        confidence: 0.9,
        angle: 0,
      ),
  ];
  final block = TextBlock(
    text: text,
    lines: lines,
    boundingBox: Rect.zero,
    recognizedLanguages: const [],
    cornerPoints: lines.isEmpty ? const [] : lines.first.cornerPoints,
  );
  return RecognizedText(text: text, blocks: [block]);
}

/// One horizontal line, reading left to right.
List<Point<int>> _uprightLine(int x, int y) => [
  Point(x, y),
  Point(x + 300, y),
  Point(x + 300, y + 20),
  Point(x, y + 20),
];

void main() {
  group('quarterTurnsToUprightText', () {
    test('an upright page needs no turning', () {
      final page = _recognized([
        _uprightLine(100, 100),
        _uprightLine(100, 200),
        _uprightLine(100, 300),
        _uprightLine(100, 400),
      ]);
      expect(quarterTurnsToUprightText(page), 0);
    });

    test('an upside-down page asks for two turns', () {
      // Reading right-to-left with the line stack running upward: the same
      // horizontal lines, corner order reversed.
      final page = _recognized([
        [Point(400, 120), Point(100, 120), Point(100, 100), Point(400, 100)],
        [Point(400, 220), Point(100, 220), Point(100, 200), Point(400, 200)],
        [Point(400, 320), Point(100, 320), Point(100, 300), Point(400, 300)],
        [Point(400, 420), Point(100, 420), Point(100, 400), Point(400, 400)],
      ]);
      expect(quarterTurnsToUprightText(page), 2);
    });

    test('a page turned clockwise reads downward and asks for three turns', () {
      final page = _recognized([
        [Point(500, 100), Point(500, 400), Point(480, 400), Point(480, 100)],
        [Point(560, 100), Point(560, 400), Point(540, 400), Point(540, 100)],
        [Point(620, 100), Point(620, 400), Point(600, 400), Point(600, 100)],
        [Point(680, 100), Point(680, 400), Point(660, 400), Point(660, 100)],
      ]);
      expect(quarterTurnsToUprightText(page), 3);
    });

    test('a page turned counter-clockwise reads upward and asks for one turn',
        () {
      final page = _recognized([
        [Point(500, 400), Point(500, 300), Point(520, 300), Point(520, 400)],
        [Point(560, 400), Point(560, 300), Point(580, 300), Point(580, 400)],
        [Point(620, 400), Point(620, 300), Point(640, 300), Point(640, 400)],
        [Point(680, 400), Point(680, 300), Point(700, 300), Point(700, 400)],
      ]);
      expect(quarterTurnsToUprightText(page), 1);
    });

    test('too few lines is not enough to judge', () {
      final page = _recognized([
        [Point(500, 100), Point(500, 400), Point(480, 400), Point(480, 100)],
        [Point(560, 100), Point(560, 400), Point(540, 400), Point(540, 100)],
      ]);
      expect(quarterTurnsToUprightText(page), isNull);
    });

    test('lines that disagree are not enough to judge', () {
      final page = _recognized([
        _uprightLine(100, 100),
        _uprightLine(100, 200),
        _uprightLine(100, 300),
        [Point(500, 100), Point(500, 400), Point(480, 400), Point(480, 100)],
      ]);
      expect(quarterTurnsToUprightText(page), isNull);
    });

    test('a line at a diagonal casts no vote rather than a wrong one', () {
      final page = _recognized([
        // Reading direction (3,2): within the 2:1 margin of neither axis.
        [
          Point(100, 100),
          Point(103, 102),
          Point(103, 104),
          Point(100, 102),
        ],
        _uprightLine(100, 200),
        _uprightLine(100, 300),
        _uprightLine(100, 400),
      ]);
      // The three clean lines still carry the verdict.
      expect(quarterTurnsToUprightText(page), 0);
    });

    test('almost no text is not enough to judge', () {
      final page = _recognized(
        [
          _uprightLine(100, 100),
          _uprightLine(100, 200),
          _uprightLine(100, 300),
        ],
        text: 'hi',
      );
      expect(quarterTurnsToUprightText(page), isNull);
    });

    test('a single stray sideways line does not outweigh the page', () {
      final page = _recognized([
        _uprightLine(100, 100),
        _uprightLine(100, 200),
        _uprightLine(100, 300),
        _uprightLine(100, 400),
        _uprightLine(100, 500),
        _uprightLine(100, 600),
        // A stamp or a sideways watermark: one line against six.
        [Point(500, 100), Point(500, 400), Point(480, 400), Point(480, 100)],
      ]);
      // 6 of 7 agree — just above the 0.85 bar, so the page still judges.
      expect(quarterTurnsToUprightText(page), 0);
    });

    test('a lopsided vote below the agreement bar is not enough', () {
      final page = _recognized([
        _uprightLine(100, 100),
        _uprightLine(100, 200),
        _uprightLine(100, 300),
        _uprightLine(100, 400),
        _uprightLine(100, 500),
        [Point(500, 100), Point(500, 400), Point(480, 400), Point(480, 100)],
      ]);
      // 5 of 6 agree — 0.83, below the 0.85 bar.
      expect(quarterTurnsToUprightText(page), isNull);
    });

    test('no recognition at all is no rotation', () {
      expect(quarterTurnsToUprightText(RecognizedText(text: '', blocks: [])),
          isNull);
    });
  });

  group('quarterTurnsToUprightText with the page size', () {
    // Lines reading bottom-to-top, i.e. a page asking for one quarter turn.
    List<Point<int>> sidewaysLine(int x) => [
      Point(x, 400),
      Point(x, 300),
      Point(x + 20, 300),
      Point(x + 20, 400),
    ];

    test('a portrait page on its side needs more than a few lines', () {
      final page = _recognized([
        sidewaysLine(500),
        sidewaysLine(560),
        sidewaysLine(620),
        sidewaysLine(680),
      ]);
      // Four lines, all in agreement — enough for the ordinary bar, not for
      // standing a portrait page on its side.
      expect(
        quarterTurnsToUprightText(page, pageWidth: 800, pageHeight: 1130),
        isNull,
      );
    });

    test('a portrait page turns on overwhelming agreement', () {
      final page = _recognized([
        for (int i = 0; i < 7; i++) sidewaysLine(500 + i * 60),
      ]);
      expect(
        quarterTurnsToUprightText(page, pageWidth: 800, pageHeight: 1130),
        1,
      );
    });

    test('a page with nothing to lose its shape turns on ordinary evidence',
        () {
      final page = _recognized([
        sidewaysLine(500),
        sidewaysLine(560),
        sidewaysLine(620),
        sidewaysLine(680),
      ]);
      // A square-ish page stays a square-ish page either way round, so the
      // sideways verdict is no more suspicious than any other.
      expect(
        quarterTurnsToUprightText(page, pageWidth: 800, pageHeight: 820),
        1,
      );
    });

    test('an upside-down page keeps the ordinary bar', () {
      final page = _recognized([
        [Point(400, 120), Point(100, 120), Point(100, 100), Point(400, 100)],
        [Point(400, 220), Point(100, 220), Point(100, 200), Point(400, 200)],
        [Point(400, 320), Point(100, 320), Point(100, 300), Point(400, 300)],
      ]);
      // Two turns leave the page's shape alone, so three lines can carry it.
      expect(
        quarterTurnsToUprightText(page, pageWidth: 800, pageHeight: 1130),
        2,
      );
    });

    test('an unknown page size judges the way it always did', () {
      final page = _recognized([
        sidewaysLine(500),
        sidewaysLine(560),
        sidewaysLine(620),
        sidewaysLine(680),
      ]);
      expect(quarterTurnsToUprightText(page), 1);
    });

    test('a landscape page standing up needs the same strong agreement', () {
      final page = _recognized([
        for (int i = 0; i < 5; i++) sidewaysLine(500 + i * 60),
      ]);
      // Five unanimous lines: enough normally, not enough to rotate a page
      // whose shape would change.
      expect(
        quarterTurnsToUprightText(page, pageWidth: 1600, pageHeight: 900),
        isNull,
      );
      expect(
        quarterTurnsToUprightText(page, pageWidth: 1600, pageHeight: 900,
            minLines: 3),
        isNull,
      );
    });
  });
}

import 'dart:math' show Point;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'local_document_text_service.dart';

/// How many clockwise quarter turns turn the recognised text upright.
///
/// Derived from one recognition pass: ML Kit reports each line's corner points
/// in the image's own coordinate space, ordered by the line's *reading
/// direction* — corner 0 is where reading starts, corner 1 where the first
/// character run ends. The vector from corner 0 to corner 1 therefore points
/// the way the text is read, wherever on the page and whatever the page's
/// orientation, and the vector from corner 0 to corner 3 points down the line
/// stack. Rotating the page so those two vectors map onto (+x, +y) is the
/// upright orientation.
const double kOrientationAxisMargin = 2.0;

/// A line whose reading direction is not within about 26° of a text axis
/// (`|dx| ≥ 2|dy|` or the reverse) is ambiguous — a headline drawn at an art
/// angle, a watermark — and casts no vote.
const int kOrientationMinLines = 3;

/// Lines that agree on one turn, out of all lines that cast a vote.
///
/// Below this share the page's lines disagree — mixed-orientation layouts,
/// stamps over text — and guessing would rotate a page that was fine.
const double kOrientationAgreement = 0.85;

/// Text volume below which the geometry is not trusted.
///
/// A page that yielded a single short line has not earned a rotation: one
/// misread stamp could outweigh the whole layout.
const int kOrientationMinRunes = 20;

/// How far a page's long side has to exceed its short side before the two count
/// as different shapes.
const double kOrientationAspectMargin = 1.15;

/// Evidence a turn that *swaps* those two shapes needs before it is acted on.
///
/// Almost every document is portrait, so a quarter turn that lays a page on
/// its side is the rotation a user is most likely to have to undo — and a
/// layout that reads sideways without being sideways (a column of single
/// characters, a sideways stamp over otherwise upright lines, a table read
/// column-wise) can talk a majority into it. Upright pages and upside-down ones
/// keep the ordinary bar: those verdicts do not change the page's shape.
const int kOrientationTurnMinLines = 6;
const double kOrientationTurnAgreement = 0.95;

/// Whether the recognised lines say the page needs [turns] clockwise quarter
/// turns to be read upright, or null when the evidence is not conclusive.
///
/// Returns 0 when the page is confidently upright — callers treat "no
/// consensus" and "upright" the same way, but the distinction is kept so a
/// caller that wants to know *why* nothing moved can tell them apart.
///
/// [pageWidth] and [pageHeight], when both are known, describe the page as it
/// was rendered. They only ever raise the bar: a turn that would stand the page
/// on its side needs [kOrientationTurnMinLines] lines agreeing at
/// [kOrientationTurnAgreement] before it is believed.
int? quarterTurnsToUprightText(
  RecognizedText recognized, {
  int minLines = kOrientationMinLines,
  double agreement = kOrientationAgreement,
  int minRunes = kOrientationMinRunes,
  int? pageWidth,
  int? pageHeight,
}) {
  if (recognized.text.trim().runes.length < minRunes) return null;

  final votes = <int>[];
  for (final block in recognized.blocks) {
    for (final line in block.lines) {
      final points = line.cornerPoints;
      if (points.length != 4) continue;
      final vote = _lineVote(points);
      if (vote != null) votes.add(vote);
    }
  }
  if (votes.length < minLines) return null;

  final tally = List<int>.filled(4, 0);
  for (final vote in votes) {
    tally[vote] += 1;
  }
  var winner = 0;
  for (var turn = 1; turn < 4; turn++) {
    if (tally[turn] > tally[winner]) winner = turn;
  }
  final share = tally[winner] / votes.length;
  if (share < agreement) return null;

  if (winner % 2 == 1 && _swapsPageShape(pageWidth, pageHeight)) {
    if (votes.length < kOrientationTurnMinLines) return null;
    if (share < kOrientationTurnAgreement) return null;
  }
  return winner;
}

/// Whether standing the page on its side would visibly change its shape, which
/// is what makes a sideways verdict worth this much more evidence.
bool _swapsPageShape(int? width, int? height) {
  if (width == null || height == null || width <= 0 || height <= 0) {
    return false;
  }
  final long = width > height ? width : height;
  final short = width > height ? height : width;
  return long > short * kOrientationAspectMargin;
}

/// The turn this one line votes for, or null when its shape is ambiguous.
int? _lineVote(List<Point<int>> points) {
  final read = _dominantAxis(points[1] - points[0]);
  final down = _dominantAxis(points[3] - points[0]);
  if (read == null || down == null) return null;

  // Corner 0→1 runs the way the text reads; corner 0→3 runs down the line
  // stack. Both must agree on the same rotation, otherwise this line's shape
  // says nothing trustworthy (see [kOrientationAxisMargin]).
  final readTurn = _turnForReadAxis(read);
  final downTurn = _turnForDownAxis(down);
  if (readTurn == null || downTurn == null || readTurn != downTurn) {
    return null;
  }
  return readTurn;
}

/// The unit-ish direction collapsed onto its dominant axis, or null when the
/// vector sits too close to a diagonal to name an axis.
///
/// Coordinates use the image convention (y grows downward).
int? _dominantAxis(Point<int> vector) {
  final dx = vector.x.toDouble();
  final dy = vector.y.toDouble();
  if (dx.abs() < 1 && dy.abs() < 1) return null;
  if (dx.abs() >= kOrientationAxisMargin * dy.abs()) {
    return dx > 0 ? _axisRight : _axisLeft;
  }
  if (dy.abs() >= kOrientationAxisMargin * dx.abs()) {
    return dy > 0 ? _axisDown : _axisUp;
  }
  return null;
}

const int _axisRight = 0;
const int _axisLeft = 1;
const int _axisUp = 2;
const int _axisDown = 3;

/// Which clockwise quarter turn brings the reading axis onto +x.
int? _turnForReadAxis(int axis) => switch (axis) {
      // Already reading left-to-right: nothing to do.
      _axisRight => 0,
      // Reading right-to-left: the page is upside down.
      _axisLeft => 2,
      // Reading bottom-to-top: rotate the page a quarter clockwise.
      _axisUp => 1,
      // Reading top-to-bottom: rotate three quarters clockwise.
      _axisDown => 3,
      _ => null,
    };

/// Which clockwise quarter turn brings the line-stack axis onto +y.
int? _turnForDownAxis(int axis) => switch (axis) {
      _axisDown => 0,
      _axisUp => 2,
      _axisRight => 1,
      _axisLeft => 3,
      _ => null,
    };

/// Detects whether a scanned page is sideways or upside down, and by how many
/// quarter turns it should be rotated.
///
/// One recognition pass, staged the same way the text reader stages pages. The
/// verdict is deliberately conservative: a page with too little text, or lines
/// that disagree with each other, reports no rotation rather than a guess —
/// a page left tilted can still be turned by hand, and a page turned the wrong
/// way by the app has to be noticed first.
class ScanOrientationDetector {
  const ScanOrientationDetector({required LocalDocumentTextService textService})
    : _textService = textService;

  final LocalDocumentTextService _textService;

  /// Whether this build can detect orientation at all.
  bool get isSupported => _textService.isSupported;

  /// Clockwise quarter turns that would make the text on [pageBytes] upright,
  /// 0 when it already is, or null when the page's own text does not say.
  ///
  /// [pageWidth] and [pageHeight] are the rendered page's own size when the
  /// caller knows it — a quarter turn that would stand a portrait page on its
  /// side then has to clear a higher bar before it is believed.
  Future<int?> detectQuarterTurns(
    Uint8List pageBytes, {
    int? pageWidth,
    int? pageHeight,
  }) async {
    if (!isSupported || pageBytes.isEmpty) return null;
    final recognized = await _textService.readRecognized(pageBytes);
    if (recognized == null) return null;
    return quarterTurnsToUprightText(
      recognized,
      pageWidth: pageWidth,
      pageHeight: pageHeight,
    );
  }
}

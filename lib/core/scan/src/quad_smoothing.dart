import 'dart:math';

import 'models/point.dart';
import 'models/quad.dart';

/// Exponential smoothing for a live document outline.
///
/// The detector is run on a sequence of frames of a scene that is, in the
/// operator's hand, barely moving — but between-frame noise alone makes the
/// corner positions jump by a few pixels, which reads as a twitching rectangle
/// rather than a page being tracked. Averaging each corner against where it
/// was last frame removes that jitter without lagging behind a real movement:
/// a hand that actually moves drags the smoothed outline along with it within a
/// frame or two.
///
/// Kept separate from the detector so it can be tested on its own, and so the
/// one-shot (shutter-time) path never applies it: there is no previous frame
/// there, and smoothing a single final answer could only make it less accurate.

/// Weight of the newly detected corner. 1.0 means "no smoothing at all"; lower
/// values follow the new detection more slowly. 0.45 settles in two or three
/// frames while still killing the visible per-frame jitter.
const double kOutlineSmoothing = 0.45;

/// A corner that moved further than this fraction of the frame's diagonal from
/// its counterpart is treated as a genuinely new position — a re-detected
/// edge, a fresh page coming into view — and is taken as-is instead of being
/// dragged back toward the old outline. Without this, the smoothing would hold
/// the rectangle in place while the document slides across the screen.
const double kOutlineMaxJump = 0.28;

/// Blends a freshly detected outline into the previous one.
///
/// Corners are matched greedily by nearest distance rather than by position in
/// the list: the detector is free to start its quad from a different corner on
/// a different frame, and pairing corner 0 with corner 0 when the winding
/// flipped would average across the diagonal of the page.
///
/// Returns a new [Quad] in the space of [smoothed] (the coordinates of the
/// frame the detection came from).
Quad smoothQuad(Quad previous, Quad next, {double alpha = kOutlineSmoothing}) {
  final prev = previous.points;
  final fresh = next.points;

  // Diagonal, used only to decide what counts as "too far to be the same
  // corner". Same units as the corner coordinates themselves.
  final diagonal = sqrt(_squaredSpan(fresh));
  final maxJump = diagonal * kOutlineMaxJump;

  final matched = List<int?>.filled(fresh.length, null);
  final corners = <Pt>[];

  for (final candidate in prev.asMap().entries) {
    var bestIndex = -1;
    var bestDistance = double.infinity;
    for (var i = 0; i < fresh.length; i++) {
      if (matched[i] != null) continue;
      final d = _distance(candidate.value, fresh[i]);
      if (d < bestDistance) {
        bestDistance = d;
        bestIndex = i;
      }
    }
    if (bestIndex < 0) {
      corners.add(candidate.value);
      continue;
    }
    matched[bestIndex] = candidate.key;
    corners.add(
      bestDistance <= maxJump
          ? _blend(candidate.value, fresh[bestIndex], alpha)
          : fresh[bestIndex],
    );
  }
  // Any corner of the new quad that nothing in the old outline claimed.
  for (var i = 0; i < fresh.length; i++) {
    if (matched[i] == null) corners.add(fresh[i]);
  }

  return Quad(
    topLeft: corners[0],
    topRight: corners[1],
    bottomRight: corners[2],
    bottomLeft: corners[3],
  );
}

double _squaredSpan(List<Pt> points) {
  var minX = double.infinity;
  var maxX = -double.infinity;
  var minY = double.infinity;
  var maxY = -double.infinity;
  for (final p in points) {
    if (p.x < minX) minX = p.x;
    if (p.x > maxX) maxX = p.x;
    if (p.y < minY) minY = p.y;
    if (p.y > maxY) maxY = p.y;
  }
  final dx = maxX - minX;
  final dy = maxY - minY;
  return dx * dx + dy * dy;
}

double _distance(Pt a, Pt b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return sqrt(dx * dx + dy * dy);
}

Pt _blend(Pt previous, Pt next, double alpha) {
  return Pt(
    previous.x * (1 - alpha) + next.x * alpha,
    previous.y * (1 - alpha) + next.y * alpha,
  );
}

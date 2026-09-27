// Vendored from OpenScan v3.0.0 — https://github.com/ethereal-developers/OpenScan
// BSD 3-Clause License, Copyright (c) 2021, Vijay T S and Vikram H.
// See `third_party/openscan_cv/` for the full license text and the list of
// local adaptations.

import 'point.dart';

/// A quadrilateral with corners in a single canonical order everywhere in the
/// pipeline: clockwise starting at the top-left. This is the only
/// representation of a detected/edited document boundary that crosses any
/// layer boundary (detector -> crop UI -> perspective warp).
class Quad {
  const Quad({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
  });

  final Pt topLeft;
  final Pt topRight;
  final Pt bottomRight;
  final Pt bottomLeft;

  Quad scaled(double sx, double sy) => Quad(
    topLeft: topLeft.scaled(sx, sy),
    topRight: topRight.scaled(sx, sy),
    bottomRight: bottomRight.scaled(sx, sy),
    bottomLeft: bottomLeft.scaled(sx, sy),
  );

  List<Pt> get points => [topLeft, topRight, bottomRight, bottomLeft];

  @override
  String toString() =>
      'Quad(tl: $topLeft, tr: $topRight, br: $bottomRight, bl: $bottomLeft)';
}

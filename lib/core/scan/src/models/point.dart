// Vendored from OpenScan v3.0.0 — https://github.com/ethereal-developers/OpenScan
// BSD 3-Clause License, Copyright (c) 2021, Vijay T S and Vikram H.
// See `third_party/openscan_cv/` for the full license text and the list of
// local adaptations.

/// A simple 2D point used by the pure-Dart scan pipeline. Kept independent of
/// `dart:ui`'s [Offset] so this code can run in a plain (non-Flutter) isolate.
class Pt {
  const Pt(this.x, this.y);

  final double x;
  final double y;

  Pt scaled(double sx, double sy) => Pt(x * sx, y * sy);

  @override
  String toString() => 'Pt($x, $y)';
}

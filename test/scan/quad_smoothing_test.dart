import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/scan/src/models/point.dart';
import 'package:memos_flutter_app/core/scan/src/models/quad.dart';
import 'package:memos_flutter_app/core/scan/src/quad_smoothing.dart';

Quad _quadAt(double x, double y, {double s = 0}) => Quad(
  topLeft: Pt(x - s, y - s),
  topRight: Pt(x + s, y - s),
  bottomRight: Pt(x + s, y + s),
  bottomLeft: Pt(x - s, y + s),
);

void main() {
  group('smoothQuad', () {
    test('pulls a jittering corner towards where it was', () {
      // A hand that is not moving: the detector disagrees with itself by a
      // couple of pixels every frame.
      final steady = _quadAt(100, 100, s: 50);
      const jitter = 6.0;

      var quad = steady;
      for (var frame = 0; frame < 6; frame++) {
        quad = smoothQuad(
          quad,
          _quadAt(100 + jitter, 100 + jitter, s: 50),
        );
      }

      // The smoothing should have pulled the boundary most of the way back,
      // while still having seen the (real) jitter. Measured on the centre,
      // since a corner carries the corner offset on top of that.
      final centerX = (quad.topLeft.x + quad.topRight.x) / 2;
      expect(centerX, lessThan(100 + jitter));
      expect(centerX, greaterThan(100));
    });

    test('follows a hand that really is moving', () {
      // Blending against a stale outline forever would trail behind a page
      // being slid across the frame.
      var quad = _quadAt(100, 100, s: 50);
      for (var frame = 1; frame <= 8; frame++) {
        quad = smoothQuad(quad, _quadAt(100 + frame * 20, 100, s: 50));
      }

      // After eight frames of moving 20px each it should be essentially there.
      expect(quad.topLeft.x, greaterThan(180));
    });

    test('takes a corner that jumped too far as a genuinely new position', () {
      // The page is lifted off the desk and placed elsewhere. Averaging
      // towards the old outline would drag it back through empty space.
      final previous = _quadAt(100, 100, s: 50);
      final moved = _quadAt(400, 400, s: 50);

      final smoothed = smoothQuad(previous, moved);

      expect(smoothed.topLeft.x, moved.topLeft.x);
      expect(smoothed.topLeft.y, moved.topLeft.y);
    });

    test('matches corners by proximity rather than by list position', () {
      // A winding flip: the detector started its quad at the opposite corner.
      // Pairing corner 0 with corner 0 across a flip would average across the
      // page's diagonal and produce something that is not a page at all.
      final previous = _quadAt(200, 200, s: 60);
      final flipped = Quad(
        topLeft: previous.bottomLeft,
        topRight: previous.bottomRight,
        bottomRight: previous.topRight,
        bottomLeft: previous.topLeft,
      );

      final smoothed = smoothQuad(previous, flipped);
      final corners = smoothed.points;

      // Every corner stayed close to where it already was, which only happens
      // if the pairing followed the geometry and not the index.
      final previousCorners = previous.points;
      for (final corner in corners) {
        final nearest = previousCorners.fold<double>(
          double.infinity,
          (best, other) {
            final dx = other.x - corner.x;
            final dy = other.y - corner.y;
            final d = dx * dx + dy * dy;
            return d < best ? d : best;
          },
        );
        expect(nearest, lessThan(1500));
      }
    });

    test('keeps the corner order the rest of the pipeline expects', () {
      final smoothed = smoothQuad(
        _quadAt(200, 200, s: 60),
        _quadAt(205, 204, s: 58),
      );

      expect(smoothed.topLeft.x, lessThan(smoothed.topRight.x));
      expect(smoothed.topRight.y, lessThan(smoothed.bottomRight.y));
      expect(smoothed.bottomRight.x, greaterThan(smoothed.bottomLeft.x));
      expect(smoothed.bottomLeft.y, greaterThan(smoothed.topLeft.y));
    });
  });
}

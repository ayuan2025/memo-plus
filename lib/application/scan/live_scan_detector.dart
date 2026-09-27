import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../core/scan/document_scan.dart';

/// Longest edge, in pixels, a viewfinder frame is searched for a page at.
///
/// A live frame has to be answered while the user is still aiming, and the edge
/// pipeline is pure Dart, so live frames are worked far smaller than a still
/// capture: at this size a full blur -> sobel -> multi-threshold -> contour pass
/// stays inside a phone's frame budget, and it is still several times more
/// resolution than a page boundary needs. A still capture is searched at
/// [kDetectionMaxDimension] instead, on its own isolate, once.
const int kLiveScanFrameMaxDimension = 420;

/// Weight each colour channel carries in a luminance estimate.
const double _kRedWeight = 0.299;
const double _kGreenWeight = 0.587;
const double _kBlueWeight = 0.114;

/// One viewfinder frame, reduced to the grey image the detector works on.
@immutable
class LiveScanFrame {
  const LiveScanFrame({
    required this.gray,
    required this.width,
    required this.height,
    this.previousQuad,
  });

  /// Luminance, one byte per pixel, row-major and tightly packed.
  final Uint8List gray;

  final int width;
  final int height;

  /// The boundary found in the previous frame, in *this* frame's pixel
  /// coordinates, or null when the last frame held no page.
  ///
  /// Handed to [detectQuadFromGrayscale] so it prefers whichever candidate sits
  /// closest to where the outline already is. Without it the outline flickers
  /// between competing edges as the hand shakes and the Otsu threshold shifts.
  final Quad? previousQuad;
}

/// Luminance plane of a YUV camera frame, narrowed to [maxDimension].
///
/// Android delivers `imageStream` frames as YUV420, whose first plane already
/// *is* the grey image the edge pipeline wants — no colour conversion is
/// involved. Two things still have to be undone: `bytesPerRow` can exceed
/// `width` (the platform pads rows out to an alignment), and the plane's buffer
/// is reused by the camera between frames, so the pixels have to be copied out
/// rather than handed on as a view.
///
/// Returns null when the plane does not match the dimensions it claims, which
/// is how a caller finds out that this frame is not worth searching.
({Uint8List gray, int width, int height})? grayFromLumaPlane(
  Uint8List plane, {
  required int width,
  required int height,
  required int bytesPerRow,
  int maxDimension = kLiveScanFrameMaxDimension,
}) {
  if (width <= 0 || height <= 0 || bytesPerRow < width) return null;
  if (plane.length < bytesPerRow * (height - 1) + width) return null;

  final target = _workSize(width, height, maxDimension);
  final out = Uint8List(target.width * target.height);

  if (target.width == width && target.height == height) {
    for (int y = 0; y < height; y++) {
      out.setRange(y * width, (y + 1) * width, plane, y * bytesPerRow);
    }
    return (gray: out, width: width, height: height);
  }

  for (int y = 0; y < target.height; y++) {
    final sourceRow = (y * height ~/ target.height) * bytesPerRow;
    final outRow = y * target.width;
    for (int x = 0; x < target.width; x++) {
      out[outRow + x] = plane[sourceRow + (x * width ~/ target.width)];
    }
  }
  return (gray: out, width: target.width, height: target.height);
}

/// Luminance sampled out of a BGRA camera frame, narrowed to [maxDimension].
///
/// iOS has no luminance plane to borrow — `imageStream` hands over 32-bit
/// BGRA — so the grey value is computed from the colour channels here. Same row
/// padding and buffer-reuse caveats as [grayFromLumaPlane].
({Uint8List gray, int width, int height})? grayFromBgraPlane(
  Uint8List plane, {
  required int width,
  required int height,
  required int bytesPerRow,
  int maxDimension = kLiveScanFrameMaxDimension,
}) {
  if (width <= 0 || height <= 0 || bytesPerRow < width * 4) return null;
  if (plane.length < bytesPerRow * (height - 1) + width * 4) return null;

  final target = _workSize(width, height, maxDimension);
  final out = Uint8List(target.width * target.height);

  for (int y = 0; y < target.height; y++) {
    final sourceRow = (y * height ~/ target.height) * bytesPerRow;
    final outRow = y * target.width;
    for (int x = 0; x < target.width; x++) {
      final i = sourceRow + (x * width ~/ target.width) * 4;
      out[outRow + x] =
          (plane[i] * _kBlueWeight +
                  plane[i + 1] * _kGreenWeight +
                  plane[i + 2] * _kRedWeight)
              .round()
              .clamp(0, 255);
    }
  }
  return (gray: out, width: target.width, height: target.height);
}

/// Searches [frame] for a page boundary, on a worker isolate.
///
/// The pipeline allocates several full-size buffers per pass; running it on the
/// UI isolate would drop viewfinder frames every time it ran.
Future<Quad?> findPageInLiveFrame(LiveScanFrame frame) =>
    compute(_findPageInLiveFrame, frame);

Quad? _findPageInLiveFrame(LiveScanFrame frame) {
  try {
    return detectQuadFromGrayscale(
      frame.gray,
      frame.width,
      frame.height,
      previousQuad: frame.previousQuad,
    );
  } catch (_) {
    // A frame that cannot be searched is simply a frame with no page in it.
    return null;
  }
}

/// [quad], given in pixels of a [width] x [height] frame, as fractions of it.
Quad normalizedFrameQuad(Quad quad, int width, int height) {
  if (width <= 0 || height <= 0) return quad;
  return quad.scaled(1 / width, 1 / height);
}

/// Maps a point in normalized frame coordinates onto the upright preview the
/// user is looking at.
///
/// The camera reports frames in *sensor* orientation — landscape on a phone
/// held upright — while the viewfinder shows them turned back the right way, so
/// a point has to be carried through that same quarter turn. Without this the
/// outline would be drawn on its side, a quarter turn off the paper.
///
/// [sensorOrientation] is the clockwise angle the sensor's output needs in
/// order to look upright, which is what `CameraDescription.sensorOrientation`
/// reports.
Pt framePointToPreview(Pt point, int sensorOrientation) {
  return switch (sensorOrientation % 360) {
    // A quarter turn clockwise: the old bottom-left corner becomes the top
    // left, so x comes from the old y and the old x is mirrored into y.
    90 => Pt(1 - point.y, point.x),
    180 => Pt(1 - point.x, 1 - point.y),
    270 => Pt(point.y, 1 - point.x),
    _ => point,
  };
}

/// [quad] with every corner carried through [framePointToPreview].
///
/// The corners are re-sorted afterwards: a rotation moves them out of the
/// top-left-clockwise order [Quad] is defined to hold, and the crop pipeline
/// reads that order as meaning.
Quad frameQuadToPreview(Quad quad, int sensorOrientation) {
  if (sensorOrientation % 360 == 0) return quad;
  return sortCorners(
    quad.points.map((p) => framePointToPreview(p, sensorOrientation)).toList(),
  );
}

/// Size [width] x [height] is narrowed to, preserving its aspect ratio.
({int width, int height}) _workSize(int width, int height, int maxDimension) {
  final longest = max(width, height);
  if (maxDimension <= 0 || longest <= maxDimension) {
    return (width: width, height: height);
  }
  final scale = maxDimension / longest;
  return (
    width: max(1, (width * scale).round()),
    height: max(1, (height * scale).round()),
  );
}

import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Turns [bytes] [degrees] clockwise and re-encodes them as JPEG, or returns
/// null when the bytes are not an image this decoder can read.
///
/// Takes its arguments as one record so it can be handed straight to
/// [compute]: a photo is decoded, turned and encoded in one go, which on a
/// multi-megapixel scan takes long enough on the UI isolate to freeze the
/// frame the user is looking at.
Uint8List? rotateImageQuarterTurn((Uint8List, int) request) {
  final (bytes, degrees) = request;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  final rotated = img.copyRotate(decoded, angle: degrees);
  return Uint8List.fromList(img.encodeJpg(rotated, quality: 92));
}

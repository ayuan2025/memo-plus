import 'package:flutter/foundation.dart';

import '../../core/scan/src/ocr_preprocess.dart';

/// Runs [preprocessPageForOcr] off the UI isolate.
///
/// The preprocessing walks every pixel of a ~2000px page several times — the
/// illumination divide, the histogram, the level stretch — which is far too
/// long to spend on the isolate that has to keep the review screen scrolling.
/// Every call goes through [compute] for exactly that reason; there is no
/// synchronous path, because there is no legitimate reason to call this on the
/// UI isolate.
class OcrPagePreprocessor {
  const OcrPagePreprocessor();

  /// The page to hand the recogniser, or [encoded] unchanged if preprocessing
  /// could not run.
  ///
  /// Falling through to the untouched bytes is deliberate: an unflattened page
  /// still gets recognised, just less reliably, whereas a dropped page loses
  /// the scan the user just took.
  Future<Uint8List> prepare(
    Uint8List encoded, {
    OcrPreprocessLevel level = OcrPreprocessLevel.balanced,
  }) async {
    if (encoded.isEmpty) return encoded;
    try {
      // A record would read better here, but the isolate message has to cross
      // as plain primitives.
      return await compute(
        _preprocessInBackground,
        <Object>[encoded, level.index],
      );
    } catch (_) {
      return encoded;
    }
  }
}

Uint8List _preprocessInBackground(List<Object> arguments) {
  return preprocessPageForOcr(
    arguments[0] as Uint8List,
    level: OcrPreprocessLevel.values[arguments[1] as int],
  );
}

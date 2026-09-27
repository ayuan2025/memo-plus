import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../logs/log_manager.dart';

/// Reads the text off a scanned page without the page leaving the device.
///
/// ML Kit's recogniser is a bundled, on-device model: it needs no account, no
/// network and no Google Play services, which is the point of having it here —
/// a scan of a contract should not have to be uploaded anywhere for the memo to
/// get a title.
///
/// Only Android and iOS carry the native side of the plugin. Everywhere else
/// [isSupported] is false and [readText] returns null, which callers must read
/// as "no local reading available" rather than as a failure worth reporting.
class LocalDocumentTextService {
  const LocalDocumentTextService();

  /// Whether this build has a recogniser at all.
  bool get isSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// The text recognised on the page in [imageBytes], or null if none could be.
  ///
  /// [imageBytes] is handed the *rendered* page rather than the raw capture: it
  /// is already cropped to the paper and capped in size, which is both a better
  /// input and a smaller one to decode.
  Future<String?> readText(Uint8List imageBytes) async {
    if (!isSupported || imageBytes.isEmpty) return null;

    // The Android side of the plugin takes a path rather than bytes, and
    // staging the page is cheaper than decoding it once more just to build the
    // metadata object the bytes constructor would demand.
    Directory? staging;
    TextRecognizer? recognizer;
    try {
      staging = await Directory.systemTemp.createTemp('memoflow_scan_');
      final page = File('${staging.path}/page.png');
      await page.writeAsBytes(imageBytes, flush: true);

      recognizer = TextRecognizer(script: TextRecognitionScript.chinese);
      final recognized = await recognizer.processImage(
        InputImage.fromFilePath(page.path),
      );
      return recognized.text;
    } catch (error, stackTrace) {
      // A malformed page, a device without the model, an out-of-memory decode —
      // all of them mean the same thing to the user, and none of them should
      // cost them the scan they just took.
      LogManager.instance.warn(
        'LocalDocumentTextService: read_failed',
        error: error,
        stackTrace: stackTrace,
        context: {'bytes': imageBytes.length},
      );
      return null;
    } finally {
      try {
        await recognizer?.close();
      } catch (_) {
        // Closing a recogniser that never started is not worth reporting.
      }
      try {
        await staging?.delete(recursive: true);
      } catch (_) {
        // A leftover temp directory is not worth failing a scan over.
      }
    }
  }
}

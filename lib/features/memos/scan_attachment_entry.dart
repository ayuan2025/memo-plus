import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../scan/scan_camera_screen.dart';
import '../scan/scan_capture_flow.dart';
import 'gallery_attachment_picker.dart';

/// A scanned page, already in the shape the composer's attachment intake wants.
class ScannedMemoAttachment {
  const ScannedMemoAttachment({
    required this.attachment,
    this.title = '',
    this.tags = const <String>[],
    this.body = '',
  });

  final PickedLocalAttachment attachment;
  final String title;
  final List<String> tags;

  /// The full recognised text of the page, or empty when none was read.
  final String body;
}

/// Runs the scan flow and returns something the composer can stage.
///
/// Where the photo comes from depends on the platform. On a phone the scanner
/// opens its own camera, because outlining the page while the user aims needs
/// the viewfinder frames and the system camera app will never hand those over.
/// Everywhere else — and whenever the caller injects its own photo source — the
/// shot comes from [captureCameraAttachment], which knows about the Windows
/// camera screen. The result then enters the ordinary attachment intake, exactly
/// as a gallery pick would, which is what keeps the upload size policy and
/// readiness contract intact.
Future<ScannedMemoAttachment?> scanDocumentForComposer({
  required BuildContext context,
  required NavigatorState navigator,
  required ImagePicker imagePicker,
  Future<XFile?> Function()? capturePhotoOverride,
}) async {
  final document = await captureAndReviewDocument(
    context: context,
    capturePhoto: () async {
      if (capturePhotoOverride != null) {
        final picked = await capturePhotoOverride();
        return picked?.path;
      }
      // On a phone the scanner can outline the page while aiming, so the user
      // chooses between the live-edge camera and picking an existing photo.
      if (ScanCameraScreen.canTrackLivePage) {
        final source = await _pickScanSource(context);
        if (source == null) return null;
        if (source == 'gallery') {
          final picked = await imagePicker.pickImage(
            source: ImageSource.gallery,
          );
          return picked?.path;
        }
        return ScanCameraScreen.capture(context);
      }
      final picked = await captureCameraAttachment(
        navigator: navigator,
        imagePicker: imagePicker,
      );
      return picked?.filePath;
    },
  );
  if (document == null) return null;

  final file = File(document.filePath);
  if (!file.existsSync()) return null;

  return ScannedMemoAttachment(
    attachment: PickedLocalAttachment(
      filePath: document.filePath,
      filename: document.filename,
      mimeType: guessLocalAttachmentMimeType(document.filename),
      size: file.lengthSync(),
      source: PickedLocalAttachmentSource.camera,
      // The page renderer has already capped the long edge and applied its own
      // JPEG quality, so running the generic compression pass over it again
      // would only re-encode it for no gain.
      skipCompression: true,
    ),
    title: document.title,
    tags: document.tags,
    body: document.body,
  );
}

/// Asks the user whether to take a fresh photo or pick an existing one, before
/// the scan flow opens a camera or gallery surface.
///
/// Returns `'camera'`, `'gallery'`, or null when the sheet is dismissed.
Future<String?> _pickScanSource(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('拍照'),
            onTap: () => Navigator.of(sheetContext).pop('camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('从相册选择'),
            onTap: () => Navigator.of(sheetContext).pop('gallery'),
          ),
        ],
      ),
    ),
  );
}

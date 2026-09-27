import 'package:flutter/material.dart';

import '../../platform/platform_route.dart';
import 'image_preview_open_request.dart';
import 'widgets/image_preview_gallery_screen.dart';

class ImagePreviewLauncher {
  const ImagePreviewLauncher._();

  static Future<void> open(
    BuildContext context,
    ImagePreviewOpenRequest request,
  ) async {
    if (request.items.isEmpty) {
      return;
    }
    await Navigator.of(context, rootNavigator: true).push(
      buildPlatformPageRoute<void>(
        context: context,
        builder: (_) => ImagePreviewGalleryScreen(request: request),
      ),
    );
  }
}

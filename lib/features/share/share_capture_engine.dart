import 'package:flutter/foundation.dart';

import 'share_clip_models.dart';

abstract class ShareCaptureEngine {
  Future<ShareCaptureResult> capture(
    ShareCaptureRequest request, {
    ValueChanged<ShareCaptureStage>? onStageChanged,
  });
}

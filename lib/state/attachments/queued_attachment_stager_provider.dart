import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/attachments/queued_attachment_stager.dart';

final queuedAttachmentStagerProvider = Provider<QueuedAttachmentStager>((ref) {
  return QueuedAttachmentStager();
});

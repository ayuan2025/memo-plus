export '../../core/share_inline_image_content.dart';

import '../../core/share_inline_image_content.dart';
import 'share_clip_models.dart';

String buildShareInlineSyncContent(
  String content,
  Iterable<ShareAttachmentSeed> attachments,
) {
  var next = content;
  for (final attachment in attachments) {
    if (!attachment.shareInlineImage) continue;
    final localUrl = shareInlineLocalUrlFromPath(attachment.filePath);
    if (localUrl.isEmpty) continue;
    final placeholder = buildShareInlineImagePlaceholder(attachment.uid);
    next = replaceShareInlineImageReferenceWithPlaceholder(
      next,
      localUrl: localUrl,
      placeholder: placeholder,
    );
  }
  return next;
}

import '../../data/models/attachment.dart';
import '../../data/models/local_memo.dart';

String memoMediaAttachmentSourceFingerprint(Iterable<Attachment> attachments) {
  final buffer = StringBuffer();
  var count = 0;
  for (final attachment in attachments) {
    count += 1;
    _writeCacheField(buffer, attachment.name);
    _writeCacheField(buffer, attachment.filename);
    _writeCacheField(buffer, attachment.type);
    _writeCacheField(buffer, attachment.size);
    _writeCacheField(buffer, attachment.externalLink);
    _writeCacheField(buffer, attachment.width);
    _writeCacheField(buffer, attachment.height);
    _writeCacheField(buffer, attachment.hash);
  }
  return '$count|$buffer';
}

String memoMediaEntriesCacheKey({
  required LocalMemo memo,
  required Uri? baseUrl,
  required String? authHeader,
  required bool rebaseAbsoluteFileUrlForV024,
  required bool attachAuthForSameOriginAbsolute,
}) {
  final authFingerprint = authHeader == null || authHeader.trim().isEmpty
      ? 0
      : authHeader.trim().hashCode;
  return '${memo.uid}|'
      '${memo.contentFingerprint}|'
      '${memo.updateTime.toUtc().millisecondsSinceEpoch}|'
      '${memoMediaAttachmentSourceFingerprint(memo.attachments)}|'
      '${baseUrl?.toString() ?? ''}|'
      '$authFingerprint|'
      '${rebaseAbsoluteFileUrlForV024 ? 1 : 0}|'
      '${attachAuthForSameOriginAbsolute ? 1 : 0}';
}

void _writeCacheField(StringBuffer buffer, Object? value) {
  final text = value?.toString() ?? '';
  buffer
    ..write(text.length)
    ..write(':')
    ..write(text)
    ..write('|');
}

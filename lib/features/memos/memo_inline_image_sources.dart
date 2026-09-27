import 'dart:io';

import 'package:path/path.dart' as p;

import '../../data/models/attachment.dart';
import 'memo_image_src_normalizer.dart';
import 'memo_inline_image_syntax.dart';

class MemoInlineImageSourcePolicy {
  MemoInlineImageSourcePolicy({
    required Iterable<String> allowedLocalImageUrls,
    required this.fingerprint,
  }) : allowedLocalImageUrls = Set.unmodifiable(
         allowedLocalImageUrls
             .map((url) => url.trim())
             .where((url) => url.isNotEmpty),
       );

  static final empty = MemoInlineImageSourcePolicy(
    allowedLocalImageUrls: const <String>{},
    fingerprint: _fingerprintUrls(const <String>[]),
  );

  final Set<String> allowedLocalImageUrls;
  final String fingerprint;

  bool get hasAllowedSources => allowedLocalImageUrls.isNotEmpty;
}

MemoInlineImageSourcePolicy buildMemoInlineImageSourcePolicy({
  required String content,
  required Iterable<Attachment> attachments,
  MemoInlineImageSyntax imageSyntax = MemoInlineImageSyntax.markdownAndHtml,
}) {
  if (content.trim().isEmpty) return MemoInlineImageSourcePolicy.empty;

  final attachmentPaths = <String>{};
  for (final attachment in attachments) {
    final type = attachment.type.trim().toLowerCase();
    if (!type.startsWith('image')) continue;
    final source = _parseCanonicalFileUrl(attachment.externalLink);
    if (source == null) continue;
    attachmentPaths.add(source.normalizedPath);
  }
  if (attachmentPaths.isEmpty) return MemoInlineImageSourcePolicy.empty;

  final allowed = <String>{};
  for (final rawUrl in extractMemoImageUrlsForSyntax(content, imageSyntax)) {
    final source = _parseCanonicalFileUrl(rawUrl);
    if (source == null) continue;
    if (!attachmentPaths.contains(source.normalizedPath)) continue;
    allowed
      ..add(source.originalUrl)
      ..add(source.canonicalUrl);
  }

  if (allowed.isEmpty) return MemoInlineImageSourcePolicy.empty;
  return MemoInlineImageSourcePolicy(
    allowedLocalImageUrls: allowed,
    fingerprint: _fingerprintUrls(allowed),
  );
}

_LocalFileSource? _parseCanonicalFileUrl(String rawUrl) {
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.scheme.toLowerCase() != 'file') return null;
  if (uri.host.trim().isNotEmpty) return null;

  String filePath;
  try {
    filePath = uri.toFilePath();
  } catch (_) {
    return null;
  }
  if (filePath.trim().isEmpty) return null;

  final normalizedPath = _normalizeLocalPath(filePath);
  if (normalizedPath.isEmpty) return null;
  return _LocalFileSource(
    originalUrl: trimmed,
    canonicalUrl: Uri.file(filePath).toString(),
    normalizedPath: normalizedPath,
  );
}

String _normalizeLocalPath(String filePath) {
  final normalized = p.normalize(filePath.trim());
  if (normalized.isEmpty) return '';
  return Platform.isWindows ? normalized.toLowerCase() : normalized;
}

String _fingerprintUrls(Iterable<String> urls) {
  final sorted =
      urls
          .map((url) => url.trim())
          .where((url) => url.isNotEmpty)
          .toSet()
          .toList(growable: false)
        ..sort();
  final buffer = StringBuffer()..write(sorted.length);
  for (final url in sorted) {
    buffer
      ..write('|')
      ..write(url.length)
      ..write(':')
      ..write(url);
  }
  return buffer.toString();
}

class _LocalFileSource {
  const _LocalFileSource({
    required this.originalUrl,
    required this.canonicalUrl,
    required this.normalizedPath,
  });

  final String originalUrl;
  final String canonicalUrl;
  final String normalizedPath;
}

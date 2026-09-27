import 'dart:convert';

String replaceInlineImageUrlVariants(
  String content, {
  required String fromUrl,
  required String toUrl,
}) {
  if (fromUrl.trim().isEmpty || toUrl.trim().isEmpty) {
    return content;
  }
  var next = content;
  final rawFromUrl = fromUrl.trim();
  final rawToUrl = toUrl.trim();
  final escapedToUrl = escapeHtmlAttribute(rawToUrl);
  for (final variant in inlineImageUrlVariants(rawFromUrl)) {
    next = next.replaceAll(
      variant,
      variant == rawFromUrl ? rawToUrl : escapedToUrl,
    );
  }
  return next;
}

bool contentContainsInlineImageUrlVariant(String content, String url) {
  final trimmedUrl = url.trim();
  if (trimmedUrl.isEmpty) return false;
  for (final variant in inlineImageUrlVariants(trimmedUrl)) {
    if (content.contains(variant)) {
      return true;
    }
  }
  return false;
}

Iterable<String> inlineImageUrlVariants(String url) sync* {
  final variants = <String>{};
  final trimmed = url.trim();
  if (trimmed.isEmpty) return;
  variants.add(trimmed);
  variants.add(escapeHtmlAttribute(trimmed));
  for (final variant in variants) {
    if (variant.isNotEmpty) {
      yield variant;
    }
  }
}

String escapeHtmlAttribute(String value) {
  return const HtmlEscape(HtmlEscapeMode.attribute).convert(value);
}

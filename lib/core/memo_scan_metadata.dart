// Pure helpers that turn a model's answer about a scanned page into memo text.
//
// A model reading a photo is an unreliable narrator: it will wrap JSON in
// Markdown fences, answer the question in prose, return a paragraph where a
// title was asked for, or hand back tags containing spaces and `#` marks that
// would silently break Memos' tag parser. Everything in here exists to make the
// result of that conversation safe to paste into a memo, and to fail to
// `null` rather than throw when the answer is unusable.
//
// Deliberately Flutter-free so it is unit-testable without a widget tree.

import 'dart:convert';

/// Caps applied to whatever the model returns.
const int kScanMetadataMaxTitleChars = 40;
const int kScanMetadataMaxTags = 5;
const int kScanMetadataMaxTagChars = 24;

/// What a scan is proposed to be called, and how it is filed.
class ScanMetadataDraft {
  const ScanMetadataDraft({
    required this.title,
    required this.tags,
    this.text = '',
  });

  /// Empty when the model gave nothing usable for a title.
  final String title;

  /// Already sanitised and capped. Empty when nothing usable came back.
  final List<String> tags;

  /// The full recognised text of the page, or empty when none was read.
  ///
  /// Carries the whole OCR result so a caller can keep it as the memo's body
  /// while the title/tags act as the headline. It is deliberately excluded
  /// from [isEmpty]: a page with text but no headline should not by itself
  /// count as "nothing to offer".
  final String text;

  bool get isEmpty => title.isEmpty && tags.isEmpty;
}

/// Reads a title and tag list out of a model's raw reply.
///
/// Returns null when no usable JSON object could be recovered — a caller should
/// treat that as "this scan just has no suggested metadata", never as an error
/// worth interrupting the user over.
ScanMetadataDraft? parseScanMetadataResponse(String raw) {
  final decoded = _decodeFirstJsonObject(raw);
  if (decoded == null) return null;

  final title = sanitizeScanTitle(decoded['title']);
  final tags = sanitizeScanTags(decoded['tags']);
  if (title.isEmpty && tags.isEmpty) return null;
  return ScanMetadataDraft(title: title, tags: tags);
}

/// Finds the first JSON object in [raw] and decodes it.
///
/// Models routinely bracket their answer with prose or ```json fences, and the
/// cheapest robust reading is to take the outermost brace pair and parse that,
/// rather than to trust the whole reply to be JSON.
Map<String, Object?>? _decodeFirstJsonObject(String raw) {
  final start = raw.indexOf('{');
  final end = raw.lastIndexOf('}');
  if (start < 0 || end <= start) return null;
  final Object? decoded;
  try {
    decoded = jsonDecode(raw.substring(start, end + 1));
  } on FormatException {
    return null;
  }
  if (decoded is! Map) return null;
  return decoded.cast<String, Object?>();
}

/// A single line suitable for the first line of a memo, or `''`.
///
/// Memos has no title field, so a title is just the first line of the content,
/// emitted downstream as a Markdown `#` heading by [applyScanMetadataToContent].
/// Any Markdown decoration the model volunteers around the title — leading
/// `#`, `>`, `-`, `*`, backticks or quotes — is stripped here so the caller can
/// add one canonical `# ` prefix instead of risking `##` or a mismatched level.
String sanitizeScanTitle(Object? value) {
  if (value == null) return '';

  final raw = value is String
      ? value
      : value is num || value is bool
      ? value.toString()
      : '';
  if (raw.isEmpty) return '';

  var text = raw
      // Any run of whitespace becomes one space, so a multi-line answer cannot
      // push content onto a second line.
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      // Strip the wrappers a model may add around the title itself.
      .replaceAll(RegExp(r'^[#>\-*\s`"\x27]+'), '')
      .replaceAll(RegExp(r'[#`"\x27]+$'), '')
      .trim();

  // A title that was nothing but decoration has nothing left to say.
  if (text.isEmpty) return '';
  return _truncate(text, kScanMetadataMaxTitleChars);
}

/// Safe `#tag` payloads, deduplicated and capped.
///
/// Accepts a JSON array, or a plain string that the model comma- or
/// whitespace-separated instead — both shapes show up in practice.
List<String> sanitizeScanTags(Object? value) {
  final Iterable<Object?> rawItems;
  if (value is Iterable) {
    rawItems = value;
  } else if (value is String) {
    rawItems = value.split(RegExp(r'[,\s、，]+'));
  } else {
    return const <String>[];
  }

  final seen = <String>{};
  final tags = <String>[];
  for (final item in rawItems) {
    final tag = sanitizeScanTag(item);
    if (tag.isEmpty) continue;
    // Memos tags are case-sensitive as written but comparing case-insensitively
    // stops `#Receipt` and `#receipt` being minted as two tags for one scan.
    if (!seen.add(tag.toLowerCase())) continue;
    tags.add(tag);
    if (tags.length >= kScanMetadataMaxTags) break;
  }
  return tags;
}

/// One tag with everything Memos' tag parser would choke on removed.
String sanitizeScanTag(Object? value) {
  if (value == null) return '';
  final raw = value is String ? value : value.toString();

  final stripped = raw
      .replaceAll(RegExp(r'\s+'), '')
      // A leading marker is the caller's job to add, so drop any the model
      // volunteered rather than ending up with `##tag`.
      .replaceAll(RegExp(r'^#+'), '')
      // Let me `\p{L}`/`\p{N}` carry CJK, which is most of what these tags will
      // be, while keeping the structural characters Memos tolerates: `_`, `-`
      // and the `/` that makes a tag hierarchical.
      .replaceAll(RegExp(r'[^\p{L}\p{N}_\-/]', unicode: true), '')
      .replaceAll(RegExp(r'^[\-/]+|[\-/]+$'), '');

  if (stripped.isEmpty) return '';
  // Fully-qualified CJK tags: count runes, not UTF-16 units, or a 24-"character"
  // cap would cut Chinese tags at roughly half their intended length.
  return _truncate(stripped, kScanMetadataMaxTagChars);
}

/// Prefix marking where scan OCR is hidden inside a memo's stored `content`.
///
/// The OCR is kept in `content` so the local keyword-search index covers it, but
/// wrapped in this HTML comment so Markdown/HTML viewers and the list-card
/// preview hide it before display. The detail view's `HtmlWidget` ignores HTML
/// comments entirely; the card preview and editor text field call
/// [stripHiddenScanOcr] explicitly.
const String kScanOcrCommentPrefix = '<!--scan-ocr';

/// Wraps [ocr] in a hidden HTML comment suitable for embedding in `content`.
///
/// Returns an empty string when [ocr] is empty. A literal `-->` inside [ocr]
/// would close the comment early, which OCR text effectively never contains, so
/// no escaping is applied; only [wrapHiddenScanOcr] emits the closing `-->`.
String wrapHiddenScanOcr(String ocr) {
  final normalized = ocr.replaceAll('\r\n', '\n').trim();
  if (normalized.isEmpty) return '';
  return '$kScanOcrCommentPrefix\n$normalized\n-->';
}

/// True when [content] carries hidden scan OCR.
bool hasHiddenScanOcr(String content) => content.contains(kScanOcrCommentPrefix);

/// Extracts the hidden scan OCR from [content], or '' when none is present.
String extractHiddenScanOcr(String content) {
  if (!hasHiddenScanOcr(content)) return '';
  final match = RegExp(r'<!--scan-ocr\n([\s\S]*?)\n-->').firstMatch(content);
  return match?.group(1) ?? '';
}

/// Removes any hidden scan-OCR block from [content], leaving the visible text.
String stripHiddenScanOcr(String content) {
  if (!hasHiddenScanOcr(content)) return content;
  final stripped = content.replaceAll(
    RegExp(r'<!--scan-ocr\n[\s\S]*?\n-->'),
    '',
  );
  return stripped.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}

/// Appends the hidden scan-OCR block to [content] when [ocr] is non-empty.
///
/// Use this at the moment a memo is persisted so the OCR rides along in
/// `content` (searchable) without ever entering the editable composer text.
String withHiddenScanOcr(String content, String ocr) {
  final wrapped = wrapHiddenScanOcr(ocr);
  if (wrapped.isEmpty) return content;
  final base = content.trimRight();
  return base.isEmpty ? wrapped : '$base\n\n$wrapped';
}

/// Places [title] on the first line as a Markdown H1 heading and `#tag`s below
/// it, above [content].
///
/// The title is emitted as `# Title` — the ATX heading syntax — rather than as
/// bare first-line text, because that is the Markdown standard for a memo title
/// in Memos: the first `#` line is both the card title and, rendered as an H1,
/// the title style inside the note body. Tags sit on the line below so the
/// whole suggestion reads as one block the user can delete in a single
/// selection if they dislike it. A `#扫描件` tag is always appended so every
/// scanned memo is findable by that tag. Anything the user had already typed is
/// preserved underneath.
String applyScanMetadataToContent({
  required String content,
  required String title,
  required List<String> tags,
}) {
  final allTags = <String>[...tags];
  const scanTag = '扫描件';
  if (!allTags.any((tag) => tag.toLowerCase() == scanTag.toLowerCase())) {
    allTags.add(scanTag);
  }
  final headerBlocks = <String>[
    if (title.trim().isNotEmpty) '# ${title.trim()}',
    if (allTags.isNotEmpty) allTags.map((tag) => '#$tag').join(' '),
  ];
  final header = headerBlocks.join('\n\n');
  final existing = content.trim();

  // Order: suggested title/tags first, then whatever the user typed. The full
  // OCR result is intentionally NOT included here — it is carried separately
  // and re-attached only at save time so it stays hidden yet searchable.
  final parts = <String>[
    if (header.isNotEmpty) header,
    if (existing.isNotEmpty) existing,
  ];
  if (parts.isEmpty) return content;
  return parts.join('\n\n');
}

String _truncate(String value, int maxRunes) {
  final runes = value.runes;
  if (runes.length <= maxRunes) return value;
  return String.fromCharCodes(runes.take(maxRunes));
}

import 'log_sanitizer.dart';

final RegExp _memoHtmlTagPattern = RegExp(
  r'<[A-Za-z][^>]*>',
  caseSensitive: false,
);
final RegExp _memoHtmlImagePattern = RegExp(r'<img\b', caseSensitive: false);
final RegExp _memoHtmlAudioPattern = RegExp(r'<audio\b', caseSensitive: false);
final RegExp _memoHtmlVideoPattern = RegExp(r'<video\b', caseSensitive: false);
final RegExp _memoHtmlParagraphPattern = RegExp(r'<p\b', caseSensitive: false);
final RegExp _memoMarkdownImagePattern = RegExp(
  r'!\[[^\]]*]\(([^)]+)\)',
  caseSensitive: false,
);
final RegExp _memoMarkdownLinkPattern = RegExp(
  r'(?<!!)\[[^\]]*]\(([^)]+)\)',
  caseSensitive: false,
);
final RegExp _memoCodeFencePattern = RegExp(r'^\s*(```|~~~)', multiLine: true);
final RegExp _memoMathPattern = RegExp(
  r'\$\$|\\\(|\\\)|\\\[|\\\]',
  caseSensitive: false,
);
final RegExp _memoTableLinePattern = RegExp(r'^\s*\|.*\|', multiLine: true);
final RegExp _memoFrontMatterFencePattern = RegExp(
  r'^---\s*$',
  multiLine: true,
);
final RegExp _memoFileResourcePattern = RegExp(
  r'/file/resources/',
  caseSensitive: false,
);
final RegExp _memoAppdataPattern = RegExp(
  r'appdata(?::///|/)',
  caseSensitive: false,
);
final RegExp _memoHttpPattern = RegExp(r'https?://', caseSensitive: false);

Map<String, Object?> buildMemoContentDiagnostics(
  String content, {
  String? memoUid,
  String? cacheKey,
}) {
  final lines = content.split('\n');
  var maxLineLength = 0;
  for (final line in lines) {
    if (line.length > maxLineLength) {
      maxLineLength = line.length;
    }
  }

  final htmlTagCount = _memoHtmlTagPattern.allMatches(content).length;
  final htmlImageCount = _memoHtmlImagePattern.allMatches(content).length;
  final htmlAudioCount = _memoHtmlAudioPattern.allMatches(content).length;
  final htmlVideoCount = _memoHtmlVideoPattern.allMatches(content).length;
  final htmlParagraphCount = _memoHtmlParagraphPattern
      .allMatches(content)
      .length;
  final markdownImageCount = _memoMarkdownImagePattern
      .allMatches(content)
      .length;
  final markdownLinkCount = _memoMarkdownLinkPattern.allMatches(content).length;
  final codeFenceCount = _memoCodeFencePattern.allMatches(content).length;
  final mathMarkerCount = _memoMathPattern.allMatches(content).length;
  final tableLineCount = _memoTableLinePattern.allMatches(content).length;
  final frontMatterFenceCount = _memoFrontMatterFencePattern
      .allMatches(content)
      .length;
  final fileResourceCount = _memoFileResourcePattern.allMatches(content).length;
  final appdataCount = _memoAppdataPattern.allMatches(content).length;
  final httpCount = _memoHttpPattern.allMatches(content).length;

  return <String, Object?>{
    if (memoUid != null && memoUid.trim().isNotEmpty)
      'memoUidFingerprint': LogSanitizer.redactOpaque(
        memoUid.trim(),
        kind: 'memo_uid',
      ),
    if (cacheKey != null && cacheKey.trim().isNotEmpty)
      'cacheKeyFingerprint': LogSanitizer.redactOpaque(
        cacheKey.trim(),
        kind: 'memo_md_key',
      ),
    'contentFingerprint': LogSanitizer.fingerprint(content),
    'contentLength': content.length,
    'lineCount': lines.length,
    'maxLineLength': maxLineLength,
    'htmlTagCount': htmlTagCount,
    'htmlImageCount': htmlImageCount,
    'htmlAudioCount': htmlAudioCount,
    'htmlVideoCount': htmlVideoCount,
    'htmlParagraphCount': htmlParagraphCount,
    'markdownImageCount': markdownImageCount,
    'markdownLinkCount': markdownLinkCount,
    'codeFenceCount': codeFenceCount,
    'mathMarkerCount': mathMarkerCount,
    'tableLineCount': tableLineCount,
    'frontMatterFenceCount': frontMatterFenceCount,
    'fileResourceCount': fileResourceCount,
    'appdataCount': appdataCount,
    'httpCount': httpCount,
    'containsHtml': htmlTagCount > 0,
    'containsHtmlImages': htmlImageCount > 0,
    'containsHtmlMedia': htmlAudioCount > 0 || htmlVideoCount > 0,
    'containsMarkdownImages': markdownImageCount > 0,
    'containsFileResources': fileResourceCount > 0,
    'containsAppdata': appdataCount > 0,
    'containsMath': mathMarkerCount > 0,
    'containsCodeFence': codeFenceCount > 0,
    'containsTable': tableLineCount > 0,
    'containsLongLine': maxLineLength >= 1200,
  };
}

bool shouldLogMemoContentDiagnostics(String content) {
  final diagnostics = buildMemoContentDiagnostics(content);
  return (diagnostics['containsHtmlImages'] as bool? ?? false) ||
      (diagnostics['containsFileResources'] as bool? ?? false) ||
      (diagnostics['containsHtmlMedia'] as bool? ?? false) ||
      (diagnostics['containsMath'] as bool? ?? false) ||
      (diagnostics['containsLongLine'] as bool? ?? false);
}

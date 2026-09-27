const int _maxTagLength = 100;
final RegExp _tagRuneRe = RegExp(r'[\p{L}\p{N}\p{S}\p{M}]', unicode: true);
final RegExp _tagInlinePattern = RegExp(
  r'#(?!#|\s)([\p{L}\p{N}\p{S}\p{M}_/\-&\u200D]{1,100})',
  unicode: true,
);
final List<RegExp> _protectedInlineTagPatterns = <RegExp>[
  RegExp(r'!\[[^\]]*]\([^)\n]*\)'),
  RegExp(r'\[[^\]]*]\([^)\n]*\)'),
  RegExp(r'<(?:https?|ftp):[^>\s]+>', caseSensitive: false),
  RegExp(r'<(?:mailto|tel):[^>\s]+>', caseSensitive: false),
  RegExp(r'<[^>\n]+>'),
  RegExp(
    r'(?:(?:https?|ftp):\/\/|mailto:|tel:|www\.)[^\s<>()]+',
    caseSensitive: false,
  ),
];
final RegExp _memoInternalMarkerLinePattern = RegExp(
  r'^<!--\s*(?:memoflow-third-party-share|memoflow_quick_clip:[^>]*|memoflow-share-inline:[^>]*)\s*-->$',
);

class InlineTagMatch {
  const InlineTagMatch({
    required this.start,
    required this.end,
    required this.tag,
  });

  final int start;
  final int end;
  final String tag;
}

class _ProtectedRange {
  const _ProtectedRange(this.start, this.end);

  final int start;
  final int end;

  bool contains(int index) => index >= start && index < end;
}

bool _isValidTagRune(int rune) {
  if (rune == 0x5F ||
      rune == 0x2D ||
      rune == 0x2F ||
      rune == 0x26 ||
      rune == 0x200D) {
    return true;
  }
  return _tagRuneRe.hasMatch(String.fromCharCode(rune));
}

String normalizeTagPath(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  final withoutHash = trimmed.startsWith('#') ? trimmed.substring(1) : trimmed;
  final parts = withoutHash.split('/');
  final normalizedParts = <String>[];
  for (final part in parts) {
    final normalized = _normalizeTagSegment(part);
    if (normalized.isEmpty) continue;
    normalizedParts.add(normalized);
  }
  if (normalizedParts.isEmpty) return '';
  return normalizedParts.join('/');
}

String _normalizeTagSegment(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  final buffer = StringBuffer();
  for (final rune in trimmed.runes) {
    if (rune == 0x2F) continue; // slash is a path separator
    if (_isValidTagRune(rune)) {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}

bool isMemoInternalMarkerLine(String line) {
  return _memoInternalMarkerLinePattern.hasMatch(line.trim());
}

bool isMemoTagNonContentLine(String line) {
  final trimmed = line.trim();
  return trimmed.isEmpty || isMemoInternalMarkerLine(trimmed);
}

List<String> extractTags(String content) {
  final tags = <String>{};
  if (content.isEmpty) return const [];

  final lines = content.split('\n');
  final tagZoneLineIndexes = findStrictTagZoneLineIndexes(lines);
  for (final index in tagZoneLineIndexes) {
    for (final match in findStrictTagZonePrefixMatches(lines[index])) {
      if (match.tag.isEmpty) continue;
      tags.add(match.tag);
    }
  }

  final list = tags.toList(growable: false);
  list.sort();
  return list;
}

List<InlineTagMatch> findInlineTagMatches(String line) {
  if (line.isEmpty) return const [];
  final rawMatches = _tagInlinePattern.allMatches(line).toList(growable: false);
  if (rawMatches.isEmpty) return const [];

  final protectedRanges = _collectProtectedRanges(line);
  final matches = <InlineTagMatch>[];
  for (final match in rawMatches) {
    final tag = match.group(1);
    if (tag == null || tag.isEmpty || tag.length > _maxTagLength) {
      continue;
    }
    if (_isIndexProtected(match.start, protectedRanges)) {
      continue;
    }
    final previousRune = _previousRuneBefore(line, match.start);
    if (_shouldSkipInlineTag(previousRune)) {
      continue;
    }
    matches.add(InlineTagMatch(start: match.start, end: match.end, tag: tag));
  }
  return matches;
}

List<int> findStrictTagZoneLineIndexes(
  List<String> lines, {
  bool Function(String line)? isNonContentLine,
}) {
  if (lines.isEmpty) return const <int>[];

  final nonContentLine = isNonContentLine ?? isMemoTagNonContentLine;
  int? firstLine;
  int? lastLine;
  for (var i = 0; i < lines.length; i++) {
    if (nonContentLine(lines[i])) continue;
    firstLine ??= i;
    lastLine = i;
  }

  if (firstLine == null || lastLine == null) return const <int>[];

  final indexes = <int>[];
  if (isStrictTagZoneLine(lines[firstLine])) {
    indexes.add(firstLine);
  }
  if (lastLine != firstLine && isStrictTagZoneLine(lines[lastLine])) {
    indexes.add(lastLine);
  }
  return indexes;
}

bool isStrictTagZoneLine(String line) {
  return findStrictTagZonePrefixMatches(line).isNotEmpty;
}

List<InlineTagMatch> findStrictTagZonePrefixMatches(String line) {
  if (_hasIndentedCodeBlockPrefix(line)) return const [];

  if (line.trim().isEmpty) return const [];

  final matches = findInlineTagMatches(line);
  if (matches.isEmpty) return const [];

  var cursor = 0;
  final prefixMatches = <InlineTagMatch>[];
  for (final match in matches) {
    if (!_isWhitespaceOnly(line.substring(cursor, match.start))) {
      break;
    }
    if (!_hasTokenBoundaryAfter(line, match.end)) {
      break;
    }
    prefixMatches.add(match);
    cursor = match.end;
  }

  return prefixMatches;
}

bool _hasIndentedCodeBlockPrefix(String line) {
  var columns = 0;
  for (final codeUnit in line.codeUnits) {
    if (codeUnit == 0x20) {
      columns++;
    } else if (codeUnit == 0x09) {
      columns += 4;
    } else {
      break;
    }
    if (columns >= 4) return true;
  }
  return false;
}

bool _isWhitespaceOnly(String value) => value.trim().isEmpty;

bool _hasTokenBoundaryAfter(String line, int index) {
  if (index >= line.length) return true;
  return String.fromCharCode(line.codeUnitAt(index)).trim().isEmpty;
}

bool _shouldSkipInlineTag(int? previousRune) {
  if (previousRune == null) return false;
  if (previousRune == 0x23 || previousRune == 0x5C) {
    return true;
  }
  return _isValidTagRune(previousRune);
}

int? _previousRuneBefore(String text, int index) {
  if (index <= 0) return null;
  final previousCodeUnit = text.codeUnitAt(index - 1);
  if (previousCodeUnit >= 0xDC00 && previousCodeUnit <= 0xDFFF && index >= 2) {
    final highSurrogate = text.codeUnitAt(index - 2);
    if (highSurrogate >= 0xD800 && highSurrogate <= 0xDBFF) {
      return 0x10000 +
          ((highSurrogate - 0xD800) << 10) +
          (previousCodeUnit - 0xDC00);
    }
  }
  return previousCodeUnit;
}

List<_ProtectedRange> _collectProtectedRanges(String line) {
  final ranges = <_ProtectedRange>[];
  for (final pattern in _protectedInlineTagPatterns) {
    for (final match in pattern.allMatches(line)) {
      if (match.start >= match.end) continue;
      ranges.add(_ProtectedRange(match.start, match.end));
    }
  }
  if (ranges.length < 2) return ranges;

  ranges.sort((left, right) => left.start.compareTo(right.start));
  final merged = <_ProtectedRange>[ranges.first];
  for (final range in ranges.skip(1)) {
    final last = merged.last;
    if (range.start <= last.end) {
      merged[merged.length - 1] = _ProtectedRange(
        last.start,
        range.end > last.end ? range.end : last.end,
      );
      continue;
    }
    merged.add(range);
  }
  return merged;
}

bool _isIndexProtected(int index, List<_ProtectedRange> ranges) {
  for (final range in ranges) {
    if (index < range.start) return false;
    if (range.contains(index)) return true;
  }
  return false;
}

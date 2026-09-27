import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../share_clip_models.dart';
import 'share_page_parser.dart';

class XiaohongshuNoteContentCleanupResult {
  const XiaohongshuNoteContentCleanupResult({
    required this.targetNoteRoots,
    this.contentHtml,
    this.textContent,
    this.title,
    this.excerpt,
    this.noteType,
    this.imageAttachmentUrls = const [],
    this.hasArticleBody = false,
    this.isVideoNote = false,
  });

  final List<Map<String, dynamic>> targetNoteRoots;
  final String? contentHtml;
  final String? textContent;
  final String? title;
  final String? excerpt;
  final String? noteType;
  final List<String> imageAttachmentUrls;
  final bool hasArticleBody;
  final bool isVideoNote;
}

XiaohongshuNoteContentCleanupResult cleanXiaohongshuNoteContent({
  required List<Object?> roots,
  required Map<String, dynamic> bridge,
  required Uri finalUrl,
}) {
  final targetNotes = _selectTargetNoteRoots(roots, finalUrl);
  final cleanedHtml = _cleanContentHtml(bridge['contentHtml']?.toString());
  final textContent =
      _normalizeText(cleanedHtml?.textContent) ??
      _normalizeText(bridge['textContent']?.toString());
  final title =
      _resolveTitle(targetNotes) ??
      _normalizeText(bridge['articleTitle']?.toString()) ??
      _normalizeText(bridge['pageTitle']?.toString());
  final excerpt =
      _resolveExcerpt(targetNotes, textContent) ??
      _normalizeText(bridge['excerpt']?.toString());
  final noteType = _resolveNoteType(targetNotes);
  final imageUrls = <String>{};
  for (final note in targetNotes) {
    _collectImageUrlStrings(note, imageUrls);
  }
  if (cleanedHtml != null) {
    for (final url in cleanedHtml.imageUrls) {
      imageUrls.add(url);
    }
  }

  final hasArticleBody =
      (cleanedHtml?.contentHtml ?? '').trim().isNotEmpty ||
      (textContent ?? '').trim().isNotEmpty;
  final isVideoNote =
      _looksLikeVideoType(noteType) ||
      targetNotes.any(_containsDirectVideoEvidence);

  return XiaohongshuNoteContentCleanupResult(
    targetNoteRoots: targetNotes,
    contentHtml: cleanedHtml?.contentHtml,
    textContent: textContent,
    title: title,
    excerpt: excerpt,
    noteType: noteType,
    imageAttachmentUrls: imageUrls.toList(growable: false),
    hasArticleBody: hasArticleBody,
    isVideoNote: isVideoNote,
  );
}

String? normalizeXiaohongshuImageUrl(String? value) {
  final normalized = normalizeShareText(value);
  if (normalized == null) return null;
  final uri = Uri.tryParse(normalized);
  if (uri == null) return normalized;
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return normalized;
  if (scheme == 'http' && _isXiaohongshuImageHost(uri.host)) {
    return uri.replace(scheme: 'https').toString();
  }
  return normalized;
}

class _CleanedXiaohongshuHtml {
  const _CleanedXiaohongshuHtml({
    required this.contentHtml,
    required this.textContent,
    required this.imageUrls,
  });

  final String? contentHtml;
  final String? textContent;
  final List<String> imageUrls;
}

_CleanedXiaohongshuHtml? _cleanContentHtml(String? rawHtml) {
  final normalizedHtml = normalizeShareText(rawHtml);
  if (normalizedHtml == null) return null;

  var fragment = html_parser.parseFragment(normalizedHtml);
  final focused = _extractPreferredContentHtml(fragment);
  if (focused != null) {
    fragment = html_parser.parseFragment(focused);
  }
  _removeKnownNoise(fragment);
  _normalizeImageSources(fragment);
  _removeEmptyElements(fragment);

  final html = normalizeShareText(fragment.nodes.map(_serializeNode).join());
  final text = _normalizeText(fragment.text);
  final imageUrls = fragment
      .querySelectorAll('img[src]')
      .map((image) => normalizeXiaohongshuImageUrl(image.attributes['src']))
      .whereType<String>()
      .where(_looksLikeImageUrl)
      .toSet()
      .toList(growable: false);
  return _CleanedXiaohongshuHtml(
    contentHtml: html,
    textContent: text,
    imageUrls: imageUrls,
  );
}

String? _extractPreferredContentHtml(dom.DocumentFragment fragment) {
  const selectors = [
    '.author-desc-content',
    '.rich-text-wrapper',
    '.content-container .author-desc',
    '.note-content',
    '.note-desc',
    '.desc',
  ];
  for (final selector in selectors) {
    final candidate = fragment.querySelector(selector);
    final html = candidate?.innerHtml.trim() ?? '';
    if (html.isNotEmpty) return html;
  }
  return null;
}

void _removeKnownNoise(dom.DocumentFragment fragment) {
  const selectors = [
    'script',
    'style',
    'noscript',
    'svg',
    'button',
    '.topic-container',
    '.share-layer',
    '.user-notes-box',
    '.comments-container',
    '.comment-container',
    '.comment-list',
    '.related-notes',
  ];
  for (final selector in selectors) {
    for (final node in fragment.querySelectorAll(selector).toList()) {
      node.remove();
    }
  }
}

void _normalizeImageSources(dom.DocumentFragment fragment) {
  for (final image in fragment.querySelectorAll('img')) {
    final src = normalizeXiaohongshuImageUrl(
      image.attributes['src'] ??
          image.attributes['data-src'] ??
          image.attributes['data-original'] ??
          image.attributes['data-lazy-src'],
    );
    if (src != null) {
      image.attributes['src'] = src;
    }
    image.attributes.remove('data-src');
    image.attributes.remove('data-original');
    image.attributes.remove('data-lazy-src');
  }
}

void _removeEmptyElements(dom.Node node) {
  if (node is! dom.Element && node is! dom.DocumentFragment) return;
  final children = node.nodes.toList(growable: false);
  for (final child in children) {
    _removeEmptyElements(child);
  }
  if (node is! dom.Element) return;
  if (const {'br', 'hr', 'img', 'input'}.contains(node.localName)) return;
  if (node.text.trim().isEmpty && node.querySelector('img') == null) {
    node.remove();
  }
}

String _serializeNode(dom.Node node) {
  if (node is dom.Element) return node.outerHtml;
  return node.text ?? '';
}

List<Map<String, dynamic>> _selectTargetNoteRoots(
  List<Object?> roots,
  Uri finalUrl,
) {
  final candidates = <Map<String, dynamic>>[];
  final seen = <Map<String, dynamic>>{};

  void add(Object? value) {
    final map = _asMap(value);
    if (map == null || seen.contains(map)) return;
    if (!_looksLikeNoteMap(map)) return;
    seen.add(map);
    candidates.add(map);
  }

  for (final root in roots) {
    add(valueAtPath(root, const ['note']));
    add(valueAtPath(root, const ['noteInfo', 'note']));
    add(valueAtPath(root, const ['noteDetail', 'note']));
    add(valueAtPath(root, const ['data', 'note']));
    add(valueAtPath(root, const ['noteCard']));
    add(valueAtPath(root, const ['note_card']));
    add(root);
  }
  if (candidates.isNotEmpty) return candidates;

  final targetId = _targetNoteId(finalUrl);
  final scored = <({Map<String, dynamic> map, int score})>[];
  for (final root in roots) {
    for (final map in deepMaps(root)) {
      final score = _scoreFallbackNoteMap(map, targetId);
      if (score > 0) scored.add((map: map, score: score));
    }
  }
  scored.sort((left, right) => right.score.compareTo(left.score));
  for (final item in scored.take(2)) {
    add(item.map);
  }
  return candidates;
}

Map<String, dynamic>? _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return null;
}

bool _looksLikeNoteMap(Map<String, dynamic> map) {
  return _normalizeText(map['title']?.toString()) != null ||
      _normalizeText(map['desc']?.toString()) != null ||
      _normalizeText(map['noteType']?.toString()) != null ||
      _normalizeText(map['type']?.toString()) != null ||
      map.containsKey('imageList') ||
      map.containsKey('image_list') ||
      map.containsKey('images') ||
      map.containsKey('masterUrl') ||
      map.containsKey('stream');
}

int _scoreFallbackNoteMap(Map<String, dynamic> map, String? targetId) {
  var score = 0;
  final idValues = [
    map['id'],
    map['noteId'],
    map['note_id'],
    map['noteIdStr'],
  ].map((value) => value?.toString()).whereType<String>().toList();
  if (targetId != null && idValues.any((value) => value.contains(targetId))) {
    score += 5000;
  }
  if (_normalizeText(map['title']?.toString()) != null) score += 200;
  if (_normalizeText(map['desc']?.toString()) != null) score += 500;
  if (_normalizeText(map['noteType']?.toString()) != null) score += 150;
  if (map.containsKey('imageList') || map.containsKey('images')) score += 300;
  if (map.containsKey('masterUrl') || map.containsKey('stream')) score += 300;
  if (score < 500 && targetId == null) return 0;
  if (score < 5000 && targetId != null) return 0;
  return score;
}

String? _targetNoteId(Uri finalUrl) {
  final segments = finalUrl.pathSegments
      .map((segment) => segment.trim())
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);
  if (segments.isEmpty) return null;
  return segments.last;
}

String? _resolveTitle(List<Map<String, dynamic>> targetNotes) {
  for (final note in targetNotes) {
    final title = firstStringAtPaths(note, const [
      ['title'],
      ['note', 'title'],
      ['noteInfo', 'note', 'title'],
    ]);
    if (title != null) return title;
  }
  return null;
}

String? _resolveExcerpt(
  List<Map<String, dynamic>> targetNotes,
  String? textContent,
) {
  for (final note in targetNotes) {
    final excerpt = firstStringAtPaths(note, const [
      ['desc'],
      ['description'],
      ['note', 'desc'],
      ['noteInfo', 'note', 'desc'],
    ]);
    if (excerpt == null) continue;
    final text = _normalizeText(textContent);
    if (text != null && text.startsWith(excerpt)) return null;
    return excerpt;
  }
  return null;
}

String? _resolveNoteType(List<Map<String, dynamic>> targetNotes) {
  for (final note in targetNotes) {
    final type = firstStringAtPaths(note, const [
      ['noteType'],
      ['type'],
      ['modelType'],
      ['note', 'noteType'],
      ['noteInfo', 'note', 'noteType'],
    ]);
    if (type != null) return type;
  }
  return null;
}

bool _looksLikeVideoType(String? value) {
  return (value ?? '').trim().toLowerCase().contains('video');
}

bool _containsDirectVideoEvidence(Map<String, dynamic> note) {
  for (final value in deepValuesForKey(note, const {
    'masterUrl',
    'url',
    'backupUrls',
    'stream',
  })) {
    if (_containsVideoUrl(value)) return true;
  }
  return false;
}

bool _containsVideoUrl(Object? value) {
  if (value is String) {
    final normalized = normalizeShareText(value);
    return normalized != null &&
        (isDirectVideoUrl(normalized) || isUnsupportedStreamUrl(normalized));
  }
  if (value is List) {
    return value.any(_containsVideoUrl);
  }
  if (value is Map) {
    return value.values.any(_containsVideoUrl);
  }
  return false;
}

void _collectImageUrlStrings(Object? value, Set<String> output) {
  if (value == null) return;
  if (value is String) {
    final normalized = normalizeXiaohongshuImageUrl(value);
    if (normalized != null && _looksLikeImageUrl(normalized)) {
      output.add(normalized);
    }
    return;
  }
  if (value is List) {
    for (final item in value) {
      _collectImageUrlStrings(item, output);
    }
    return;
  }
  if (value is Map) {
    for (final entry in value.entries) {
      final key = entry.key.toString().toLowerCase();
      if (_isImageUrlField(key) || _isImageContainerField(key)) {
        _collectImageUrlStrings(entry.value, output);
      }
    }
  }
}

bool _isImageContainerField(String key) {
  return key.contains('image') ||
      key.contains('cover') ||
      key.contains('pic') ||
      key == 'note_card' ||
      key == 'notecard';
}

bool _isImageUrlField(String key) {
  return key == 'url' ||
      key == 'src' ||
      key == 'url_default' ||
      key == 'urldefault' ||
      key == 'url_pre' ||
      key == 'urlpre' ||
      key == 'url_size_large' ||
      key == 'urlsizelarge' ||
      key == 'imageurl' ||
      key == 'image_url' ||
      key == 'originurl' ||
      key == 'origin_url';
}

bool _looksLikeImageUrl(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null) return false;
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return false;
  final lower = value.toLowerCase();
  if (lower.contains('.mp4') || lower.contains('.m3u8')) return false;
  if (RegExp(r'\.(jpe?g|png|webp|gif|avif|heic)(?:[?#]|$)').hasMatch(lower)) {
    return true;
  }
  final host = uri.host.toLowerCase();
  return _isXiaohongshuImageHost(host) ||
      lower.contains('imageview') ||
      lower.contains('/spectrum/');
}

bool _isXiaohongshuImageHost(String host) {
  final lower = host.toLowerCase();
  return lower.contains('xhscdn') ||
      lower.contains('sns-webpic') ||
      lower.contains('sns-img') ||
      lower.contains('sns-na');
}

String? _normalizeText(String? value) {
  return normalizeShareText(value?.replaceAll(RegExp(r'\s+'), ' '));
}

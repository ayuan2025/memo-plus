import 'package:html/parser.dart' as html_parser;

import 'memo_inline_image_syntax.dart';

final RegExp _markdownImagePattern = RegExp(
  r'!\[[^\]]*]\(([^)\s]+)(?:\s+"[^"]*")?\)',
);
final RegExp _codeFencePattern = RegExp(r'^\s*(```|~~~)');

String normalizeMarkdownImageSrc(String value) {
  final trimmed = value.trim();
  String normalized;
  if (trimmed.startsWith('//')) {
    normalized = 'https:$trimmed';
  } else {
    normalized = trimmed;
  }
  normalized = _normalizeGithubBlobImageUrl(normalized);
  normalized = _normalizeGitlabBlobImageUrl(normalized);
  normalized = _normalizeGiteeBlobImageUrl(normalized);
  return normalized;
}

List<String> extractMarkdownImageUrls(String text) {
  if (text.trim().isEmpty) return const [];
  final urls = <String>[];
  var inFence = false;

  for (final line in text.split('\n')) {
    if (_codeFencePattern.hasMatch(line.trimLeft())) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;

    for (final match in _markdownImagePattern.allMatches(line)) {
      var url = (match.group(1) ?? '').trim();
      if (url.startsWith('<') && url.endsWith('>') && url.length > 2) {
        url = url.substring(1, url.length - 1).trim();
      }
      url = normalizeMarkdownImageSrc(url);
      if (url.isEmpty) continue;
      urls.add(url);
    }
  }

  return urls;
}

List<String> extractHtmlImageUrls(String text) {
  if (text.trim().isEmpty) return const [];

  final fragment = html_parser.parseFragment(_removeFencedCodeBlocks(text));
  final urls = <String>[];
  for (final element in fragment.querySelectorAll('img[src]')) {
    final raw = (element.attributes['src'] ?? '').trim();
    if (raw.isEmpty) continue;
    final normalized = normalizeMarkdownImageSrc(raw);
    if (normalized.isEmpty) continue;
    urls.add(normalized);
  }
  return urls;
}

String _removeFencedCodeBlocks(String text) {
  if (text.trim().isEmpty) return text;
  final buffer = StringBuffer();
  var inFence = false;
  for (final line in text.split('\n')) {
    if (_codeFencePattern.hasMatch(line.trimLeft())) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;
    if (buffer.isNotEmpty) {
      buffer.writeln();
    }
    buffer.write(line);
  }
  return buffer.toString();
}

List<String> extractMemoImageUrls(String text) {
  if (text.trim().isEmpty) return const [];
  return <String>[
    ...extractMarkdownImageUrls(text),
    ...extractHtmlImageUrls(text),
  ];
}

bool contentHasMarkdownImageSyntax(String text) {
  return extractMarkdownImageUrls(text).isNotEmpty;
}

List<String> extractMemoImageUrlsForSyntax(
  String text,
  MemoInlineImageSyntax syntax,
) {
  if (text.trim().isEmpty) return const [];
  return switch (syntax) {
    MemoInlineImageSyntax.none => const <String>[],
    MemoInlineImageSyntax.markdownOnly => extractMarkdownImageUrls(text),
    MemoInlineImageSyntax.markdownAndHtml => extractMemoImageUrls(text),
  };
}

String _normalizeGithubBlobImageUrl(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasScheme) return value;

  final host = uri.host.toLowerCase();
  if (host != 'github.com' && host != 'www.github.com') {
    return value;
  }

  final segments = uri.pathSegments;
  if (segments.length < 5 || segments[2] != 'blob') {
    return value;
  }

  final owner = segments[0];
  final repo = segments[1];
  final ref = segments[3];
  if (owner.isEmpty || repo.isEmpty || ref.isEmpty) {
    return _appendGithubRawQuery(uri);
  }

  final pathSegments = segments.skip(4).toList(growable: false);
  if (pathSegments.isEmpty) {
    return _appendGithubRawQuery(uri);
  }

  return Uri(
    scheme: 'https',
    host: 'raw.githubusercontent.com',
    pathSegments: <String>[owner, repo, ref, ...pathSegments],
    queryParameters: uri.queryParameters.isEmpty ? null : uri.queryParameters,
    fragment: uri.fragment.isEmpty ? null : uri.fragment,
  ).toString();
}

String _normalizeGitlabBlobImageUrl(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasScheme) return value;

  final host = uri.host.toLowerCase();
  if (host != 'gitlab.com' && host != 'www.gitlab.com') {
    return value;
  }

  final marker = '/-/blob/';
  final path = uri.path;
  final idx = path.indexOf(marker);
  if (idx <= 0) {
    return value;
  }

  final convertedPath =
      '${path.substring(0, idx)}/-/raw/${path.substring(idx + marker.length)}';
  return uri.replace(path: convertedPath).toString();
}

String _normalizeGiteeBlobImageUrl(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasScheme) return value;

  final host = uri.host.toLowerCase();
  if (host != 'gitee.com' && host != 'www.gitee.com') {
    return value;
  }

  final marker = '/blob/';
  final path = uri.path;
  final idx = path.indexOf(marker);
  if (idx <= 0) {
    return value;
  }

  final convertedPath =
      '${path.substring(0, idx)}/raw/${path.substring(idx + marker.length)}';
  return uri.replace(path: convertedPath).toString();
}

String _appendGithubRawQuery(Uri uri) {
  final params = Map<String, String>.from(uri.queryParameters);
  final raw = (params['raw'] ?? '').trim().toLowerCase();
  if (raw != '1' && raw != 'true') {
    params['raw'] = '1';
  }
  return uri.replace(queryParameters: params).toString();
}

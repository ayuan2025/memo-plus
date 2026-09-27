import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

class RssHtmlSanitizer {
  const RssHtmlSanitizer();

  String sanitize(String html, {required Uri baseUri}) {
    final source = html.trim();
    if (source.isEmpty) return '';
    final fragment = html_parser.parseFragment(source);
    return fragment.nodes
        .map((node) => _sanitizeNode(node, baseUri: baseUri))
        .where((html) => html.trim().isNotEmpty)
        .join('\n')
        .trim();
  }

  String _sanitizeNode(dom.Node node, {required Uri baseUri}) {
    if (node is dom.Text) {
      return _escapeHtml(node.data);
    }
    if (node is! dom.Element) {
      return '';
    }

    final tag = node.localName?.toLowerCase() ?? '';
    if (_blockedTags.contains(tag)) return '';

    final children = node.nodes
        .map((child) => _sanitizeNode(child, baseUri: baseUri))
        .join()
        .trim();

    if (!_allowedTags.contains(tag)) {
      return children;
    }

    if (_voidTags.contains(tag)) {
      final attributes = _sanitizeAttributes(node, tag, baseUri: baseUri);
      if ((tag == 'img' || tag == 'source') && !attributes.containsKey('src')) {
        return '';
      }
      return '<$tag${_formatAttributes(attributes)}>';
    }

    if (children.isEmpty && !_emptyAllowedTags.contains(tag)) {
      return '';
    }
    final attributes = _sanitizeAttributes(node, tag, baseUri: baseUri);
    if (tag == 'a' && !attributes.containsKey('href')) {
      return children;
    }
    return '<$tag${_formatAttributes(attributes)}>$children</$tag>';
  }

  Map<String, String> _sanitizeAttributes(
    dom.Element element,
    String tag, {
    required Uri baseUri,
  }) {
    final output = <String, String>{};
    if (tag == 'a') {
      final href = _sanitizeUrl(
        element.attributes['href'],
        baseUri: baseUri,
        allowMailto: true,
      );
      if (href != null) {
        output['href'] = href;
        output['rel'] = 'noreferrer noopener';
      }
    } else if (tag == 'img' || tag == 'source') {
      final src = _sanitizeUrl(element.attributes['src'], baseUri: baseUri);
      if (src != null) output['src'] = src;
      final type = element.attributes['type']?.trim().toLowerCase();
      if (type != null &&
          type.isNotEmpty &&
          RegExp(r'^[a-z0-9.+-]+/[a-z0-9.+-]+$').hasMatch(type)) {
        output['type'] = type;
      }
      if (tag == 'img') {
        final alt = element.attributes['alt']?.trim();
        if (alt != null && alt.isNotEmpty) output['alt'] = alt;
      }
    } else if (tag == 'video') {
      output['controls'] = 'controls';
      final poster = _sanitizeUrl(
        element.attributes['poster'],
        baseUri: baseUri,
      );
      if (poster != null) output['poster'] = poster;
    }

    return output;
  }

  String? _sanitizeUrl(
    String? raw, {
    required Uri baseUri,
    bool allowMailto = false,
  }) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    Uri resolved;
    try {
      resolved = baseUri.resolve(value);
    } catch (_) {
      return null;
    }
    final scheme = resolved.scheme.toLowerCase();
    if (scheme == 'http' ||
        scheme == 'https' ||
        (allowMailto && scheme == 'mailto')) {
      return resolved.toString();
    }
    return null;
  }

  String _formatAttributes(Map<String, String> attributes) {
    if (attributes.isEmpty) return '';
    return attributes.entries
        .map((entry) => ' ${entry.key}="${_escapeAttribute(entry.value)}"')
        .join();
  }
}

const _blockedTags = <String>{
  'script',
  'style',
  'noscript',
  'iframe',
  'object',
  'embed',
  'form',
  'input',
  'button',
  'svg',
  'canvas',
};

const _allowedTags = <String>{
  'a',
  'article',
  'aside',
  'b',
  'blockquote',
  'br',
  'code',
  'dd',
  'del',
  'div',
  'dl',
  'dt',
  'em',
  'figcaption',
  'figure',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'hr',
  'i',
  'img',
  'li',
  'main',
  'ol',
  'p',
  'pre',
  'section',
  'source',
  'span',
  'strong',
  'sub',
  'sup',
  'table',
  'tbody',
  'td',
  'tfoot',
  'th',
  'thead',
  'tr',
  'u',
  'ul',
  'video',
};

const _voidTags = <String>{'br', 'hr', 'img', 'source'};
const _emptyAllowedTags = <String>{'br', 'hr', 'img', 'source', 'video'};

String _escapeHtml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}

String _escapeAttribute(String value) {
  return _escapeHtml(value).replaceAll('"', '&quot;');
}

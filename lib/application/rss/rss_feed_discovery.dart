import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

class RssFeedDiscovery {
  const RssFeedDiscovery();

  List<Uri> discoverAlternateFeeds(String html, {required Uri pageUri}) {
    final document = html_parser.parse(html);
    final links = <Uri>[];
    final seen = <String>{};
    for (final element in document.querySelectorAll('link[href]')) {
      if (!_isSupportedAlternate(element)) continue;
      final href = (element.attributes['href'] ?? '').trim();
      if (href.isEmpty) continue;
      Uri resolved;
      try {
        resolved = pageUri.resolve(href);
      } catch (_) {
        continue;
      }
      if (seen.add(resolved.toString())) {
        links.add(resolved);
      }
    }
    return links;
  }

  bool _isSupportedAlternate(dom.Element element) {
    final rel = (element.attributes['rel'] ?? '').trim().toLowerCase();
    if (!rel.split(RegExp(r'\s+')).contains('alternate')) {
      return false;
    }
    final type = (element.attributes['type'] ?? '').trim().toLowerCase();
    return type == 'application/rss+xml' ||
        type == 'application/atom+xml' ||
        type == 'text/xml' ||
        type == 'application/xml';
  }
}

import 'package:html/parser.dart' as html_parser;
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';

import '../../data/models/rss_feed_preview.dart';

class RssFeedParseException implements Exception {
  const RssFeedParseException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RssFeedParser {
  const RssFeedParser();

  RssFeedPreview parse(String source, {required Uri sourceUri}) {
    final XmlDocument document;
    try {
      document = XmlDocument.parse(source);
    } catch (error) {
      throw RssFeedParseException('Invalid feed XML: $error');
    }
    final rss = _firstDescendantByName(document.rootElement, 'rss');
    if (rss != null) return _parseRss(rss, sourceUri: sourceUri);
    final atom = _firstDescendantByName(document.rootElement, 'feed');
    if (atom != null) return _parseAtom(atom, sourceUri: sourceUri);
    throw const RssFeedParseException('No RSS or Atom feed root found.');
  }

  RssFeedPreview _parseRss(XmlElement rss, {required Uri sourceUri}) {
    final channel = _firstDescendantByName(rss, 'channel') ?? rss;
    final title = _childText(channel, const {'title'});
    final siteUrl = _resolveUrl(sourceUri, _childText(channel, const {'link'}));
    final description = _childText(channel, const {'description'});
    final iconUrl = _resolveUrl(
      sourceUri,
      _childText(_firstDescendantByName(channel, 'image'), const {'url'}),
    );
    final items = _childrenByName(channel, 'item')
        .map((item) => _parseRssItem(item, sourceUri: sourceUri))
        .where((item) => item.stableIdentity.isNotEmpty)
        .toList(growable: false);
    if (title.trim().isEmpty && items.isEmpty) {
      throw const RssFeedParseException('RSS feed did not include metadata.');
    }
    return RssFeedPreview(
      requestedUrl: sourceUri.toString(),
      feedUrl: sourceUri.toString(),
      siteUrl: siteUrl,
      title: title,
      description: description,
      iconUrl: iconUrl,
      articles: items,
    );
  }

  RssArticlePreview _parseRssItem(XmlElement item, {required Uri sourceUri}) {
    final link = _resolveUrl(sourceUri, _childText(item, const {'link'}));
    return RssArticlePreview(
      guid: _childText(item, const {'guid'}),
      link: link,
      title: _childText(item, const {'title'}),
      author: _childText(item, const {'author', 'dc:creator'}),
      summaryHtml: _childHtml(item, const {'description'}),
      contentHtml: _childHtml(item, const {'content:encoded', 'content'}),
      leadImageUrl: _resolveLeadImage(item, sourceUri: sourceUri),
      publishedTime: _parseFeedDate(
        _childText(item, const {'pubdate', 'published', 'dc:date'}),
      ),
    );
  }

  RssFeedPreview _parseAtom(XmlElement feed, {required Uri sourceUri}) {
    final title = _childText(feed, const {'title'});
    final siteUrl = _resolveUrl(sourceUri, _atomLink(feed));
    final description = _childText(feed, const {'subtitle', 'tagline'});
    final iconUrl = _resolveUrl(
      sourceUri,
      _childText(feed, const {'icon', 'logo'}),
    );
    final items = _childrenByName(feed, 'entry')
        .map((entry) => _parseAtomEntry(entry, sourceUri: sourceUri))
        .where((item) => item.stableIdentity.isNotEmpty)
        .toList(growable: false);
    if (title.trim().isEmpty && items.isEmpty) {
      throw const RssFeedParseException('Atom feed did not include metadata.');
    }
    return RssFeedPreview(
      requestedUrl: sourceUri.toString(),
      feedUrl: sourceUri.toString(),
      siteUrl: siteUrl,
      title: title,
      description: description,
      iconUrl: iconUrl,
      articles: items,
    );
  }

  RssArticlePreview _parseAtomEntry(
    XmlElement entry, {
    required Uri sourceUri,
  }) {
    final author = _childText(_firstDescendantByName(entry, 'author'), const {
      'name',
    });
    return RssArticlePreview(
      guid: _childText(entry, const {'id'}),
      link: _resolveUrl(sourceUri, _atomLink(entry)),
      title: _childText(entry, const {'title'}),
      author: author,
      summaryHtml: _childHtml(entry, const {'summary'}),
      contentHtml: _childHtml(entry, const {'content'}),
      leadImageUrl: _resolveLeadImage(entry, sourceUri: sourceUri),
      publishedTime: _parseFeedDate(
        _childText(entry, const {'published', 'updated'}),
      ),
    );
  }

  String _atomLink(XmlElement element) {
    final links = _childrenByName(element, 'link');
    XmlElement? alternate;
    for (final link in links) {
      final rel = (link.getAttribute('rel') ?? 'alternate')
          .trim()
          .toLowerCase();
      if (rel.isEmpty || rel == 'alternate') {
        alternate = link;
        break;
      }
    }
    final target = alternate ?? (links.isEmpty ? null : links.first);
    return (target?.getAttribute('href') ?? '').trim();
  }

  String _resolveLeadImage(XmlElement element, {required Uri sourceUri}) {
    for (final media in _descendantsByNames(element, const {
      'media:content',
      'media:thumbnail',
      'enclosure',
    })) {
      final url =
          (media.getAttribute('url') ?? media.getAttribute('href') ?? '')
              .trim();
      if (url.isEmpty) continue;
      final type = (media.getAttribute('type') ?? '').trim().toLowerCase();
      if (type.isEmpty || type.startsWith('image/')) {
        return _resolveUrl(sourceUri, url);
      }
    }
    final html = _childHtml(element, const {
      'content:encoded',
      'content',
      'description',
      'summary',
    });
    if (html.isNotEmpty) {
      final fragment = html_parser.parseFragment(html);
      final image = fragment.querySelector('img[src]');
      final src = (image?.attributes['src'] ?? '').trim();
      if (src.isNotEmpty) return _resolveUrl(sourceUri, src);
    }
    return '';
  }

  String _childText(XmlElement? element, Set<String> names) {
    final child = _firstChildByNames(element, names);
    if (child == null) return '';
    return _normalizeText(child.innerText);
  }

  String _childHtml(XmlElement? element, Set<String> names) {
    final child = _firstChildByNames(element, names);
    if (child == null) return '';
    final html = _innerFeedHtml(child);
    if (html.isNotEmpty) return html;
    return _normalizeText(child.innerText);
  }

  XmlElement? _firstChildByNames(XmlElement? element, Set<String> names) {
    if (element == null) return null;
    final normalized = names.map((name) => name.toLowerCase()).toSet();
    for (final child in element.childElements) {
      if (_matchesName(child, normalized)) return child;
    }
    for (final child in element.childElements) {
      final found = _firstDescendantByNames(child, normalized);
      if (found != null) return found;
    }
    return null;
  }

  XmlElement? _firstDescendantByName(XmlElement? element, String name) {
    return _firstDescendantByNames(element, {name.toLowerCase()});
  }

  XmlElement? _firstDescendantByNames(XmlElement? element, Set<String> names) {
    if (element == null) return null;
    if (_matchesName(element, names)) return element;
    for (final child in element.childElements) {
      final found = _firstDescendantByNames(child, names);
      if (found != null) return found;
    }
    return null;
  }

  List<XmlElement> _childrenByName(XmlElement element, String name) {
    final normalized = name.toLowerCase();
    return element.childElements
        .where((child) => _matchesName(child, {normalized}))
        .toList(growable: false);
  }

  List<XmlElement> _descendantsByNames(XmlElement element, Set<String> names) {
    final normalized = names.map((name) => name.toLowerCase()).toSet();
    final matches = <XmlElement>[];
    void visit(XmlElement current) {
      if (_matchesName(current, normalized)) matches.add(current);
      for (final child in current.childElements) {
        visit(child);
      }
    }

    visit(element);
    return matches;
  }

  bool _matchesName(XmlElement element, Set<String> names) {
    final local = element.name.local.toLowerCase();
    final qualified = element.name.qualified.toLowerCase();
    return names.contains(local) || names.contains(qualified);
  }

  String _innerFeedHtml(XmlElement element) {
    final buffer = StringBuffer();
    for (final node in element.children) {
      if (node is XmlCDATA) {
        buffer.write(node.value);
      } else if (node is XmlText) {
        buffer.write(node.value);
      } else {
        buffer.write(node.toXmlString());
      }
    }
    return buffer.toString().trim();
  }

  DateTime? _parseFeedDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.toLocal();
    final cleaned = value.replaceAll(
      RegExp(r'\s+GMT$', caseSensitive: false),
      ' +0000',
    );
    for (final pattern in const <String>[
      'EEE, dd MMM yyyy HH:mm:ss Z',
      'EEE, dd MMM yyyy HH:mm Z',
      'dd MMM yyyy HH:mm:ss Z',
      'dd MMM yyyy HH:mm Z',
    ]) {
      try {
        return DateFormat(pattern, 'en_US').parseUtc(cleaned).toLocal();
      } catch (_) {}
    }
    return null;
  }

  String _resolveUrl(Uri base, String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    try {
      return base.resolve(value).toString();
    } catch (_) {
      return value;
    }
  }

  String _normalizeText(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

class RssExtractedContent {
  const RssExtractedContent({
    required this.title,
    required this.contentHtml,
    required this.textLength,
  });

  final String title;
  final String contentHtml;
  final int textLength;
}

class RssFullContentExtractor {
  const RssFullContentExtractor({this.minimumTextLength = 40});

  final int minimumTextLength;

  RssExtractedContent? extract(String html) {
    final source = html.trim();
    if (source.isEmpty) return null;
    final document = html_parser.parse(source);
    _removeNoise(document);

    final title =
        document
            .querySelector('meta[property="og:title"]')
            ?.attributes['content']
            ?.trim() ??
        document.querySelector('title')?.text.trim() ??
        '';
    final candidates = _candidateElements(document);
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => _score(b).compareTo(_score(a)));
    final selected = candidates.first;
    final textLength = _normalizedText(selected).length;
    if (textLength < minimumTextLength) return null;
    return RssExtractedContent(
      title: title,
      contentHtml: selected.innerHtml.trim(),
      textLength: textLength,
    );
  }

  List<dom.Element> _candidateElements(dom.Document document) {
    final selectors = <String>[
      'article',
      'main',
      '[role="main"]',
      '.post-content',
      '.entry-content',
      '.article-content',
      '.article-body',
      '.content',
      '#content',
    ];
    final candidates = <dom.Element>[];
    final seen = <dom.Element>{};
    for (final selector in selectors) {
      for (final element in document.querySelectorAll(selector)) {
        if (seen.add(element)) candidates.add(element);
      }
    }
    final body = document.body;
    if (body != null && seen.add(body)) candidates.add(body);
    return candidates;
  }

  int _score(dom.Element element) {
    final text = _normalizedText(element);
    if (text.isEmpty) return 0;
    var score = text.length;
    score += element.querySelectorAll('p').length * 25;
    score += element.querySelectorAll('h1,h2,h3').length * 15;
    score += element.querySelectorAll('img').length * 8;
    final linkText = element
        .querySelectorAll('a')
        .map((link) => _normalizedText(link).length)
        .fold<int>(0, (sum, value) => sum + value);
    score -= (linkText * 0.7).round();
    final tag = element.localName?.toLowerCase();
    if (tag == 'article') score += 250;
    if (tag == 'main') score += 120;
    return score;
  }

  void _removeNoise(dom.Document document) {
    const selectors = <String>[
      'script',
      'style',
      'noscript',
      'iframe',
      'nav',
      'header',
      'footer',
      'form',
      'aside',
      '.sidebar',
      '.comments',
      '.comment',
      '.related',
      '.share',
      '.social',
      '.advertisement',
      '.ads',
      '[role="navigation"]',
      '[aria-hidden="true"]',
    ];
    for (final selector in selectors) {
      for (final node in document.querySelectorAll(selector).toList()) {
        node.remove();
      }
    }
  }
}

String _normalizedText(dom.Element element) {
  return element.text.replaceAll(RegExp(r'\s+'), ' ').trim();
}

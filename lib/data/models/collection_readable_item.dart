import 'attachment.dart';
import 'content_fingerprint.dart';
import 'local_memo.dart';
import 'memo_location.dart';
import 'rss_article.dart';
import 'rss_feed.dart';

enum CollectionReadableItemKind { memo, rssArticle }

abstract class CollectionReadableItem {
  const CollectionReadableItem();

  CollectionReadableItemKind get kind;
  String get uid;
  String get title;
  String get subtitle;
  String get content;
  DateTime get effectiveDisplayTime;
  DateTime get updateTime;
  String get contentFingerprint;
  List<Attachment> get attachments;
  MemoLocation? get location;
  bool get pinned => false;
  LocalMemo? get localMemo => null;
  RssArticle? get rssArticle => null;
  RssFeed? get rssFeed => null;
  String? get originalUrl => null;
  String? get savedMemoUid => null;
  bool get isRead => true;
}

class MemoCollectionReadableItem extends CollectionReadableItem {
  const MemoCollectionReadableItem(this.memo);

  final LocalMemo memo;

  @override
  CollectionReadableItemKind get kind => CollectionReadableItemKind.memo;

  @override
  String get uid => memo.uid;

  @override
  String get title => _firstLine(memo.content);

  @override
  String get subtitle => '';

  @override
  String get content => memo.content;

  @override
  DateTime get effectiveDisplayTime => memo.effectiveDisplayTime;

  @override
  DateTime get updateTime => memo.updateTime;

  @override
  String get contentFingerprint => memo.contentFingerprint;

  @override
  List<Attachment> get attachments => memo.attachments;

  @override
  MemoLocation? get location => memo.location;

  @override
  bool get pinned => memo.pinned;

  @override
  LocalMemo get localMemo => memo;
}

class RssCollectionReadableItem extends CollectionReadableItem {
  const RssCollectionReadableItem({required this.article, required this.feed});

  final RssArticle article;
  final RssFeed feed;

  @override
  CollectionReadableItemKind get kind => CollectionReadableItemKind.rssArticle;

  @override
  String get uid => 'rss:${article.id}';

  @override
  String get title {
    final articleTitle = article.title.trim();
    if (articleTitle.isNotEmpty) return articleTitle;
    return feed.displayTitle;
  }

  @override
  String get subtitle {
    final source = feed.displayTitle.trim();
    final author = article.author.trim();
    if (author.isNotEmpty && source.isNotEmpty) return '$source · $author';
    return author.isNotEmpty ? author : source;
  }

  @override
  String get content {
    final body = article.readableHtml.trim();
    final lead = article.leadImageUrl.trim();
    final parts = <String>[
      if (title.trim().isNotEmpty) '<h1>${_escapeHtml(title)}</h1>',
      if (subtitle.trim().isNotEmpty)
        '<p><em>${_escapeHtml(subtitle)}</em></p>',
      if (lead.isNotEmpty) '<p><img src="${_escapeHtmlAttribute(lead)}"></p>',
      if (body.isNotEmpty) body,
      if (article.link.trim().isNotEmpty)
        '<p><a href="${_escapeHtmlAttribute(article.link.trim())}">${_escapeHtml(article.link.trim())}</a></p>',
    ];
    return parts.join('\n');
  }

  @override
  DateTime get effectiveDisplayTime => article.effectiveDisplayTime;

  @override
  DateTime get updateTime => article.updatedTime;

  @override
  String get contentFingerprint => computeContentFingerprint(content);

  @override
  List<Attachment> get attachments => const <Attachment>[];

  @override
  MemoLocation? get location => null;

  @override
  RssArticle get rssArticle => article;

  @override
  RssFeed get rssFeed => feed;

  @override
  String? get originalUrl {
    final link = article.link.trim();
    return link.isEmpty ? null : link;
  }

  @override
  String? get savedMemoUid => article.savedMemoUid;

  @override
  bool get isRead => article.isRead;
}

String _firstLine(String value) {
  for (final line in value.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isNotEmpty) return trimmed;
  }
  return '';
}

String _escapeHtml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}

String _escapeHtmlAttribute(String value) {
  return _escapeHtml(value).replaceAll('"', '&quot;');
}

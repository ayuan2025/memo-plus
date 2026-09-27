final class MemoSearchDocumentBuilder {
  const MemoSearchDocumentBuilder._();

  static String build({
    required String content,
    String sourceName = '',
    String authorName = '',
    String sourceUrl = '',
  }) {
    final parts = <String>[
      content.trimRight(),
      sourceName.trim(),
      authorName.trim(),
    ];
    final normalizedUrl = sourceUrl.trim();
    if (normalizedUrl.isNotEmpty) {
      final parsed = Uri.tryParse(normalizedUrl);
      final host = (parsed?.host ?? '').trim().toLowerCase();
      final hostWithoutWww = host.startsWith('www.') ? host.substring(4) : host;
      if (host.isNotEmpty) {
        parts.add(host);
      }
      if (hostWithoutWww.isNotEmpty && hostWithoutWww != host) {
        parts.add(hostWithoutWww);
      }
      parts.add(normalizedUrl);
    }
    return parts.where((part) => part.trim().isNotEmpty).join('\n');
  }

  static String buildCanonical({
    required String content,
    String tagsText = '',
    String sourceName = '',
    String authorName = '',
    String sourceUrl = '',
  }) {
    final parts = <String>[
      build(
        content: content,
        sourceName: sourceName,
        authorName: authorName,
        sourceUrl: sourceUrl,
      ),
      ...splitTagsText(tagsText),
    ];
    return parts
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join('\n')
        .toLowerCase();
  }

  static List<String> splitTagsText(String tagsText) {
    if (tagsText.trim().isEmpty) return const [];
    return tagsText
        .split(' ')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList(growable: false);
  }
}

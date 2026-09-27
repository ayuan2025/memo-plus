final class MemoSearchMatcher {
  const MemoSearchMatcher._();

  static String normalizeQuery(String? raw) {
    return (raw ?? '').trim();
  }

  static bool matchesText({required String text, required String query}) {
    final normalizedQuery = normalizeQuery(query);
    if (normalizedQuery.isEmpty) return true;
    return text.toLowerCase().contains(normalizedQuery.toLowerCase());
  }

  static String toSqlLikePattern(String query) {
    final normalizedQuery = normalizeQuery(query);
    final escaped = normalizedQuery
        .replaceAll('\\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    return '%$escaped%';
  }
}

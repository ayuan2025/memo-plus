import '../share_clip_models.dart';

bool isUnknownUrlSchemeBrowserErrorPage({
  String? pageTitle,
  String? articleTitle,
  String? textContent,
  String? contentHtml,
  String? error,
  Uri? finalUrl,
  Uri? attemptedUrl,
}) {
  final combined = [
    pageTitle,
    articleTitle,
    textContent,
    contentHtml,
    error,
  ].map((value) => value ?? '').join('\n').toLowerCase();
  if (!combined.contains('err_unknown_url_scheme') &&
      !combined.contains('unknown url scheme')) {
    return false;
  }

  final hasBrowserErrorShape =
      combined.contains('net::') ||
      combined.contains('webpage not available') ||
      combined.contains('web page not available') ||
      combined.contains('this webpage is not available') ||
      combined.contains('this site can') ||
      combined.contains('page cannot be loaded') ||
      combined.contains('网页无法打开') ||
      combined.contains('无法加载');
  if (hasBrowserErrorShape) return true;

  return _isNonHttpUrl(finalUrl) || _isNonHttpUrl(attemptedUrl);
}

bool _isNonHttpUrl(Uri? uri) {
  if (uri == null) return false;
  final scheme = normalizeShareText(uri.scheme.toLowerCase());
  if (scheme == null) return false;
  return scheme != 'http' && scheme != 'https';
}

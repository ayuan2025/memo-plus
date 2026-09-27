import 'dart:convert';

import 'package:charset/charset.dart';
import 'package:dio/dio.dart';

class RssHttpResponse {
  const RssHttpResponse({
    required this.body,
    required this.statusCode,
    this.headers = const <String, String>{},
  });

  factory RssHttpResponse.fromBytes({
    required List<int> bodyBytes,
    required int statusCode,
    Map<String, String> headers = const <String, String>{},
  }) {
    final normalizedHeaders = normalizeRssHttpHeaders(headers);
    return RssHttpResponse(
      body: decodeRssHttpBody(bodyBytes, normalizedHeaders),
      statusCode: statusCode,
      headers: normalizedHeaders,
    );
  }

  final String body;
  final int statusCode;
  final Map<String, String> headers;

  String header(String name) => headers[name.toLowerCase()] ?? '';
}

typedef RssHttpFetcher =
    Future<RssHttpResponse> Function(Uri uri, {Map<String, String>? headers});

Future<RssHttpResponse> defaultRssHttpFetch(
  Uri uri, {
  Map<String, String>? headers,
  Duration timeout = const Duration(seconds: 15),
  int maxRedirects = 5,
}) async {
  final dio = Dio(
    BaseOptions(
      followRedirects: true,
      maxRedirects: maxRedirects,
      responseType: ResponseType.bytes,
      validateStatus: (_) => true,
      connectTimeout: timeout,
      receiveTimeout: timeout,
      sendTimeout: timeout,
    ),
  );
  final response = await dio.getUri<List<int>>(
    uri,
    options: Options(headers: headers),
  );
  final normalizedHeaders = <String, String>{};
  for (final entry in response.headers.map.entries) {
    if (entry.value.isEmpty) continue;
    normalizedHeaders[entry.key.toLowerCase()] = entry.value.first;
  }
  return RssHttpResponse.fromBytes(
    bodyBytes: response.data ?? const <int>[],
    statusCode: response.statusCode ?? 0,
    headers: normalizedHeaders,
  );
}

Map<String, String> normalizeRssHttpHeaders(Map<String, String> headers) {
  return <String, String>{
    for (final entry in headers.entries) entry.key.toLowerCase(): entry.value,
  };
}

String decodeRssHttpBody(List<int> bytes, Map<String, String> headers) {
  if (bytes.isEmpty) return '';

  final bomEncoding = Charset.detect(
    bytes,
    orders: const <Encoding>[],
    utf8BOM: true,
  );
  if (bomEncoding != null) {
    return bomEncoding.decode(bytes);
  }

  final declaredName =
      _charsetFromContentType(headers['content-type'] ?? '') ??
      _charsetFromXmlDeclaration(bytes);
  final declaredEncoding = declaredName == null
      ? null
      : Charset.getByName(declaredName);
  if (declaredEncoding != null) {
    return declaredEncoding.decode(bytes);
  }

  try {
    return utf8.decode(bytes);
  } on FormatException {
    final detected = Charset.detect(bytes);
    if (detected != null) {
      return detected.decode(bytes);
    }
    return utf8.decode(bytes, allowMalformed: true);
  }
}

String? _charsetFromContentType(String value) {
  final match = RegExp(
    r'charset\s*=\s*"?([^";\s]+)',
    caseSensitive: false,
  ).firstMatch(value);
  return match?.group(1)?.trim();
}

String? _charsetFromXmlDeclaration(List<int> bytes) {
  final prefixLength = bytes.length < 512 ? bytes.length : 512;
  final prefix = latin1.decode(bytes.take(prefixLength).toList());
  final match = RegExp(
    r'<\?xml[^>]*encoding\s*=\s*["'
    ']([^"'
    ']+)["'
    ']',
    caseSensitive: false,
  ).firstMatch(prefix);
  return match?.group(1)?.trim();
}

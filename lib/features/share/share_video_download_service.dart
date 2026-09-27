import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path/path.dart' as p;

import '../../core/debug_ephemeral_storage.dart';
import 'parsers/share_page_parser.dart';
import 'share_clip_models.dart';

const int kShareVideoAttachmentLimitBytes = 30 * 1024 * 1024;
const int kShareVideoCompressionTargetBytes = 29 * 1024 * 1024;

@immutable
class ShareVideoDownloadResult {
  const ShareVideoDownloadResult({
    required this.filePath,
    required this.fileSize,
    required this.headers,
  });

  final String filePath;
  final int fileSize;
  final Map<String, String> headers;
}

@immutable
class ShareVideoProbeResult {
  const ShareVideoProbeResult({
    required this.headers,
    this.contentLength,
    this.mimeType,
  });

  final Map<String, String> headers;
  final int? contentLength;
  final String? mimeType;
}

@immutable
class ShareVideoHttpProbeResult {
  const ShareVideoHttpProbeResult({this.contentLength, this.mimeType});

  final int? contentLength;
  final String? mimeType;
}

abstract class ShareVideoHttpClient {
  Future<void> download(
    String url,
    String savePath, {
    required Map<String, String> headers,
    ValueChanged<double>? onProgress,
  });

  Future<ShareVideoHttpProbeResult> probe(
    String url, {
    required Map<String, String> headers,
  });
}

class DioShareVideoHttpClient implements ShareVideoHttpClient {
  DioShareVideoHttpClient({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  @override
  Future<void> download(
    String url,
    String savePath, {
    required Map<String, String> headers,
    ValueChanged<double>? onProgress,
  }) async {
    await _dio.download(
      url,
      savePath,
      options: Options(
        headers: headers,
        responseType: ResponseType.stream,
        validateStatus: (status) => status != null && status >= 200 && status < 400,
        followRedirects: true,
      ),
      onReceiveProgress: (received, total) {
        if (onProgress == null || total <= 0) return;
        onProgress(received / total);
      },
    );
  }

  @override
  Future<ShareVideoHttpProbeResult> probe(
    String url, {
    required Map<String, String> headers,
  }) async {
    final headResult = await _probeHead(url, headers: headers);
    if (headResult != null &&
        (headResult.contentLength != null || headResult.mimeType != null)) {
      return headResult;
    }
    final rangeResult = await _probeRange(url, headers: headers);
    if (rangeResult != null) {
      return ShareVideoHttpProbeResult(
        contentLength: rangeResult.contentLength ?? headResult?.contentLength,
        mimeType: rangeResult.mimeType ?? headResult?.mimeType,
      );
    }
    return headResult ?? const ShareVideoHttpProbeResult();
  }

  Future<ShareVideoHttpProbeResult?> _probeHead(
    String url, {
    required Map<String, String> headers,
  }) async {
    try {
      final response = await _dio.request<void>(
        url,
        options: Options(
          method: 'HEAD',
          headers: headers,
          responseType: ResponseType.plain,
          validateStatus: (status) => status != null && status >= 200 && status < 400,
          followRedirects: true,
        ),
      );
      return _buildProbeResult(response.headers.map);
    } catch (_) {
      return null;
    }
  }

  Future<ShareVideoHttpProbeResult?> _probeRange(
    String url, {
    required Map<String, String> headers,
  }) async {
    try {
      final response = await _dio.get<void>(
        url,
        options: Options(
          headers: <String, String>{...headers, 'Range': 'bytes=0-0'},
          responseType: ResponseType.stream,
          validateStatus: (status) => status != null && status >= 200 && status < 400,
          followRedirects: true,
        ),
      );
      return _buildProbeResult(response.headers.map);
    } catch (_) {
      return null;
    }
  }

  ShareVideoHttpProbeResult _buildProbeResult(Map<String, List<String>> headers) {
    final mimeType = _firstHeader(headers, Headers.contentTypeHeader)
        ?.split(';')
        .first
        .trim();
    return ShareVideoHttpProbeResult(
      contentLength: _parseContentLength(headers),
      mimeType: normalizeShareText(mimeType),
    );
  }

  int? _parseContentLength(Map<String, List<String>> headers) {
    final contentLength = _firstHeader(headers, Headers.contentLengthHeader);
    final parsedLength = int.tryParse(contentLength ?? '');
    if (parsedLength != null && parsedLength > 0) {
      return parsedLength;
    }
    final contentRange = _firstHeader(headers, 'content-range');
    if (contentRange == null) return null;
    final match = RegExp(r'/([0-9]+)$').firstMatch(contentRange);
    return int.tryParse(match?.group(1) ?? '');
  }

  String? _firstHeader(Map<String, List<String>> headers, String key) {
    final values = headers[key.toLowerCase()] ?? headers[key] ?? const <String>[];
    for (final value in values) {
      final normalized = normalizeShareText(value);
      if (normalized != null) {
        return normalized;
      }
    }
    return null;
  }
}

class ShareVideoDownloadService {
  ShareVideoDownloadService({
    ShareVideoHttpClient? client,
    Future<Directory> Function()? resolveDirectory,
    Future<String?> Function(Uri scope)? readCookieHeader,
  }) : _client = client ?? DioShareVideoHttpClient(),
       _resolveDirectory = resolveDirectory ?? _defaultResolveDirectory,
       _readCookieHeader = readCookieHeader ?? _defaultReadCookieHeader;

  final ShareVideoHttpClient _client;
  final Future<Directory> Function() _resolveDirectory;
  final Future<String?> Function(Uri scope) _readCookieHeader;

  Future<ShareVideoDownloadResult> download({
    required ShareCaptureResult result,
    required ShareVideoCandidate candidate,
    ValueChanged<double>? onProgress,
  }) async {
    final directory = await _resolveDirectory();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final fileName = _buildSafeFileName(candidate, result);
    final savePath = p.join(directory.path, fileName);
    final targetFile = File(savePath);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }

    final headers = await buildRequestHeaders(result: result, candidate: candidate);
    await _client.download(
      candidate.url,
      savePath,
      headers: headers,
      onProgress: onProgress,
    );

    if (!await targetFile.exists()) {
      throw const FileSystemException('Downloaded video file is missing.');
    }
    final fileSize = await targetFile.length();
    if (fileSize <= 0) {
      try {
        await targetFile.delete();
      } catch (_) {}
      throw const FileSystemException('Downloaded video file is empty.');
    }

    return ShareVideoDownloadResult(
      filePath: savePath,
      fileSize: fileSize,
      headers: headers,
    );
  }

  Future<ShareVideoProbeResult> probe({
    required ShareCaptureResult result,
    required ShareVideoCandidate candidate,
  }) async {
    final headers = await buildRequestHeaders(result: result, candidate: candidate);
    final probe = await _client.probe(candidate.url, headers: headers);
    return ShareVideoProbeResult(
      headers: headers,
      contentLength: probe.contentLength,
      mimeType: normalizeShareText(probe.mimeType) ?? normalizeShareText(candidate.mimeType),
    );
  }

  Future<Map<String, String>> buildRequestHeaders({
    required ShareCaptureResult result,
    required ShareVideoCandidate candidate,
  }) async {
    final referer = normalizeShareText(candidate.referer) ?? result.finalUrl.toString();
    final headers = <String, String>{
      'Referer': referer,
      if (normalizeShareText(result.pageUserAgent) != null)
        'User-Agent': result.pageUserAgent!,
    };
    if (candidate.headers != null) {
      headers.addAll(candidate.headers!);
    }
    final cookieScope = Uri.tryParse(
      candidate.cookieUrl ?? candidate.url,
    ) ?? result.finalUrl;
    final cookieHeader = await _readCookieHeader(cookieScope);
    if (normalizeShareText(cookieHeader) != null && !headers.containsKey('Cookie')) {
      headers['Cookie'] = cookieHeader!;
    }
    return headers;
  }

  static Future<Directory> _defaultResolveDirectory() async {
    final root = await resolveAppSupportDirectory();
    return Directory(p.join(root.path, 'share_media_cache'));
  }

  static Future<String?> _defaultReadCookieHeader(Uri scope) async {
    try {
      final cookies = await CookieManager.instance().getCookies(
        url: WebUri(scope.toString()),
      );
      if (cookies.isEmpty) return null;
      return cookies
          .map((item) => '${item.name}=${item.value ?? ''}')
          .join('; ');
    } catch (_) {
      return null;
    }
  }

  String _buildSafeFileName(
    ShareVideoCandidate candidate,
    ShareCaptureResult result,
  ) {
    final baseName = normalizeShareText(candidate.title) ??
        normalizeShareText(result.articleTitle) ??
        normalizeShareText(result.pageTitle) ??
        fileNameFromUrl(candidate.url) ??
        'shared-video';
    final sanitized = baseName.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
    final extension = _resolveExtension(candidate.url, candidate.mimeType);
    return '${sanitized}_${DateTime.now().millisecondsSinceEpoch}$extension';
  }

  String _resolveExtension(String url, String? mimeType) {
    final lowerUrl = url.toLowerCase();
    for (final ext in const ['.mp4', '.webm', '.mov', '.m4v', '.mkv', '.avi']) {
      if (lowerUrl.contains(ext)) return ext;
    }
    final lowerMime = (mimeType ?? '').toLowerCase();
    if (lowerMime.contains('webm')) return '.webm';
    if (lowerMime.contains('quicktime')) return '.mov';
    return '.mp4';
  }
}




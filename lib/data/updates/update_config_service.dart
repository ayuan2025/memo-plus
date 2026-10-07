import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/app_links.dart';
import 'update_config.dart';

const Duration kUpdateConfigTimeout = Duration(seconds: 3);

/// memo+ 改版：更新源指向 GitHub Releases。
///
/// 上游 memoflow 的 latest.json 发布的是上游 APK，与本包
/// （com.memoflow.hzc073.pro，Debug 签名）签名不一致，弹窗引导只会装失败；
/// 且更新文案属于上游版本线，对改版没有意义。所以改成读 GitHub Releases 上的
/// latest.json：发布新 release 时把该文件（含各语言副本 `latest.<locale>.json`）
/// 与 APK 一起作为附件上传，「检查更新」就会提示。`releases/latest/download/`
/// 永远指向最新 release，地址稳定。
///
/// 列表是**按序回退**：GitHub 仓库尚未创建（或某次网络失败）时，落到旧的自建
/// 发布页兜底，保证「检查更新」不会彻底断粮。仓库稳定发布后可移除兜底项。
///
/// 注意 URL 用 ASCII 文件名（memo-plus-v1057.apk），中文名在部分网络与
/// 浏览器上会被转义成 %xx 导致 404。
const List<String> kUpdateConfigUrls = <String>[
  '${MemoPlusLinks.updateConfigBaseUrl}/latest.json',
  // 兜底：GitHub 仓库建好并完成首次发布前，检查更新仍走自建发布页。
  'https://memo-plus-apk.app.workbuddy.host/latest.json',
];

const List<String> kPreviewUpdateConfigUrls = <String>[];
const String kUpdateConfigFallbackLocale = 'en';
const Set<String> kSupportedUpdateConfigLocales = {
  'zh-Hans',
  'zh-Hant-TW',
  'en',
  'ja',
  'de',
  'pt-BR',
  'ko',
};

enum UpdateConfigSourceType { production, preview, customUrl, localJson }

class UpdateConfigSource {
  const UpdateConfigSource._({required this.type, this.url, this.jsonText});

  const UpdateConfigSource.production()
    : this._(type: UpdateConfigSourceType.production);

  const UpdateConfigSource.preview()
    : this._(type: UpdateConfigSourceType.preview);

  const UpdateConfigSource.customUrl(String url)
    : this._(type: UpdateConfigSourceType.customUrl, url: url);

  const UpdateConfigSource.localJson(String jsonText)
    : this._(type: UpdateConfigSourceType.localJson, jsonText: jsonText);

  final UpdateConfigSourceType type;
  final String? url;
  final String? jsonText;
}

class UpdateConfigService {
  UpdateConfigService({
    Dio? dio,
    List<String>? configUrls,
    List<String>? previewConfigUrls,
  }) : _dio = dio ?? Dio(),
       _configUrls = configUrls ?? kUpdateConfigUrls,
       _previewConfigUrls = previewConfigUrls ?? kPreviewUpdateConfigUrls;

  final Dio _dio;
  final List<String> _configUrls;
  final List<String> _previewConfigUrls;

  Future<UpdateAnnouncementConfig?> fetchLatest({
    Duration timeout = kUpdateConfigTimeout,
    UpdateConfigSource source = const UpdateConfigSource.production(),
    String localeTag = '',
  }) async {
    final expectedLocale = normalizeUpdateConfigLocaleTag(localeTag);
    if (source.type == UpdateConfigSourceType.localJson) {
      return _parseConfig(
        source.jsonText ?? '',
        expectedLocale: expectedLocale,
        allowUndeclaredLocale: true,
      );
    }

    final urls = switch (source.type) {
      UpdateConfigSourceType.production => _configUrls,
      UpdateConfigSourceType.preview => _previewConfigUrls,
      UpdateConfigSourceType.customUrl => [source.url ?? ''],
      UpdateConfigSourceType.localJson => const <String>[],
    };

    if (source.type == UpdateConfigSourceType.production ||
        source.type == UpdateConfigSourceType.preview) {
      for (final attempt in _localizedFetchPlan(urls, expectedLocale)) {
        final config = await _fetchFromUrl(
          attempt.url,
          timeout: timeout,
          expectedLocale: attempt.expectedLocale,
          allowUndeclaredLocale: attempt.allowUndeclaredLocale,
        );
        if (config != null) return config;
      }
      return null;
    }

    for (final url in urls) {
      final trimmed = url.trim();
      if (trimmed.isEmpty) continue;
      final config = await _fetchFromUrl(
        trimmed,
        timeout: timeout,
        expectedLocale: expectedLocale,
        allowUndeclaredLocale: true,
      );
      if (config != null) return config;
    }
    return null;
  }

  Future<UpdateAnnouncementConfig?> _fetchFromUrl(
    String url, {
    required Duration timeout,
    required String expectedLocale,
    required bool allowUndeclaredLocale,
  }) async {
    try {
      _dio.options
        ..connectTimeout = timeout
        ..sendTimeout = timeout
        ..receiveTimeout = timeout;
      final response = await _dio.get<dynamic>(
        url,
        options: Options(
          responseType: ResponseType.json,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 300,
        ),
      );
      final data = response.data;
      return _parseDecodedConfig(
        data,
        expectedLocale: expectedLocale,
        allowUndeclaredLocale: allowUndeclaredLocale,
      );
    } on DioException {
      return null;
    } on FormatException {
      return null;
    }
  }

  UpdateAnnouncementConfig? _parseConfig(
    String raw, {
    required String expectedLocale,
    required bool allowUndeclaredLocale,
  }) {
    try {
      return _parseDecodedConfig(
        jsonDecode(raw),
        expectedLocale: expectedLocale,
        allowUndeclaredLocale: allowUndeclaredLocale,
      );
    } on FormatException {
      return null;
    }
  }

  UpdateAnnouncementConfig? _parseDecodedConfig(
    dynamic data, {
    required String expectedLocale,
    required bool allowUndeclaredLocale,
  }) {
    final decoded = data is String ? jsonDecode(data) : data;
    if (decoded is Map) {
      final config = UpdateAnnouncementConfig.fromJson(
        decoded.cast<String, dynamic>(),
      );
      return _acceptsConfigLocale(
            config,
            expectedLocale: expectedLocale,
            allowUndeclaredLocale: allowUndeclaredLocale,
          )
          ? config
          : null;
    }
    return null;
  }

  List<_UpdateConfigFetchAttempt> _localizedFetchPlan(
    List<String> urls,
    String expectedLocale,
  ) {
    if (expectedLocale.isEmpty) {
      return [
        for (final url in urls)
          _UpdateConfigFetchAttempt(
            url: url,
            expectedLocale: '',
            allowUndeclaredLocale: true,
          ),
      ];
    }

    final attempts = <_UpdateConfigFetchAttempt>[];
    final seen = <String>{};
    void add(String url, String locale, bool allowUndeclaredLocale) {
      final trimmed = url.trim();
      if (trimmed.isEmpty ||
          !seen.add('$trimmed|$locale|$allowUndeclaredLocale')) {
        return;
      }
      attempts.add(
        _UpdateConfigFetchAttempt(
          url: trimmed,
          expectedLocale: locale,
          allowUndeclaredLocale: allowUndeclaredLocale,
        ),
      );
    }

    for (final url in urls) {
      add(_localizedConfigUrl(url, expectedLocale), expectedLocale, false);
    }
    if (expectedLocale != kUpdateConfigFallbackLocale) {
      for (final url in urls) {
        add(
          _localizedConfigUrl(url, kUpdateConfigFallbackLocale),
          kUpdateConfigFallbackLocale,
          false,
        );
      }
    }
    for (final url in urls) {
      add(url, '', true);
    }
    return attempts;
  }
}

class _UpdateConfigFetchAttempt {
  const _UpdateConfigFetchAttempt({
    required this.url,
    required this.expectedLocale,
    required this.allowUndeclaredLocale,
  });

  final String url;
  final String expectedLocale;
  final bool allowUndeclaredLocale;
}

String normalizeUpdateConfigLocaleTag(String localeTag) {
  final normalized = localeTag.trim().replaceAll('_', '-').toLowerCase();
  if (normalized.isEmpty) return '';
  final resolved = switch (normalized) {
    'zh' || 'zh-cn' || 'zh-sg' || 'zh-hans' => 'zh-Hans',
    'zh-tw' || 'zh-hk' || 'zh-mo' || 'zh-hant' || 'zh-hant-tw' => 'zh-Hant-TW',
    'en' || 'en-us' || 'en-gb' => 'en',
    'ja' => 'ja',
    'de' => 'de',
    'pt' || 'pt-br' => 'pt-BR',
    'ko' => 'ko',
    _ => '',
  };
  return kSupportedUpdateConfigLocales.contains(resolved) ? resolved : '';
}

String _localizedConfigUrl(String url, String localeTag) {
  final locale = normalizeUpdateConfigLocaleTag(localeTag);
  if (locale.isEmpty) return url;
  final uri = Uri.tryParse(url);
  if (uri != null && uri.pathSegments.isNotEmpty) {
    final segments = [...uri.pathSegments];
    segments[segments.length - 1] = _localizedFilename(segments.last, locale);
    return uri.replace(pathSegments: segments).toString();
  }
  return url.replaceFirst(RegExp(r'\.json($|\?)'), '.$locale.json');
}

String _localizedFilename(String filename, String locale) {
  if (!filename.endsWith('.json')) return filename;
  return '${filename.substring(0, filename.length - 5)}.$locale.json';
}

bool _acceptsConfigLocale(
  UpdateAnnouncementConfig config, {
  required String expectedLocale,
  required bool allowUndeclaredLocale,
}) {
  final declared = normalizeUpdateConfigLocaleTag(config.locale);
  if (expectedLocale.isEmpty) return true;
  if (declared.isEmpty) return allowUndeclaredLocale;
  return declared == expectedLocale;
}

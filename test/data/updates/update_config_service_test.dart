import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/updates/update_config_service.dart';

void main() {
  group('UpdateConfigService sources', () {
    test('production source uses production URLs by default', () async {
      final adapter = _FakeHttpClientAdapter([
        _FakeResponse(_configJson(version: '1.0.1')),
      ]);
      final service = UpdateConfigService(
        dio: _dioWith(adapter),
        configUrls: const ['https://prod.example/latest.json'],
        previewConfigUrls: const ['https://preview.example/latest.json'],
      );

      final config = await service.fetchLatest();

      expect(config?.versionInfo.latestVersion, '1.0.1');
      expect(adapter.requestedUrls, ['https://prod.example/latest.json']);
    });

    test('preview source uses preview URLs explicitly', () async {
      final adapter = _FakeHttpClientAdapter([
        _FakeResponse(_configJson(version: '1.0.2')),
      ]);
      final service = UpdateConfigService(
        dio: _dioWith(adapter),
        configUrls: const ['https://prod.example/latest.json'],
        previewConfigUrls: const ['https://preview.example/latest.json'],
      );

      final config = await service.fetchLatest(
        source: const UpdateConfigSource.preview(),
      );

      expect(config?.versionInfo.latestVersion, '1.0.2');
      expect(adapter.requestedUrls, ['https://preview.example/latest.json']);
    });

    test('custom URL source fetches only the requested URL', () async {
      final adapter = _FakeHttpClientAdapter([
        _FakeResponse(_configJson(version: '1.0.3')),
      ]);
      final service = UpdateConfigService(
        dio: _dioWith(adapter),
        configUrls: const ['https://prod.example/latest.json'],
        previewConfigUrls: const ['https://preview.example/latest.json'],
      );

      final config = await service.fetchLatest(
        source: const UpdateConfigSource.customUrl(
          'https://custom.example/config.json',
        ),
      );

      expect(config?.versionInfo.latestVersion, '1.0.3');
      expect(adapter.requestedUrls, ['https://custom.example/config.json']);
    });

    test('local JSON source parses without network requests', () async {
      final adapter = _FakeHttpClientAdapter([]);
      final service = UpdateConfigService(dio: _dioWith(adapter));

      final config = await service.fetchLatest(
        source: UpdateConfigSource.localJson(_configJson(version: '1.0.4')),
      );

      expect(config?.versionInfo.latestVersion, '1.0.4');
      expect(adapter.requestedUrls, isEmpty);
    });

    test(
      'invalid preview config returns null without production fallback',
      () async {
        final adapter = _FakeHttpClientAdapter([
          const _FakeResponse('{not-json'),
        ]);
        final service = UpdateConfigService(
          dio: _dioWith(adapter),
          configUrls: const ['https://prod.example/latest.json'],
          previewConfigUrls: const ['https://preview.example/latest.json'],
        );

        final config = await service.fetchLatest(
          source: const UpdateConfigSource.preview(),
        );

        expect(config, isNull);
        expect(adapter.requestedUrls, ['https://preview.example/latest.json']);
      },
    );

    test('localized production source falls back to English config', () async {
      final adapter = _FakeHttpClientAdapter([
        const _FakeResponse('', statusCode: 404),
        _FakeResponse(_configJson(version: '1.0.5', locale: 'en')),
      ]);
      final service = UpdateConfigService(
        dio: _dioWith(adapter),
        configUrls: const ['https://prod.example/update/latest.json'],
        previewConfigUrls: const ['https://preview.example/update/latest.json'],
      );

      final config = await service.fetchLatest(localeTag: 'de');

      expect(config?.versionInfo.latestVersion, '1.0.5');
      expect(config?.locale, 'en');
      expect(adapter.requestedUrls, [
        'https://prod.example/update/latest.de.json',
        'https://prod.example/update/latest.en.json',
      ]);
    });

    test('locale config with mismatched marker is rejected', () async {
      final service = UpdateConfigService();

      final config = await service.fetchLatest(
        localeTag: 'en',
        source: UpdateConfigSource.localJson(
          _configJson(version: '1.0.6', locale: 'de'),
        ),
      );

      expect(config, isNull);
    });
  });
}

Dio _dioWith(HttpClientAdapter adapter) {
  return Dio()..httpClientAdapter = adapter;
}

String _configJson({required String version, String locale = ''}) {
  final localeFields = locale.isEmpty
      ? ''
      : '''
  "schema_version": 3,
  "locale": "$locale",
  "fallback_locale": "en",
''';
  return '''
{
$localeFields
  ${localeFields.isEmpty ? '"schema_version": 2,' : ''}
  "version_info": {
    "latest_version": "$version"
  },
  "announcement": {
    "id": 1,
    "title": "Release",
    "contents": ["Line"]
  }
}
''';
}

class _FakeResponse {
  const _FakeResponse(this.body, {this.statusCode = 200});

  final String body;
  final int statusCode;
}

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this._responses);

  final List<_FakeResponse> _responses;
  final requestedUrls = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestedUrls.add(options.uri.toString());
    if (_responses.isEmpty) {
      return ResponseBody.fromString('', 404);
    }
    final response = _responses.removeAt(0);
    return ResponseBody.fromString(
      response.body,
      response.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

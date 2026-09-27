import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/api/memo_api_facade.dart';
import 'package:memos_flutter_app/data/api/memo_api_version.dart';

void main() {
  group('MemoApiFacade personal access token route compatibility', () {
    test('0.26 keeps numeric user resource names', () async {
      final harness = await _FakePatServer.start(MemoApiVersion.v026);
      addTearDown(() async {
        await harness.close();
      });

      final api = MemoApiFacade.authenticated(
        baseUrl: harness.baseUrl,
        personalAccessToken: 'test-pat',
        version: MemoApiVersion.v026,
      );

      final tokens = await api.listPersonalAccessTokens(userName: 'users/1');
      expect(tokens, hasLength(1));

      final created = await api.createPersonalAccessToken(
        userName: 'users/1',
        description: 'MemoFlow test token',
        expiresInDays: 0,
      );
      expect(created.token, 'memos_pat_created');

      expect(
        harness.findRequest(
          method: 'GET',
          path: '/api/v1/users/1/personalAccessTokens',
        ),
        isNotNull,
      );
      expect(
        harness.findRequest(
          method: 'POST',
          path: '/api/v1/users/1/personalAccessTokens',
        ),
        isNotNull,
      );
      expect(
        harness.findRequest(method: 'GET', path: '/api/v1/auth/me'),
        isNull,
      );
    });

    test('0.27 resolves username user resource names', () async {
      final harness = await _FakePatServer.start(MemoApiVersion.v027);
      addTearDown(() async {
        await harness.close();
      });

      final api = MemoApiFacade.authenticated(
        baseUrl: harness.baseUrl,
        personalAccessToken: 'test-pat',
        version: MemoApiVersion.v027,
      );

      final tokens = await api.listPersonalAccessTokens(userName: 'users/1');
      expect(tokens, hasLength(1));
      expect(
        tokens.single.name,
        'users/demo/personalAccessTokens/existing-token',
      );

      final created = await api.createPersonalAccessToken(
        userName: 'users/1',
        description: 'MemoFlow test token',
        expiresInDays: 0,
      );
      expect(
        created.personalAccessToken.name,
        'users/demo/personalAccessTokens/created-token',
      );
      expect(created.token, 'memos_pat_created');

      expect(
        harness.findRequest(method: 'GET', path: '/api/v1/auth/me'),
        isNotNull,
      );
      expect(
        harness.findRequest(
          method: 'GET',
          path: '/api/v1/users/demo/personalAccessTokens',
        ),
        isNotNull,
      );
      expect(
        harness.findRequest(
          method: 'POST',
          path: '/api/v1/users/demo/personalAccessTokens',
        ),
        isNotNull,
      );
    });
  });
}

class _CapturedRequest {
  const _CapturedRequest({required this.method, required this.path});

  final String method;
  final String path;
}

class _FakePatServer {
  _FakePatServer._(this.version, this._server);

  final MemoApiVersion version;
  final HttpServer _server;
  final List<_CapturedRequest> requests = <_CapturedRequest>[];

  Uri get baseUrl => Uri.parse('http://127.0.0.1:${_server.port}');

  static Future<_FakePatServer> start(MemoApiVersion version) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final harness = _FakePatServer._(version, server);
    server.listen(harness._handleRequest);
    return harness;
  }

  _CapturedRequest? findRequest({
    required String method,
    required String path,
  }) {
    for (final request in requests) {
      if (request.method == method && request.path == path) {
        return request;
      }
    }
    return null;
  }

  Future<void> close() async {
    await _server.close(force: true);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    await utf8.decoder.bind(request).join();
    requests.add(
      _CapturedRequest(method: request.method, path: request.uri.path),
    );

    final userName = version == MemoApiVersion.v027 ? 'users/demo' : 'users/1';
    final patPath = version == MemoApiVersion.v027
        ? '/api/v1/users/demo/personalAccessTokens'
        : '/api/v1/users/1/personalAccessTokens';

    if (request.method == 'GET' && request.uri.path == '/api/v1/auth/me') {
      await _writeJson(request.response, <String, Object?>{
        'user': <String, Object?>{
          'name': userName,
          'username': 'demo',
          'displayName': 'Demo User',
          'avatarUrl': '',
          'description': '',
        },
      });
      return;
    }

    if (request.method == 'GET' && request.uri.path == patPath) {
      await _writeJson(request.response, <String, Object?>{
        'personalAccessTokens': <Object?>[
          <String, Object?>{
            'name': '$userName/personalAccessTokens/existing-token',
            'description': 'Existing token',
            'createdAt': '2026-04-18T12:00:00Z',
          },
        ],
      });
      return;
    }

    if (request.method == 'POST' && request.uri.path == patPath) {
      await _writeJson(request.response, <String, Object?>{
        'token': 'memos_pat_created',
        'personalAccessToken': <String, Object?>{
          'name': '$userName/personalAccessTokens/created-token',
          'description': 'MemoFlow test token',
          'createdAt': '2026-04-18T12:00:00Z',
        },
      });
      return;
    }

    await _writeJson(request.response, <String, Object?>{
      'error': 'Unhandled test route',
      'method': request.method,
      'path': request.uri.path,
    }, statusCode: HttpStatus.notFound);
  }
}

Future<void> _writeJson(
  HttpResponse response,
  Object payload, {
  int statusCode = HttpStatus.ok,
}) async {
  response.statusCode = statusCode;
  response.headers.contentType = ContentType.json;
  response.write(jsonEncode(payload));
  await response.close();
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/api/memo_api_facade.dart';
import 'package:memos_flutter_app/data/api/memo_api_version.dart';
import 'package:memos_flutter_app/data/api/password_sign_in_api.dart';

const Set<String> _allCurrentUserEndpoints = <String>{
  'GET /api/v1/auth/sessions/current',
  'GET /api/v1/auth/me',
  'POST /api/v1/auth/status',
  'GET /api/v1/auth/status',
  'POST /api/v2/auth/status',
  'GET /api/v1/user/me',
  'GET /api/v1/users/me',
  'GET /api/user/me',
};
const String _v027AmpersandTag = 'science&tech';
const String _v027EmojiTag = 'watch\u{1F441}\uFE0F';

void main() {
  group('MemoApiVersion 0.28/0.29 support', () {
    test('parses and normalizes 0.28 versions', () {
      expect(parseMemoApiVersion('0.28'), MemoApiVersion.v028);
      expect(parseMemoApiVersion('0.28.0'), MemoApiVersion.v028);
      expect(parseMemoApiVersion('0.28.7'), MemoApiVersion.v028);
      expect(normalizeMemoApiVersion(' 0.28 '), '0.28.0');
      expect(MemoApiVersion.v028.label, 'v0.28.0');
    });

    test('parses and normalizes 0.29 versions', () {
      expect(parseMemoApiVersion('0.29'), MemoApiVersion.v029);
      expect(parseMemoApiVersion('0.29.0'), MemoApiVersion.v029);
      expect(parseMemoApiVersion('0.29.7'), MemoApiVersion.v029);
      expect(normalizeMemoApiVersion(' 0.29 '), '0.29.0');
      expect(MemoApiVersion.v029.label, 'v0.29.0');
    });

    test('includes 0.29.0 in probe order as the newest version', () {
      expect(kMemoApiVersionsProbeOrder.last, MemoApiVersion.v029);
      expect(
        kMemoApiVersionsProbeOrder.map((version) => version.versionString),
        containsAll(<String>['0.28.0', '0.29.0']),
      );
    });
  });

  group('MemoApiFacade 0.29 profile', () {
    test('creates strict 0.29 clients', () {
      final baseUrl = Uri.parse('http://127.0.0.1:1');

      final unauthenticated = MemoApiFacade.unauthenticated(
        baseUrl: baseUrl,
        version: MemoApiVersion.v029,
      );
      expect(unauthenticated.isStrictRouteLocked, isTrue);
      expect(unauthenticated.effectiveServerVersion, '0.29.0');

      final authenticated = MemoApiFacade.authenticated(
        baseUrl: baseUrl,
        personalAccessToken: 'test-pat',
        version: MemoApiVersion.v029,
      );
      expect(authenticated.isStrictRouteLocked, isTrue);
      expect(authenticated.effectiveServerVersion, '0.29.0');

      final sessionAuthenticated = MemoApiFacade.sessionAuthenticated(
        baseUrl: baseUrl,
        sessionCookie: 'user_session=test-session',
        version: MemoApiVersion.v029,
      );
      expect(sessionAuthenticated.isStrictRouteLocked, isTrue);
      expect(sessionAuthenticated.effectiveServerVersion, '0.29.0');
    });

    test('routes password sign-in through the modern v1 endpoint', () async {
      final harness = await _FakeMemosServer.start(MemoApiVersion.v029);
      addTearDown(() async {
        await harness.close();
      });

      final result = await MemoApiFacade.passwordSignIn(
        baseUrl: harness.baseUrl,
        username: 'demo',
        password: 'secret',
        version: MemoApiVersion.v029,
      );

      expect(result.endpoint, MemoPasswordSignInEndpoint.signinV1);
      expect(result.accessToken, 'test-token');
      expect(
        harness.findRequest(method: 'POST', path: '/api/v1/auth/signin'),
        isNotNull,
      );
    });
  });

  group('MemoApiFacade versioned route compatibility', () {
    for (final version in kMemoApiVersionsProbeOrder) {
      test(
        'version ${version.versionString} uses expected auth + list routes',
        () async {
          final harness = await _FakeMemosServer.start(version);
          addTearDown(() async {
            await harness.close();
          });

          final api = MemoApiFacade.authenticated(
            baseUrl: harness.baseUrl,
            personalAccessToken: 'test-pat',
            version: version,
          );

          final user = await api.getCurrentUser();
          expect(user.name, _expectedCurrentUserName(version));

          final (memos, nextPageToken) = await api.listMemos(
            pageSize: 10,
            state: 'NORMAL',
          );
          expect(memos, hasLength(1));
          expect(memos.first.uid, '101');
          if (version == MemoApiVersion.v027) {
            expect(memos.first.tags, const <String>[
              _v027AmpersandTag,
              _v027EmojiTag,
            ]);
          }

          final expected = _expectedRoutes(version);
          final currentUserRequest = harness.findRequest(
            method: expected.currentUserMethod,
            path: expected.currentUserPath,
          );
          expect(currentUserRequest, isNotNull);

          final listRequest = harness.findRequest(
            method: 'GET',
            path: expected.listMemosPath,
          );
          expect(listRequest, isNotNull);
          final capturedListRequest = listRequest!;

          if (expected.usesLegacyMemoListRoute) {
            expect(capturedListRequest.queryParameters['rowStatus'], 'NORMAL');
            expect(capturedListRequest.queryParameters['limit'], '10');
            expect(nextPageToken, '1');
          } else {
            expect(capturedListRequest.queryParameters['pageSize'], '10');
            expect(capturedListRequest.queryParameters['page_size'], '10');
            expect(nextPageToken, isEmpty);
          }

          switch (version) {
            case MemoApiVersion.v022:
              expect(
                capturedListRequest.queryParameters['filter'],
                'row_status == "NORMAL"',
              );
              expect(
                capturedListRequest.queryParameters.containsKey('state'),
                isFalse,
              );
              expect(
                capturedListRequest.queryParameters.containsKey('view'),
                isFalse,
              );
              break;
            case MemoApiVersion.v023:
              expect(
                capturedListRequest.queryParameters['view'],
                'MEMO_VIEW_FULL',
              );
              expect(
                capturedListRequest.queryParameters['filter'],
                'row_status == "NORMAL"',
              );
              expect(
                capturedListRequest.queryParameters.containsKey('state'),
                isFalse,
              );
              break;
            case MemoApiVersion.v024:
            case MemoApiVersion.v025:
            case MemoApiVersion.v026:
            case MemoApiVersion.v027:
            case MemoApiVersion.v028:
            case MemoApiVersion.v029:
              expect(capturedListRequest.queryParameters['state'], 'NORMAL');
              expect(
                capturedListRequest.queryParameters.containsKey('view'),
                isFalse,
              );
              break;
            case MemoApiVersion.v021:
              expect(
                capturedListRequest.queryParameters.containsKey('state'),
                isFalse,
              );
              expect(
                capturedListRequest.queryParameters.containsKey('filter'),
                isFalse,
              );
              break;
          }

          final currentUserAttemptCount = harness.requests.where((request) {
            return _allCurrentUserEndpoints.contains(
              '${request.method} ${request.path}',
            );
          }).length;
          expect(currentUserAttemptCount, 1);
        },
      );
    }

    test('version 0.27.0 preserves display_time list ordering', () async {
      final harness = await _FakeMemosServer.start(MemoApiVersion.v027);
      addTearDown(() async {
        await harness.close();
      });

      final api = MemoApiFacade.authenticated(
        baseUrl: harness.baseUrl,
        personalAccessToken: 'test-pat',
        version: MemoApiVersion.v027,
      );

      await api.listMemos(
        pageSize: 10,
        state: 'NORMAL',
        orderBy: 'display_time desc',
      );

      final listRequest = harness.findRequest(
        method: 'GET',
        path: _expectedRoutes(MemoApiVersion.v027).listMemosPath,
      );
      expect(listRequest, isNotNull);
      expect(listRequest!.queryParameters['orderBy'], 'display_time desc');
      expect(listRequest.queryParameters['order_by'], 'display_time desc');
    });

    for (final version in <MemoApiVersion>[
      MemoApiVersion.v028,
      MemoApiVersion.v029,
    ]) {
      test(
        'version ${version.versionString} remaps display_time list ordering',
        () async {
          final harness = await _FakeMemosServer.start(version);
          addTearDown(() async {
            await harness.close();
          });

          final api = MemoApiFacade.authenticated(
            baseUrl: harness.baseUrl,
            personalAccessToken: 'test-pat',
            version: version,
          );

          await api.listMemos(
            pageSize: 10,
            state: 'NORMAL',
            orderBy: 'display_time desc',
          );
          await api.listExploreMemos(
            pageSize: 10,
            state: 'NORMAL',
            orderBy: 'display_time desc',
          );

          final listRequests = harness.requests
              .where(
                (request) =>
                    request.method == 'GET' &&
                    request.path == _expectedRoutes(version).listMemosPath,
              )
              .toList(growable: false);
          expect(listRequests, hasLength(2));

          for (final request in listRequests) {
            expect(request.queryParameters['orderBy'], 'create_time desc');
            expect(request.queryParameters['order_by'], 'create_time desc');
            expect(
              request.queryParameters.values.any(
                (value) => value.contains('display_time'),
              ),
              isFalse,
            );
          }
        },
      );
    }
  });
}

class _ExpectedRoutes {
  const _ExpectedRoutes({
    required this.currentUserMethod,
    required this.currentUserPath,
    required this.listMemosPath,
    required this.usesLegacyMemoListRoute,
  });

  final String currentUserMethod;
  final String currentUserPath;
  final String listMemosPath;
  final bool usesLegacyMemoListRoute;
}

_ExpectedRoutes _expectedRoutes(MemoApiVersion version) {
  return switch (version) {
    MemoApiVersion.v021 => const _ExpectedRoutes(
      currentUserMethod: 'POST',
      currentUserPath: '/api/v2/auth/status',
      listMemosPath: '/api/v1/memo',
      usesLegacyMemoListRoute: true,
    ),
    MemoApiVersion.v022 => const _ExpectedRoutes(
      currentUserMethod: 'POST',
      currentUserPath: '/api/v1/auth/status',
      listMemosPath: '/api/v1/memos',
      usesLegacyMemoListRoute: false,
    ),
    MemoApiVersion.v023 => const _ExpectedRoutes(
      currentUserMethod: 'POST',
      currentUserPath: '/api/v1/auth/status',
      listMemosPath: '/api/v1/memos',
      usesLegacyMemoListRoute: false,
    ),
    MemoApiVersion.v024 => const _ExpectedRoutes(
      currentUserMethod: 'POST',
      currentUserPath: '/api/v1/auth/status',
      listMemosPath: '/api/v1/memos',
      usesLegacyMemoListRoute: false,
    ),
    MemoApiVersion.v025 => const _ExpectedRoutes(
      currentUserMethod: 'GET',
      currentUserPath: '/api/v1/auth/sessions/current',
      listMemosPath: '/api/v1/memos',
      usesLegacyMemoListRoute: false,
    ),
    MemoApiVersion.v026 => const _ExpectedRoutes(
      currentUserMethod: 'GET',
      currentUserPath: '/api/v1/auth/me',
      listMemosPath: '/api/v1/memos',
      usesLegacyMemoListRoute: false,
    ),
    MemoApiVersion.v027 => const _ExpectedRoutes(
      currentUserMethod: 'GET',
      currentUserPath: '/api/v1/auth/me',
      listMemosPath: '/api/v1/memos',
      usesLegacyMemoListRoute: false,
    ),
    MemoApiVersion.v028 => const _ExpectedRoutes(
      currentUserMethod: 'GET',
      currentUserPath: '/api/v1/auth/me',
      listMemosPath: '/api/v1/memos',
      usesLegacyMemoListRoute: false,
    ),
    MemoApiVersion.v029 => const _ExpectedRoutes(
      currentUserMethod: 'GET',
      currentUserPath: '/api/v1/auth/me',
      listMemosPath: '/api/v1/memos',
      usesLegacyMemoListRoute: false,
    ),
  };
}

String _expectedCurrentUserName(MemoApiVersion version) {
  return version == MemoApiVersion.v027 ? 'users/demo' : 'users/1';
}

class _CapturedRequest {
  const _CapturedRequest({
    required this.method,
    required this.path,
    required this.queryParameters,
  });

  final String method;
  final String path;
  final Map<String, String> queryParameters;
}

class _FakeMemosServer {
  _FakeMemosServer._(this.version, this._server);

  final MemoApiVersion version;
  final HttpServer _server;
  final List<_CapturedRequest> requests = <_CapturedRequest>[];

  Uri get baseUrl => Uri.parse('http://127.0.0.1:${_server.port}');

  static Future<_FakeMemosServer> start(MemoApiVersion version) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final harness = _FakeMemosServer._(version, server);
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
      _CapturedRequest(
        method: request.method,
        path: request.uri.path,
        queryParameters: request.uri.queryParameters,
      ),
    );

    final expected = _expectedRoutes(version);
    if (request.method == 'POST' && request.uri.path == '/api/v1/auth/signin') {
      await _writeJson(request.response, <String, Object?>{
        'accessToken': 'test-token',
        'user': <String, Object?>{
          'name': 'users/demo',
          'username': 'demo',
          'displayName': 'Demo User',
          'avatarUrl': '',
          'description': '',
        },
      });
      return;
    }

    final isCurrentUserRoute =
        request.method == expected.currentUserMethod &&
        request.uri.path == expected.currentUserPath;
    if (isCurrentUserRoute) {
      await _writeJson(request.response, <String, Object?>{
        'user': <String, Object?>{
          'name': _expectedCurrentUserName(version),
          'username': 'demo',
          'displayName': 'Demo User',
          'avatarUrl': '',
          'description': '',
        },
      });
      return;
    }

    final isListMemosRoute =
        request.method == 'GET' && request.uri.path == expected.listMemosPath;
    if (isListMemosRoute) {
      await _writeJson(request.response, _listMemosPayload(version));
      return;
    }

    await _writeJson(request.response, <String, Object?>{
      'error': 'Unhandled test route',
      'method': request.method,
      'path': request.uri.path,
    }, statusCode: HttpStatus.notFound);
  }
}

Object _listMemosPayload(MemoApiVersion version) {
  if (version == MemoApiVersion.v021) {
    return <Object?>[
      <String, Object?>{
        'id': 101,
        'creatorId': 1,
        'content': 'legacy memo',
        'visibility': 'PRIVATE',
        'pinned': false,
        'rowStatus': 'NORMAL',
        'createdTs': 1704067200,
        'updatedTs': 1704067260,
      },
    ];
  }

  return <String, Object?>{
    'memos': <Object?>[
      <String, Object?>{
        'name': 'memos/101',
        'creator': _expectedCurrentUserName(version),
        'content': 'modern memo',
        'visibility': 'PRIVATE',
        'pinned': false,
        'state': 'NORMAL',
        'createTime': '2024-01-01T00:00:00Z',
        'updateTime': '2024-01-01T00:01:00Z',
        'tags': version == MemoApiVersion.v027
            ? const <String>[_v027AmpersandTag, _v027EmojiTag]
            : const <String>[],
        'attachments': const <Object>[],
      },
    ],
    'nextPageToken': '',
  };
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

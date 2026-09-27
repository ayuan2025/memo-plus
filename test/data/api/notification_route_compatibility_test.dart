import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/api/memo_api_facade.dart';
import 'package:memos_flutter_app/data/api/memo_api_version.dart';

void main() {
  group('MemoApiFacade notification route compatibility', () {
    test('0.26 keeps numeric notification parent', () async {
      final harness = await _FakeNotificationServer.start(MemoApiVersion.v026);
      addTearDown(() async {
        await harness.close();
      });

      final api = MemoApiFacade.authenticated(
        baseUrl: harness.baseUrl,
        personalAccessToken: 'test-pat',
        version: MemoApiVersion.v026,
      );

      final (notifications, nextPageToken) = await api.listNotifications(
        pageSize: 10,
        userName: 'users/1',
      );

      expect(notifications, hasLength(1));
      expect(nextPageToken, isEmpty);
      expect(notifications.single.name, 'users/1/notifications/7');
      expect(notifications.single.activityId, 7);
      expect(
        harness.findRequest(
          method: 'GET',
          path: '/api/v1/users/1/notifications',
        ),
        isNotNull,
      );
      expect(
        harness.findRequest(method: 'GET', path: '/api/v1/auth/me'),
        isNull,
      );
    });

    test(
      '0.27 resolves username notification parent and caches refs',
      () async {
        final harness = await _FakeNotificationServer.start(
          MemoApiVersion.v027,
        );
        addTearDown(() async {
          await harness.close();
        });

        final api = MemoApiFacade.authenticated(
          baseUrl: harness.baseUrl,
          personalAccessToken: 'test-pat',
          version: MemoApiVersion.v027,
        );

        final (notifications, nextPageToken) = await api.listNotifications(
          pageSize: 10,
          userName: 'users/1',
        );

        expect(notifications, hasLength(1));
        expect(nextPageToken, isEmpty);
        expect(notifications.single.name, 'users/demo/notifications/41');
        expect(notifications.single.activityId, 41);

        final refs = await api.getMemoCommentActivityRefs(activityId: 41);
        expect(refs.commentMemoUid, 'comment-uid');
        expect(refs.relatedMemoUid, 'related-uid');

        expect(
          harness.findRequest(method: 'GET', path: '/api/v1/auth/me'),
          isNotNull,
        );
        expect(
          harness.findRequest(
            method: 'GET',
            path: '/api/v1/users/demo/notifications',
          ),
          isNotNull,
        );
        expect(
          harness.findRequest(method: 'GET', path: '/api/v1/activities/41'),
          isNull,
        );
      },
    );
  });
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

class _FakeNotificationServer {
  _FakeNotificationServer._(this.version, this._server);

  final MemoApiVersion version;
  final HttpServer _server;
  final List<_CapturedRequest> requests = <_CapturedRequest>[];

  Uri get baseUrl => Uri.parse('http://127.0.0.1:${_server.port}');

  static Future<_FakeNotificationServer> start(MemoApiVersion version) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final harness = _FakeNotificationServer._(version, server);
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

    if (request.method == 'GET' && request.uri.path == '/api/v1/auth/me') {
      await _writeJson(request.response, <String, Object?>{
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

    if (request.method == 'GET' &&
        request.uri.path == '/api/v1/users/1/notifications') {
      expect(version, MemoApiVersion.v026);
      expect(request.uri.queryParameters['pageSize'], '10');
      expect(request.uri.queryParameters['page_size'], '10');
      await _writeJson(request.response, <String, Object?>{
        'notifications': <Object?>[
          <String, Object?>{
            'name': 'users/1/notifications/7',
            'sender': 'users/2',
            'status': 'UNREAD',
            'type': 'MEMO_COMMENT',
            'createTime': '2026-04-22T12:00:00Z',
            'activityId': 7,
          },
        ],
        'nextPageToken': '',
      });
      return;
    }

    if (request.method == 'GET' &&
        request.uri.path == '/api/v1/users/demo/notifications') {
      expect(version, MemoApiVersion.v027);
      expect(request.uri.queryParameters['pageSize'], '10');
      expect(request.uri.queryParameters['page_size'], '10');
      await _writeJson(request.response, <String, Object?>{
        'notifications': <Object?>[
          <String, Object?>{
            'name': 'users/demo/notifications/41',
            'sender': 'users/sender',
            'status': 'UNREAD',
            'type': 'MEMO_COMMENT',
            'createTime': '2026-04-22T12:00:00Z',
            'memoComment': <String, Object?>{
              'memo': 'memos/comment-uid',
              'relatedMemo': 'memos/related-uid',
              'memoSnippet': 'Comment content',
              'relatedMemoSnippet': 'Base memo',
            },
          },
        ],
        'nextPageToken': '',
      });
      return;
    }

    if (request.method == 'GET' && request.uri.path == '/api/v1/activities/7') {
      await _writeJson(request.response, <String, Object?>{
        'payload': <String, Object?>{
          'memoComment': <String, Object?>{
            'memo': 'memos/comment-uid',
            'relatedMemo': 'memos/related-uid',
          },
        },
      });
      return;
    }

    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
  }
}

Future<void> _writeJson(
  HttpResponse response,
  Map<String, Object?> body,
) async {
  response.statusCode = HttpStatus.ok;
  response.headers.contentType = ContentType.json;
  response.write(jsonEncode(body));
  await response.close();
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/api/memo_api_version.dart';
import 'package:memos_flutter_app/data/api/memos_live_refresh_api.dart';

void main() {
  group('MemosLiveRefreshSseParser', () {
    test('parses known events and skips heartbeat or malformed lines', () async {
      const parser = MemosLiveRefreshSseParser();
      final events = await parser
          .parseLines(
            Stream<String>.fromIterable(const <String>[
              ': connected',
              ': heartbeat',
              '',
              'event: message',
              'data: not-json',
              'data: {"type":"unknown","name":"memos/memo-0"}',
              'data: {"type":"reaction.upserted","name":"memos/memo-1"}',
              'data: {"type":"reaction.deleted","name":"memos/memo-1/reactions/r1"}',
              'data: {"type":"memo.comment.created","name":"memos/comment-1","parent":"memos/memo-1"}',
              'data: {"type":"memo.created","name":"memos/memo-2"}',
              'data: {"type":"memo.updated","name":"memos/memo-2"}',
              'data: {"type":"memo.deleted","name":"memos/memo-2"}',
            ]),
          )
          .toList();

      expect(events.map((event) => event.type), <MemosLiveRefreshEventType>[
        MemosLiveRefreshEventType.reactionUpserted,
        MemosLiveRefreshEventType.reactionDeleted,
        MemosLiveRefreshEventType.memoCommentCreated,
        MemosLiveRefreshEventType.memoCreated,
        MemosLiveRefreshEventType.memoUpdated,
        MemosLiveRefreshEventType.memoDeleted,
      ]);
      expect(events[0].targetMemoUid, 'memo-1');
      expect(events[1].targetMemoUid, 'memo-1');
      expect(events[2].targetMemoUid, 'memo-1');
      expect(events[0].refreshesReactions, isTrue);
      expect(events[2].refreshesComments, isTrue);
      expect(events[3].refreshesMemoList, isTrue);
    });
  });

  group('MemosLiveRefreshApi', () {
    test('requests /api/v1/sse with SSE accept and bearer headers', () async {
      final harness = await _FakeSseServer.start(
        statusCode: HttpStatus.ok,
        lines: const <String>[
          ': connected',
          'data: {"type":"reaction.upserted","name":"memos/memo-1"}',
          'data: not-json',
          'data: {"type":"memo.comment.created","name":"memos/comment-1","parent":"memos/memo-1"}',
        ],
      );
      addTearDown(harness.close);

      var connected = false;
      final events = await MemosLiveRefreshApi(
        baseUrl: harness.baseUrl,
        personalAccessToken: 'test-pat',
        version: MemoApiVersion.v029,
      ).watchEvents(onConnected: () => connected = true).toList();

      expect(connected, isTrue);
      expect(events.map((event) => event.type), [
        MemosLiveRefreshEventType.reactionUpserted,
        MemosLiveRefreshEventType.memoCommentCreated,
      ]);
      expect(harness.requests, hasLength(1));
      final request = harness.requests.single;
      expect(request.method, 'GET');
      expect(request.path, '/api/v1/sse');
      expect(request.accept, kMemosLiveRefreshContentType);
      expect(request.authorization, 'Bearer test-pat');
    });

    test('does not request SSE for unsupported API versions', () async {
      final harness = await _FakeSseServer.start(statusCode: HttpStatus.ok);
      addTearDown(harness.close);

      final events = await MemosLiveRefreshApi(
        baseUrl: harness.baseUrl,
        personalAccessToken: 'test-pat',
        version: MemoApiVersion.v026,
      ).watchEvents().toList();

      expect(events, isEmpty);
      expect(harness.requests, isEmpty);
    });

    test('downgrades unavailable or unauthenticated SSE responses', () async {
      for (final statusCode in <int>[
        HttpStatus.unauthorized,
        HttpStatus.notFound,
        HttpStatus.methodNotAllowed,
        HttpStatus.notImplemented,
      ]) {
        final harness = await _FakeSseServer.start(statusCode: statusCode);
        addTearDown(harness.close);

        final events = await MemosLiveRefreshApi(
          baseUrl: harness.baseUrl,
          personalAccessToken: 'test-pat',
          version: MemoApiVersion.v029,
        ).watchEvents().toList();

        expect(events, isEmpty, reason: 'status $statusCode');
        expect(harness.requests, hasLength(1), reason: 'status $statusCode');
      }
    });
  });
}

class _CapturedSseRequest {
  const _CapturedSseRequest({
    required this.method,
    required this.path,
    required this.accept,
    required this.authorization,
  });

  final String method;
  final String path;
  final String? accept;
  final String? authorization;
}

class _FakeSseServer {
  _FakeSseServer._({
    required HttpServer server,
    required int statusCode,
    required List<String> lines,
  }) : _server = server,
       _statusCode = statusCode,
       _lines = lines;

  final HttpServer _server;
  final int _statusCode;
  final List<String> _lines;
  final List<_CapturedSseRequest> requests = <_CapturedSseRequest>[];

  Uri get baseUrl => Uri.parse('http://127.0.0.1:${_server.port}');

  static Future<_FakeSseServer> start({
    required int statusCode,
    List<String> lines = const <String>[],
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final harness = _FakeSseServer._(
      server: server,
      statusCode: statusCode,
      lines: lines,
    );
    server.listen(harness._handleRequest);
    return harness;
  }

  Future<void> close() async {
    await _server.close(force: true);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    requests.add(
      _CapturedSseRequest(
        method: request.method,
        path: request.uri.path,
        accept: request.headers.value('Accept'),
        authorization: request.headers.value('Authorization'),
      ),
    );

    if (request.method != 'GET' || request.uri.path != '/api/v1/sse') {
      await _writeJson(request.response, <String, Object?>{
        'error': 'Unhandled test route',
      }, statusCode: HttpStatus.notFound);
      return;
    }

    request.response.statusCode = _statusCode;
    if (_statusCode != HttpStatus.ok) {
      await _writeJson(request.response, <String, Object?>{
        'error': 'SSE unavailable',
      }, statusCode: _statusCode);
      return;
    }

    request.response.headers.contentType = ContentType('text', 'event-stream');
    for (final line in _lines) {
      request.response.write('$line\n');
    }
    await request.response.close();
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

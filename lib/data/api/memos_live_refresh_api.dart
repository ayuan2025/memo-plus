import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/url.dart';
import '../logs/breadcrumb_store.dart';
import '../logs/log_manager.dart';
import '../logs/network_log_buffer.dart';
import '../logs/network_log_interceptor.dart';
import '../logs/network_log_store.dart';
import 'memo_api_version.dart';

const String kMemosLiveRefreshSsePath = 'api/v1/sse';
const String kMemosLiveRefreshContentType = 'text/event-stream';

bool supportsMemosLiveRefresh(MemoApiVersion version) {
  return switch (version) {
    MemoApiVersion.v027 || MemoApiVersion.v028 || MemoApiVersion.v029 => true,
    MemoApiVersion.v021 ||
    MemoApiVersion.v022 ||
    MemoApiVersion.v023 ||
    MemoApiVersion.v024 ||
    MemoApiVersion.v025 ||
    MemoApiVersion.v026 => false,
  };
}

enum MemosLiveRefreshEventType {
  memoCreated('memo.created'),
  memoUpdated('memo.updated'),
  memoDeleted('memo.deleted'),
  memoCommentCreated('memo.comment.created'),
  reactionUpserted('reaction.upserted'),
  reactionDeleted('reaction.deleted');

  const MemosLiveRefreshEventType(this.wireName);

  final String wireName;

  static MemosLiveRefreshEventType? fromWireName(String raw) {
    final normalized = raw.trim();
    for (final type in values) {
      if (type.wireName == normalized) return type;
    }
    return null;
  }
}

class MemosLiveRefreshEvent {
  const MemosLiveRefreshEvent({
    required this.type,
    required this.name,
    this.parent,
  });

  final MemosLiveRefreshEventType type;
  final String name;
  final String? parent;

  String? get targetMemoUid {
    return _memoUidFromResourceName(parent) ?? _memoUidFromResourceName(name);
  }

  bool get refreshesReactions {
    return type == MemosLiveRefreshEventType.reactionUpserted ||
        type == MemosLiveRefreshEventType.reactionDeleted;
  }

  bool get refreshesComments {
    return type == MemosLiveRefreshEventType.memoCommentCreated;
  }

  bool get refreshesMemoList {
    return type == MemosLiveRefreshEventType.memoCreated ||
        type == MemosLiveRefreshEventType.memoUpdated ||
        type == MemosLiveRefreshEventType.memoDeleted;
  }

  static MemosLiveRefreshEvent? fromJson(Map<String, Object?> json) {
    final typeRaw = json['type'];
    final nameRaw = json['name'];
    if (typeRaw is! String || nameRaw is! String) return null;
    final type = MemosLiveRefreshEventType.fromWireName(typeRaw);
    final name = nameRaw.trim();
    if (type == null || name.isEmpty) return null;

    final parentRaw = json['parent'];
    final parent = parentRaw is String && parentRaw.trim().isNotEmpty
        ? parentRaw.trim()
        : null;
    return MemosLiveRefreshEvent(type: type, name: name, parent: parent);
  }

  @override
  bool operator ==(Object other) {
    return other is MemosLiveRefreshEvent &&
        other.type == type &&
        other.name == name &&
        other.parent == parent;
  }

  @override
  int get hashCode => Object.hash(type, name, parent);

  @override
  String toString() {
    return 'MemosLiveRefreshEvent(type: ${type.wireName}, name: $name, parent: $parent)';
  }
}

class MemosLiveRefreshSseParser {
  const MemosLiveRefreshSseParser();

  Stream<MemosLiveRefreshEvent> parseBytes(Stream<List<int>> stream) {
    final bytes = stream.map<List<int>>((chunk) => chunk);
    return parseLines(bytes.transform(utf8.decoder).transform(LineSplitter()));
  }

  Stream<MemosLiveRefreshEvent> parseLines(Stream<String> lines) async* {
    await for (final line in lines) {
      final event = parseLine(line);
      if (event != null) yield event;
    }
  }

  MemosLiveRefreshEvent? parseLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith(':')) return null;
    if (!trimmed.startsWith('data:')) return null;

    final payload = trimmed.substring('data:'.length).trimLeft();
    if (payload.isEmpty) return null;
    Object? decoded;
    try {
      decoded = jsonDecode(payload);
    } catch (_) {
      return null;
    }
    if (decoded is! Map) return null;
    return MemosLiveRefreshEvent.fromJson(decoded.cast<String, Object?>());
  }
}

abstract class MemosLiveRefreshEventSource {
  bool get isSupported;

  Stream<MemosLiveRefreshEvent> watchEvents({void Function()? onConnected});
}

class MemosLiveRefreshApi implements MemosLiveRefreshEventSource {
  MemosLiveRefreshApi({
    required Uri baseUrl,
    required String personalAccessToken,
    required MemoApiVersion version,
    NetworkLogStore? logStore,
    NetworkLogBuffer? logBuffer,
    BreadcrumbStore? breadcrumbStore,
    LogManager? logManager,
    Dio? dio,
    MemosLiveRefreshSseParser parser = const MemosLiveRefreshSseParser(),
  }) : _version = version,
       _personalAccessToken = personalAccessToken,
       _parser = parser,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: dioBaseUrlString(baseUrl),
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: null,
             ),
           ) {
    if (logStore != null ||
        logManager != null ||
        logBuffer != null ||
        breadcrumbStore != null) {
      _dio.interceptors.add(
        NetworkLogInterceptor(
          logStore,
          buffer: logBuffer,
          breadcrumbStore: breadcrumbStore,
          logManager: logManager,
        ),
      );
    }
  }

  final MemoApiVersion _version;
  final String _personalAccessToken;
  final MemosLiveRefreshSseParser _parser;
  final Dio _dio;

  @override
  bool get isSupported => supportsMemosLiveRefresh(_version);

  @override
  Stream<MemosLiveRefreshEvent> watchEvents({void Function()? onConnected}) {
    if (!isSupported) return const Stream<MemosLiveRefreshEvent>.empty();
    final token = _personalAccessToken.trim();
    if (token.isEmpty) return const Stream<MemosLiveRefreshEvent>.empty();
    return _watchEvents(onConnected: onConnected);
  }

  Stream<MemosLiveRefreshEvent> _watchEvents({
    void Function()? onConnected,
  }) async* {
    final response = await _dio.get<ResponseBody>(
      kMemosLiveRefreshSsePath,
      options: Options(
        responseType: ResponseType.stream,
        receiveTimeout: null,
        validateStatus: (_) => true,
        headers: <String, Object?>{
          'Accept': kMemosLiveRefreshContentType,
          'Authorization': 'Bearer ${_personalAccessToken.trim()}',
        },
      ),
    );

    final status = response.statusCode;
    if (status != null && status >= 200 && status < 300) {
      final body = response.data;
      if (body == null) return;
      onConnected?.call();
      yield* _parser.parseBytes(body.stream);
      return;
    }

    if (_isUnavailableStatus(status)) return;

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
      message: 'Memos live refresh SSE returned HTTP ${status ?? '?'}',
    );
  }
}

bool _isUnavailableStatus(int? status) {
  return status == 401 || status == 404 || status == 405 || status == 501;
}

String? _memoUidFromResourceName(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return null;
  final marker = RegExp(r'(?:^|/)memos/([^/]+)').firstMatch(value);
  if (marker == null) return null;
  final uid = marker.group(1)?.trim();
  return uid == null || uid.isEmpty ? null : uid;
}

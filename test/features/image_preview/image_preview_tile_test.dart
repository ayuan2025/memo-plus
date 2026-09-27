import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/features/image_preview/image_preview_item.dart';
import 'package:memos_flutter_app/features/image_preview/widgets/image_preview_tile.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

class _SvgHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _SvgHttpClientRequest();

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _SvgHttpClientRequest();

  @override
  void close({bool force = false}) {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SvgHttpClientRequest implements HttpClientRequest {
  final HttpHeaders _headers = _SvgHttpHeaders();
  final BytesBuilder _body = BytesBuilder(copy: false);
  bool _followRedirects = true;
  int _maxRedirects = 5;
  int _contentLength = 0;
  bool _persistentConnection = true;
  bool _bufferOutput = true;

  @override
  HttpHeaders get headers => _headers;

  @override
  bool get followRedirects => _followRedirects;

  @override
  set followRedirects(bool value) {
    _followRedirects = value;
  }

  @override
  int get maxRedirects => _maxRedirects;

  @override
  set maxRedirects(int value) {
    _maxRedirects = value;
  }

  @override
  int get contentLength => _contentLength;

  @override
  set contentLength(int value) {
    _contentLength = value;
  }

  @override
  bool get persistentConnection => _persistentConnection;

  @override
  set persistentConnection(bool value) {
    _persistentConnection = value;
  }

  @override
  bool get bufferOutput => _bufferOutput;

  @override
  set bufferOutput(bool value) {
    _bufferOutput = value;
  }

  @override
  Future<HttpClientResponse> close() async => _SvgHttpClientResponse();

  @override
  void add(List<int> data) {
    _body.add(data);
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final chunk in stream) {
      _body.add(chunk);
    }
  }

  @override
  Future<void> flush() async {}

  @override
  void write(Object? object) {}

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object? object = '']) {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SvgHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _SvgHttpClientResponse()
    : _bytes = Uint8List.fromList(
        utf8.encode(
          '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10">'
          '<rect width="10" height="10" fill="red"/></svg>',
        ),
      );

  final Uint8List _bytes;

  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _bytes.length;

  @override
  HttpHeaders get headers => _SvgHttpHeaders();

  @override
  bool get isRedirect => false;

  @override
  List<RedirectInfo> get redirects => const <RedirectInfo>[];

  @override
  String get reasonPhrase => 'OK';

  @override
  bool get persistentConnection => false;

  @override
  X509Certificate? get certificate => null;

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable(<List<int>>[_bytes]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SvgHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _values = <String, List<String>>{
    HttpHeaders.contentTypeHeader: <String>['image/svg+xml'],
  };

  @override
  ContentType? get contentType => ContentType('image', 'svg+xml');

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _values.putIfAbsent(name, () => <String>[]).add(value.toString());
  }

  @override
  void set(
    String name,
    Object value, {
    bool preserveHeaderCase = false,
  }) {
    _values[name] = <String>[value.toString()];
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _values.forEach(action);
  }

  @override
  List<String>? operator [](String name) => _values[name];

  @override
  String? value(String name) {
    final values = _values[name];
    if (values == null || values.isEmpty) {
      return null;
    }
    return values.first;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('renders local raster via Image', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ImagePreviewTile(
          item: ImagePreviewItem(
            id: 'local-raster',
            title: 'Local',
            mimeType: 'image/png',
            localFile: File('local.png'),
          ),
          width: 64,
          height: 64,
          borderRadius: 12,
          backgroundColor: Colors.black,
          borderColor: Colors.transparent,
          placeholderColor: Colors.black,
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('renders local svg via SvgPicture', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ImagePreviewTile(
          item: ImagePreviewItem(
            id: 'local-svg',
            title: 'Local SVG',
            mimeType: 'image/svg+xml',
            localFile: File('local.svg'),
          ),
          width: 64,
          height: 64,
          borderRadius: 12,
          backgroundColor: Colors.black,
          borderColor: Colors.transparent,
          placeholderColor: Colors.black,
        ),
      ),
    );

    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('renders remote raster via CachedNetworkImage', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const ImagePreviewTile(
          item: ImagePreviewItem(
            id: 'remote-raster',
            title: 'Remote',
            mimeType: 'image/png',
            thumbnailUrl: 'https://example.com/thumb.png',
          ),
          width: 64,
          height: 64,
          borderRadius: 12,
          backgroundColor: Colors.black,
          borderColor: Colors.transparent,
          placeholderColor: Colors.black,
          cacheWidth: 96,
          cacheHeight: 72,
        ),
      ),
    );

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.memCacheWidth, 96);
    expect(image.memCacheHeight, 72);
    expect(image.maxWidthDiskCache, 96);
    expect(image.maxHeightDiskCache, 72);
  });

  testWidgets('renders remote svg via SvgPicture', (tester) async {
    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(
        _wrap(
          const ImagePreviewTile(
            item: ImagePreviewItem(
              id: 'remote-svg',
              title: 'Remote SVG',
              mimeType: 'image/svg+xml',
              thumbnailUrl: 'https://example.com/image.svg',
            ),
            width: 64,
            height: 64,
            borderRadius: 12,
            backgroundColor: Colors.black,
            borderColor: Colors.transparent,
            placeholderColor: Colors.black,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(SvgPicture), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, createHttpClient: (_) => _SvgHttpClient());
  });

  testWidgets('falls back to placeholder when no source is available', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const ImagePreviewTile(
          item: ImagePreviewItem(
            id: 'empty',
            title: 'Empty',
            mimeType: 'image/png',
          ),
          width: 64,
          height: 64,
          borderRadius: 12,
          backgroundColor: Colors.black,
          borderColor: Colors.transparent,
          placeholderColor: Colors.black,
        ),
      ),
    );

    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
  });
}

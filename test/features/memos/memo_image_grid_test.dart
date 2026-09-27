import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/models/attachment.dart';
import 'package:memos_flutter_app/features/image_preview/widgets/image_preview_tile.dart';
import 'package:memos_flutter_app/features/memos/memo_image_grid.dart';
import 'package:memos_flutter_app/features/memos/memo_media_grid.dart';

void main() {
  test('collectMemoImageEntries resolves html memos resource urls', () {
    final entries = collectMemoImageEntries(
      content: '<p>hello</p><img src="/file/resources/demo/image.jpg">',
      attachments: const [],
      baseUrl: Uri.parse('http://example.com:5230'),
      authHeader: 'Bearer token',
    );

    expect(entries, hasLength(1));
    expect(
      entries.first.fullUrl,
      'http://example.com:5230/file/resources/demo/image.jpg',
    );
    expect(
      entries.first.previewUrl,
      'http://example.com:5230/file/resources/demo/image.jpg?thumbnail=true',
    );
    expect(entries.first.headers, {'Authorization': 'Bearer token'});
  });

  test('collectMemoImageEntries prefers local files for inline html images', () {
    final localUrl = Uri.file(
      '${Directory.systemTemp.path}${Platform.pathSeparator}memo-inline-image.jpg',
    ).toString();

    final entries = collectMemoImageEntries(
      content: '<img src="$localUrl">',
      attachments: const [],
      baseUrl: null,
      authHeader: null,
    );

    expect(entries, hasLength(1));
    expect(entries.first.localFile, isNotNull);
    expect(entries.first.fullUrl, isNull);
    expect(entries.first.previewUrl, isNull);
  });

  test(
    'collectMemoImageEntries deduplicates matching inline local images and attachments',
    () {
      final localUrl = Uri.file(
        '${Directory.systemTemp.path}${Platform.pathSeparator}memo-inline-owned-image.jpg',
      ).toString();

      final entries = collectMemoImageEntries(
        content: '<img src="$localUrl">',
        attachments: [
          Attachment(
            name: 'attachments/demo',
            filename: 'demo.jpg',
            type: 'image/jpeg',
            size: 1024,
            externalLink: localUrl,
          ),
        ],
        baseUrl: null,
        authHeader: null,
      );

      expect(entries, hasLength(1));
      expect(entries.single.isAttachment, isFalse);
      expect(entries.single.localFile, isNotNull);
    },
  );

  test(
    'collectMemoImageEntries ignores html image examples in fenced code',
    () {
      final entries = collectMemoImageEntries(
        content: '```html\n<img src="https://example.com/in-code.png">\n```',
        attachments: const [],
        baseUrl: Uri.parse('https://example.com'),
        authHeader: null,
      );

      expect(entries, isEmpty);
    },
  );

  test(
    'attachment image entries preserve intrinsic dimensions for gallery',
    () {
      final entries = collectMemoImageEntries(
        content: '',
        attachments: const [
          Attachment(
            name: 'attachments/demo',
            filename: 'demo.jpg',
            type: 'image/jpeg',
            size: 1024,
            externalLink: '',
            width: 1080,
            height: 2400,
          ),
        ],
        baseUrl: Uri.parse('https://example.com'),
        authHeader: null,
      );

      expect(entries, hasLength(1));
      final source = entries.first.toGallerySource();
      expect(source.width, 1080);
      expect(source.height, 2400);
    },
  );

  testWidgets('image-only grid uses aspect-safe cache sizing', (tester) async {
    _setUnitDevicePixelRatio(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 100,
            child: MemoImageGrid(
              images: const <MemoImageEntry>[
                MemoImageEntry(
                  id: 'wide',
                  title: 'wide',
                  mimeType: 'image/png',
                  previewUrl: 'https://example.com/wide.png',
                  width: 400,
                  height: 100,
                ),
              ],
              columns: 1,
              spacing: 0,
              borderColor: Colors.white24,
              backgroundColor: Colors.black,
              textColor: Colors.white,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final tile = tester.widget<ImagePreviewTile>(find.byType(ImagePreviewTile));
    expect(tile.cacheWidth, 600);
    expect(tile.cacheHeight, 150);
  });

  testWidgets('unknown source dimensions use single-axis cache fallback', (
    tester,
  ) async {
    _setUnitDevicePixelRatio(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 100,
            child: MemoImageGrid(
              images: const <MemoImageEntry>[
                MemoImageEntry(
                  id: 'unknown',
                  title: 'unknown',
                  mimeType: 'image/png',
                  previewUrl: 'https://example.com/unknown.png',
                ),
              ],
              columns: 1,
              spacing: 0,
              borderColor: Colors.white24,
              backgroundColor: Colors.black,
              textColor: Colors.white,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final tile = tester.widget<ImagePreviewTile>(find.byType(ImagePreviewTile));
    expect(tile.cacheWidth, 150);
    expect(tile.cacheHeight, isNull);
  });

  testWidgets('media grid wide image uses aspect-safe cache sizing', (
    tester,
  ) async {
    _setUnitDevicePixelRatio(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 100,
            child: MemoMediaGrid(
              entries: const <MemoMediaEntry>[
                MemoMediaEntry.image(
                  MemoImageEntry(
                    id: 'wide',
                    title: 'wide',
                    mimeType: 'image/png',
                    width: 400,
                    height: 100,
                  ),
                ),
              ],
              columns: 1,
              spacing: 0,
              borderColor: Colors.white24,
              backgroundColor: Colors.black,
              textColor: Colors.white,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final tile = tester.widget<ImagePreviewTile>(find.byType(ImagePreviewTile));
    expect(tile.cacheWidth, 600);
    expect(tile.cacheHeight, 150);
  });

  testWidgets('media grid tall image uses aspect-safe cache sizing', (
    tester,
  ) async {
    _setUnitDevicePixelRatio(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 100,
            child: MemoMediaGrid(
              entries: const <MemoMediaEntry>[
                MemoMediaEntry.image(
                  MemoImageEntry(
                    id: 'tall',
                    title: 'tall',
                    mimeType: 'image/png',
                    width: 100,
                    height: 400,
                  ),
                ),
              ],
              columns: 1,
              spacing: 0,
              borderColor: Colors.white24,
              backgroundColor: Colors.black,
              textColor: Colors.white,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final tile = tester.widget<ImagePreviewTile>(find.byType(ImagePreviewTile));
    expect(tile.cacheWidth, 150);
    expect(tile.cacheHeight, 600);
  });

  testWidgets('media grid height-limited tile avoids exact tile ratio decode', (
    tester,
  ) async {
    _setUnitDevicePixelRatio(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 100,
            child: MemoMediaGrid(
              entries: const <MemoMediaEntry>[
                MemoMediaEntry.image(
                  MemoImageEntry(
                    id: 'square',
                    title: 'square',
                    mimeType: 'image/png',
                    width: 400,
                    height: 400,
                  ),
                ),
              ],
              columns: 1,
              spacing: 0,
              maxHeight: 50,
              borderColor: Colors.white24,
              backgroundColor: Colors.black,
              textColor: Colors.white,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final tile = tester.widget<ImagePreviewTile>(find.byType(ImagePreviewTile));
    expect(tile.cacheWidth, 150);
    expect(tile.cacheHeight, 150);
  });
}

void _setUnitDevicePixelRatio(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetDevicePixelRatio);
}

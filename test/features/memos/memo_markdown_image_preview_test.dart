import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/features/image_preview/image_preview_item.dart';
import 'package:memos_flutter_app/features/image_preview/image_preview_open_request.dart';
import 'package:memos_flutter_app/features/memos/memo_markdown.dart';

void main() {
  test('markdown preview index matches local file item', () {
    final local = ImagePreviewItem(
      id: 'local',
      title: 'Local',
      mimeType: 'image/png',
      localFile: File(r'C:\demo\image.png'),
    );

    expect(
      resolveMemoMarkdownImagePreviewIndex(
        items: <ImagePreviewItem>[local],
        localFile: File(r'C:\demo\image.png'),
        resolvedRemoteSrc: '',
      ),
      0,
    );
  });

  test('markdown preview index matches resolved remote url', () {
    const remote = ImagePreviewItem(
      id: 'remote',
      title: 'Remote',
      mimeType: 'image/png',
      fullUrl: 'https://example.com/full.png',
    );

    expect(
      resolveMemoMarkdownImagePreviewIndex(
        items: const <ImagePreviewItem>[remote],
        localFile: null,
        resolvedRemoteSrc: 'https://example.com/full.png',
      ),
      0,
    );
  });

  test('markdown preview index falls back when no item matches', () {
    const remote = ImagePreviewItem(
      id: 'remote',
      title: 'Remote',
      mimeType: 'image/png',
      fullUrl: 'https://example.com/full.png',
    );

    expect(
      resolveMemoMarkdownImagePreviewIndex(
        items: const <ImagePreviewItem>[remote],
        localFile: null,
        resolvedRemoteSrc: 'https://example.com/other.png',
      ),
      -1,
    );
  });

  testWidgets('tapping markdown image opens matching preview request', (
    tester,
  ) async {
    ImagePreviewOpenRequest? capturedRequest;
    const previewItem = ImagePreviewItem(
      id: 'remote',
      title: 'Remote',
      mimeType: 'image/png',
      fullUrl: 'https://example.com/full.png',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MemoMarkdown(
            data: '![demo](https://example.com/full.png)',
            imagePreviewItems: const <ImagePreviewItem>[previewItem],
            onOpenImagePreview: (request) async {
              capturedRequest = request;
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(CachedNetworkImage), findsOneWidget);
    await tester.tap(find.byType(CachedNetworkImage).first);
    await tester.pump();

    expect(capturedRequest, isNotNull);
    expect(capturedRequest!.initialIndex, 0);
    expect(capturedRequest!.items.length, 1);
    expect(capturedRequest!.items.first.id, 'remote');
  });

  testWidgets('tapping unmatched markdown image falls back to single preview item', (
    tester,
  ) async {
    ImagePreviewOpenRequest? capturedRequest;
    const previewItem = ImagePreviewItem(
      id: 'remote',
      title: 'Remote',
      mimeType: 'image/png',
      fullUrl: 'https://example.com/full.png',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MemoMarkdown(
            data: '![demo](https://example.com/other.png)',
            imagePreviewItems: const <ImagePreviewItem>[previewItem],
            onOpenImagePreview: (request) async {
              capturedRequest = request;
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(CachedNetworkImage), findsOneWidget);
    await tester.tap(find.byType(CachedNetworkImage).first);
    await tester.pump();

    expect(capturedRequest, isNotNull);
    expect(capturedRequest!.initialIndex, 0);
    expect(capturedRequest!.items.length, 1);
    expect(capturedRequest!.items.first.fullUrl, 'https://example.com/other.png');
  });

  testWidgets('markdown image tap keeps default behavior when callback is absent', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MemoMarkdown(
            data: '![demo](https://example.com/full.png)',
            imagePreviewItems: const <ImagePreviewItem>[
              ImagePreviewItem(
                id: 'remote',
                title: 'Remote',
                mimeType: 'image/png',
                fullUrl: 'https://example.com/full.png',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(CachedNetworkImage), findsOneWidget);
    await tester.tap(find.byType(CachedNetworkImage).first);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}

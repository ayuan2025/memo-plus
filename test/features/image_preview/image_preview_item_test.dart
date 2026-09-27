import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:memos_flutter_app/features/image_preview/image_preview_item.dart';
import 'package:memos_flutter_app/features/image_preview/image_preview_metadata_resolver.dart';
import 'package:memos_flutter_app/features/image_preview/image_preview_open_request.dart';

void main() {
  test('item prefers thumbnail for tile and full for gallery', () {
    const item = ImagePreviewItem(
      id: 'one',
      title: 'One',
      mimeType: 'image/png',
      thumbnailUrl: 'https://example.com/thumb.png',
      fullUrl: 'https://example.com/full.png',
    );

    expect(item.resolvedTileUrl, 'https://example.com/thumb.png');
    expect(item.resolvedGalleryUrl, 'https://example.com/full.png');
    expect(item.hasRenderableSource, isTrue);
  });

  test('findImagePreviewItemIndex matches local path and url candidates', () {
    const remote = ImagePreviewItem(
      id: 'remote',
      title: 'Remote',
      mimeType: 'image/png',
      fullUrl: 'https://example.com/full.png',
    );
    final local = ImagePreviewItem(
      id: 'local',
      title: 'Local',
      mimeType: 'image/png',
      localFile: File(r'C:\demo\image.png'),
    );

    expect(
      findImagePreviewItemIndex(
        items: <ImagePreviewItem>[remote, local],
        urlCandidates: const <String>['https://example.com/full.png'],
      ),
      0,
    );
    expect(
      findImagePreviewItemIndex(
        items: <ImagePreviewItem>[remote, local],
        localPath: r'C:\demo\image.png',
      ),
      1,
    );
  });

  test('open request exposes expected defaults', () {
    const request = ImagePreviewOpenRequest(
      items: <ImagePreviewItem>[],
      initialIndex: 0,
    );

    expect(request.enableDownload, isTrue);
    expect(request.albumName, 'MemoFlow');
  });

  test('display size parser swaps axes for rotated jpeg', () {
    final image = img.Image(width: 2, height: 4);
    image.exif.imageIfd.orientation = 6;
    final bytes = img.encodeJpg(image);

    expect(resolveImagePreviewDisplaySizeFromBytes(bytes), (
      width: 4,
      height: 2,
    ));
  });

  test(
    'resolved intrinsic size prefers provider when orientation conflicts',
    () {
      expect(
        chooseImagePreviewResolvedIntrinsicSize(
          fileResolved: (width: 1600, height: 900),
          providerResolved: (width: 900, height: 1600),
        ),
        (width: 900, height: 1600),
      );
    },
  );

  test('resolved intrinsic size prefers provider when dimensions agree', () {
    expect(
      chooseImagePreviewResolvedIntrinsicSize(
        fileResolved: (width: 900, height: 1600),
        providerResolved: (width: 912, height: 1600),
      ),
      (width: 912, height: 1600),
    );
  });

  test('resolved intrinsic size falls back to file probe', () {
    expect(
      chooseImagePreviewResolvedIntrinsicSize(
        fileResolved: (width: 900, height: 1600),
      ),
      (width: 900, height: 1600),
    );
  });

  test('decode size preserves contained aspect ratio', () {
    final portrait = resolveImagePreviewDecodeSize(
      const Size(720, 1600),
      const Size(400, 800),
      3,
      isDesktop: false,
    );

    expect(portrait, isNotNull);
    expect(portrait!.width, 864);
    expect(portrait.height, 1920);
  });

  test('direct render is enabled for very tall images', () {
    expect(
      shouldUseDirectImagePreviewRender((width: 720, height: 3200)),
      isTrue,
    );
  });

  test('direct render stays disabled for regular images', () {
    expect(
      shouldUseDirectImagePreviewRender((width: 720, height: 1600)),
      isFalse,
    );
  });
}

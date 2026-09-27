import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:memos_flutter_app/core/debug_ephemeral_storage.dart';
import 'package:memos_flutter_app/core/video_thumbnail_cache.dart';

import '../test_support.dart';

void main() {
  late TestSupport support;

  setUpAll(() async {
    support = await initializeTestSupport();
  });

  tearDownAll(() async {
    await VideoThumbnailCache.clearCache();
    await support.dispose();
  });

  test('disables plugin fallback on Windows', () {
    final allowed =
        VideoThumbnailCache.allowVideoThumbnailPluginFallbackForPlatform(
          isWeb: false,
          isWindows: true,
          isAndroid: false,
          isMacOS: false,
          isLinux: false,
        );

    expect(allowed, isFalse);
  });

  test('keeps plugin fallback enabled on Android', () {
    expect(
      VideoThumbnailCache.allowVideoThumbnailPluginFallbackForPlatform(
        isWeb: false,
        isWindows: false,
        isAndroid: true,
        isMacOS: false,
        isLinux: false,
      ),
      isTrue,
    );
  });

  test(
    'describes and clears disk, memory, and file thumbnail caches',
    () async {
      await VideoThumbnailCache.clearCache();
      final sourceDir = await support.createTempDir('video_source');
      final sourceFile = File(p.join(sourceDir.path, 'sample.mp4'));
      await sourceFile.writeAsBytes(const <int>[1, 2, 3, 4], flush: true);

      final supportDir = await resolveAppSupportDirectory();
      final cacheDir = Directory(p.join(supportDir.path, 'video_thumbnails'));
      await cacheDir.create(recursive: true);
      final key = _videoThumbnailCacheKey(
        id: 'memo-video',
        size: 320,
        localFile: sourceFile,
        videoUrl: null,
      );
      final thumbnailFile = File(p.join(cacheDir.path, '$key.jpg'));
      await thumbnailFile.writeAsBytes(const <int>[8, 9, 10], flush: true);

      final before = await VideoThumbnailCache.describeCache();
      expect(before.files, 1);
      expect(before.bytes, 3);

      final file = await VideoThumbnailCache.getThumbnailFile(
        id: 'memo-video',
        size: 320,
        localFile: sourceFile,
        videoUrl: null,
      );
      expect(file?.path, thumbnailFile.path);
      expect(VideoThumbnailCache.debugFileCacheEntryCount, 1);

      final bytes = await VideoThumbnailCache.getThumbnailBytes(
        id: 'memo-video',
        size: 320,
        localFile: sourceFile,
        videoUrl: null,
      );
      expect(bytes, const <int>[8, 9, 10]);
      expect(VideoThumbnailCache.debugMemoryCacheEntryCount, 1);

      await VideoThumbnailCache.clearCache();

      final after = await VideoThumbnailCache.describeCache();
      expect(after.files, 0);
      expect(after.bytes, 0);
      expect(await thumbnailFile.exists(), isFalse);
      expect(VideoThumbnailCache.debugFileCacheEntryCount, 0);
      expect(VideoThumbnailCache.debugMemoryCacheEntryCount, 0);
    },
  );
}

String _videoThumbnailCacheKey({
  required String id,
  required int size,
  required File? localFile,
  required String? videoUrl,
}) {
  final source = (localFile?.path ?? videoUrl ?? id).trim();
  final raw = '$source|$size|10';
  return sha1.convert(utf8.encode(raw)).toString();
}

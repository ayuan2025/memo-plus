import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:memos_flutter_app/application/maintenance/media_cache_file_system.dart';
import 'package:memos_flutter_app/application/maintenance/media_cache_maintenance_models.dart';
import 'package:memos_flutter_app/application/maintenance/media_cache_maintenance_service.dart';

void main() {
  test('loads category summaries and aggregate known size', () async {
    final service = MediaCacheMaintenanceService(
      targets: [
        _FakeMaintenanceTarget(
          categoryId: MediaCacheCategoryId.networkImage,
          sizeBytes: 1024,
        ),
        _FakeMaintenanceTarget(
          categoryId: MediaCacheCategoryId.videoThumbnail,
          sizeBytes: 2048,
        ),
      ],
    );

    final summary = await service.loadSummary();

    expect(summary.categories, hasLength(2));
    expect(summary.totalKnownSizeBytes, 3072);
    expect(summary.hasFailures, isFalse);
  });

  test(
    'stat failure records unknown category without blocking summary',
    () async {
      final service = MediaCacheMaintenanceService(
        targets: [
          _FakeMaintenanceTarget(
            categoryId: MediaCacheCategoryId.networkImage,
            sizeBytes: 512,
          ),
          _FakeMaintenanceTarget(
            categoryId: MediaCacheCategoryId.videoThumbnail,
            sizeError: StateError('stat failed'),
          ),
        ],
      );

      final summary = await service.loadSummary();

      expect(summary.totalKnownSizeBytes, 512);
      expect(summary.hasUnknownSize, isTrue);
      expect(summary.hasFailures, isTrue);
      expect(summary.categories.last.sizeBytes, isNull);
    },
  );

  test('clearAll keeps clearing when size estimation fails', () async {
    final failingStatTarget = _FakeMaintenanceTarget(
      categoryId: MediaCacheCategoryId.networkImage,
      sizeError: StateError('stat failed'),
    );
    final normalTarget = _FakeMaintenanceTarget(
      categoryId: MediaCacheCategoryId.videoThumbnail,
      sizeBytes: 2048,
    );
    final service = MediaCacheMaintenanceService(
      targets: [failingStatTarget, normalTarget],
    );

    final result = await service.clearAll();

    expect(failingStatTarget.clearCalls, 1);
    expect(normalTarget.clearCalls, 1);
    expect(result.isSuccess, isTrue);
    expect(result.clearedKnownBytes, 2048);
    expect(result.categories.first.sizeBeforeBytes, isNull);
  });

  test(
    'clearAll reports partial failures without rolling back successes',
    () async {
      final successTarget = _FakeMaintenanceTarget(
        categoryId: MediaCacheCategoryId.networkImage,
        sizeBytes: 1024,
      );
      final failingTarget = _FakeMaintenanceTarget(
        categoryId: MediaCacheCategoryId.videoThumbnail,
        sizeBytes: 2048,
        clearError: StateError('clear failed'),
      );
      final service = MediaCacheMaintenanceService(
        targets: [successTarget, failingTarget],
      );

      final result = await service.clearAll();

      expect(successTarget.clearCalls, 1);
      expect(failingTarget.clearCalls, 1);
      expect(result.isPartialFailure, isTrue);
      expect(result.clearedKnownBytes, 1024);
      expect(result.categories.last.success, isFalse);
    },
  );

  test(
    'network image target uses allowlisted DefaultCacheManager directory',
    () async {
      final root = await Directory.systemTemp.createTemp('media_cache_target_');
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      const cacheKey = 'libCachedImageData';
      final cacheDir = Directory(p.join(root.path, cacheKey));
      await cacheDir.create(recursive: true);
      await File(
        p.join(cacheDir.path, 'image.bin'),
      ).writeAsBytes(List<int>.filled(128, 1), flush: true);
      await File(
        p.join(root.path, 'outside.bin'),
      ).writeAsBytes(List<int>.filled(1024, 2), flush: true);
      var clearCalls = 0;
      final target = DefaultNetworkImageCacheMaintenanceTarget(
        fileSystem: const MediaCacheFileSystem(),
        cacheKey: cacheKey,
        clearCache: () async {
          clearCalls += 1;
        },
        temporaryDirectoryResolver: () async => root,
      );

      final size = await target.estimateSizeBytes();
      await target.clear();

      expect(size, 128);
      expect(clearCalls, 1);
    },
  );
}

class _FakeMaintenanceTarget implements MediaCacheMaintenanceTarget {
  _FakeMaintenanceTarget({
    required this.categoryId,
    this.sizeBytes,
    this.sizeError,
    this.clearError,
  });

  @override
  final MediaCacheCategoryId categoryId;
  final int? sizeBytes;
  final Object? sizeError;
  final Object? clearError;
  int clearCalls = 0;

  @override
  Future<int?> estimateSizeBytes() async {
    final error = sizeError;
    if (error != null) throw error;
    return sizeBytes;
  }

  @override
  Future<void> clear() async {
    clearCalls += 1;
    final error = clearError;
    if (error != null) throw error;
  }
}

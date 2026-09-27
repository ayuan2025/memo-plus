import 'dart:async';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/video_thumbnail_cache.dart';
import '../attachments/compression/compression_cache_store.dart';
import 'media_cache_file_system.dart';
import 'media_cache_maintenance_models.dart';

abstract class MediaCacheMaintenanceTarget {
  MediaCacheCategoryId get categoryId;

  Future<int?> estimateSizeBytes();

  Future<void> clear();
}

class MediaCacheMaintenanceService {
  MediaCacheMaintenanceService({
    required List<MediaCacheMaintenanceTarget> targets,
  }) : _targets = List<MediaCacheMaintenanceTarget>.unmodifiable(targets);

  factory MediaCacheMaintenanceService.defaults() {
    const fileSystem = MediaCacheFileSystem();
    return MediaCacheMaintenanceService(
      targets: [
        DefaultNetworkImageCacheMaintenanceTarget(fileSystem: fileSystem),
        FlutterImageMemoryCacheMaintenanceTarget(),
        const VideoThumbnailCacheMaintenanceTarget(),
        ImageCompressionTemporaryCacheMaintenanceTarget(
          store: CompressionCacheStore(),
        ),
      ],
    );
  }

  final List<MediaCacheMaintenanceTarget> _targets;

  Future<MediaCacheSummary> loadSummary() async {
    final summaries = <MediaCacheCategorySummary>[];
    for (final target in _targets) {
      try {
        final bytes = await target.estimateSizeBytes();
        summaries.add(
          MediaCacheCategorySummary(
            categoryId: target.categoryId,
            sizeBytes: bytes,
          ),
        );
      } catch (error) {
        summaries.add(
          MediaCacheCategorySummary(
            categoryId: target.categoryId,
            sizeBytes: null,
            error: error,
          ),
        );
      }
    }
    return MediaCacheSummary(categories: List.unmodifiable(summaries));
  }

  Future<MediaCacheClearResult> clearAll() async {
    final results = <MediaCacheCategoryClearResult>[];
    for (final target in _targets) {
      int? sizeBeforeBytes;
      try {
        sizeBeforeBytes = await target.estimateSizeBytes();
      } catch (_) {
        sizeBeforeBytes = null;
      }

      try {
        await target.clear();
        results.add(
          MediaCacheCategoryClearResult(
            categoryId: target.categoryId,
            success: true,
            sizeBeforeBytes: sizeBeforeBytes,
          ),
        );
      } catch (error) {
        results.add(
          MediaCacheCategoryClearResult(
            categoryId: target.categoryId,
            success: false,
            sizeBeforeBytes: sizeBeforeBytes,
            error: error,
          ),
        );
      }
    }
    return MediaCacheClearResult(categories: List.unmodifiable(results));
  }
}

typedef DirectoryResolver = Future<Directory> Function();
typedef ImageCacheClearer = void Function();

class DefaultNetworkImageCacheMaintenanceTarget
    implements MediaCacheMaintenanceTarget {
  DefaultNetworkImageCacheMaintenanceTarget({
    required MediaCacheFileSystem fileSystem,
    Future<void> Function()? clearCache,
    DirectoryResolver? temporaryDirectoryResolver,
    String cacheKey = DefaultCacheManager.key,
  }) : _fileSystem = fileSystem,
       _clearCache = clearCache ?? DefaultCacheManager().emptyCache,
       _temporaryDirectoryResolver =
           temporaryDirectoryResolver ?? getTemporaryDirectory,
       _cacheKey = cacheKey;

  final MediaCacheFileSystem _fileSystem;
  final Future<void> Function() _clearCache;
  final DirectoryResolver _temporaryDirectoryResolver;
  final String _cacheKey;

  @override
  MediaCacheCategoryId get categoryId => MediaCacheCategoryId.networkImage;

  @override
  Future<int?> estimateSizeBytes() async {
    final temp = await _temporaryDirectoryResolver();
    final cacheDir = Directory(p.join(temp.path, _cacheKey));
    final stats = await _fileSystem.describeDirectory(cacheDir);
    return stats.bytes;
  }

  @override
  Future<void> clear() => _clearCache();
}

class FlutterImageMemoryCacheMaintenanceTarget
    implements MediaCacheMaintenanceTarget {
  FlutterImageMemoryCacheMaintenanceTarget({ImageCacheClearer? clearImages})
    : _clearImages = clearImages ?? _clearFlutterImageCache;

  final ImageCacheClearer _clearImages;

  @override
  MediaCacheCategoryId get categoryId =>
      MediaCacheCategoryId.flutterImageMemory;

  @override
  Future<int?> estimateSizeBytes() async {
    final imageCache = PaintingBinding.instance.imageCache;
    return imageCache.currentSizeBytes;
  }

  @override
  Future<void> clear() async {
    _clearImages();
  }

  static void _clearFlutterImageCache() {
    final imageCache = PaintingBinding.instance.imageCache;
    imageCache.clear();
    imageCache.clearLiveImages();
  }
}

class VideoThumbnailCacheMaintenanceTarget
    implements MediaCacheMaintenanceTarget {
  const VideoThumbnailCacheMaintenanceTarget();

  @override
  MediaCacheCategoryId get categoryId => MediaCacheCategoryId.videoThumbnail;

  @override
  Future<int?> estimateSizeBytes() async {
    final stats = await VideoThumbnailCache.describeCache();
    return stats.bytes;
  }

  @override
  Future<void> clear() => VideoThumbnailCache.clearCache();
}

class ImageCompressionTemporaryCacheMaintenanceTarget
    implements MediaCacheMaintenanceTarget {
  const ImageCompressionTemporaryCacheMaintenanceTarget({required this.store});

  final CompressionCacheStore store;

  @override
  MediaCacheCategoryId get categoryId =>
      MediaCacheCategoryId.imageCompressionTemporary;

  @override
  Future<int?> estimateSizeBytes() async {
    final stats = await store.describeCache();
    return stats.bytes;
  }

  @override
  Future<void> clear() => store.clearCache();
}

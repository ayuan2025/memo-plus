import 'dart:io';

class MediaCacheDirectoryStats {
  const MediaCacheDirectoryStats({required this.bytes, required this.files});

  final int bytes;
  final int files;
}

class MediaCacheFileSystem {
  const MediaCacheFileSystem();

  Future<MediaCacheDirectoryStats> describeDirectory(Directory dir) async {
    if (!await dir.exists()) {
      return const MediaCacheDirectoryStats(bytes: 0, files: 0);
    }
    var bytes = 0;
    var files = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      try {
        bytes += await entity.length();
        files += 1;
      } catch (_) {
        // Ignore files that disappear or cannot be read while summarizing.
      }
    }
    return MediaCacheDirectoryStats(bytes: bytes, files: files);
  }

  Future<void> clearDirectoryContents(Directory dir) async {
    if (!await dir.exists()) return;
    await for (final entity in dir.list(followLinks: false)) {
      try {
        await entity.delete(recursive: true);
      } catch (_) {
        rethrow;
      }
    }
  }
}

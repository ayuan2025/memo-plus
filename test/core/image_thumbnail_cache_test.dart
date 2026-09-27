import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/image_thumbnail_cache.dart';

void main() {
  group('resolveThumbnailCacheExtent', () {
    test('returns null for invalid input', () {
      expect(resolveThumbnailCacheExtent(0, 3), isNull);
      expect(resolveThumbnailCacheExtent(120, 0), isNull);
      expect(resolveThumbnailCacheExtent(double.nan, 3), isNull);
    });

    test('scales by device pixel ratio and overscan', () {
      expect(resolveThumbnailCacheExtent(100, 2), 300);
      expect(resolveThumbnailCacheExtent(100, 2, overscan: 1), 200);
    });

    test('caps decode extent at max decode px', () {
      expect(resolveThumbnailCacheExtent(500, 3), 1024);
      expect(resolveThumbnailCacheExtent(500, 3, maxDecodePx: 768), 768);
    });
  });

  group('resolveAspectSafeThumbnailCacheTarget', () {
    test('preserves wide source aspect while covering square tile', () {
      final target = resolveAspectSafeThumbnailCacheTarget(
        tileWidth: 100,
        tileHeight: 100,
        devicePixelRatio: 2,
        sourceWidth: 4000,
        sourceHeight: 1000,
        overscan: 1,
      );

      expect(target.width, 800);
      expect(target.height, 200);
    });

    test('preserves tall source aspect while covering square tile', () {
      final target = resolveAspectSafeThumbnailCacheTarget(
        tileWidth: 100,
        tileHeight: 100,
        devicePixelRatio: 2,
        sourceWidth: 1000,
        sourceHeight: 4000,
        overscan: 1,
      );

      expect(target.width, 200);
      expect(target.height, 800);
    });

    test('keeps square source square for square tile', () {
      final target = resolveAspectSafeThumbnailCacheTarget(
        tileWidth: 100,
        tileHeight: 100,
        devicePixelRatio: 2,
        sourceWidth: 1200,
        sourceHeight: 1200,
        overscan: 1,
      );

      expect(target.width, 200);
      expect(target.height, 200);
    });

    test('does not force source to height-limited tile shape', () {
      final target = resolveAspectSafeThumbnailCacheTarget(
        tileWidth: 300,
        tileHeight: 100,
        devicePixelRatio: 1,
        sourceWidth: 1000,
        sourceHeight: 1000,
        overscan: 1,
      );

      expect(target.width, 300);
      expect(target.height, 300);
    });

    test('uses single-axis fallback when source dimensions are unknown', () {
      final target = resolveAspectSafeThumbnailCacheTarget(
        tileWidth: 100,
        tileHeight: 100,
        devicePixelRatio: 2,
        overscan: 1,
      );

      expect(target.width, 200);
      expect(target.height, isNull);
    });

    test('caps aspect-safe target at max decode px', () {
      final target = resolveAspectSafeThumbnailCacheTarget(
        tileWidth: 500,
        tileHeight: 500,
        devicePixelRatio: 3,
        sourceWidth: 4000,
        sourceHeight: 1000,
        overscan: 1,
        maxDecodePx: 1024,
      );

      expect(target.width, 1024);
      expect(target.height, 256);
    });
  });
}

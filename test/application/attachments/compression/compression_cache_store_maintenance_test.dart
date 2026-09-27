import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:memos_flutter_app/application/attachments/compression/compression_cache_store.dart';
import 'package:memos_flutter_app/application/attachments/compression/compression_models.dart';
import 'package:memos_flutter_app/core/debug_ephemeral_storage.dart';
import 'package:memos_flutter_app/data/models/image_compression_settings.dart';

import '../../../test_support.dart';

void main() {
  late TestSupport support;

  setUpAll(() async {
    support = await initializeTestSupport();
  });

  tearDownAll(() async {
    await support.dispose();
  });

  test('describes and clears only the image compression cache root', () async {
    final store = CompressionCacheStore();
    final outputPath = await store.resolveOutputPath(
      'cache-key',
      CompressionImageFormat.jpeg,
    );
    await File(outputPath).writeAsBytes(List<int>.filled(64, 1), flush: true);
    await store.writeManifest(
      'cache-key',
      const CompressionCacheManifest(
        status: CompressionCacheStatus.ok,
        engine: 'test',
        libraryVersion: '1',
        mode: ImageCompressionMode.quality,
        sourceFormat: CompressionImageFormat.png,
        outputFormat: CompressionImageFormat.jpeg,
        size: 64,
        width: 100,
        height: 100,
        hash: 'source',
        fallbackReason: null,
      ),
    );
    final supportDir = await resolveAppSupportDirectory();
    final neighbor = File(p.join(supportDir.path, 'neighbor.txt'));
    await neighbor.writeAsString('keep', flush: true);

    final before = await store.describeCache();
    expect(before.files, 2);
    expect(before.bytes, greaterThanOrEqualTo(64));

    await store.clearCache();

    final after = await store.describeCache();
    expect(after.files, 0);
    expect(after.bytes, 0);
    expect(await File(outputPath).exists(), isFalse);
    expect(await neighbor.readAsString(), 'keep');
  });
}

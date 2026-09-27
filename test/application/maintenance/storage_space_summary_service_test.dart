import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:memos_flutter_app/application/maintenance/media_cache_maintenance_models.dart';
import 'package:memos_flutter_app/application/maintenance/media_cache_maintenance_service.dart';
import 'package:memos_flutter_app/application/maintenance/storage_space_summary_models.dart';
import 'package:memos_flutter_app/application/maintenance/storage_space_summary_service.dart';
import 'package:memos_flutter_app/data/db/app_database.dart';

void main() {
  test(
    'summarizes MemoFlow known usage and degrades when capacity unavailable',
    () async {
      final database = _FakeStorageSummaryDatabase(
        rows: [
          _memoRow(
            uid: 'memo-1',
            content: 'hello',
            attachments: [
              _attachment(
                name: 'attachments/image-1',
                filename: 'photo.jpg',
                type: 'image/jpeg',
                size: 1024,
              ),
              _attachment(
                name: 'attachments/video-1',
                filename: 'clip.mp4',
                type: 'video/mp4',
                size: 2048,
              ),
              _attachment(
                name: 'attachments/audio-1',
                filename: 'voice.mp3',
                type: 'audio/mpeg',
                size: 4096,
              ),
              _attachment(
                name: 'attachments/doc-1',
                filename: 'paper.pdf',
                type: 'application/pdf',
                size: 8192,
              ),
            ],
          ),
          _memoRow(
            uid: 'memo-2',
            content: '你好',
            attachments: [
              _attachment(
                name: 'attachments/missing-size',
                filename: 'missing.png',
                type: 'image/png',
                size: 0,
              ),
            ],
          ),
        ],
      );
      final service = StorageSpaceSummaryService(
        database: database,
        mediaCacheMaintenanceService: MediaCacheMaintenanceService(
          targets: [
            _FakeMediaCacheTarget(
              categoryId: MediaCacheCategoryId.networkImage,
              sizeBytes: 512,
            ),
          ],
        ),
        deviceStorageCapacityAdapter:
            const UnavailableDeviceStorageCapacityAdapter(),
      );

      final summary = await service.loadSummary();

      expect(database.lastState, 'NORMAL');
      expect(summary.deviceCapacity.hasTotalBytes, isFalse);
      expect(summary.category(StorageSpaceCategoryId.cache)?.sizeBytes, 512);
      expect(
        summary.category(StorageSpaceCategoryId.noteContent)?.sizeBytes,
        11,
      );
      expect(
        summary.category(StorageSpaceCategoryId.noteImages)?.sizeBytes,
        1024,
      );
      expect(
        summary.category(StorageSpaceCategoryId.noteVideos)?.sizeBytes,
        2048,
      );
      expect(
        summary.category(StorageSpaceCategoryId.noteAudio)?.sizeBytes,
        4096,
      );
      expect(
        summary.category(StorageSpaceCategoryId.noteFiles)?.sizeBytes,
        8192,
      );
      expect(summary.knownUsageBytes, 15883);
      expect(summary.deviceUsageRatio, isNull);
    },
  );

  test('deduplicates attachment identity before adding category size', () {
    final summary = MemoStorageUsageSummaryCalculator.calculate([
      _memoRow(
        uid: 'memo-a',
        content: '',
        attachments: [
          _attachment(
            name: 'attachments/same',
            filename: 'a.jpg',
            type: 'image/jpeg',
            size: 1024,
          ),
        ],
      ),
      _memoRow(
        uid: 'memo-b',
        content: '',
        attachments: [
          _attachment(
            name: 'attachments/same',
            filename: 'copy.jpg',
            type: 'image/jpeg',
            size: 2048,
          ),
          _attachment(name: '', filename: 'unknown.bin', type: '', size: 128),
        ],
      ),
    ]);

    expect(summary.noteImageBytes, 1024);
    expect(summary.noteFileBytes, 128);
  });

  test('uses device capacity as optional denominator when available', () async {
    final service = StorageSpaceSummaryService(
      database: _FakeStorageSummaryDatabase(
        rows: [_memoRow(uid: 'memo-1', content: 'abc', attachments: const [])],
      ),
      mediaCacheMaintenanceService: MediaCacheMaintenanceService(
        targets: [
          _FakeMediaCacheTarget(
            categoryId: MediaCacheCategoryId.networkImage,
            sizeBytes: 97,
          ),
        ],
      ),
      deviceStorageCapacityAdapter: const _FakeCapacityAdapter(
        DeviceStorageCapacitySummary(totalBytes: 1000, availableBytes: 250),
      ),
    );

    final summary = await service.loadSummary();

    expect(summary.knownUsageBytes, 100);
    expect(summary.deviceUsageRatio, 0.1);
  });
}

Map<String, dynamic> _memoRow({
  required String uid,
  required String content,
  required List<Map<String, dynamic>> attachments,
}) {
  return {
    'uid': uid,
    'content': content,
    'attachments_json': jsonEncode(attachments),
  };
}

Map<String, dynamic> _attachment({
  required String name,
  required String filename,
  required String type,
  required int size,
}) {
  return {
    'name': name,
    'filename': filename,
    'type': type,
    'size': size,
    'externalLink': '',
  };
}

class _FakeStorageSummaryDatabase extends AppDatabase {
  _FakeStorageSummaryDatabase({required this.rows}) : super(dbName: 'fake.db');

  final List<Map<String, dynamic>> rows;
  String? lastState;

  @override
  Future<List<Map<String, dynamic>>> listMemoStorageSummaryRows({
    String? state,
  }) async {
    lastState = state;
    return rows;
  }
}

class _FakeCapacityAdapter implements DeviceStorageCapacityAdapter {
  const _FakeCapacityAdapter(this.summary);

  final DeviceStorageCapacitySummary summary;

  @override
  Future<DeviceStorageCapacitySummary> loadCapacity() async => summary;
}

class _FakeMediaCacheTarget implements MediaCacheMaintenanceTarget {
  _FakeMediaCacheTarget({required this.categoryId, required this.sizeBytes});

  @override
  final MediaCacheCategoryId categoryId;
  final int sizeBytes;

  @override
  Future<int?> estimateSizeBytes() async => sizeBytes;

  @override
  Future<void> clear() async {}
}

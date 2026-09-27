import 'dart:convert';

import '../../data/db/app_database.dart';
import '../../data/models/attachment.dart';
import 'media_cache_maintenance_models.dart';
import 'media_cache_maintenance_service.dart';
import 'storage_space_summary_models.dart';

abstract class DeviceStorageCapacityAdapter {
  Future<DeviceStorageCapacitySummary> loadCapacity();
}

class UnavailableDeviceStorageCapacityAdapter
    implements DeviceStorageCapacityAdapter {
  const UnavailableDeviceStorageCapacityAdapter();

  @override
  Future<DeviceStorageCapacitySummary> loadCapacity() async {
    return const DeviceStorageCapacitySummary.unavailable();
  }
}

class StorageSpaceSummaryService {
  StorageSpaceSummaryService({
    required AppDatabase? database,
    required MediaCacheMaintenanceService mediaCacheMaintenanceService,
    required DeviceStorageCapacityAdapter deviceStorageCapacityAdapter,
    String memoState = 'NORMAL',
  }) : _database = database,
       _mediaCacheMaintenanceService = mediaCacheMaintenanceService,
       _deviceStorageCapacityAdapter = deviceStorageCapacityAdapter,
       _memoState = memoState;

  final AppDatabase? _database;
  final MediaCacheMaintenanceService _mediaCacheMaintenanceService;
  final DeviceStorageCapacityAdapter _deviceStorageCapacityAdapter;
  final String _memoState;

  Future<StorageSpaceSummary> loadSummary() async {
    final mediaCacheSummary = await _mediaCacheMaintenanceService.loadSummary();
    final memoSummary = await loadMemoUsageSummary();
    final deviceCapacity = await _loadDeviceCapacity();

    return StorageSpaceSummary(
      categories: [
        StorageSpaceCategorySummary(
          categoryId: StorageSpaceCategoryId.cache,
          sizeBytes: mediaCacheSummary.totalKnownSizeBytes,
          clearable: true,
          error: mediaCacheSummary.hasFailures ? mediaCacheSummary : null,
        ),
        StorageSpaceCategorySummary(
          categoryId: StorageSpaceCategoryId.noteContent,
          sizeBytes: memoSummary.noteContentBytes,
        ),
        StorageSpaceCategorySummary(
          categoryId: StorageSpaceCategoryId.noteImages,
          sizeBytes: memoSummary.noteImageBytes,
        ),
        StorageSpaceCategorySummary(
          categoryId: StorageSpaceCategoryId.noteVideos,
          sizeBytes: memoSummary.noteVideoBytes,
        ),
        StorageSpaceCategorySummary(
          categoryId: StorageSpaceCategoryId.noteAudio,
          sizeBytes: memoSummary.noteAudioBytes,
        ),
        StorageSpaceCategorySummary(
          categoryId: StorageSpaceCategoryId.noteFiles,
          sizeBytes: memoSummary.noteFileBytes,
        ),
      ],
      deviceCapacity: deviceCapacity,
      mediaCacheSummary: mediaCacheSummary,
    );
  }

  Future<MemoStorageUsageSummary> loadMemoUsageSummary() async {
    final database = _database;
    if (database == null) return const MemoStorageUsageSummary.empty();
    final rows = await database.listMemoStorageSummaryRows(state: _memoState);
    return MemoStorageUsageSummaryCalculator.calculate(rows);
  }

  Future<MediaCacheClearResult> clearCache() {
    return _mediaCacheMaintenanceService.clearAll();
  }

  Future<DeviceStorageCapacitySummary> _loadDeviceCapacity() async {
    try {
      return await _deviceStorageCapacityAdapter.loadCapacity();
    } catch (error) {
      return DeviceStorageCapacitySummary.unavailable(error);
    }
  }
}

class MemoStorageUsageSummaryCalculator {
  const MemoStorageUsageSummaryCalculator._();

  static MemoStorageUsageSummary calculate(List<Map<String, dynamic>> rows) {
    var noteContentBytes = 0;
    var noteImageBytes = 0;
    var noteVideoBytes = 0;
    var noteAudioBytes = 0;
    var noteFileBytes = 0;
    final seenAttachmentIdentities = <String>{};

    for (final row in rows) {
      final memoUid = _readString(row['uid']);
      noteContentBytes += utf8.encode(_readString(row['content'])).length;

      for (final attachment in _readAttachments(row['attachments_json'])) {
        final identity = _attachmentIdentity(attachment, memoUid);
        if (!seenAttachmentIdentities.add(identity)) continue;

        final size = attachment.size > 0 ? attachment.size : 0;
        if (attachment.isImage) {
          noteImageBytes += size;
        } else if (attachment.isVideo) {
          noteVideoBytes += size;
        } else if (attachment.isAudio) {
          noteAudioBytes += size;
        } else {
          noteFileBytes += size;
        }
      }
    }

    return MemoStorageUsageSummary(
      noteContentBytes: noteContentBytes,
      noteImageBytes: noteImageBytes,
      noteVideoBytes: noteVideoBytes,
      noteAudioBytes: noteAudioBytes,
      noteFileBytes: noteFileBytes,
    );
  }

  static List<Attachment> _readAttachments(Object? raw) {
    final text = _readString(raw).trim();
    if (text.isEmpty || text == '[]') return const [];

    try {
      final decoded = jsonDecode(text);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => Attachment.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  static String _attachmentIdentity(Attachment attachment, String memoUid) {
    final name = attachment.name.trim();
    if (name.isNotEmpty) return 'name:$name';

    final uid = attachment.uid.trim();
    if (uid.isNotEmpty) return 'uid:$uid';

    final externalLink = attachment.externalLink.trim();
    if (externalLink.isNotEmpty) return 'external:$externalLink';

    return [
      'memo:$memoUid',
      'filename:${attachment.filename.trim()}',
      'size:${attachment.size}',
      'type:${attachment.type.trim()}',
    ].join('|');
  }

  static String _readString(Object? raw) {
    if (raw is String) return raw;
    return raw?.toString() ?? '';
  }
}

import 'dart:convert';

import '../../core/memo_relations.dart';
import 'content_fingerprint.dart';
import 'attachment.dart';
import 'memo.dart';
import 'memo_location.dart';

enum SyncState { synced, pending, error }

class LocalMemo {
  const LocalMemo({
    required this.uid,
    required this.content,
    required this.contentFingerprint,
    required this.visibility,
    required this.pinned,
    required this.state,
    required this.createTime,
    this.displayTime,
    required this.updateTime,
    required this.tags,
    required this.attachments,
    required this.relationCount,
    this.location,
    required this.syncState,
    required this.lastError,
  });

  final String uid;
  final String content;
  final String contentFingerprint;
  final String visibility;
  final bool pinned;
  final String state;
  final DateTime createTime;
  final DateTime? displayTime;
  final DateTime updateTime;
  final List<String> tags;
  final List<Attachment> attachments;
  final int relationCount;
  final MemoLocation? location;
  final SyncState syncState;
  final String? lastError;

  DateTime get effectiveDisplayTime => displayTime ?? createTime;

  factory LocalMemo.fromRemote(Memo memo) {
    return LocalMemo(
      uid: memo.uid,
      content: memo.content,
      contentFingerprint: memo.contentFingerprint,
      visibility: memo.visibility,
      pinned: memo.pinned,
      state: memo.state,
      createTime: memo.createTime.toLocal(),
      displayTime: memo.displayTime?.toLocal(),
      updateTime: memo.updateTime.toLocal(),
      tags: memo.tags,
      attachments: memo.attachments,
      relationCount: countReferenceRelations(
        memoUid: memo.uid,
        relations: memo.relations,
      ),
      location: memo.location,
      syncState: SyncState.synced,
      lastError: null,
    );
  }

  factory LocalMemo.fromDb(Map<String, dynamic> row) {
    final content = (row['content'] as String?) ?? '';
    final tagsText = (row['tags'] as String?) ?? '';
    final attachmentsJson = (row['attachments_json'] as String?) ?? '[]';

    final attachments = <Attachment>[];
    try {
      final decoded = jsonDecode(attachmentsJson);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            attachments.add(Attachment.fromJson(item.cast<String, dynamic>()));
          }
        }
      }
    } catch (_) {}

    final syncStateInt = (row['sync_state'] as int?) ?? 0;
    final syncState = switch (syncStateInt) {
      1 => SyncState.pending,
      2 => SyncState.error,
      _ => SyncState.synced,
    };

    final contentFingerprint = computeContentFingerprint(content);

    final location = _parseLocation(
      placeholder: row['location_placeholder'],
      latitude: row['location_lat'],
      longitude: row['location_lng'],
    );

    return LocalMemo(
      uid: (row['uid'] as String?) ?? '',
      content: content,
      contentFingerprint: contentFingerprint,
      visibility: (row['visibility'] as String?) ?? 'PRIVATE',
      pinned: ((row['pinned'] as int?) ?? 0) == 1,
      state: (row['state'] as String?) ?? 'NORMAL',
      createTime: DateTime.fromMillisecondsSinceEpoch(
        ((row['create_time'] as int?) ?? 0) * 1000,
        isUtc: true,
      ).toLocal(),
      displayTime: _parseOptionalTime(row['display_time']),
      updateTime: DateTime.fromMillisecondsSinceEpoch(
        ((row['update_time'] as int?) ?? 0) * 1000,
        isUtc: true,
      ).toLocal(),
      tags: tagsText.isEmpty
          ? const []
          : tagsText
                .split(' ')
                .where((t) => t.isNotEmpty)
                .toList(growable: false),
      attachments: attachments,
      relationCount: (row['relation_count'] as int?) ?? 0,
      location: location,
      syncState: syncState,
      lastError: row['last_error'] as String?,
    );
  }

  static MemoLocation? _parseLocation({
    required dynamic placeholder,
    required dynamic latitude,
    required dynamic longitude,
  }) {
    final lat = _readDouble(latitude);
    final lng = _readDouble(longitude);
    if (lat == null || lng == null) return null;
    final text = placeholder is String
        ? placeholder
        : placeholder?.toString() ?? '';
    return MemoLocation(placeholder: text, latitude: lat, longitude: lng);
  }

  static double? _readDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  static DateTime? _parseOptionalTime(dynamic value) {
    if (value == null) return null;
    int? seconds;
    if (value is int) {
      seconds = value;
    } else if (value is num) {
      seconds = value.toInt();
    } else if (value is String) {
      seconds = int.tryParse(value.trim());
    }
    if (seconds == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      seconds * 1000,
      isUtc: true,
    ).toLocal();
  }
}

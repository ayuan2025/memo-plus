part of 'memos_providers.dart';

class ResourceEntry {
  const ResourceEntry({
    required this.memoUid,
    required this.memoUpdateTime,
    required this.attachment,
  });

  final String memoUid;
  final DateTime memoUpdateTime;
  final Attachment attachment;
}

final resourcesProvider = StreamProvider<List<ResourceEntry>>((ref) async* {
  final db = ref.watch(databaseProvider);

  Future<List<ResourceEntry>> load() async {
    final rows = await db.listMemoAttachmentRows(state: 'NORMAL');
    final entries = <ResourceEntry>[];

    for (final row in rows) {
      final memoUid = row['uid'] as String?;
      final updateTimeSec = row['update_time'] as int?;
      final raw = row['attachments_json'] as String?;
      if (memoUid == null ||
          memoUid.isEmpty ||
          updateTimeSec == null ||
          raw == null ||
          raw.isEmpty) {
        continue;
      }

      final memoUpdateTime = DateTime.fromMillisecondsSinceEpoch(
        updateTimeSec * 1000,
        isUtc: true,
      ).toLocal();

      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              entries.add(
                ResourceEntry(
                  memoUid: memoUid,
                  memoUpdateTime: memoUpdateTime,
                  attachment: Attachment.fromJson(item.cast<String, dynamic>()),
                ),
              );
            }
          }
        }
      } catch (_) {}
    }

    entries.sort((a, b) => b.memoUpdateTime.compareTo(a.memoUpdateTime));
    return entries;
  }

  yield await load();
  await for (final _ in db.changes) {
    yield await load();
  }
});

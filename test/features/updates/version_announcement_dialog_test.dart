import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/updates/update_config.dart';
import 'package:memos_flutter_app/features/updates/version_announcement_dialog.dart';

void main() {
  group('buildVersionAnnouncementEntries', () {
    test('sorts release notes by latest version first', () {
      final entries = buildVersionAnnouncementEntries([
        const UpdateReleaseNoteEntry(
          version: '1.0.14',
          dateLabel: '2026-02-14',
          items: [],
        ),
        const UpdateReleaseNoteEntry(
          version: '1.0.16',
          dateLabel: '2026-03-07',
          items: [],
        ),
        const UpdateReleaseNoteEntry(
          version: '1.0.15',
          dateLabel: '2026-02-21',
          items: [],
        ),
      ]);

      expect(entries.map((entry) => entry.version), [
        '1.0.16',
        '1.0.15',
        '1.0.14',
      ]);
    });

    test('uses date as fallback when versions match', () {
      final entries = buildVersionAnnouncementEntries([
        const UpdateReleaseNoteEntry(
          version: 'v1.0.16',
          dateLabel: '2026-03-01',
          items: [],
        ),
        const UpdateReleaseNoteEntry(
          version: '1.0.16',
          dateLabel: '2026-03-07',
          items: [],
        ),
      ]);

      expect(entries.map((entry) => entry.dateLabel), [
        '2026-03-07',
        '2026-03-01',
      ]);
    });
  });
}

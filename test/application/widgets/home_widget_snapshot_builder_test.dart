import 'package:flutter_test/flutter_test.dart';

import 'package:memos_flutter_app/application/widgets/home_widget_snapshot_builder.dart';
import 'package:memos_flutter_app/data/models/app_preferences.dart';
import 'package:memos_flutter_app/data/models/local_memo.dart';

void main() {
  test('sanitizeMemoPreview strips markdown noise and truncates content', () {
    final memo = LocalMemo(
      uid: 'memo-1',
      content: '''# Title

See [link](https://example.com) and ```code``` text''',
      contentFingerprint: 'fp',
      visibility: 'PRIVATE',
      pinned: false,
      state: 'NORMAL',
      createTime: DateTime(2025, 3, 12, 12),
      updateTime: DateTime(2025, 3, 12, 12),
      tags: const <String>[],
      attachments: const [],
      relationCount: 0,
      location: null,
      syncState: SyncState.synced,
      lastError: null,
    );

    final preview = sanitizeMemoPreview(memo, maxLength: 24);

    expect(preview, 'Title See link and text');
  });

  test('buildDailyReviewWidgetItems returns random-walk memo items', () {
    final rows = <Map<String, dynamic>>[
      _memoRow(uid: 'memo-a', content: 'First memo'),
      _memoRow(uid: 'memo-b', content: 'Second memo'),
      _memoRow(uid: 'memo-c', content: 'Third memo'),
    ];

    final items = buildDailyReviewWidgetItems(
      rows,
      language: AppLanguage.en,
      now: DateTime(2025, 3, 12, 9),
      limit: 2,
    );

    expect(items, hasLength(2));
    expect(
      items.map((item) => item.memoUid),
      everyElement(anyOf('memo-a', 'memo-b', 'memo-c')),
    );
    expect(items.map((item) => item.excerpt), everyElement(isNotEmpty));
  });

  test(
    'buildCalendarWidgetSnapshot builds leap-year month grid and intensities',
    () {
      final rows = <Map<String, dynamic>>[
        _memoRow(
          uid: 'memo-1',
          content: 'One',
          createTime: DateTime(2024, 2, 1, 12),
        ),
        _memoRow(
          uid: 'memo-2',
          content: 'Two',
          createTime: DateTime(2024, 2, 29, 12),
        ),
        _memoRow(
          uid: 'memo-3',
          content: 'Three',
          createTime: DateTime(2024, 2, 29, 13),
        ),
        _memoRow(
          uid: 'memo-4',
          content: 'Four',
          createTime: DateTime(2024, 2, 29, 14),
        ),
        _memoRow(
          uid: 'memo-5',
          content: 'Five',
          createTime: DateTime(2024, 2, 29, 15),
        ),
      ];

      final snapshot = buildCalendarWidgetSnapshot(
        month: DateTime(2024, 2),
        rows: rows,
        language: AppLanguage.de,
        themeColorArgb: 0xFF123456,
        today: DateTime(2024, 2, 21, 10),
      );

      expect(snapshot.monthLabel, '2024-02');
      expect(snapshot.days, hasLength(42));
      expect(snapshot.themeColorArgb, 0xFF123456);
      expect(snapshot.weekdayLabels, hasLength(7));
      expect(snapshot.days[3].label, '1');
      expect(snapshot.days[0].label, '29');
      expect(snapshot.days[3].intensity, 2);
      final leapDay = snapshot.days.lastWhere(
        (day) => day.label == '29' && day.isCurrentMonth,
      );
      expect(leapDay.intensity, 6);
      expect(leapDay.dayEpochSec, isNotNull);
      final today = snapshot.days.firstWhere((day) => day.label == '21');
      expect(today.isToday, isTrue);
    },
  );

  test('buildCalendarWidgetSnapshot uses six non-empty intensity levels', () {
    final rows = <Map<String, dynamic>>[
      _memoRow(
        uid: 'memo-1-1',
        content: '1234567890',
        createTime: DateTime(2025, 3, 1, 12),
      ),
      _memoRow(
        uid: 'memo-2-1',
        content: '1234567890',
        createTime: DateTime(2025, 3, 2, 12),
      ),
      _memoRow(
        uid: 'memo-2-2',
        content: '1234567890',
        createTime: DateTime(2025, 3, 2, 13),
      ),
      _memoRow(
        uid: 'memo-3-1',
        content: '1234567890',
        createTime: DateTime(2025, 3, 3, 12),
      ),
      _memoRow(
        uid: 'memo-3-2',
        content: '1234567890',
        createTime: DateTime(2025, 3, 3, 13),
      ),
      _memoRow(
        uid: 'memo-3-3',
        content: '1234567890',
        createTime: DateTime(2025, 3, 3, 14),
      ),
      _memoRow(
        uid: 'memo-4-1',
        content: '1234567890',
        createTime: DateTime(2025, 3, 4, 12),
      ),
      _memoRow(
        uid: 'memo-4-2',
        content: '1234567890',
        createTime: DateTime(2025, 3, 4, 13),
      ),
      _memoRow(
        uid: 'memo-4-3',
        content: '1234567890',
        createTime: DateTime(2025, 3, 4, 14),
      ),
      _memoRow(
        uid: 'memo-4-4',
        content: '1234567890',
        createTime: DateTime(2025, 3, 4, 15),
      ),
      _memoRow(
        uid: 'memo-5-1',
        content: '1234567890',
        createTime: DateTime(2025, 3, 5, 12),
      ),
      _memoRow(
        uid: 'memo-5-2',
        content: '1234567890',
        createTime: DateTime(2025, 3, 5, 13),
      ),
      _memoRow(
        uid: 'memo-5-3',
        content: '1234567890',
        createTime: DateTime(2025, 3, 5, 14),
      ),
      _memoRow(
        uid: 'memo-5-4',
        content: '1234567890',
        createTime: DateTime(2025, 3, 5, 15),
      ),
      _memoRow(
        uid: 'memo-5-5',
        content: '1234567890',
        createTime: DateTime(2025, 3, 5, 16),
      ),
      _memoRow(
        uid: 'memo-6-1',
        content: '1234567890',
        createTime: DateTime(2025, 3, 6, 12),
      ),
      _memoRow(
        uid: 'memo-6-2',
        content: '1234567890',
        createTime: DateTime(2025, 3, 6, 13),
      ),
      _memoRow(
        uid: 'memo-6-3',
        content: '1234567890',
        createTime: DateTime(2025, 3, 6, 14),
      ),
      _memoRow(
        uid: 'memo-6-4',
        content: '1234567890',
        createTime: DateTime(2025, 3, 6, 15),
      ),
      _memoRow(
        uid: 'memo-6-5',
        content: '1234567890',
        createTime: DateTime(2025, 3, 6, 16),
      ),
      _memoRow(
        uid: 'memo-6-6',
        content: '1234567890',
        createTime: DateTime(2025, 3, 6, 17),
      ),
    ];

    final snapshot = buildCalendarWidgetSnapshot(
      month: DateTime(2025, 3),
      rows: rows,
      language: AppLanguage.en,
      themeColorArgb: 0xFFAA5500,
      today: DateTime(2025, 3, 12),
    );

    int intensityForDay(String label) {
      return snapshot.days
          .firstWhere((day) => day.label == label && day.isCurrentMonth)
          .intensity;
    }

    expect(intensityForDay('1'), 1);
    expect(intensityForDay('2'), 2);
    expect(intensityForDay('3'), 3);
    expect(intensityForDay('4'), 4);
    expect(intensityForDay('5'), 5);
    expect(intensityForDay('6'), 6);
    expect(intensityForDay('7'), 0);
  });

  test('buildCalendarWidgetSnapshot keeps placeholders outside month', () {
    final snapshot = buildCalendarWidgetSnapshot(
      month: DateTime(2025, 3),
      rows: const <Map<String, dynamic>>[],
      language: AppLanguage.en,
      themeColorArgb: 0xFFAA5500,
      today: DateTime(2025, 3, 12),
    );

    expect(snapshot.days.first.label, '23');
    expect(snapshot.days.first.isCurrentMonth, isFalse);
    expect(snapshot.days.first.intensity, 0);
    expect(snapshot.days.first.dayEpochSec, isNull);
  });
}

Map<String, dynamic> _memoRow({
  required String uid,
  required String content,
  DateTime? createTime,
}) {
  final localTime = createTime ?? DateTime(2025, 3, 12, 12);
  final utcSec = localTime.toUtc().millisecondsSinceEpoch ~/ 1000;
  return <String, dynamic>{
    'uid': uid,
    'content': content,
    'visibility': 'PRIVATE',
    'pinned': 0,
    'state': 'NORMAL',
    'create_time': utcSec,
    'update_time': utcSec,
    'tags': '',
    'attachments_json': '[]',
    'relation_count': 0,
    'sync_state': 0,
    'last_error': null,
    'location_placeholder': null,
    'location_lat': null,
    'location_lng': null,
  };
}

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/features/review/random_walk_models.dart';
import 'package:memos_flutter_app/features/review/random_walk_providers.dart';
import 'package:memos_flutter_app/features/review/random_walk_sampling.dart';
import 'package:memos_flutter_app/state/tags/tag_color_lookup.dart';

void main() {
  group('sampleUpTo', () {
    test('returns all items when candidate count is below limit', () {
      final values = List<int>.generate(199, (index) => index);

      final sampled = sampleUpTo(values, 200, math.Random(7));

      expect(sampled, hasLength(199));
      expect(sampled.toSet(), values.toSet());
    });

    test('returns all items when candidate count matches limit', () {
      final values = List<int>.generate(200, (index) => index);

      final sampled = sampleUpTo(values, 200, math.Random(9));

      expect(sampled, hasLength(200));
      expect(sampled.toSet(), values.toSet());
    });

    test('caps results at the requested limit', () {
      final values = List<int>.generate(250, (index) => index);

      final sampled = sampleUpTo(values, 200, math.Random(13));

      expect(sampled, hasLength(200));
      expect(sampled.toSet(), hasLength(200));
    });

    test('returns the same sample and order for the same seed', () {
      final values = List<int>.generate(250, (index) => index);

      final first = sampleUpTo(values, 200, math.Random(17));
      final second = sampleUpTo(values, 200, math.Random(17));

      expect(second, orderedEquals(first));
    });
  });

  group('buildRandomWalkEntriesFromLocalRows', () {
    test(
      'samples from the full local candidate set before truncating to 200',
      () {
        final olderDay = DateTime.utc(2024, 1, 1, 8);
        final newestDay = DateTime.utc(2024, 1, 2, 8);
        final rows = <Map<String, dynamic>>[
          for (var index = 0; index < 50; index++)
            _memoRow(
              uid: 'older-$index',
              content: 'Older memo $index',
              createTime: olderDay.add(Duration(minutes: index)),
            ),
          for (var index = 0; index < 200; index++)
            _memoRow(
              uid: 'newer-$index',
              content: 'Newer memo $index',
              createTime: newestDay.add(Duration(minutes: index)),
            ),
        ];
        final tagColors = TagColorLookup(const []);

        final allEntries = buildRandomWalkEntriesFromLocalRows(
          rows,
          query: RandomWalkQuery(
            source: RandomWalkSourceScope.allMemos,
            selectedTagKeys: const [],
            dateStartSec: null,
            dateEndSecExclusive: null,
            sampleLimit: 999,
            sampleSeed: 23,
          ),
          tagColors: tagColors,
        );
        final sampledEntries = buildRandomWalkEntriesFromLocalRows(
          rows,
          query: RandomWalkQuery(
            source: RandomWalkSourceScope.allMemos,
            selectedTagKeys: const [],
            dateStartSec: null,
            dateEndSecExclusive: null,
            sampleLimit: 200,
            sampleSeed: 23,
          ),
          tagColors: tagColors,
        );

        expect(allEntries, hasLength(250));
        expect(sampledEntries, hasLength(200));
        expect(
          sampledEntries.any(
            (entry) => entry.memo!.createTime.isBefore(newestDay),
          ),
          isTrue,
        );
      },
    );
  });
}

Map<String, dynamic> _memoRow({
  required String uid,
  required String content,
  required DateTime createTime,
}) {
  final createTimeSec = createTime.millisecondsSinceEpoch ~/ 1000;
  return <String, dynamic>{
    'uid': uid,
    'content': content,
    'visibility': 'PRIVATE',
    'pinned': 0,
    'state': 'NORMAL',
    'create_time': createTimeSec,
    'update_time': createTimeSec,
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

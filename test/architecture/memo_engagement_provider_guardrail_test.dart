import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'memo engagement loading and mutations stay in the state seam',
    () async {
      final stateFile = File('lib/state/memos/memo_engagement_provider.dart');
      final stateContents = await stateFile.readAsString();

      const requiredStatePatterns = <String>{
        'listMemoReactions(',
        'listMemoComments(',
        'upsertMemoReaction(',
        'deleteMemoReaction(',
        'createMemoComment(',
      };

      final missing = requiredStatePatterns
          .where((pattern) => !stateContents.contains(pattern))
          .toList(growable: false);

      expect(
        missing,
        isEmpty,
        reason: missing.isEmpty
            ? null
            : 'Memo engagement API ownership should stay in '
                  'memo_engagement_provider.dart:\n${missing.join('\n')}',
      );

      final featureFiles = <File>[
        File('lib/features/memos/memo_detail_screen.dart'),
        File('lib/features/memos/widgets/memos_list_memo_card.dart'),
        File('lib/features/memos/widgets/memo_engagement_surface.dart'),
      ];
      final violations = <String>[];
      for (final file in featureFiles) {
        final contents = await file.readAsString();
        for (final pattern in requiredStatePatterns) {
          if (contents.contains(pattern)) {
            violations.add('${file.path}: $pattern');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: violations.isEmpty
            ? null
            : 'Feature files must consume memoEngagementControllerProvider '
                  'instead of owning engagement API calls:\n'
                  '${violations.join('\n')}',
      );
    },
  );

  test(
    'memo live refresh parsing and coordination stay out of widgets',
    () async {
      final dataFile = File('lib/data/api/memos_live_refresh_api.dart');
      final dataContents = await dataFile.readAsString();
      final stateFile = File('lib/state/memos/memo_engagement_provider.dart');
      final stateContents = await stateFile.readAsString();

      const requiredDataPatterns = <String>{
        'MemosLiveRefreshSseParser',
        'MemosLiveRefreshApi',
        'api/v1/sse',
        'text/event-stream',
      };
      const requiredStatePatterns = <String>{
        'MemoEngagementLiveRefreshRegistry',
        'MemoEngagementLiveRefreshCoordinator',
        'memoEngagementLiveRefreshRegistrationProvider',
        'scheduleEvent(',
        'loadReactions(force: true)',
        'loadComments(force: true)',
      };

      final missingData = requiredDataPatterns
          .where((pattern) => !dataContents.contains(pattern))
          .toList(growable: false);
      final missingState = requiredStatePatterns
          .where((pattern) => !stateContents.contains(pattern))
          .toList(growable: false);

      expect(
        missingData,
        isEmpty,
        reason: missingData.isEmpty
            ? null
            : 'SSE request and parsing ownership should stay in data/api:\n'
                  '${missingData.join('\n')}',
      );
      expect(
        missingState,
        isEmpty,
        reason: missingState.isEmpty
            ? null
            : 'Live engagement refresh ownership should stay in state/memos:\n'
                  '${missingState.join('\n')}',
      );

      final featureFiles = <File>[
        File('lib/features/memos/memo_detail_screen.dart'),
        File('lib/features/memos/widgets/memos_list_memo_card.dart'),
        File('lib/features/memos/widgets/memo_engagement_surface.dart'),
      ];
      const prohibitedFeaturePatterns = <String>{
        'MemosLiveRefreshApi',
        'MemosLiveRefreshSseParser',
        'MemosLiveRefreshEventType',
        'api/v1/sse',
        'text/event-stream',
        'watchEvents(',
        'scheduleEvent(',
      };

      final violations = <String>[];
      for (final file in featureFiles) {
        final contents = await file.readAsString();
        for (final pattern in prohibitedFeaturePatterns) {
          if (contents.contains(pattern)) {
            violations.add('${file.path}: $pattern');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: violations.isEmpty
            ? null
            : 'Feature widgets may register active engagement but must not own '
                  'SSE parsing, connection, or event mapping:\n'
                  '${violations.join('\n')}',
      );
    },
  );

  test(
    'memo engagement display cannot bypass the unified preference gate',
    () async {
      final featureFiles = <File>[
        File('lib/features/memos/memo_detail_screen.dart'),
        File('lib/features/memos/desktop_memo_reader_surface.dart'),
        File('lib/features/memos/widgets/memos_list_desktop_preview_pane.dart'),
        File('lib/features/memos/widgets/memos_list_memo_card_container.dart'),
        File('lib/features/explore/explore_screen.dart'),
        File('lib/features/notifications/notifications_screen.dart'),
      ];
      const prohibitedPatterns = <String>{
        'showEngagement: true',
        'shouldShowEngagement: true',
        'widget.showEngagement ||',
      };

      final violations = <String>[];
      for (final file in featureFiles) {
        final contents = await file.readAsString();
        for (final pattern in prohibitedPatterns) {
          if (contents.contains(pattern)) {
            violations.add('${file.path}: $pattern');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: violations.isEmpty
            ? null
            : 'Memo engagement surfaces must consume the unified resolved '
                  'gate instead of forcing likes/comments visible:\n'
                  '${violations.join('\n')}',
      );
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/ai/ai_analysis_models.dart';
import 'package:memos_flutter_app/data/models/app_preferences.dart';
import 'package:memos_flutter_app/features/review/random_walk_display.dart';
import 'package:memos_flutter_app/i18n/strings.g.dart';

void main() {
  group('exactDaysAgo', () {
    test('returns 0 for the same local day', () {
      final target = DateTime(2024, 1, 2, 0, 1);
      final now = DateTime(2024, 1, 2, 23, 59);

      expect(exactDaysAgo(target, now), 0);
      expect(formatExactDaysAgo(0, AppLanguage.zhHans), '0天前');
    });

    test('returns 1 across a date boundary even when under 24 hours', () {
      final target = DateTime(2024, 1, 1, 23, 59);
      final now = DateTime(2024, 1, 2, 0, 1);

      expect(exactDaysAgo(target, now), 1);
    });
  });

  group('resolveDayPeriod', () {
    testWidgets('maps boundary times correctly', (tester) async {
      final cases = <MapEntry<DateTime, String>>[
        MapEntry(DateTime(2024, 1, 1, 4, 59), '夜晚'),
        MapEntry(DateTime(2024, 1, 1, 5, 0), '清晨'),
        MapEntry(DateTime(2024, 1, 1, 7, 59), '清晨'),
        MapEntry(DateTime(2024, 1, 1, 8, 0), '上午'),
        MapEntry(DateTime(2024, 1, 1, 10, 59), '上午'),
        MapEntry(DateTime(2024, 1, 1, 11, 0), '中午'),
        MapEntry(DateTime(2024, 1, 1, 12, 59), '中午'),
        MapEntry(DateTime(2024, 1, 1, 13, 0), '下午'),
        MapEntry(DateTime(2024, 1, 1, 16, 59), '下午'),
        MapEntry(DateTime(2024, 1, 1, 17, 0), '傍晚'),
        MapEntry(DateTime(2024, 1, 1, 18, 59), '傍晚'),
        MapEntry(DateTime(2024, 1, 1, 19, 0), '夜晚'),
      ];

      for (final entry in cases) {
        expect(
          await _resolvePeriod(tester, entry.key),
          entry.value,
          reason: entry.key.toIso8601String(),
        );
      }
    });
  });

  group('buildAiHistoryFullBodyText', () {
    test('combines summary, narrative sections, closing, and evidence', () {
      final report = AiSavedAnalysisReport(
        taskId: 1,
        taskUid: 'task-1',
        status: AiTaskStatus.completed,
        summary: 'Summary line',
        sections: [
          const AiAnalysisSectionData(
            sectionKey: 'theme',
            title: 'Theme',
            body: 'Narrative one',
            evidenceKeys: ['e1'],
          ),
          const AiAnalysisSectionData(
            sectionKey: 'leave_space',
            title: 'Leave space',
            body: 'Ignore me',
            evidenceKeys: [],
          ),
          const AiAnalysisSectionData(
            sectionKey: 'pattern',
            title: 'Pattern',
            body: 'Narrative two',
            evidenceKeys: ['e2'],
          ),
          const AiAnalysisSectionData(
            sectionKey: 'closing',
            title: 'Closing',
            body: 'Closing words',
            evidenceKeys: [],
          ),
        ],
        evidences: List<AiAnalysisEvidenceData>.generate(
          7,
          (index) => AiAnalysisEvidenceData(
            evidenceKey: 'e$index',
            sectionKey: 'theme',
            memoUid: 'memo-$index',
            chunkId: index,
            quoteText: 'Quote $index',
            charStart: 0,
            charEnd: 7,
            relevanceScore: 0.9,
          ),
        ),
        followUpSuggestions: const ['Follow-up suggestion'],
        isStale: false,
      );

      final text = buildAiHistoryFullBodyText(report, isZh: false);

      expect(text, contains('Summary line'));
      expect(text, contains('Narrative one'));
      expect(text, contains('Narrative two'));
      expect(text, contains('Closing words'));
      expect(text, contains('This insight drew on these note fragments:'));
      expect(text, contains('- "Quote 0"'));
      expect(text, isNot(contains('Ignore me')));
      expect(text, isNot(contains('Follow-up suggestion')));
      expect(RegExp(r'- "Quote').allMatches(text), hasLength(6));
      expect(text, isNot(contains('Quote 6')));
    });

    test(
      'falls back to the first follow-up suggestion when closing is absent',
      () {
        final report = AiSavedAnalysisReport(
          taskId: 2,
          taskUid: 'task-2',
          status: AiTaskStatus.completed,
          summary: 'Another summary',
          sections: const [
            AiAnalysisSectionData(
              sectionKey: 'pattern',
              title: 'Pattern',
              body: 'Narrative body',
              evidenceKeys: [],
            ),
          ],
          evidences: const [],
          followUpSuggestions: const ['Try a slower evening reset.'],
          isStale: false,
        );

        final text = buildAiHistoryFullBodyText(report, isZh: false);

        expect(text, contains('Narrative body'));
        expect(text, contains('Try a slower evening reset.'));
      },
    );
  });
}

Future<String> _resolvePeriod(WidgetTester tester, DateTime dateTime) async {
  LocaleSettings.setLocale(AppLocale.zhHans);
  late String result;

  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            result = resolveDayPeriod(dateTime, context);
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );

  return result;
}

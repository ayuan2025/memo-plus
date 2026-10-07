import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/features/memos/theme/memo_card_theme.dart';
import 'package:memos_flutter_app/features/memos/theme/memo_themed_preview.dart';
import 'package:memos_flutter_app/features/memos/theme/memo_share_card.dart';

void main() {
  Widget wrap(Widget child, MemoCardTheme theme) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );
  }

  testWidgets('MemoThemedPreview renders the card title and time', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        MemoThemedPreview(
          content: '# 标题\n\n正文内容',
          time: DateTime(2026, 10, 7, 12, 30),
          theme: kMemoCardThemeWarmWhite,
        ),
        kMemoCardThemeWarmWhite,
      ),
    );
    await tester.pumpAndSettle();

    // Title comes from the first non-empty line (heading marks stripped) and is
    // rendered by this widget as a plain Text. The body itself is painted by
    // MemoMarkdown (RichText fragments), covered by its own tests.
    expect(find.text('标题'), findsOneWidget);
    expect(find.text('2026-10-07 12:30'), findsOneWidget);
    expect(find.text('memo+'), findsOneWidget);
  });

  testWidgets('MemoThemedPreview shows a formatted timestamp', (tester) async {
    await tester.pumpWidget(
      wrap(
        MemoThemedPreview(
          content: '正文',
          time: DateTime(2026, 10, 7, 9, 5),
          theme: kMemoCardThemeWarmWhite,
        ),
        kMemoCardThemeWarmWhite,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2026-10-07 09:05'), findsOneWidget);
  });

  testWidgets('MemoThemedPreview can hide the footer', (tester) async {
    await tester.pumpWidget(
      wrap(
        MemoThemedPreview(
          content: '正文',
          time: DateTime(2026, 10, 7),
          theme: kMemoCardThemeWarmWhite,
          showFooter: false,
        ),
        kMemoCardThemeWarmWhite,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('memo+'), findsNothing);
    expect(find.text('由 memo+ 生成'), findsNothing);
  });

  test('deriveCardTitle takes first non-empty line and strips heading marks', () {
    expect(deriveCardTitle('# 标题\n\n正文'), '标题');
    expect(deriveCardTitle('\n\n  \n正文'), '正文');
    expect(deriveCardTitle('   \n\t'), isNull);
  });

  test('formatCardTime zero-pads month/day/hour/minute', () {
    expect(formatCardTime(DateTime(2026, 1, 2, 3, 4)), '2026-01-02 03:04');
  });
}
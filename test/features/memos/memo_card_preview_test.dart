import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/models/app_preferences.dart';
import 'package:memos_flutter_app/features/memos/memo_card_preview.dart';

void main() {
  test('truncates long preview text', () {
    final content = List<String>.filled(8, 'line').join('\n');

    final result = truncateMemoCardPreview(content, collapseLongContent: true);

    expect(result.truncated, isTrue);
    expect(result.text, contains('...'));
  });

  test('preserves markdown links when truncating', () {
    final content =
        '${List<String>.filled(218, 'a').join()} [OpenAI](https://openai.com) tail';

    final result = truncateMemoCardPreview(content, collapseLongContent: true);

    expect(result.truncated, isTrue);
    expect(result.text, contains('[OpenAI](https://openai.com)'));
  });

  test('collapses quoted lines into summary when enabled', () {
    final previewText = buildMemoCardPreviewText(
      'Main line\n> Quote 1\n> Quote 2',
      collapseReferences: true,
      language: AppLanguage.en,
    );

    expect(previewText, 'Main line\n\nQuoted 2 lines');
  });

  test('normalizes html-heavy preview content into lightweight text', () {
    final previewText = buildMemoCardPreviewText(
      '# Clip title\n\n'
      'Intro <img src="https://example.com/clip.jpg"> tail\n\n'
      '- [x] done\n\n'
      '[OpenAI](https://openai.com)',
      collapseReferences: false,
      language: AppLanguage.en,
    );

    expect(previewText, contains('Clip title'));
    expect(previewText, contains('Intro tail'));
    expect(previewText, contains('☑ done'));
    expect(previewText, contains('OpenAI'));
    expect(previewText, isNot(contains('<img')));
    expect(previewText, isNot(contains('https://example.com/clip.jpg')));
  });

  test('preview plan separates measurement text from render source', () {
    final plan = buildMemoCardPreviewPlan(
      '上标 x<sup>2</sup>\n\n这里是 `inline code` 示例',
      collapseReferences: false,
      language: AppLanguage.en,
      collapseLongContent: true,
    );

    expect(plan.measurementText, contains('上标 x2'));
    expect(plan.measurementText, contains('这里是 inline code 示例'));
    expect(plan.measurementText, isNot(contains('<sup>')));
    expect(plan.measurementText, isNot(contains('`inline code`')));
    expect(plan.renderSource, contains('<sup>2</sup>'));
    expect(plan.renderSource, contains('`inline code`'));
    expect(plan.preview.truncated, isFalse);
  });

  test('preview plan applies reference collapse to measurement and source', () {
    final plan = buildMemoCardPreviewPlan(
      '**Main**\n> Quote 1\n> Quote 2',
      collapseReferences: true,
      language: AppLanguage.en,
      collapseLongContent: true,
    );

    expect(plan.measurementText, contains('Main'));
    expect(plan.measurementText, contains('Quoted 2 lines'));
    expect(plan.measurementText, isNot(contains('Quote 1')));
    expect(plan.renderSource, contains('**Main**'));
    expect(plan.renderSource, contains('Quoted 2 lines'));
    expect(plan.renderSource, isNot(contains('> Quote 1')));
  });

  test('long preview plan does not truncate render source before markdown', () {
    final content =
        '```dart\n'
        'final x = 1;\n'
        '```\n\n'
        '${List<String>.generate(12, (index) => 'line $index').join('\n')}';

    final plan = buildMemoCardPreviewPlan(
      content,
      collapseReferences: false,
      language: AppLanguage.en,
      collapseLongContent: true,
    );

    expect(plan.preview.truncated, isTrue);
    expect(plan.preview.text, contains('...'));
    expect(plan.renderSource, contains('```dart'));
    expect(plan.renderSource, contains('final x = 1;'));
    expect(plan.renderSource, contains('line 11'));
    expect(plan.renderSource, isNot(endsWith('...')));
  });
}

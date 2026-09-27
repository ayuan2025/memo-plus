import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/models/memo_clip_card_metadata.dart';
import 'package:memos_flutter_app/features/memos/widgets/memo_clip_card_header.dart';

void main() {
  MemoClipCardMetadata buildMetadata({
    required MemoClipPlatform platform,
    required String sourceName,
    required String authorName,
  }) {
    final now = DateTime(2026, 4, 19, 12, 34);
    return MemoClipCardMetadata(
      memoUid: 'memo-1',
      clipKind: MemoClipKind.article,
      platform: platform,
      sourceName: sourceName,
      sourceAvatarUrl: '',
      authorName: authorName,
      authorAvatarUrl: '',
      sourceUrl: 'https://example.com/post',
      leadImageUrl: '',
      parserTag: memoClipPlatformValue(platform),
      createdTime: now,
      updatedTime: now,
    );
  }

  Future<void> pumpHeader(
    WidgetTester tester,
    MemoClipCardMetadata metadata,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: const [Locale('zh')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: MemoClipReadonlyHeader(
            metadata: metadata,
            title: 'Example title',
          ),
        ),
      ),
    );
  }

  testWidgets(
    'coolapk header uses author as primary identity and neutral platform text',
    (tester) async {
      await pumpHeader(
        tester,
        buildMetadata(
          platform: MemoClipPlatform.coolapk,
          sourceName: '\u9177\u5b89',
          authorName: '\u7231\u559d\u56db\u5b63\u6625\u8336\u7684\u74dc\u76ae',
        ),
      );

      expect(
        find.text('\u7231\u559d\u56db\u5b63\u6625\u8336\u7684\u74dc\u76ae'),
        findsOneWidget,
      );
      expect(find.text('\u9177\u5b89'), findsOneWidget);

      final platformLabelFinder = find.text('\u9177\u5b89');
      final platformLabelText = tester.widget<Text>(platformLabelFinder);
      final theme = Theme.of(tester.element(platformLabelFinder));
      expect(
        platformLabelText.style?.color,
        theme.colorScheme.onSurfaceVariant,
      );
      final logoImage = tester.widget<Image>(find.byType(Image).first);
      expect(
        logoImage.image,
        isA<AssetImage>().having(
          (image) => image.assetName,
          'assetName',
          'assets/images/coolapk_logo.png',
        ),
      );
    },
  );

  testWidgets('non-coolapk header still shows source and author', (
    tester,
  ) async {
    await pumpHeader(
      tester,
      buildMetadata(
        platform: MemoClipPlatform.wechat,
        sourceName: '\u4e2d\u56fd\u6c11\u5175',
        authorName: '\u7f16\u8f91\u90e8',
      ),
    );

    expect(find.text('\u4e2d\u56fd\u6c11\u5175'), findsOneWidget);
    expect(find.text('\u7f16\u8f91\u90e8'), findsOneWidget);
  });
}

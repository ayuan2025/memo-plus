import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/i18n/strings.g.dart';

void main() {
  test('engagement preference copy is surface agnostic', () {
    expect(
      AppLocale.en.build().strings.settings.preferences.showMemoEngagement,
      'Show likes and comments',
    );
    expect(
      AppLocale.de.build().strings.settings.preferences.showMemoEngagement,
      'Likes und Kommentare anzeigen',
    );
    expect(
      AppLocale.ja.build().strings.settings.preferences.showMemoEngagement,
      'いいねとコメントを表示',
    );
    expect(
      AppLocale.ko.build().strings.settings.preferences.showMemoEngagement,
      '좋아요와 댓글 표시',
    );
    expect(
      AppLocale.ptBr.build().strings.settings.preferences.showMemoEngagement,
      'Mostrar curtidas e comentários',
    );
    expect(
      AppLocale.zhHans.build().strings.settings.preferences.showMemoEngagement,
      '显示点赞与评论',
    );
    expect(
      AppLocale.zhHantTw
          .build()
          .strings
          .settings
          .preferences
          .showMemoEngagement,
      '顯示按讚與評論',
    );
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memos_flutter_app/core/app_localization.dart';
import 'package:memos_flutter_app/core/sync_feedback.dart';
import 'package:memos_flutter_app/data/models/app_preferences.dart';
import 'package:memos_flutter_app/i18n/strings.g.dart';

void main() {
  group('Chinese localization', () {
    test('zh-Hans keeps key UI labels in Chinese', () {
      final t = AppLocale.zhHans.build();

      expect(t.strings.onboarding.modeLocalLabel, '本地模式');
      expect(t.strings.onboarding.modeServerLabel, '服务器模式');
      expect(
        t.strings.common.serverVersionProbeHint,
        '登录前，仅会探测所选服务端版本的核心 API。',
      );
      expect(t.strings.login.field.tokenLabel, '令牌（PAT）');
      expect(t.strings.legacy.msg_query, '查询参数');
      expect(t.strings.legacy.msg_body_json, '请求体（JSON）');
      expect(t.strings.legacy.msg_webhooks, '网络回调');
      expect(t.strings.legacy.msg_comments(widget_commentCount: 3), '3 条评论');
      expect(t.strings.legacy.msg_web_api_key, 'Web API 密钥');
      expect(t.strings.legacy.msg_back_2, '返回');
      expect(t.strings.legacy.msg_energy_restored, '⚡ 能量已恢复');
      expect(
        t.strings.legacy.msg_webhooks_not_supported_server,
        '当前服务器不支持网络回调',
      );
    });

    test('zh-Hant-TW keeps key UI labels in Traditional Chinese', () {
      final t = AppLocale.zhHantTw.build();

      expect(
        t.strings.common.serverVersionProbeHint,
        '登入前，僅會探測所選伺服器版本的核心 API。',
      );
      expect(t.strings.login.field.tokenLabel, '權杖（PAT）');
      expect(t.strings.legacy.msg_query, '查詢參數');
      expect(t.strings.legacy.msg_body_json, '請求本文（JSON）');
      expect(t.strings.legacy.msg_webhooks, '網路回呼');
      expect(t.strings.legacy.msg_restored, '已恢復');
      expect(t.strings.legacy.msg_comments(widget_commentCount: 3), '3 則評論');
      expect(t.strings.legacy.msg_web_api_key, 'Web API 金鑰');
      expect(t.strings.legacy.msg_back_2, '返回');
      expect(t.strings.legacy.msg_energy_restored, '⚡ 能量已恢復');
      expect(
        t.strings.legacy.msg_webhooks_not_supported_server,
        '目前伺服器不支援網路回呼',
      );
    });
  });

  group('Brazilian Portuguese localization', () {
    test('pt-BR keeps key UI labels in Portuguese', () {
      final t = AppLocale.ptBr.build();

      expect(t.strings.common.back, 'Voltar');
      expect(t.strings.common.cancel, 'Cancelar');
      expect(t.strings.common.confirm, 'Confirmar');
      expect(
        t.strings.common.serverVersionValue(version: '0.26.0'),
        'Vers\u00e3o do servidor: 0.26.0',
      );
      expect(t.strings.onboarding.selectLanguage, 'Selecione o idioma');
      expect(t.strings.languages.ptBr, 'Portugu\u00eas (Brasil)');
      expect(t.strings.languagesNative.ptBr, 'Portugu\u00eas (Brasil)');
      expect(t.strings.legacy.app_language.pt_br, 'Portugu\u00eas (Brasil)');
    });

    test('supported locales include pt-BR', () {
      expect(AppLocaleUtils.supportedLocalesRaw, contains('pt-BR'));
      expect(
        AppLocaleUtils.supportedLocales,
        contains(AppLocale.ptBr.flutterLocale),
      );
    });

    test('Portuguese device locales map to Brazilian Portuguese', () {
      expect(
        appLanguageFromLocale(
          const Locale.fromSubtags(languageCode: 'pt', countryCode: 'BR'),
        ),
        AppLanguage.ptBr,
      );
      expect(
        appLanguageFromLocale(
          const Locale.fromSubtags(languageCode: 'pt', countryCode: 'PT'),
        ),
        AppLanguage.ptBr,
      );
      expect(appLocaleForLanguage(AppLanguage.ptBr), AppLocale.ptBr);
    });

    test('existing non-Portuguese locale mappings remain stable', () {
      expect(
        appLanguageFromLocale(
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
        ),
        AppLanguage.zhHans,
      );
      expect(
        appLanguageFromLocale(
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        ),
        AppLanguage.zhHantTw,
      );
      expect(appLanguageFromLocale(const Locale('ja')), AppLanguage.ja);
      expect(appLanguageFromLocale(const Locale('de')), AppLanguage.de);
      expect(appLanguageFromLocale(const Locale('en')), AppLanguage.en);
    });
  });

  group('Korean localization', () {
    test('ko keeps key UI labels in Korean', () {
      final t = AppLocale.ko.build();

      expect(t.strings.common.back, '뒤로');
      expect(t.strings.common.cancel, '취소');
      expect(t.strings.common.confirm, '확인');
      expect(
        t.strings.common.serverVersionValue(version: '0.26.0'),
        '서버 버전: 0.26.0',
      );
      expect(t.strings.onboarding.selectLanguage, '언어 선택');
      expect(t.strings.settings.preferences.language, '언어');
      expect(t.strings.languages.ko, '한국어');
      expect(t.strings.languagesNative.ko, '한국어');
      expect(t.strings.legacy.app_language.ko, '한국어');
    });

    test('supported locales include Korean', () {
      expect(AppLocaleUtils.supportedLocalesRaw, contains('ko'));
      expect(
        AppLocaleUtils.supportedLocales,
        contains(AppLocale.ko.flutterLocale),
      );
    });

    test('Korean device locale maps to Korean', () {
      expect(appLanguageFromLocale(const Locale('ko')), AppLanguage.ko);
      expect(
        appLanguageFromLocale(
          const Locale.fromSubtags(languageCode: 'ko', countryCode: 'KR'),
        ),
        AppLanguage.ko,
      );
      expect(appLocaleForDeviceLocale(const Locale('ko')), AppLocale.ko);
      expect(appLocaleForLanguage(AppLanguage.ko), AppLocale.ko);
      expect(AppLanguage.ko.name, 'ko');
    });

    testWidgets('Follow System resolves Korean device locale to Korean', (
      tester,
    ) async {
      tester.binding.platformDispatcher.localeTestValue = const Locale('ko');
      addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);

      expect(appLocaleForLanguage(AppLanguage.system), AppLocale.ko);
      expect(localeTagForAppLanguage(AppLanguage.system), 'ko');
    });

    test('existing non-Korean locale mappings remain stable', () {
      expect(
        appLanguageFromLocale(
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
        ),
        AppLanguage.zhHans,
      );
      expect(
        appLanguageFromLocale(
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        ),
        AppLanguage.zhHantTw,
      );
      expect(appLanguageFromLocale(const Locale('ja')), AppLanguage.ja);
      expect(appLanguageFromLocale(const Locale('de')), AppLanguage.de);
      expect(appLanguageFromLocale(const Locale('pt')), AppLanguage.ptBr);
      expect(appLanguageFromLocale(const Locale('en')), AppLanguage.en);
    });

    test('manual Korean localization paths are covered', () {
      expect(
        buildSyncFeedbackMessage(language: AppLanguage.ko, succeeded: true),
        '동기화 완료',
      );
      expect(
        buildSyncFeedbackMessage(language: AppLanguage.ko, succeeded: false),
        '동기화 실패',
      );
      expect(
        buildAutoSyncProgressMessage(language: AppLanguage.ko),
        '자동 동기화 진행 중...',
      );
      expect(aiOutputLanguageNameFor(AppLanguage.ko), 'Korean');
      expect(localeTagForAppLanguage(AppLanguage.ko), 'ko');
    });
  });
}

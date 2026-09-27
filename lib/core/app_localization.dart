import 'package:flutter/widgets.dart';

import '../data/models/app_preferences.dart';
import '../i18n/strings.g.dart';

AppLanguage appLanguageFromLocale(Locale locale) {
  switch (locale.languageCode.toLowerCase()) {
    case 'en':
      return AppLanguage.en;
    case 'ja':
      return AppLanguage.ja;
    case 'de':
      return AppLanguage.de;
    case 'ko':
      return AppLanguage.ko;
    case 'pt':
      return AppLanguage.ptBr;
    case 'zh':
      return _isTraditionalZhLocale(locale)
          ? AppLanguage.zhHantTw
          : AppLanguage.zhHans;
    default:
      return AppLanguage.en;
  }
}

bool _isTraditionalZhLocale(Locale locale) {
  if (locale.languageCode.toLowerCase() != 'zh') return false;
  final script = locale.scriptCode?.toLowerCase();
  if (script == 'hant') return true;
  final region = locale.countryCode?.toUpperCase();
  return region == 'TW' || region == 'HK' || region == 'MO';
}

bool _devicePrefersZh() {
  return _devicePrefersLanguage(AppLanguage.zhHans) ||
      _devicePrefersLanguage(AppLanguage.zhHantTw);
}

bool _devicePrefersLanguage(AppLanguage language) {
  return appLanguageFromLocale(
        WidgetsBinding.instance.platformDispatcher.locale,
      ) ==
      language;
}

bool _devicePrefersTraditionalZh() {
  return _isTraditionalZhLocale(
    WidgetsBinding.instance.platformDispatcher.locale,
  );
}

bool prefersEnglishFor(AppLanguage language) {
  return switch (language) {
    AppLanguage.en => true,
    AppLanguage.zhHans => false,
    AppLanguage.zhHantTw => false,
    AppLanguage.system => !_devicePrefersZh(),
    AppLanguage.ja => true,
    AppLanguage.de => true,
    AppLanguage.ptBr => true,
    AppLanguage.ko => true,
  };
}

bool prefersTraditionalFor(AppLanguage language) {
  return switch (language) {
    AppLanguage.zhHantTw => true,
    AppLanguage.system => _devicePrefersTraditionalZh(),
    _ => false,
  };
}

AppLocale _deviceLocaleToAppLocale(Locale locale) {
  return switch (locale.languageCode.toLowerCase()) {
    'zh' =>
      _isTraditionalZhLocale(locale) ? AppLocale.zhHantTw : AppLocale.zhHans,
    'ja' => AppLocale.ja,
    'de' => AppLocale.de,
    'ko' => AppLocale.ko,
    'pt' => AppLocale.ptBr,
    _ => AppLocale.en,
  };
}

AppLocale appLocaleForDeviceLocale(Locale locale) {
  return _deviceLocaleToAppLocale(locale);
}

AppLocale appLocaleForLanguage(AppLanguage language) {
  return switch (language) {
    AppLanguage.system => _deviceLocaleToAppLocale(
      WidgetsBinding.instance.platformDispatcher.locale,
    ),
    AppLanguage.zhHans => AppLocale.zhHans,
    AppLanguage.zhHantTw => AppLocale.zhHantTw,
    AppLanguage.en => AppLocale.en,
    AppLanguage.ja => AppLocale.ja,
    AppLanguage.de => AppLocale.de,
    AppLanguage.ptBr => AppLocale.ptBr,
    AppLanguage.ko => AppLocale.ko,
  };
}

AppLanguage effectiveAppLanguage(AppLanguage language) {
  return language == AppLanguage.system
      ? appLanguageFromLocale(WidgetsBinding.instance.platformDispatcher.locale)
      : language;
}

String localeTagForAppLanguage(AppLanguage language) {
  return switch (effectiveAppLanguage(language)) {
    AppLanguage.zhHans => 'zh-Hans',
    AppLanguage.zhHantTw => 'zh-Hant-TW',
    AppLanguage.ja => 'ja',
    AppLanguage.de => 'de',
    AppLanguage.ptBr => 'pt-BR',
    AppLanguage.ko => 'ko',
    AppLanguage.en || AppLanguage.system => 'en',
  };
}

bool startsWeekOnMondayForAppLanguage(AppLanguage language) {
  return switch (effectiveAppLanguage(language)) {
    AppLanguage.de => true,
    _ => false,
  };
}

String aiOutputLanguageNameFor(AppLanguage language) {
  return switch (effectiveAppLanguage(language)) {
    AppLanguage.zhHans => 'Simplified Chinese',
    AppLanguage.zhHantTw => 'Traditional Chinese',
    AppLanguage.ko => 'Korean',
    _ => 'English',
  };
}

String trByLanguageKey({
  required AppLanguage language,
  required String key,
  Map<String, Object?> params = const {},
}) {
  final locale = appLocaleForLanguage(language);
  final translations = locale.build();
  final entry = translations['strings.$key'];
  if (entry is String) return entry;
  if (entry is Function) {
    final named = <Symbol, dynamic>{};
    params.forEach((k, v) => named[Symbol(k)] = v);
    return Function.apply(entry, const [], named) as String;
  }
  return key;
}

String trByLanguage({
  required AppLanguage language,
  required String zh,
  required String en,
}) {
  return prefersEnglishFor(language) ? en : zh;
}

String trByLocale({
  required Locale locale,
  required String zh,
  required String en,
}) {
  final code = locale.languageCode.toLowerCase();
  if (code == 'en') return en;
  if (code == 'zh') return zh;
  return _devicePrefersZh() ? zh : en;
}

extension AppLocalizationX on BuildContext {
  AppLanguage get appLanguage =>
      appLanguageFromLocale(Localizations.localeOf(this));

  String tr({required String zh, required String en}) {
    return trByLocale(locale: Localizations.localeOf(this), zh: zh, en: en);
  }
}

extension NavigatorSafePopX on BuildContext {
  void safePop<T extends Object?>([T? result]) {
    final navigator = Navigator.maybeOf(this);
    if (navigator == null || !navigator.mounted || !navigator.canPop()) return;
    navigator.pop(result);
  }
}

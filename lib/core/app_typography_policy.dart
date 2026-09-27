import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../data/models/app_preferences.dart';

const String windowsDefaultFontFamily = 'Microsoft YaHei';

const List<String> windowsDefaultFonts = [
  windowsDefaultFontFamily,
  'Microsoft YaHei UI',
  '\u5FAE\u8F6F\u96C5\u9ED1',
];

const List<String> windowsDefaultFontFallback = [
  'Microsoft YaHei UI',
  '\u5FAE\u8F6F\u96C5\u9ED1',
];

class EffectiveAppTypography {
  const EffectiveAppTypography({
    required this.themeFontFamily,
    required this.themeFontFallback,
    required this.applyUiLineHeight,
    required this.uiLineHeight,
    required this.contentLineHeight,
    required this.textScaler,
    required this.canChooseSystemFonts,
  });

  final String? themeFontFamily;
  final List<String>? themeFontFallback;
  final bool applyUiLineHeight;
  final double uiLineHeight;
  final double contentLineHeight;
  final TextScaler textScaler;
  final bool canChooseSystemFonts;
}

EffectiveAppTypography resolveEffectiveAppTypography({
  required AppFontSize fontSize,
  required AppLineHeight lineHeight,
  String? fontFamily,
  String? fontFile,
  TargetPlatform? targetPlatform,
  bool isWeb = kIsWeb,
  TextScaler systemTextScaler = TextScaler.noScaling,
}) {
  final platform = targetPlatform ?? defaultTargetPlatform;
  final appScale = appTextScaleFor(fontSize);
  final contentLineHeight = appLineHeightFor(lineHeight);
  final appleMobile = isAppleMobileTypographyTarget(
    targetPlatform: platform,
    isWeb: isWeb,
  );
  final effectiveFont = _resolveThemeFont(
    targetPlatform: platform,
    isWeb: isWeb,
    fontFamily: fontFamily,
  );

  return EffectiveAppTypography(
    themeFontFamily: effectiveFont.family,
    themeFontFallback: effectiveFont.fallback,
    applyUiLineHeight: !appleMobile,
    uiLineHeight: contentLineHeight,
    contentLineHeight: contentLineHeight,
    textScaler: appleMobile
        ? _combineTextScalers(systemTextScaler, appScale)
        : TextScaler.linear(appScale),
    canChooseSystemFonts: canChooseSystemFontsForPlatform(
      targetPlatform: platform,
      isWeb: isWeb,
    ),
  );
}

bool isAppleMobileTypographyTarget({
  TargetPlatform? targetPlatform,
  bool isWeb = kIsWeb,
}) {
  if (isWeb) return false;
  return (targetPlatform ?? defaultTargetPlatform) == TargetPlatform.iOS;
}

bool canChooseSystemFontsForPlatform({
  TargetPlatform? targetPlatform,
  bool isWeb = kIsWeb,
}) {
  if (isWeb) return false;
  return switch (targetPlatform ?? defaultTargetPlatform) {
    TargetPlatform.android ||
    TargetPlatform.macOS ||
    TargetPlatform.windows ||
    TargetPlatform.linux => true,
    TargetPlatform.iOS || TargetPlatform.fuchsia => false,
  };
}

double appTextScaleFor(AppFontSize value) {
  return switch (value) {
    AppFontSize.standard => 1.0,
    AppFontSize.large => 1.12,
    AppFontSize.small => 0.92,
  };
}

double appLineHeightFor(AppLineHeight value) {
  return switch (value) {
    AppLineHeight.classic => 1.55,
    AppLineHeight.compact => 1.35,
    AppLineHeight.relaxed => 1.75,
  };
}

_EffectiveThemeFont _resolveThemeFont({
  required TargetPlatform targetPlatform,
  required bool isWeb,
  required String? fontFamily,
}) {
  if (isAppleMobileTypographyTarget(
    targetPlatform: targetPlatform,
    isWeb: isWeb,
  )) {
    return const _EffectiveThemeFont();
  }

  final normalizedFamily = fontFamily?.trim();
  final hasFamily = normalizedFamily != null && normalizedFamily.isNotEmpty;
  if (!isWeb && targetPlatform == TargetPlatform.windows && !hasFamily) {
    return const _EffectiveThemeFont(
      family: windowsDefaultFontFamily,
      fallback: windowsDefaultFontFallback,
    );
  }

  return _EffectiveThemeFont(family: hasFamily ? normalizedFamily : null);
}

TextScaler _combineTextScalers(TextScaler systemTextScaler, double appScale) {
  if (appScale == 1.0) return systemTextScaler;
  if (identical(systemTextScaler, TextScaler.noScaling)) {
    return TextScaler.linear(appScale);
  }
  return _AppPreferenceTextScaler(systemTextScaler, appScale);
}

class _EffectiveThemeFont {
  const _EffectiveThemeFont({this.family, this.fallback});

  final String? family;
  final List<String>? fallback;
}

class _AppPreferenceTextScaler extends TextScaler {
  const _AppPreferenceTextScaler(this.base, this.appScale);

  final TextScaler base;
  final double appScale;

  @override
  double scale(double fontSize) => base.scale(fontSize) * appScale;

  @override
  double get textScaleFactor => scale(14) / 14;

  @override
  bool operator ==(Object other) {
    return other is _AppPreferenceTextScaler &&
        other.base == base &&
        other.appScale == appScale;
  }

  @override
  int get hashCode => Object.hash(base, appScale);

  @override
  String toString() => 'system text scaler with app scale ${appScale}x';
}

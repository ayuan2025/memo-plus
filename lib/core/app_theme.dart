import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/models/app_preferences.dart';
import 'app_typography_policy.dart';
import 'memoflow_palette.dart';

TextTheme _applyLineHeight(TextTheme theme, double height) {
  TextStyle? apply(TextStyle? style) => style?.copyWith(height: height);
  return theme.copyWith(
    bodyLarge: apply(theme.bodyLarge),
    bodyMedium: apply(theme.bodyMedium),
    bodySmall: apply(theme.bodySmall),
    titleLarge: apply(theme.titleLarge),
    titleMedium: apply(theme.titleMedium),
    titleSmall: apply(theme.titleSmall),
  );
}

TextTheme _applyFontFamily(
  TextTheme theme, {
  String? family,
  List<String>? fallback,
}) {
  if (family == null && (fallback == null || fallback.isEmpty)) return theme;
  return theme.apply(fontFamily: family, fontFamilyFallback: fallback);
}

ThemeData buildAppTheme(Brightness brightness) {
  final scaffoldBackgroundColor = brightness == Brightness.dark
      ? MemoFlowPalette.backgroundDark
      : MemoFlowPalette.backgroundLight;
  final seedColor = brightness == Brightness.dark
      ? MemoFlowPalette.primaryDark
      : MemoFlowPalette.primary;
  final baseScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness,
  );
  final onPrimary =
      ThemeData.estimateBrightnessForColor(seedColor) == Brightness.dark
      ? Colors.white
      : Colors.black;
  final colorScheme = baseScheme.copyWith(
    primary: seedColor,
    onPrimary: onPrimary,
  );

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: scaffoldBackgroundColor,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: scaffoldBackgroundColor.withValues(alpha: 0.9),
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: brightness == Brightness.dark
          ? MemoFlowPalette.cardDark
          : MemoFlowPalette.cardLight,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 0,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colorScheme.surfaceContainerHighest,
      contentTextStyle: TextStyle(color: colorScheme.onSurface),
      actionTextColor: colorScheme.primary,
    ),
  );
}

ThemeData applyPreferencesToTheme(
  ThemeData theme,
  AppPreferences prefs, {
  TargetPlatform? targetPlatform,
  bool isWeb = kIsWeb,
}) {
  final typography = resolveEffectiveAppTypography(
    targetPlatform: targetPlatform,
    isWeb: isWeb,
    fontSize: prefs.fontSize,
    lineHeight: prefs.lineHeight,
    fontFamily: prefs.fontFamily,
    fontFile: prefs.fontFile,
  );
  final textThemeWithFont = _applyFontFamily(
    theme.textTheme,
    family: typography.themeFontFamily,
    fallback: typography.themeFontFallback,
  );
  final primaryTextThemeWithFont = _applyFontFamily(
    theme.primaryTextTheme,
    family: typography.themeFontFamily,
    fallback: typography.themeFontFallback,
  );
  final textTheme = typography.applyUiLineHeight
      ? _applyLineHeight(textThemeWithFont, typography.uiLineHeight)
      : textThemeWithFont;
  final primaryTextTheme = typography.applyUiLineHeight
      ? _applyLineHeight(primaryTextThemeWithFont, typography.uiLineHeight)
      : primaryTextThemeWithFont;

  return theme.copyWith(
    textTheme: textTheme,
    primaryTextTheme: primaryTextTheme,
  );
}

double textScaleFor(AppFontSize v) {
  return appTextScaleFor(v);
}

double lineHeightFor(AppLineHeight v) {
  return appLineHeightFor(v);
}

ThemeMode themeModeFor(AppThemeMode mode) {
  return switch (mode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };
}

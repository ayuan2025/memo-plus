import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/app_theme.dart';
import 'package:memos_flutter_app/core/app_typography_policy.dart';
import 'package:memos_flutter_app/data/models/app_preferences.dart';

void main() {
  group('resolveEffectiveAppTypography', () {
    test('ignores persisted font family and file on iOS', () {
      final typography = resolveEffectiveAppTypography(
        targetPlatform: TargetPlatform.iOS,
        isWeb: false,
        fontSize: AppFontSize.standard,
        lineHeight: AppLineHeight.classic,
        fontFamily: 'Inter',
        fontFile: 'fonts/Inter.ttf',
      );

      expect(typography.themeFontFamily, isNull);
      expect(typography.themeFontFallback, isNull);
      expect(typography.canChooseSystemFonts, isFalse);
    });

    test('uses the same system-font rule for iPadOS target', () {
      final typography = resolveEffectiveAppTypography(
        targetPlatform: TargetPlatform.iOS,
        isWeb: false,
        fontSize: AppFontSize.large,
        lineHeight: AppLineHeight.relaxed,
        fontFamily: 'Desktop Font',
        fontFile: '/Library/Fonts/Desktop.ttf',
      );

      expect(typography.themeFontFamily, isNull);
      expect(typography.themeFontFallback, isNull);
      expect(typography.canChooseSystemFonts, isFalse);
    });

    test('preserves selected font family on non-iOS platforms', () {
      final androidTypography = resolveEffectiveAppTypography(
        targetPlatform: TargetPlatform.android,
        isWeb: false,
        fontSize: AppFontSize.standard,
        lineHeight: AppLineHeight.classic,
        fontFamily: 'Roboto Serif',
        fontFile: '/system/fonts/RobotoSerif.ttf',
      );
      final macosTypography = resolveEffectiveAppTypography(
        targetPlatform: TargetPlatform.macOS,
        isWeb: false,
        fontSize: AppFontSize.standard,
        lineHeight: AppLineHeight.classic,
        fontFamily: 'New York',
        fontFile: '/Library/Fonts/NewYork.ttf',
      );

      expect(androidTypography.themeFontFamily, 'Roboto Serif');
      expect(androidTypography.canChooseSystemFonts, isTrue);
      expect(macosTypography.themeFontFamily, 'New York');
      expect(macosTypography.canChooseSystemFonts, isTrue);
    });

    test('keeps the Windows default font fallback when no family is set', () {
      final typography = resolveEffectiveAppTypography(
        targetPlatform: TargetPlatform.windows,
        isWeb: false,
        fontSize: AppFontSize.standard,
        lineHeight: AppLineHeight.classic,
      );

      expect(typography.themeFontFamily, windowsDefaultFontFamily);
      expect(typography.themeFontFallback, windowsDefaultFontFallback);
      expect(typography.canChooseSystemFonts, isTrue);
    });

    test('combines iOS system text scaler with app font size preference', () {
      final typography = resolveEffectiveAppTypography(
        targetPlatform: TargetPlatform.iOS,
        isWeb: false,
        fontSize: AppFontSize.large,
        lineHeight: AppLineHeight.classic,
        systemTextScaler: const TextScaler.linear(1.3),
      );

      expect(typography.textScaler.scale(10), closeTo(14.56, 0.001));
    });

    test('standard iOS font size preserves system text scaling', () {
      final typography = resolveEffectiveAppTypography(
        targetPlatform: TargetPlatform.iOS,
        isWeb: false,
        fontSize: AppFontSize.standard,
        lineHeight: AppLineHeight.classic,
        systemTextScaler: const TextScaler.linear(1.3),
      );

      expect(typography.textScaler.scale(10), closeTo(13, 0.001));
    });

    test('non-iOS text scaler keeps existing app-only behavior', () {
      final typography = resolveEffectiveAppTypography(
        targetPlatform: TargetPlatform.windows,
        isWeb: false,
        fontSize: AppFontSize.large,
        lineHeight: AppLineHeight.classic,
        systemTextScaler: const TextScaler.linear(1.3),
      );

      expect(typography.textScaler.scale(10), closeTo(11.2, 0.001));
    });

    test('does not apply reader line height to iOS UI chrome', () {
      final typography = resolveEffectiveAppTypography(
        targetPlatform: TargetPlatform.iOS,
        isWeb: false,
        fontSize: AppFontSize.standard,
        lineHeight: AppLineHeight.relaxed,
      );

      expect(typography.applyUiLineHeight, isFalse);
      expect(
        typography.contentLineHeight,
        appLineHeightFor(AppLineHeight.relaxed),
      );
    });

    test('continues applying UI line height outside iOS', () {
      final typography = resolveEffectiveAppTypography(
        targetPlatform: TargetPlatform.windows,
        isWeb: false,
        fontSize: AppFontSize.standard,
        lineHeight: AppLineHeight.compact,
      );

      expect(typography.applyUiLineHeight, isTrue);
      expect(typography.uiLineHeight, appLineHeightFor(AppLineHeight.compact));
    });

    test('app theme ignores unsupported iOS font and UI line height', () {
      final prefs = AppPreferences.defaults.copyWith(
        fontFamily: 'Inter',
        fontFile: 'fonts/Inter.ttf',
        lineHeight: AppLineHeight.relaxed,
      );

      final theme = applyPreferencesToTheme(
        buildAppTheme(Brightness.light),
        prefs,
        targetPlatform: TargetPlatform.iOS,
        isWeb: false,
      );

      expect(theme.textTheme.bodyMedium?.fontFamily, isNot('Inter'));
      expect(
        theme.textTheme.bodyMedium?.height,
        isNot(appLineHeightFor(AppLineHeight.relaxed)),
      );
    });

    test('app theme preserves non-iOS font and UI line height behavior', () {
      final prefs = AppPreferences.defaults.copyWith(
        fontFamily: 'Inter',
        fontFile: 'fonts/Inter.ttf',
        lineHeight: AppLineHeight.relaxed,
      );

      final theme = applyPreferencesToTheme(
        buildAppTheme(Brightness.light),
        prefs,
        targetPlatform: TargetPlatform.android,
        isWeb: false,
      );

      expect(theme.textTheme.bodyMedium?.fontFamily, 'Inter');
      expect(
        theme.textTheme.bodyMedium?.height,
        appLineHeightFor(AppLineHeight.relaxed),
      );
    });
  });

  group('canChooseSystemFontsForPlatform', () {
    test('reports selectable system fonts only for supported targets', () {
      expect(
        canChooseSystemFontsForPlatform(
          targetPlatform: TargetPlatform.iOS,
          isWeb: false,
        ),
        isFalse,
      );
      expect(
        canChooseSystemFontsForPlatform(
          targetPlatform: TargetPlatform.windows,
          isWeb: false,
        ),
        isTrue,
      );
      expect(
        canChooseSystemFontsForPlatform(
          targetPlatform: TargetPlatform.linux,
          isWeb: false,
        ),
        isTrue,
      );
      expect(
        canChooseSystemFontsForPlatform(
          targetPlatform: TargetPlatform.android,
          isWeb: true,
        ),
        isFalse,
      );
    });
  });
}

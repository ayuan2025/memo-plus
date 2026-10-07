import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/memoflow_palette.dart';
import 'package:memos_flutter_app/features/memos/theme/memo_card_theme.dart';

void main() {
  group('kMemoCardThemes', () {
    test('ships at least the seven ported themes', () {
      expect(kMemoCardThemes.length, greaterThanOrEqualTo(7));
    });

    test('ids and labels are unique', () {
      final ids = kMemoCardThemes.map((t) => t.id).toSet();
      final labels = kMemoCardThemes.map((t) => t.label).toSet();
      expect(ids.length, kMemoCardThemes.length);
      expect(labels.length, kMemoCardThemes.length);
    });

    test('the warm white theme stays first as the default pick', () {
      expect(kMemoCardThemes.first.id, 'warm_white');
      expect(kMemoCardThemes.first, same(kMemoCardThemeWarmWhite));
    });

    test('every theme builds a usable ThemeData', () {
      for (final theme in kMemoCardThemes) {
        final data = theme.toThemeData();
        // The App background is deliberately one step behind the paper — a page
        // laid on a surface, not a page that fills the whole screen. It must
        // still come from the theme though: that is what makes the theme global
        // rather than a wrapper around the note body.
        expect(data.scaffoldBackgroundColor, theme.appBackground);
        expect(
          data.scaffoldBackgroundColor == theme.paper,
          isFalse,
          reason: '${theme.label}: App background must differ from the paper',
        );
        expect(data.colorScheme.primary, theme.accent);
        expect(data.colorScheme.onSurface, theme.text);
        expect(data.brightness, theme.brightness);
      }
    });

    test('the theme covers the chrome, not just the page', () {
      // These are what made the first attempt look like a widget inside a box:
      // the note body was themed while the surrounding app kept the old
      // palette. Each of these has to carry the theme's colours now.
      for (final theme in kMemoCardThemes) {
        final data = theme.toThemeData();
        final name = theme.label;
        expect(
          data.appBarTheme.backgroundColor,
          isNot(Colors.transparent),
          reason: '$name: AppBar must be tinted by the theme',
        );
        expect(data.dialogTheme.backgroundColor, theme.appCard,
            reason: '$name: dialogs must not stay on the old palette');
        expect(data.bottomSheetTheme.backgroundColor, theme.appCard,
            reason: '$name: sheets must not stay on the old palette');
        expect(data.snackBarTheme.backgroundColor, theme.codeBackground,
            reason: '$name: snackbars must not stay on the old palette');
        expect(data.cardTheme.color, theme.appCard);
        expect(data.dividerColor, theme.border);
        expect(data.appBarTheme.foregroundColor, theme.text);
      }
    });

    test('every theme declares its own brightness — no third light/dark switch',
        () {
      // 7 ported themes, 5 light and 2 dark. The App no longer carries a
      // separate light/dark preference because this is where that decision
      // lives now; if a future theme's paper were mid-grey both branches would
      // flip at once and the two would be indistinguishable.
      expect(kMemoCardThemes.where((t) => t.isDark).length, 2);
      expect(kMemoCardThemes.where((t) => !t.isDark).length, 5);
      for (final theme in kMemoCardThemes) {
        expect(
          theme.isDark,
          theme.paper.computeLuminance() <= 0.5,
          reason: '${theme.label}: brightness must follow the paper',
        );
      }
    });

    test('app surfaces are layered so the interface keeps its hierarchy', () {
      for (final theme in kMemoCardThemes) {
        // background behind, card in front: they must be distinguishable or
        // lists and sheets stop reading as surfaces at all.
        expect(
          theme.appCard,
          isNot(theme.appBackground),
          reason: '${theme.label}: cards must stand off the background',
        );
        expect(
          theme.appSurface,
          isNot(theme.appBackground),
          reason: '${theme.label}: toolbars must stand off the background',
        );
      }
    });

    test('dark themes read light text on dark paper', () {
      for (final theme in kMemoCardThemes) {
        final paperLuma = theme.paper.computeLuminance();
        final textLuma = theme.text.computeLuminance();
        if (paperLuma < 0.3) {
          expect(textLuma, greaterThan(paperLuma),
              reason: '${theme.label} is a dark paper but its text is darker');
        } else {
          expect(textLuma, lessThan(paperLuma),
              reason: '${theme.label} is a light paper but its text is lighter');
        }
      }
    });
  });

  group('applyToPalette', () {
    test('the palette takes the theme so its 854 static call sites follow',
        () {
      // MemoFlowPalette is referenced from 88 files. Rather than rewriting all
      // of them to read from Theme.of, the theme is projected onto the palette
      // once at the MaterialApp root. This is the assertion that keeps that
      // projection honest.
      for (final theme in kMemoCardThemes) {
        theme.applyToPalette();
        expect(MemoFlowPalette.primary, theme.accent,
            reason: '${theme.label}: primary must be the theme accent');
        expect(MemoFlowPalette.backgroundLight, theme.appBackground);
        expect(MemoFlowPalette.backgroundDark, theme.appBackground);
        expect(MemoFlowPalette.cardLight, theme.appCard);
        expect(MemoFlowPalette.cardDark, theme.appCard);
        expect(MemoFlowPalette.borderLight, theme.border);
        expect(MemoFlowPalette.borderDark, theme.border);
        expect(MemoFlowPalette.textLight, theme.text);
        expect(MemoFlowPalette.textDark, theme.text);
      }
    });

    test('light and dark palette pairs collapse — no second source of truth',
        () {
      // The App no longer has a light/dark preference, so the paired tokens
      // must be identical: leaving them different is what would let a stray
      // `isDark ? cardDark : cardLight` reintroduce a second palette.
      for (final theme in kMemoCardThemes) {
        theme.applyToPalette();
        expect(MemoFlowPalette.backgroundLight, MemoFlowPalette.backgroundDark,
            reason: theme.label);
        expect(MemoFlowPalette.cardLight, MemoFlowPalette.cardDark,
            reason: theme.label);
        expect(MemoFlowPalette.textLight, MemoFlowPalette.textDark,
            reason: theme.label);
      }
    });
  });
}

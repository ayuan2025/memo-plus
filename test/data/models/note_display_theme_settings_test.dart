import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/models/note_display_theme_settings.dart';
import 'package:memos_flutter_app/features/memos/theme/memo_card_theme.dart';

void main() {
  group('NoteDisplayThemeSettings', () {
    test('defaults to the warm white card theme', () {
      expect(NoteDisplayThemeSettings.defaults.themeId, 'warm_white');
      expect(
        NoteDisplayThemeSettings.defaults.themeId,
        kMemoCardThemeWarmWhite.id,
      );
    });

    test('copyWith overrides the theme id only when provided', () {
      const base = NoteDisplayThemeSettings(themeId: 'midnight');
      expect(base.copyWith().themeId, 'midnight');
      expect(base.copyWith(themeId: 'serif_press').themeId, 'serif_press');
    });

    test('round-trips through json', () {
      const settings = NoteDisplayThemeSettings(themeId: 'note_dark');
      final restored = NoteDisplayThemeSettings.fromJson(settings.toJson());
      expect(restored.themeId, settings.themeId);
    });

    test('falls back to defaults for blank or missing values', () {
      expect(
        NoteDisplayThemeSettings.fromJson(const {}).themeId,
        NoteDisplayThemeSettings.defaults.themeId,
      );
      expect(
        NoteDisplayThemeSettings.fromJson(const {'themeId': '   '}).themeId,
        NoteDisplayThemeSettings.defaults.themeId,
      );
      expect(
        NoteDisplayThemeSettings.fromJson(const {'themeId': 42}).themeId,
        NoteDisplayThemeSettings.defaults.themeId,
      );
    });
  });

  group('selected card theme resolution', () {
    MemoCardTheme resolve(String id) {
      return kMemoCardThemes.firstWhere(
        (theme) => theme.id == id,
        orElse: () => kMemoCardThemeWarmWhite,
      );
    }

    test('resolves every declared theme id', () {
      for (final theme in kMemoCardThemes) {
        expect(
          resolve(theme.id).id,
          theme.id,
          reason: '${theme.id} must be resolvable by id',
        );
      }
    });

    test('unknown ids fall back to warm white', () {
      expect(resolve('does-not-exist').id, kMemoCardThemeWarmWhite.id);
    });
  });
}

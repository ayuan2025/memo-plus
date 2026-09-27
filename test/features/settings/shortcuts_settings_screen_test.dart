import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/features/settings/shortcut_editor_screen.dart';
import 'package:memos_flutter_app/features/settings/shortcuts_settings_screen.dart';
import 'package:memos_flutter_app/features/settings/settings_ui.dart';
import 'package:memos_flutter_app/i18n/strings.g.dart';
import 'package:memos_flutter_app/state/settings/user_settings_provider.dart';

void main() {
  testWidgets('empty shortcuts list uses settings seams and opens editor', (
    tester,
  ) async {
    LocaleSettings.setLocale(AppLocale.en);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [shortcutsProvider.overrideWith((ref) async => const [])],
        child: TranslationProvider(
          child: MaterialApp(
            locale: AppLocale.en.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const ShortcutsSettingsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.byType(SettingsSection), findsOneWidget);
    expect(find.text('No shortcuts configured'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(ShortcutEditorScreen), findsOneWidget);
    expect(find.byType(SettingsPage), findsOneWidget);
  });
}

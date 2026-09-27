import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/features/memos/compose_toolbar_shared.dart';
import 'package:memos_flutter_app/i18n/strings.g.dart';

Widget _buildToolbar({
  required MemoToolbarPreferences preferences,
  required List<MemoComposeToolbarActionSpec> actions,
}) {
  LocaleSettings.setLocale(AppLocale.en);
  return TranslationProvider(
    child: MaterialApp(
      locale: AppLocale.en.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 420,
            child: MemoComposeToolbar(
              isDark: false,
              preferences: preferences,
              actions: actions,
              visibilityMessage: 'Visibility',
              visibilityIcon: Icons.lock_outline,
              visibilityColor: Colors.red,
              visibilityButtonKey: const ValueKey<String>('visibility-button'),
              onVisibilityPressed: () {},
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('filters hidden and unsupported actions', (tester) async {
    final preferences = MemoToolbarPreferences.defaults.setHidden(
      MemoToolbarActionId.attachment,
      true,
    );

    await tester.pumpWidget(
      _buildToolbar(
        preferences: preferences,
        actions: [
          MemoComposeToolbarActionSpec.builtin(id: MemoToolbarActionId.bold),
          MemoComposeToolbarActionSpec.builtin(id: MemoToolbarActionId.tag),
          MemoComposeToolbarActionSpec.builtin(
            id: MemoToolbarActionId.attachment,
          ),
          MemoComposeToolbarActionSpec.builtin(
            id: MemoToolbarActionId.location,
            supported: false,
          ),
        ],
      ),
    );

    expect(find.byTooltip('Bold'), findsOneWidget);
    expect(find.byTooltip('Tag'), findsOneWidget);
    expect(find.byTooltip('Attachment'), findsNothing);
    expect(find.byTooltip('Location'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('visibility-button')),
      findsOneWidget,
    );
  });

  testWidgets('collapses empty top row', (tester) async {
    var preferences = MemoToolbarPreferences.defaults;
    for (final action in kMemoToolbarDefaultTopRow) {
      preferences = preferences.setHidden(action, true);
    }

    await tester.pumpWidget(
      _buildToolbar(
        preferences: preferences,
        actions: [
          MemoComposeToolbarActionSpec.builtin(id: MemoToolbarActionId.bold),
          MemoComposeToolbarActionSpec.builtin(id: MemoToolbarActionId.tag),
        ],
      ),
    );

    expect(find.byKey(MemoComposeToolbar.topRowKey), findsNothing);
    expect(find.byKey(MemoComposeToolbar.bottomRowKey), findsOneWidget);
    expect(find.byTooltip('Tag'), findsOneWidget);
  });

  testWidgets('renders custom buttons from preferences', (tester) async {
    final customButton = MemoToolbarCustomButton(
      id: 'heading-1',
      label: 'H1',
      iconKey: 'hammer',
      insertContent: '# ',
    );
    final preferences = MemoToolbarPreferences.defaults
        .addCustomButton(customButton, hidden: false)
        .moveItem(
          item: customButton.itemId,
          targetRow: MemoToolbarRow.top,
          targetIndex: 1,
        );

    await tester.pumpWidget(
      _buildToolbar(
        preferences: preferences,
        actions: [
          MemoComposeToolbarActionSpec.builtin(id: MemoToolbarActionId.bold),
          MemoComposeToolbarActionSpec.custom(button: customButton),
        ],
      ),
    );

    expect(find.byTooltip('H1'), findsOneWidget);
  });

  testWidgets('renders labels for newly added markdown actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildToolbar(
        preferences: MemoToolbarPreferences.defaults,
        actions: [
          MemoComposeToolbarActionSpec.builtin(id: MemoToolbarActionId.italic),
          MemoComposeToolbarActionSpec.builtin(
            id: MemoToolbarActionId.strikethrough,
          ),
          MemoComposeToolbarActionSpec.builtin(id: MemoToolbarActionId.quote),
          MemoComposeToolbarActionSpec.builtin(
            id: MemoToolbarActionId.heading1,
          ),
          MemoComposeToolbarActionSpec.builtin(
            id: MemoToolbarActionId.inlineMath,
          ),
          MemoComposeToolbarActionSpec.builtin(
            id: MemoToolbarActionId.blockMath,
          ),
        ],
      ),
    );

    expect(find.byTooltip('Italic'), findsOneWidget);
    expect(find.byTooltip('Strikethrough'), findsOneWidget);
    expect(find.byTooltip('Quote'), findsOneWidget);
    expect(find.byTooltip('Heading 1'), findsOneWidget);
    expect(find.byTooltip('Inline Math'), findsOneWidget);
    expect(find.byTooltip('Block Math'), findsOneWidget);
  });
}

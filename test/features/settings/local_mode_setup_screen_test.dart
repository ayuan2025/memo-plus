import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/top_toast.dart';
import 'package:memos_flutter_app/features/settings/local_mode_setup_screen.dart';
import 'package:memos_flutter_app/features/settings/settings_ui.dart';
import 'package:memos_flutter_app/i18n/strings.g.dart';
import 'package:memos_flutter_app/platform/platform_target.dart';

void main() {
  tearDown(() {
    debugPlatformTargetOverride = null;
    dismissTopToast();
  });

  testWidgets('default mode shows storage info card', (
    WidgetTester tester,
  ) async {
    LocaleSettings.setLocale(AppLocale.en);

    await tester.pumpWidget(
      TranslationProvider(
        child: const MaterialApp(
          home: LocalModeSetupScreen(
            title: 'Add local library',
            confirmLabel: 'Confirm',
            cancelLabel: 'Cancel',
            initialName: 'Local Library',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.byType(SettingsSection), findsNWidgets(2));
    expect(find.byType(SettingsInfoRow), findsOneWidget);
    expect(find.byType(SettingsInputRow), findsOneWidget);
    expect(find.byType(SettingsAction), findsNWidgets(2));
    expect(
      find.text(
        "Local mode data is stored in the app's private files by default.",
      ),
      findsOneWidget,
    );
  });

  testWidgets('rename mode hides storage info card and returns trimmed name', (
    WidgetTester tester,
  ) async {
    LocaleSettings.setLocale(AppLocale.en);

    LocalModeSetupResult? result;

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    result = await LocalModeSetupScreen.show(
                      context,
                      title: 'Local library name',
                      confirmLabel: 'Confirm',
                      cancelLabel: 'Cancel',
                      initialName: 'Old Name',
                      subtitle: 'C:/MemoFlow/local_workspace',
                      showStorageInfoCard: false,
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        "Local mode data is stored in the app's private files by default.",
      ),
      findsNothing,
    );
    expect(find.text('C:/MemoFlow/local_workspace'), findsOneWidget);
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.byType(SettingsInfoRow), findsOneWidget);
    expect(find.byType(SettingsInputRow), findsOneWidget);
    expect(find.byType(SettingsAction), findsNWidgets(2));

    await tester.enterText(find.byType(TextField), '  Renamed Library  ');
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(result?.name, 'Renamed Library');
  });

  testWidgets('empty name shows validation message without closing', (
    WidgetTester tester,
  ) async {
    LocaleSettings.setLocale(AppLocale.en);

    await tester.pumpWidget(
      TranslationProvider(
        child: const MaterialApp(
          home: LocalModeSetupScreen(
            title: 'Add local library',
            confirmLabel: 'Confirm',
            cancelLabel: 'Cancel',
            initialName: 'Local Library',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Confirm'));
    await tester.pump();

    expect(find.text('Please enter a repository name.'), findsOneWidget);
    expect(find.byType(LocalModeSetupScreen), findsOneWidget);

    dismissTopToast();
    await tester.pump();
  });

  testWidgets('iPhone local setup renders without material ancestor errors', (
    WidgetTester tester,
  ) async {
    LocaleSettings.setLocale(AppLocale.en);
    await _setViewport(tester, const Size(390, 844));
    debugPlatformTargetOverride = TargetPlatform.iOS;

    await tester.pumpWidget(
      TranslationProvider(
        child: const MaterialApp(
          home: LocalModeSetupScreen(
            title: 'Add local library',
            confirmLabel: 'Confirm',
            cancelLabel: 'Cancel',
            initialName: 'Local Library',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.byType(SettingsInputRow), findsOneWidget);
    expect(find.byType(CupertinoTextField), findsOneWidget);
  });

  testWidgets('iPhone local setup returns trimmed edited name through route', (
    WidgetTester tester,
  ) async {
    LocaleSettings.setLocale(AppLocale.en);
    await _setViewport(tester, const Size(390, 844));
    debugPlatformTargetOverride = TargetPlatform.iOS;

    LocalModeSetupResult? result;

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    result = await LocalModeSetupScreen.show(
                      context,
                      title: 'Add local library',
                      confirmLabel: 'Confirm',
                      cancelLabel: 'Cancel',
                      initialName: 'Local Library',
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(LocalModeSetupScreen), findsOneWidget);
    expect(
      ModalRoute.of(tester.element(find.byType(LocalModeSetupScreen))),
      isA<CupertinoPageRoute<LocalModeSetupResult>>(),
    );

    await tester.enterText(
      find.byType(CupertinoTextField),
      '  Renamed Library  ',
    );
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(result?.name, 'Renamed Library');
  });

  testWidgets('iPhone empty name shows overlay feedback without closing', (
    WidgetTester tester,
  ) async {
    LocaleSettings.setLocale(AppLocale.en);
    await _setViewport(tester, const Size(390, 844));
    debugPlatformTargetOverride = TargetPlatform.iOS;

    await tester.pumpWidget(
      TranslationProvider(
        child: const MaterialApp(
          home: LocalModeSetupScreen(
            title: 'Add local library',
            confirmLabel: 'Confirm',
            cancelLabel: 'Cancel',
            initialName: 'Local Library',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(CupertinoTextField), '   ');
    await tester.tap(find.text('Confirm'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Please enter a repository name.'), findsOneWidget);
    expect(find.byType(LocalModeSetupScreen), findsOneWidget);

    dismissTopToast();
    await tester.pump();
  });

  testWidgets('iPad local setup reuses shared input behavior', (
    WidgetTester tester,
  ) async {
    LocaleSettings.setLocale(AppLocale.en);
    await _setViewport(tester, const Size(820, 1180));
    debugPlatformTargetOverride = TargetPlatform.iOS;

    await tester.pumpWidget(
      TranslationProvider(
        child: const MaterialApp(
          home: LocalModeSetupScreen(
            title: 'Add local library',
            confirmLabel: 'Confirm',
            cancelLabel: 'Cancel',
            initialName: 'Local Library',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(LocalModeSetupScreen), findsOneWidget);
    expect(find.byType(SettingsInputRow), findsOneWidget);
    expect(find.byType(CupertinoTextField), findsOneWidget);
  });
}

Future<void> _setViewport(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

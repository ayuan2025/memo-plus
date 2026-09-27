import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/features/settings/donation_dialog.dart';
import 'package:memos_flutter_app/features/settings/settings_ui.dart';
import 'package:memos_flutter_app/i18n/strings.g.dart';

void main() {
  testWidgets('donation dialog uses settings actions and shows success flow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    LocaleSettings.setLocale(AppLocale.en);

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => DonationDialog.show(context),
                  child: const Text('Open donation'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open donation'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(DonationDialog), findsOneWidget);
    expect(find.byType(SettingsAction), findsWidgets);
    expect(find.text('Energy critically low!'), findsOneWidget);
    expect(find.text('Save and open Alipay to scan'), findsOneWidget);
    expect(
      find.textContaining('Coffee it is / add a drumstick'),
      findsOneWidget,
    );

    final confirmAction = find.byKey(
      const ValueKey<String>('donationDialog.confirmAction'),
    );
    await tester.tap(confirmAction);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SettingsAction), findsWidgets);
    expect(find.textContaining('ENERGY RESTORED'), findsOneWidget);
    expect(find.textContaining('Awesome!'), findsOneWidget);

    final closeAction = find.descendant(
      of: find.byKey(const ValueKey<String>('donationDialog.closeAction')),
      matching: find.byType(FilledButton),
    );
    expect(tester.widget<FilledButton>(closeAction).onPressed, isNotNull);
  });

  testWidgets('donation dialog cancel closes request step', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    LocaleSettings.setLocale(AppLocale.en);

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => DonationDialog.show(context),
                  child: const Text('Open donation'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open donation'));
    await tester.pump(const Duration(milliseconds: 300));

    final cancelAction = find.textContaining('Next time, back to fixing bugs');
    await tester.tap(cancelAction);
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(DonationDialog), findsNothing);
  });
}

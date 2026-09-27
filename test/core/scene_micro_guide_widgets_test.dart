import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/scene_micro_guide_widgets.dart';
import 'package:memos_flutter_app/i18n/strings.g.dart';

Widget _buildTestApp(Widget child, {AppLocale locale = AppLocale.en}) {
  LocaleSettings.setLocale(locale);
  return TranslationProvider(
    child: MaterialApp(
      locale: locale.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  testWidgets('banner renders and dismisses', (tester) async {
    var dismissed = false;

    await tester.pumpWidget(
      _buildTestApp(
        SceneMicroGuideBanner(
          message: 'Long press to copy',
          onDismiss: () => dismissed = true,
        ),
      ),
    );

    expect(find.text('Long press to copy'), findsOneWidget);

    await tester.tap(find.text('Got it'));
    await tester.pump();

    expect(dismissed, isTrue);
  });

  testWidgets('overlay pill renders and dismisses', (tester) async {
    var dismissed = false;

    await tester.pumpWidget(
      _buildTestApp(
        SceneMicroGuideOverlayPill(
          message: 'Double-tap to reset',
          onDismiss: () => dismissed = true,
        ),
      ),
    );

    expect(find.text('Double-tap to reset'), findsOneWidget);

    await tester.tap(find.text('Got it'));
    await tester.pump();

    expect(dismissed, isTrue);
  });
}

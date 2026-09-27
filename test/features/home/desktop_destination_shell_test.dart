import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/desktop/window_chrome_safe_area.dart';
import 'package:memos_flutter_app/core/platform_layout.dart';
import 'package:memos_flutter_app/features/home/app_drawer.dart';
import 'package:memos_flutter_app/features/home/desktop/desktop_destination_shell.dart';
import 'package:memos_flutter_app/i18n/strings.g.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LocaleSettings.setLocale(AppLocale.en);
  });

  testWidgets('routes Windows destinations through the command bar shell', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(platform: TargetPlatform.windows, width: 1400),
    );

    expect(
      find.byKey(const ValueKey<String>('windows-desktop-command-bar')),
      findsOneWidget,
    );
    expect(find.text('Destination'), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
  });

  testWidgets('suppresses macOS expanded-sidebar duplicate title', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(platform: TargetPlatform.macOS, width: 1400),
    );

    expect(
      find.byKey(const ValueKey<String>('apple-macos-page-shell')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('desktop-navigation-sidebar')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey<String>('apple-macos-toolbar')))
          .height,
      kMacosTitleBarHeight,
    );
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey<String>('desktop-navigation-sidebar')),
          )
          .width,
      kMemoFlowDesktopDrawerWidth,
    );
    expect(find.text('Destination'), findsNothing);
  });

  testWidgets('keeps macOS rail title visible when sidebar labels are hidden', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(platform: TargetPlatform.macOS, width: 900),
    );

    expect(
      find.byKey(const ValueKey<String>('desktop-navigation-rail')),
      findsOneWidget,
    );
    expect(find.text('Destination'), findsOneWidget);
  });

  testWidgets('keeps macOS rail navigation menu below traffic-light chrome', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(platform: TargetPlatform.macOS, width: 900),
    );

    final menuButtonFinder = find.byKey(
      const ValueKey<String>('desktop-navigation-rail-button-menu'),
    );
    expect(menuButtonFinder, findsOneWidget);
    expect(
      tester.getTopLeft(menuButtonFinder).dy,
      greaterThanOrEqualTo(kMacosTitleBarHeight),
    );

    await tester.tap(menuButtonFinder);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('desktop-navigation-rail-menu-panel')),
      findsOneWidget,
    );
    expect(find.text('Draft Box'), findsOneWidget);
    expect(find.text('Archive'), findsOneWidget);
  });

  testWidgets('renders explicit desktop dismissal intent through the shell', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        platform: TargetPlatform.windows,
        width: 1400,
        dismissalIntent: DesktopDestinationDismissalIntent(
          tooltip: 'Close destination',
          icon: Icons.close_rounded,
          onPressed: () {},
        ),
      ),
    );

    expect(find.byTooltip('Close destination'), findsOneWidget);
  });

  testWidgets('passes heatmap day selection callback to the shell drawer', (
    tester,
  ) async {
    void handleDay(DateTime day) {}

    await tester.pumpWidget(
      _buildHarness(
        platform: TargetPlatform.windows,
        width: 1400,
        onSelectDay: handleDay,
      ),
    );

    final drawer = tester.widget<AppDrawer>(find.byType(AppDrawer).first);
    expect(drawer.onSelectDay, same(handleDay));
  });
}

Widget _buildHarness({
  required TargetPlatform platform,
  required double width,
  DesktopDestinationDismissalIntent? dismissalIntent,
  ValueChanged<DateTime>? onSelectDay,
}) {
  return ProviderScope(
    child: TranslationProvider(
      child: MaterialApp(
        theme: ThemeData(platform: platform),
        locale: AppLocale.en.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, 900)),
          child: DesktopDestinationShell(
            selectedDestination: AppDrawerDestination.dailyReview,
            onSelectDestination: (_) {},
            onSelectTag: (_) {},
            onSelectDay: onSelectDay,
            onOpenNotifications: () {},
            title: const Text('Destination'),
            actions: [
              IconButton(
                tooltip: 'Search',
                onPressed: () {},
                icon: const Icon(Icons.search_rounded),
              ),
            ],
            dismissalIntent: dismissalIntent,
            body: const SizedBox.expand(
              key: ValueKey<String>('destination-body'),
            ),
            fallback: const SizedBox.shrink(
              key: ValueKey<String>('destination-fallback'),
            ),
            showWindowControls: false,
          ),
        ),
      ),
    ),
  );
}

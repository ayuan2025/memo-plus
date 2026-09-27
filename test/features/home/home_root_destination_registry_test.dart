import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/models/home_navigation_preferences.dart';
import 'package:memos_flutter_app/features/home/app_drawer_destination_builder.dart';
import 'package:memos_flutter_app/features/home/home_navigation_host.dart';
import 'package:memos_flutter_app/features/home/home_root_destination_registry.dart';
import 'package:memos_flutter_app/features/memos/draft_box_navigation_screen.dart';
import 'package:memos_flutter_app/features/memos/memos_list_screen.dart';
import 'package:memos_flutter_app/features/home/app_drawer.dart';
import 'package:memos_flutter_app/platform/platform_target.dart';

void main() {
  tearDown(() {
    debugPlatformTargetOverride = null;
  });

  testWidgets('memos root screen enables resizable home inline compose', (
    tester,
  ) async {
    Widget? built;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.windows),
        home: Builder(
          builder: (context) {
            built = buildHomeRootScreen(
              context: context,
              destination: HomeRootDestination.memos,
              presentation: HomeScreenPresentation.standalone,
              navigationHost: null,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(built, isA<MemosListScreen>());
    expect(
      (built! as MemosListScreen).enableDesktopResizableHomeInlineCompose,
      isTrue,
    );
  });

  testWidgets('macOS memos root enables resizable home inline compose', (
    tester,
  ) async {
    Widget? built;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.macOS),
        home: Builder(
          builder: (context) {
            built = buildHomeRootScreen(
              context: context,
              destination: HomeRootDestination.memos,
              presentation: HomeScreenPresentation.standalone,
              navigationHost: null,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(built, isA<MemosListScreen>());
    expect(
      (built! as MemosListScreen).enableDesktopResizableHomeInlineCompose,
      isTrue,
    );
  });

  testWidgets(
    'embedded memos root keeps resizable home inline compose disabled',
    (tester) async {
      Widget? built;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.windows),
          home: Builder(
            builder: (context) {
              built = buildHomeRootScreen(
                context: context,
                destination: HomeRootDestination.memos,
                presentation: HomeScreenPresentation.embeddedBottomNav,
                navigationHost: null,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(built, isA<MemosListScreen>());
      expect(
        (built! as MemosListScreen).enableDesktopResizableHomeInlineCompose,
        isFalse,
      );
    },
  );

  testWidgets('drawer memos route uses shared resize capability on Windows', (
    tester,
  ) async {
    Widget? built;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.windows),
        home: Builder(
          builder: (context) {
            built = buildDrawerDestinationScreen(
              context: context,
              destination: AppDrawerDestination.memos,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(built, isA<MemosListScreen>());
    expect(
      (built! as MemosListScreen).enableDesktopResizableHomeInlineCompose,
      isTrue,
    );
  });

  testWidgets('desktop utility route preserves resize capability on Windows', (
    tester,
  ) async {
    MemosListScreen? built;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.windows),
        home: Builder(
          builder: (context) {
            built = buildDesktopHomeUtilityDestination(
              context: context,
              utility: DesktopHomeUtilityView.notifications,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(built, isNotNull);
    expect(built!.enableDesktopResizableHomeInlineCompose, isTrue);
    expect(
      built!.initialDesktopUtilityView,
      DesktopHomeUtilityView.notifications,
    );
  });

  testWidgets('desktop draft box route embeds in home utility content', (
    tester,
  ) async {
    debugPlatformTargetOverride = TargetPlatform.windows;
    Widget? built;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.windows),
        home: Builder(
          builder: (context) {
            built = buildDrawerDestinationScreen(
              context: context,
              destination: AppDrawerDestination.draftBox,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(built, isA<MemosListScreen>());
    expect(
      (built! as MemosListScreen).initialDesktopUtilityView,
      DesktopHomeUtilityView.draftBox,
    );
  });

  testWidgets('mobile draft box route keeps standalone draft screen', (
    tester,
  ) async {
    Widget? built;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Builder(
          builder: (context) {
            built = buildDrawerDestinationScreen(
              context: context,
              destination: AppDrawerDestination.draftBox,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(built, isA<DraftBoxNavigationScreen>());
  });

  testWidgets('Linux desktop memos routes keep resize disabled', (
    tester,
  ) async {
    Widget? rootBuilt;
    Widget? drawerBuilt;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.linux),
        home: Builder(
          builder: (context) {
            rootBuilt = buildHomeRootScreen(
              context: context,
              destination: HomeRootDestination.memos,
              presentation: HomeScreenPresentation.standalone,
              navigationHost: null,
            );
            drawerBuilt = buildDrawerDestinationScreen(
              context: context,
              destination: AppDrawerDestination.memos,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(rootBuilt, isA<MemosListScreen>());
    expect(drawerBuilt, isA<MemosListScreen>());
    expect(
      (rootBuilt! as MemosListScreen).enableDesktopResizableHomeInlineCompose,
      isFalse,
    );
    expect(
      (drawerBuilt! as MemosListScreen).enableDesktopResizableHomeInlineCompose,
      isFalse,
    );
  });

  testWidgets('draft box root has registry metadata and screen builder', (
    tester,
  ) async {
    Widget? built;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            built = buildHomeRootScreen(
              context: context,
              destination: HomeRootDestination.draftBox,
              presentation: HomeScreenPresentation.embeddedBottomNav,
              navigationHost: null,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final definition = homeRootDestinationDefinition(
      HomeRootDestination.draftBox,
    );
    expect(definition, isNotNull);
    expect(definition!.drawerDestination, AppDrawerDestination.draftBox);
    expect(definition.icon, Icons.inventory_2_outlined);
    expect(built, isA<DraftBoxNavigationScreen>());
  });
}

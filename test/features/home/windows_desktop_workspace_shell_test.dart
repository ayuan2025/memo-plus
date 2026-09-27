import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memos_flutter_app/core/platform_layout.dart';
import 'package:memos_flutter_app/features/home/desktop/windows_desktop_workspace_shell.dart';

void main() {
  Widget buildShell({
    required WindowsDesktopLayoutSpec spec,
    Widget? overlayNavigation,
    Widget? secondaryPane,
    bool secondaryPaneVisible = false,
    double secondaryPaneWidth = 420,
    double navigationWidth = 72,
    WindowsDesktopSecondaryPaneMotionSpec? secondaryPaneMotionSpec,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox.expand(
          child: WindowsDesktopWorkspaceShell(
            layoutSpec: spec,
            navigation: SizedBox(
              key: const ValueKey<String>('nav'),
              width: navigationWidth,
              child: const ColoredBox(color: Colors.blue),
            ),
            commandBar: const SizedBox(height: 46),
            body: const ColoredBox(
              key: ValueKey<String>('body'),
              color: Colors.amber,
            ),
            overlayNavigation: overlayNavigation,
            secondaryPane: secondaryPane,
            secondaryPaneVisible: secondaryPaneVisible,
            secondaryPaneWidth: secondaryPaneWidth,
            secondaryPaneMotionSpec: secondaryPaneMotionSpec,
          ),
        ),
      ),
    );
  }

  testWidgets('narrow layout hides pinned navigation and shows overlay', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildShell(
        spec: resolveWindowsDesktopLayout(900, platform: TargetPlatform.windows),
        overlayNavigation: const ColoredBox(
          key: ValueKey<String>('overlay'),
          color: Colors.red,
        ),
      ),
    );

    expect(find.byKey(const ValueKey<String>('nav')), findsNothing);
    expect(find.byKey(const ValueKey<String>('overlay')), findsOneWidget);
  });

  testWidgets('compact layout shows rail-sized navigation', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildShell(
        spec: resolveWindowsDesktopLayout(1100, platform: TargetPlatform.windows),
        navigationWidth: kWindowsDesktopRailWidth,
      ),
    );

    expect(find.byKey(const ValueKey<String>('nav')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey<String>('nav'))).width,
      kWindowsDesktopRailWidth,
    );
  });

  testWidgets('expanded layout shows sidebar-sized navigation', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildShell(
        spec: resolveWindowsDesktopLayout(1280, platform: TargetPlatform.windows),
        navigationWidth: kWindowsDesktopSidebarWidth,
      ),
    );

    expect(find.byKey(const ValueKey<String>('nav')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey<String>('nav'))).width,
      kWindowsDesktopSidebarWidth,
    );
  });

  testWidgets('secondary pane width is clamped and uses horizontal slide', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildShell(
        spec: resolveWindowsDesktopLayout(1600, platform: TargetPlatform.windows),
        navigationWidth: kWindowsDesktopSidebarWidth,
        secondaryPane: const ColoredBox(
          key: ValueKey<String>('secondary-pane-child'),
          color: Colors.green,
        ),
        secondaryPaneVisible: true,
        secondaryPaneWidth: 999,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('secondary-pane-child')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey<String>('secondary-pane-child'))).width,
      560,
    );

    final animatedSlides = tester.widgetList<AnimatedSlide>(
      find.byType(AnimatedSlide),
    );
    expect(animatedSlides, isNotEmpty);
    expect(animatedSlides.last.offset.dy, 0);
  });

  testWidgets('secondary pane motion spec customizes inline animation', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const motionSpec = WindowsDesktopSecondaryPaneMotionSpec(
      resizeDuration: Duration(milliseconds: 111),
      surfaceEnterDuration: Duration(milliseconds: 222),
      surfaceExitDuration: Duration(milliseconds: 77),
      resizeCurve: Curves.easeInOut,
      surfaceEnterCurve: Curves.easeOut,
      surfaceExitCurve: Curves.easeIn,
      surfaceEntryOffset: Offset(0.012, 0),
      surfaceEntryScale: 0.992,
    );

    await tester.pumpWidget(
      buildShell(
        spec: resolveWindowsDesktopLayout(1600, platform: TargetPlatform.windows),
        navigationWidth: kWindowsDesktopSidebarWidth,
        secondaryPane: const ColoredBox(
          key: ValueKey<String>('secondary-pane-child'),
          color: Colors.green,
        ),
        secondaryPaneVisible: false,
        secondaryPaneMotionSpec: motionSpec,
      ),
    );

    final animatedContainers = tester.widgetList<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    expect(animatedContainers, isNotEmpty);
    expect(animatedContainers.first.duration, motionSpec.surfaceExitDuration);
    expect(animatedContainers.first.curve, motionSpec.resizeCurve);

    final slide = tester.widget<AnimatedSlide>(find.byType(AnimatedSlide).last);
    expect(slide.duration, motionSpec.surfaceExitDuration);
    expect(slide.curve, motionSpec.surfaceExitCurve);
    expect(slide.offset, motionSpec.surfaceEntryOffset);

    final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale).last);
    expect(scale.duration, motionSpec.surfaceExitDuration);
    expect(scale.curve, motionSpec.surfaceExitCurve);
    expect(scale.scale, motionSpec.surfaceEntryScale);
  });
}

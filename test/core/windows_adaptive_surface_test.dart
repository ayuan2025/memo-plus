import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/windows_adaptive_surface.dart';

void main() {
  testWidgets('shouldUseWindowsAdaptiveSurface respects platform', (
    tester,
  ) async {
    bool? windowsEnabled;
    await tester.pumpWidget(
      MaterialApp(
        home: Theme(
          data: ThemeData(platform: TargetPlatform.windows),
          child: Builder(
            builder: (context) {
              windowsEnabled = shouldUseWindowsAdaptiveSurface(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    expect(windowsEnabled, isTrue);

    bool? androidEnabled;
    await tester.pumpWidget(
      MaterialApp(
        home: Theme(
          data: ThemeData(platform: TargetPlatform.android),
          child: Builder(
            builder: (context) {
              androidEnabled = shouldUseWindowsAdaptiveSurface(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    expect(androidEnabled, isFalse);
  });

  testWidgets('showWindowsAdaptiveSurface uses large dialog defaults', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.windows),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showWindowsAdaptiveSurface<void>(
                      context: context,
                      kind: WindowsAdaptiveSurfaceKind.largeDialog,
                      builder: (_) => const SizedBox(
                        key: ValueKey<String>('adaptive-child'),
                        width: 1200,
                        height: 1200,
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('adaptive-child')),
      findsOneWidget,
    );

    final renderedSize = tester.getSize(
      find.byKey(const ValueKey<String>('adaptive-child')),
    );
    expect(renderedSize.width, lessThanOrEqualTo(860));
    expect(renderedSize.height, lessThanOrEqualTo(880));
  });

  testWidgets('showWindowsAdaptiveSurface uses popover defaults', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.windows),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showWindowsAdaptiveSurface<void>(
                      context: context,
                      kind: WindowsAdaptiveSurfaceKind.popover,
                      builder: (_) => const SizedBox(
                        key: ValueKey<String>('popover-child'),
                        width: 1200,
                        height: 1200,
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('windows-adaptive-surface-popover')),
      findsOneWidget,
    );

    final renderedSize = tester.getSize(
      find.byKey(const ValueKey<String>('popover-child')),
    );
    expect(renderedSize.width, lessThanOrEqualTo(420));
    expect(renderedSize.height, lessThanOrEqualTo(720));
  });

  testWidgets('showWindowsAdaptiveSurface popover anchors below context', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final anchorKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.windows),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.fromLTRB(80, 120, 0, 0),
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  key: anchorKey,
                  onPressed: () {
                    showWindowsAdaptiveSurface<void>(
                      context: context,
                      kind: WindowsAdaptiveSurfaceKind.popover,
                      anchorContext: anchorKey.currentContext,
                      builder: (_) => const SizedBox(
                        key: ValueKey<String>('anchored-popover-child'),
                        width: 240,
                        height: 120,
                      ),
                    );
                  },
                  child: const Text('Anchor'),
                );
              },
            ),
          ),
        ),
      ),
    );

    final anchorBottomRight = tester.getBottomLeft(find.byKey(anchorKey));

    await tester.tap(find.text('Anchor'));
    await tester.pumpAndSettle();

    final popoverTopLeft = tester.getTopLeft(
      find.byKey(const ValueKey<String>('anchored-popover-child')),
    );
    expect(popoverTopLeft.dx, closeTo(anchorBottomRight.dx, 1));
    expect(popoverTopLeft.dy, greaterThan(anchorBottomRight.dy));
  });

  testWidgets('showWindowsAdaptiveSurface returns pop result', (tester) async {
    String? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.windows),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showWindowsAdaptiveSurface<String>(
                      context: context,
                      builder: (dialogContext) => Center(
                        child: TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop('done'),
                          child: const Text('Close'),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(result, 'done');
  });
}

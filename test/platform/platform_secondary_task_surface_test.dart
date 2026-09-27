import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/desktop/window_chrome_safe_area.dart';
import 'package:memos_flutter_app/platform/platform_target.dart';
import 'package:memos_flutter_app/platform/widgets/platform_secondary_task_surface.dart';

void main() {
  void setTargetPlatform(TargetPlatform platform) {
    debugPlatformTargetOverride = platform;
    addTearDown(() {
      debugPlatformTargetOverride = null;
    });
  }

  tearDownAll(() {
    debugPlatformTargetOverride = null;
  });

  testWidgets('desktop platforms use secondary task surfaces', (tester) async {
    for (final platform in <TargetPlatform>[
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.linux,
    ]) {
      setTargetPlatform(platform);

      bool? enabled;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              enabled = shouldUsePlatformSecondaryTaskSurface(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(enabled, isTrue, reason: '$platform should use task surface');
      debugPlatformTargetOverride = null;
    }
  });

  testWidgets('mobile platforms keep caller-owned presentation', (
    tester,
  ) async {
    for (final platform in <TargetPlatform>[
      TargetPlatform.android,
      TargetPlatform.iOS,
    ]) {
      setTargetPlatform(platform);

      bool? enabled;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              enabled = shouldUsePlatformSecondaryTaskSurface(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(enabled, isFalse, reason: '$platform should keep route or sheet');
      debugPlatformTargetOverride = null;
    }
  });

  testWidgets('macOS task surface is bounded below titlebar controls', (
    tester,
  ) async {
    setTargetPlatform(TargetPlatform.macOS);
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    showPlatformSecondaryTaskSurface<void>(
                      context: context,
                      builder: (_) => const PlatformSecondaryTaskFrame(
                        title: Text('Task title'),
                        body: SizedBox(
                          key: ValueKey<String>('surface-body'),
                          width: 1200,
                          height: 1200,
                          child: Text('Body'),
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

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Task title')).dy,
      greaterThanOrEqualTo(kMacosTitleBarHeight),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey<String>('surface-body'))).width,
      lessThanOrEqualTo(860),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey<String>('surface-body'))).height,
      lessThanOrEqualTo(880),
    );
  });

  testWidgets('Windows and Linux task surfaces keep default centered spacing', (
    tester,
  ) async {
    for (final platform in <TargetPlatform>[
      TargetPlatform.windows,
      TargetPlatform.linux,
    ]) {
      setTargetPlatform(platform);
      await tester.binding.setSurfaceSize(const Size(900, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () {
                      showPlatformSecondaryTaskSurface<void>(
                        context: context,
                        builder: (_) => const PlatformSecondaryTaskFrame(
                          title: Text('Task title'),
                          body: SizedBox(
                            key: ValueKey<String>('surface-body'),
                            width: 600,
                            height: 400,
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

      final titleLeft = tester.getTopLeft(find.text('Task title')).dx;
      expect(titleLeft, lessThan(kMacosTrafficLightReservedWidth));

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      debugPlatformTargetOverride = null;
    }
  });

  testWidgets('small windows keep frame controls reachable', (tester) async {
    setTargetPlatform(TargetPlatform.windows);
    await tester.binding.setSurfaceSize(const Size(420, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    showPlatformSecondaryTaskSurface<void>(
                      context: context,
                      builder: (_) => const PlatformSecondaryTaskFrame(
                        title: Text('Task title'),
                        body: SingleChildScrollView(
                          child: SizedBox(
                            key: ValueKey<String>('tall-body'),
                            width: 900,
                            height: 900,
                            child: Text('Scrollable body'),
                          ),
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

    expect(find.text('Task title'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(
      tester
          .getSize(
            find.byKey(
              const ValueKey<String>('platform-secondary-task-surface-dialog'),
            ),
          )
          .height,
      lessThanOrEqualTo(360),
    );
  });

  testWidgets('task surface returns pop result', (tester) async {
    setTargetPlatform(TargetPlatform.windows);
    String? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    result = await showPlatformSecondaryTaskSurface<String>(
                      context: context,
                      builder: (dialogContext) => Center(
                        child: TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop('done'),
                          child: const Text('Finish'),
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
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    expect(result, 'done');
  });
}

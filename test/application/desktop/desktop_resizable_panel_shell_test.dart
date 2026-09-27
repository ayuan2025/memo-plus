import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memos_flutter_app/application/desktop/desktop_resizable_panel_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('right handle grows width without moving left edge', (
    tester,
  ) async {
    final key = GlobalKey<_ResizableShellHarnessState>();
    await tester.pumpWidget(_ResizableShellHarness(key: key));

    await tester.drag(
      find.byKey(const ValueKey<String>('desktop-resizable-panel-right')),
      const Offset(40, 0),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(key.currentState!.rect.left, 40);
    expect(key.currentState!.rect.width, 240);
    expect(key.currentState!.endRect?.width, 240);
  });

  testWidgets('top-left handle moves origin and shrinks both axes', (
    tester,
  ) async {
    final key = GlobalKey<_ResizableShellHarnessState>();
    await tester.pumpWidget(_ResizableShellHarness(key: key));

    await tester.drag(
      find.byKey(const ValueKey<String>('desktop-resizable-panel-topLeft')),
      const Offset(30, 20),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(key.currentState!.rect.left, 70);
    expect(key.currentState!.rect.top, 44);
    expect(key.currentState!.rect.width, 170);
    expect(key.currentState!.rect.height, 140);
  });

  testWidgets('left handle moves left edge and shrinks width', (tester) async {
    final key = GlobalKey<_ResizableShellHarnessState>();
    await tester.pumpWidget(_ResizableShellHarness(key: key));

    await tester.drag(
      find.byKey(const ValueKey<String>('desktop-resizable-panel-left')),
      const Offset(24, 0),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(key.currentState!.rect.left, 64);
    expect(key.currentState!.rect.width, 176);
  });

  testWidgets('top handle moves top edge and shrinks height', (tester) async {
    final key = GlobalKey<_ResizableShellHarnessState>();
    await tester.pumpWidget(_ResizableShellHarness(key: key));

    await tester.drag(
      find.byKey(const ValueKey<String>('desktop-resizable-panel-top')),
      const Offset(0, 18),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(key.currentState!.rect.top, 42);
    expect(key.currentState!.rect.height, 142);
  });

  testWidgets('bottom-right handle clamps to max size', (tester) async {
    final key = GlobalKey<_ResizableShellHarnessState>();
    await tester.pumpWidget(_ResizableShellHarness(key: key));

    await tester.drag(
      find.byKey(const ValueKey<String>('desktop-resizable-panel-bottomRight')),
      const Offset(400, 400),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(key.currentState!.rect.width, 360);
    expect(key.currentState!.rect.height, 260);
  });

  testWidgets('corner hit area is transparent by default', (tester) async {
    final key = GlobalKey<_ResizableShellHarnessState>();
    await tester.pumpWidget(_ResizableShellHarness(key: key));

    final shellFinder = find.byType(DesktopResizablePanelShell);
    expect(
      find.descendant(of: shellFinder, matching: find.byType(DecoratedBox)),
      findsNothing,
    );
  });

  testWidgets('can show visible resize affordance without blocking drag', (
    tester,
  ) async {
    final key = GlobalKey<_ResizableShellHarnessState>();
    await tester.pumpWidget(
      _ResizableShellHarness(key: key, showHandleAffordance: true),
    );

    expect(
      find.byKey(
        const ValueKey<String>(
          'desktop-resizable-panel-bottomRight-affordance',
        ),
      ),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey<String>('desktop-resizable-panel-bottomRight')),
      const Offset(32, 28),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(key.currentState!.rect.width, 232);
    expect(key.currentState!.rect.height, 188);
  });

  testWidgets('dragging resize handle does not scroll ancestor viewport', (
    tester,
  ) async {
    final key = GlobalKey<_ResizableShellHarnessState>();
    final scrollController = ScrollController(initialScrollOffset: 200);
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                const SizedBox(height: 600),
                SizedBox(
                  width: 420,
                  height: 320,
                  child: _ResizableShellHarness(key: key),
                ),
                const SizedBox(height: 1200),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final beforeOffset = scrollController.offset;

    await tester.drag(
      find.byKey(const ValueKey<String>('desktop-resizable-panel-bottomRight')),
      const Offset(0, 36),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(scrollController.offset, beforeOffset);
    expect(key.currentState!.rect.height, 196);
  });

  testWidgets('can limit enabled resize handles', (tester) async {
    final key = GlobalKey<_ResizableShellHarnessState>();
    await tester.pumpWidget(
      _ResizableShellHarness(
        key: key,
        enabledHandles: const <DesktopResizeHandle>{
          DesktopResizeHandle.right,
          DesktopResizeHandle.bottom,
          DesktopResizeHandle.bottomRight,
        },
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('desktop-resizable-panel-top')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('desktop-resizable-panel-left')),
      findsNothing,
    );

    await tester.drag(
      find.byKey(const ValueKey<String>('desktop-resizable-panel-right')),
      const Offset(24, 0),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(key.currentState!.rect.left, 40);
    expect(key.currentState!.rect.width, 224);
  });
}

class _ResizableShellHarness extends StatefulWidget {
  const _ResizableShellHarness({
    super.key,
    this.enabledHandles,
    this.showHandleAffordance = false,
  });

  final Set<DesktopResizeHandle>? enabledHandles;
  final bool showHandleAffordance;

  @override
  State<_ResizableShellHarness> createState() => _ResizableShellHarnessState();
}

class _ResizableShellHarnessState extends State<_ResizableShellHarness> {
  DesktopResizablePanelRect rect = const DesktopResizablePanelRect(
    left: 40,
    top: 24,
    width: 200,
    height: 160,
  );
  DesktopResizablePanelRect? endRect;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 420,
            height: 320,
            child: DesktopResizablePanelShell(
              viewportSize: const Size(420, 320),
              rect: rect,
              minWidth: 120,
              maxWidth: 360,
              minHeight: 100,
              maxHeight: 260,
              hitZoneExtent: 8,
              enabledHandles: widget.enabledHandles,
              showHandleAffordance: widget.showHandleAffordance,
              onChanged: (next) => setState(() => rect = next),
              onChangeEnd: (next) {
                setState(() {
                  rect = next;
                  endRect = next;
                });
              },
              child: ColoredBox(
                key: const ValueKey<String>('panel-child'),
                color: Colors.blue,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

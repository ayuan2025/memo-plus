import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/features/memos/android_memo_keyboard_resume_controller.dart';

void main() {
  Future<FocusNode> pumpFocusedEditor(WidgetTester tester) async {
    final focusNode = FocusNode(debugLabel: 'keyboard_resume_test_editor');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Focus(focusNode: focusNode, child: const SizedBox.shrink()),
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
    return focusNode;
  }

  Future<void> pumpResumeRestore(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(AndroidMemoKeyboardResumeController.defaultRestoreDelay);
    await tester.pump();
  }

  Future<void> disposeEditor({
    required WidgetTester tester,
    required AndroidMemoKeyboardResumeController controller,
    required FocusNode focusNode,
  }) async {
    controller.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    focusNode.dispose();
  }

  testWidgets('restores keyboard when focused Android editor had visible IME', (
    tester,
  ) async {
    final focusNode = await pumpFocusedEditor(tester);
    var keyboardVisible = true;
    var showCount = 0;
    final controller = AndroidMemoKeyboardResumeController(
      focusNode: focusNode,
      isSurfaceEligible: () => true,
      isRouteCurrent: () => true,
      isKeyboardVisible: () => keyboardVisible,
      isAndroid: () => true,
      showKeyboard: () => showCount++,
      restoreDelay: Duration.zero,
    );

    controller.updateKeyboardVisibility();
    controller.didChangeAppLifecycleState(AppLifecycleState.inactive);
    expect(controller.debugRestorePending, isTrue);
    keyboardVisible = false;
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpResumeRestore(tester);

    expect(focusNode.hasFocus, isTrue);
    expect(controller.debugRestorePending, isFalse);
    expect(showCount, 1);

    await disposeEditor(
      tester: tester,
      controller: controller,
      focusNode: focusNode,
    );
  });

  testWidgets(
    'does not restore when keyboard was not visible before background',
    (tester) async {
      final focusNode = await pumpFocusedEditor(tester);
      var showCount = 0;
      final controller = AndroidMemoKeyboardResumeController(
        focusNode: focusNode,
        isSurfaceEligible: () => true,
        isRouteCurrent: () => true,
        isKeyboardVisible: () => false,
        isAndroid: () => true,
        showKeyboard: () => showCount++,
        restoreDelay: Duration.zero,
      );

      controller.updateKeyboardVisibility();
      controller.didChangeAppLifecycleState(AppLifecycleState.inactive);
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpResumeRestore(tester);

      expect(showCount, 0);

      await disposeEditor(
        tester: tester,
        controller: controller,
        focusNode: focusNode,
      );
    },
  );

  testWidgets('does not restore when the editor route is no longer current', (
    tester,
  ) async {
    final focusNode = await pumpFocusedEditor(tester);
    var routeCurrent = true;
    var showCount = 0;
    final controller = AndroidMemoKeyboardResumeController(
      focusNode: focusNode,
      isSurfaceEligible: () => true,
      isRouteCurrent: () => routeCurrent,
      isKeyboardVisible: () => true,
      isAndroid: () => true,
      showKeyboard: () => showCount++,
      restoreDelay: Duration.zero,
    );

    controller.updateKeyboardVisibility();
    controller.didChangeAppLifecycleState(AppLifecycleState.inactive);
    routeCurrent = false;
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpResumeRestore(tester);

    expect(showCount, 0);

    await disposeEditor(
      tester: tester,
      controller: controller,
      focusNode: focusNode,
    );
  });

  testWidgets('does not restore on non-Android platforms', (tester) async {
    final focusNode = await pumpFocusedEditor(tester);
    var showCount = 0;
    final controller = AndroidMemoKeyboardResumeController(
      focusNode: focusNode,
      isSurfaceEligible: () => true,
      isRouteCurrent: () => true,
      isKeyboardVisible: () => true,
      isAndroid: () => false,
      showKeyboard: () => showCount++,
      restoreDelay: Duration.zero,
    );

    controller.updateKeyboardVisibility();
    controller.didChangeAppLifecycleState(AppLifecycleState.inactive);
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpResumeRestore(tester);

    expect(showCount, 0);

    await disposeEditor(
      tester: tester,
      controller: controller,
      focusNode: focusNode,
    );
  });

  testWidgets('does not restore when the editor lost focus before background', (
    tester,
  ) async {
    final focusNode = await pumpFocusedEditor(tester);
    var showCount = 0;
    final controller = AndroidMemoKeyboardResumeController(
      focusNode: focusNode,
      isSurfaceEligible: () => true,
      isRouteCurrent: () => true,
      isKeyboardVisible: () => true,
      isAndroid: () => true,
      showKeyboard: () => showCount++,
      restoreDelay: Duration.zero,
    );

    focusNode.unfocus();
    await tester.pump();
    controller.didChangeAppLifecycleState(AppLifecycleState.inactive);
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpResumeRestore(tester);

    expect(showCount, 0);

    await disposeEditor(
      tester: tester,
      controller: controller,
      focusNode: focusNode,
    );
  });
}

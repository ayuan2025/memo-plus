import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/desktop/shortcuts.dart';
import 'package:memos_flutter_app/features/desktop/quick_input/desktop_quick_input_window.dart';

void main() {
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.windows);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('configured publish binding maps to submit intent', () {
    final bindings = <DesktopShortcutAction, DesktopShortcutBinding>{
      DesktopShortcutAction.publishMemo: DesktopShortcutBinding(
        keyId: LogicalKeyboardKey.keyS.keyId,
        primary: true,
        shift: true,
        alt: false,
      ),
    };

    expect(
      resolveDesktopQuickInputShortcutIntent(
        event: _keyDown(LogicalKeyboardKey.keyS),
        pressedKeys: <LogicalKeyboardKey>{
          LogicalKeyboardKey.controlLeft,
          LogicalKeyboardKey.shiftLeft,
          LogicalKeyboardKey.keyS,
        },
        bindings: bindings,
        editorFocused: true,
        alwaysOnTopSupported: false,
        pinning: false,
      ),
      DesktopQuickInputShortcutIntent.submit,
    );
    expect(
      resolveDesktopQuickInputShortcutIntent(
        event: _keyDown(LogicalKeyboardKey.enter),
        pressedKeys: <LogicalKeyboardKey>{
          LogicalKeyboardKey.controlLeft,
          LogicalKeyboardKey.enter,
        },
        bindings: bindings,
        editorFocused: true,
        alwaysOnTopSupported: false,
        pinning: false,
      ),
      isNull,
    );
  });

  test('formatting shortcut still maps while editor is focused', () {
    expect(
      resolveDesktopQuickInputShortcutIntent(
        event: _keyDown(LogicalKeyboardKey.keyB),
        pressedKeys: <LogicalKeyboardKey>{
          LogicalKeyboardKey.controlLeft,
          LogicalKeyboardKey.keyB,
        },
        bindings: desktopShortcutDefaultBindings,
        editorFocused: true,
        alwaysOnTopSupported: false,
        pinning: false,
      ),
      DesktopQuickInputShortcutIntent.bold,
    );
  });

  test('plain Enter falls through to editor smart-enter handling', () {
    expect(
      resolveDesktopQuickInputShortcutIntent(
        event: _keyDown(LogicalKeyboardKey.enter),
        pressedKeys: <LogicalKeyboardKey>{LogicalKeyboardKey.enter},
        bindings: desktopShortcutDefaultBindings,
        editorFocused: true,
        alwaysOnTopSupported: false,
        pinning: false,
      ),
      isNull,
    );
  });
}

KeyDownEvent _keyDown(LogicalKeyboardKey key) {
  return KeyDownEvent(
    timeStamp: Duration.zero,
    logicalKey: key,
    physicalKey: PhysicalKeyboardKey(key.keyId),
  );
}

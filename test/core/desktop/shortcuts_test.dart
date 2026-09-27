import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/desktop/shortcuts.dart';

void main() {
  test('windows global actions include paging shortcuts', () {
    final actions = desktopShortcutGlobalActionsForPlatform(
      TargetPlatform.windows,
    );

    expect(actions, contains(DesktopShortcutAction.previousPage));
    expect(actions, contains(DesktopShortcutAction.nextPage));
  });

  test('non-windows global actions exclude paging shortcuts', () {
    final actions = desktopShortcutGlobalActionsForPlatform(
      TargetPlatform.macOS,
    );

    expect(actions, isNot(contains(DesktopShortcutAction.previousPage)));
    expect(actions, isNot(contains(DesktopShortcutAction.nextPage)));
  });

  test('paging shortcuts default to plain PageUp and PageDown', () {
    expect(
      desktopShortcutDefaultBindings[DesktopShortcutAction.previousPage],
      DesktopShortcutBinding(
        keyId: LogicalKeyboardKey.pageUp.keyId,
        primary: false,
        shift: false,
        alt: false,
      ),
    );
    expect(
      desktopShortcutDefaultBindings[DesktopShortcutAction.nextPage],
      DesktopShortcutBinding(
        keyId: LogicalKeyboardKey.pageDown.keyId,
        primary: false,
        shift: false,
        alt: false,
      ),
    );
  });

  test('plain binding allowance is limited to paging actions', () {
    expect(
      desktopShortcutActionAllowsPlainBinding(
        DesktopShortcutAction.previousPage,
        LogicalKeyboardKey.pageUp,
      ),
      isTrue,
    );
    expect(
      desktopShortcutActionAllowsPlainBinding(
        DesktopShortcutAction.nextPage,
        LogicalKeyboardKey.pageDown,
      ),
      isTrue,
    );
    expect(
      desktopShortcutActionAllowsPlainBinding(
        DesktopShortcutAction.search,
        LogicalKeyboardKey.pageUp,
      ),
      isFalse,
    );
  });

  test('paging binding labels keep PageUp and PageDown names', () {
    expect(
      desktopShortcutBindingLabel(
        DesktopShortcutBinding(
          keyId: LogicalKeyboardKey.pageUp.keyId,
          primary: false,
          shift: false,
          alt: false,
        ),
      ),
      'PageUp',
    );
    expect(
      desktopShortcutBindingLabel(
        DesktopShortcutBinding(
          keyId: LogicalKeyboardKey.pageDown.keyId,
          primary: false,
          shift: false,
          alt: false,
        ),
      ),
      'PageDown',
    );
  });

  test('shortcut labels use platform key names', () {
    final binding = DesktopShortcutBinding(
      keyId: LogicalKeyboardKey.enter.keyId,
      primary: true,
      shift: true,
      alt: true,
    );

    expect(
      desktopShortcutBindingLabel(binding, TargetPlatform.windows),
      'Ctrl + Shift + Alt + Enter',
    );
    expect(
      desktopShortcutBindingLabel(binding, TargetPlatform.macOS),
      '⌘ + ⇧ + ⌥ + Return',
    );
    expect(desktopShiftEnterShortcutLabel(TargetPlatform.macOS), '⇧ + Return');
  });

  test('publish memo default binding label uses platform primary Enter', () {
    final binding =
        desktopShortcutDefaultBindings[DesktopShortcutAction.publishMemo]!;

    expect(
      desktopShortcutBindingLabel(binding, TargetPlatform.windows),
      'Ctrl + Enter',
    );
    expect(
      desktopShortcutBindingLabel(binding, TargetPlatform.macOS),
      '⌘ + Return',
    );
  });

  test('guide binding label uses the active search shortcut', () {
    expect(
      desktopShortcutGuideBindingLabel(
        desktopShortcutDefaultBindings,
        DesktopShortcutAction.search,
      ),
      'Ctrl + K',
    );
  });

  test('guide binding label keeps F1 fallback for shortcut overview', () {
    expect(
      desktopShortcutGuideBindingLabel(
        desktopShortcutDefaultBindings,
        DesktopShortcutAction.shortcutOverview,
      ),
      'Shift + / / F1',
    );
    expect(
      desktopShortcutGuideBindingLabel(
        desktopShortcutDefaultBindings,
        DesktopShortcutAction.shortcutOverview,
        TargetPlatform.macOS,
      ),
      '⇧ + / / F1',
    );
  });

  test('submit action matcher uses Windows primary Enter binding', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    expect(
      matchesDesktopShortcutAction(
        event: _keyDown(LogicalKeyboardKey.enter),
        pressedKeys: <LogicalKeyboardKey>{
          LogicalKeyboardKey.controlLeft,
          LogicalKeyboardKey.enter,
        },
        bindings: desktopShortcutDefaultBindings,
        action: DesktopShortcutAction.publishMemo,
      ),
      isTrue,
    );
    expect(
      matchesDesktopShortcutAction(
        event: _keyDown(LogicalKeyboardKey.enter),
        pressedKeys: <LogicalKeyboardKey>{LogicalKeyboardKey.enter},
        bindings: desktopShortcutDefaultBindings,
        action: DesktopShortcutAction.publishMemo,
      ),
      isFalse,
    );
  });

  test('submit action matcher uses macOS primary Return binding', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    expect(
      matchesDesktopShortcutAction(
        event: _keyDown(LogicalKeyboardKey.enter),
        pressedKeys: <LogicalKeyboardKey>{
          LogicalKeyboardKey.metaLeft,
          LogicalKeyboardKey.enter,
        },
        bindings: desktopShortcutDefaultBindings,
        action: DesktopShortcutAction.publishMemo,
      ),
      isTrue,
    );
    expect(
      matchesDesktopShortcutAction(
        event: _keyDown(LogicalKeyboardKey.enter),
        pressedKeys: <LogicalKeyboardKey>{LogicalKeyboardKey.enter},
        bindings: desktopShortcutDefaultBindings,
        action: DesktopShortcutAction.publishMemo,
      ),
      isFalse,
    );
  });

  test('action matcher honors custom modifier binding', () {
    final bindings = <DesktopShortcutAction, DesktopShortcutBinding>{
      DesktopShortcutAction.publishMemo: DesktopShortcutBinding(
        keyId: LogicalKeyboardKey.keyS.keyId,
        primary: true,
        shift: true,
        alt: false,
      ),
    };

    expect(
      matchesDesktopShortcutAction(
        event: _keyDown(LogicalKeyboardKey.keyS),
        pressedKeys: <LogicalKeyboardKey>{
          LogicalKeyboardKey.controlLeft,
          LogicalKeyboardKey.shiftLeft,
          LogicalKeyboardKey.keyS,
        },
        bindings: bindings,
        action: DesktopShortcutAction.publishMemo,
      ),
      isTrue,
    );
    expect(
      matchesDesktopShortcutAction(
        event: _keyDown(LogicalKeyboardKey.keyS),
        pressedKeys: <LogicalKeyboardKey>{
          LogicalKeyboardKey.controlLeft,
          LogicalKeyboardKey.keyS,
        },
        bindings: bindings,
        action: DesktopShortcutAction.publishMemo,
      ),
      isFalse,
    );
  });

  test('action matcher treats Enter and NumpadEnter as submit equivalents', () {
    final bindings = <DesktopShortcutAction, DesktopShortcutBinding>{
      DesktopShortcutAction.publishMemo: DesktopShortcutBinding(
        keyId: LogicalKeyboardKey.enter.keyId,
        primary: true,
        shift: false,
        alt: false,
      ),
    };

    expect(
      matchesDesktopShortcutAction(
        event: _keyDown(LogicalKeyboardKey.numpadEnter),
        pressedKeys: <LogicalKeyboardKey>{
          LogicalKeyboardKey.controlLeft,
          LogicalKeyboardKey.numpadEnter,
        },
        bindings: bindings,
        action: DesktopShortcutAction.publishMemo,
      ),
      isTrue,
    );
    expect(
      matchesDesktopShortcutAction(
        event: _keyDown(LogicalKeyboardKey.numpadEnter),
        pressedKeys: <LogicalKeyboardKey>{LogicalKeyboardKey.numpadEnter},
        bindings: bindings,
        action: DesktopShortcutAction.publishMemo,
      ),
      isFalse,
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memos_flutter_app/core/markdown_editing.dart';

void main() {
  testWidgets(
    'continues unordered list items inside a ValueListenableBuilder-backed field',
    (tester) async {
      final harnessKey = GlobalKey<_InlineComposeHarnessState>();

      await tester.pumpWidget(_InlineComposeHarness(key: harnessKey));

      final field = find.byKey(const ValueKey('inline-compose-text-field'));
      await tester.showKeyboard(field);
      await tester.enterText(field, '- item');
      await tester.pump();

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '- item\n',
          selection: TextSelection.collapsed(offset: 7),
          composing: TextRange.empty,
        ),
      );
      await tester.pump();

      expect(harnessKey.currentState!.controller.text, '- item\n- ');
      expect(
        harnessKey.currentState!.controller.selection,
        const TextSelection.collapsed(offset: 9),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'increments ordered list items inside a ValueListenableBuilder-backed field',
    (tester) async {
      final harnessKey = GlobalKey<_InlineComposeHarnessState>();

      await tester.pumpWidget(_InlineComposeHarness(key: harnessKey));

      final field = find.byKey(const ValueKey('inline-compose-text-field'));
      await tester.showKeyboard(field);
      await tester.enterText(field, '1. item');
      await tester.pump();

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '1. item\n',
          selection: TextSelection.collapsed(offset: 8),
          composing: TextRange.empty,
        ),
      );
      await tester.pump();

      expect(harnessKey.currentState!.controller.text, '1. item\n2. ');
      expect(
        harnessKey.currentState!.controller.selection,
        const TextSelection.collapsed(offset: 11),
      );
      expect(tester.takeException(), isNull);
    },
  );
}

class _InlineComposeHarness extends StatefulWidget {
  const _InlineComposeHarness({super.key});

  @override
  State<_InlineComposeHarness> createState() => _InlineComposeHarnessState();
}

class _InlineComposeHarnessState extends State<_InlineComposeHarness> {
  late final TextEditingController controller;
  late final FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    focusNode = FocusNode();
  }

  @override
  void dispose() {
    focusNode.dispose();
    controller.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            return KeyedSubtree(
              key: const ValueKey('inline-compose-subtree'),
              child: Focus(
                canRequestFocus: false,
                onKeyEvent: _handleKeyEvent,
                child: TextField(
                  key: const ValueKey('inline-compose-text-field'),
                  controller: controller,
                  focusNode: focusNode,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  inputFormatters: const [SmartEnterTextInputFormatter()],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

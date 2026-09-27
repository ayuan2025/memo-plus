import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/db/serialized_workspace_write_runner.dart';

void main() {
  test('serializes writes within the same workspace key', () async {
    final runner = SerializedWorkspaceWriteRunner();
    final order = <String>[];
    final firstEntered = Completer<void>();
    final releaseFirst = Completer<void>();

    final first = runner.run<void>('workspace-a', () async {
      order.add('first-start');
      firstEntered.complete();
      await releaseFirst.future;
      order.add('first-end');
    });
    await firstEntered.future;

    final second = runner.run<void>('workspace-a', () async {
      order.add('second-start');
      order.add('second-end');
    });

    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(order, ['first-start']);

    releaseFirst.complete();
    await Future.wait<void>([first, second]);
    expect(order, ['first-start', 'first-end', 'second-start', 'second-end']);
  });

  test('does not block different workspace keys', () async {
    final runner = SerializedWorkspaceWriteRunner();
    final firstEntered = Completer<void>();
    final secondCompleted = Completer<void>();
    final releaseFirst = Completer<void>();

    final first = runner.run<void>('workspace-a', () async {
      firstEntered.complete();
      await releaseFirst.future;
    });
    await firstEntered.future;

    await runner.run<void>('workspace-b', () async {
      secondCompleted.complete();
    });

    expect(secondCompleted.isCompleted, isTrue);
    releaseFirst.complete();
    await first;
  });
}

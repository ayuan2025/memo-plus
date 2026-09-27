import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'desktop quick input window listens for DB invalidation broadcasts',
    () async {
      final file = File(
        'lib/features/desktop/quick_input/desktop_quick_input_window.dart',
      );
      final contents = await file.readAsString();

      expect(
        contents,
        contains('desktopDbChangedMethod'),
        reason:
            'desktop_quick_input_window.dart must keep handling desktop DB '
            'change broadcasts.',
      );
      expect(
        contents,
        contains('notifyDataChanged()'),
        reason:
            'desktop_quick_input_window.dart must invalidate local database '
            'listeners when desktop DB changes arrive.',
      );
    },
  );
}

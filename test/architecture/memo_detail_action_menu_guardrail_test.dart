import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('memo detail action menu helper stays presentation-only', () async {
    final file = File(
      'lib/features/memos/widgets/memo_detail_action_menu.dart',
    );
    final contents = await file.readAsString();

    const forbiddenPatterns = <String>[
      "import '../../../application/",
      "import '../../../state/",
      "import '../../../data/repositories/",
      "import '../memo_editor_screen.dart'",
      "import '../memo_versions_screen.dart'",
      "import '../memo_time_adjustment_sheet.dart'",
      "import '../../collections/",
      "import '../../reminders/",
      'Navigator.',
      'Clipboard.',
      'showAddMemoToCollectionSheet',
      'updateLocalAndEnqueue',
      'deleteMemo(',
      'adjustMemoTime(',
    ];

    final violations = forbiddenPatterns
        .where((pattern) => contents.contains(pattern))
        .toList(growable: false);

    expect(
      violations,
      isEmpty,
      reason: violations.isEmpty
          ? null
          : 'Memo detail action menu must remain presentation-only and '
                'return selected actions instead of owning behavior:\n'
                '${violations.join('\n')}',
    );
  });
}

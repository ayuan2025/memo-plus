import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/features/memos/memo_task_list_service.dart';

void main() {
  const service = MemoTaskListService();

  test('stripToggleHint removes hint suffix and keeps title', () {
    const content =
        '\u4efb\u52a1\u5217\u8868\uff08\u53ef\u70b9\u51fb\u5207\u6362\uff09\n- [ ] \u672a\u5b8c\u6210\u4efb\u52a1\n- [x] \u5df2\u5b8c\u6210\u4efb\u52a1';

    expect(
      service.stripToggleHint(content),
      '\u4efb\u52a1\u5217\u8868\n- [ ] \u672a\u5b8c\u6210\u4efb\u52a1\n- [x] \u5df2\u5b8c\u6210\u4efb\u52a1',
    );
  });

  test('count ignores fenced code and optionally skips quoted lines', () {
    const content =
        '- [ ] open\n'
        '```\n'
        '- [x] hidden\n'
        '```\n'
        '> - [x] quoted\n'
        '1. [x] ordered';

    final defaultStats = service.count(content);
    expect(defaultStats.total, 1);
    expect(defaultStats.checked, 0);

    final orderedStats = service.count(
      content,
      options: const TaskListOptions(includeOrderedMarkers: true),
    );
    expect(orderedStats.total, 3);
    expect(orderedStats.checked, 2);

    final skipQuotedStats = service.count(
      content,
      options: const TaskListOptions(
        skipQuotedLines: true,
        includeOrderedMarkers: true,
      ),
    );
    expect(skipQuotedStats.total, 2);
    expect(skipQuotedStats.checked, 1);
  });

  test('progress uses shared counting rules', () {
    const content = '- [x] done\n- [ ] open';

    expect(service.progress(content), 0.5);
  });

  test('toggle flips unordered checkbox without changing other lines', () {
    const content = '- [ ] first\n- [x] second';

    expect(service.toggle(content, 0), '- [x] first\n- [x] second');
    expect(service.toggle(content, 1), '- [ ] first\n- [ ] second');
  });

  test('toggle supports ordered and quoted markers when enabled', () {
    const content = '1. [ ] first\n> 2. [x] second\n- [ ] third';

    expect(
      service.toggle(
        content,
        1,
        options: const TaskListOptions(includeOrderedMarkers: true),
      ),
      '1. [ ] first\n> 2. [ ] second\n- [ ] third',
    );
  });
}

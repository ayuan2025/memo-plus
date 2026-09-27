class TaskStats {
  const TaskStats({required this.total, required this.checked});

  final int total;
  final int checked;
}

class TaskListOptions {
  const TaskListOptions({
    this.skipQuotedLines = false,
    this.includeOrderedMarkers = false,
  });

  final bool skipQuotedLines;
  final bool includeOrderedMarkers;
}

const String _taskListTitle = '\u4efb\u52a1\u5217\u8868';
const String _taskListToggleHintFullWidth =
    '\u4efb\u52a1\u5217\u8868\uFF08\u53ef\u70b9\u51fb\u5207\u6362\uFF09';
const String _taskListToggleHintAscii =
    '\u4efb\u52a1\u5217\u8868(\u53ef\u70b9\u51fb\u5207\u6362)';

const MemoTaskListService _memoTaskListService = MemoTaskListService();

String stripTaskListToggleHint(String content) {
  return _memoTaskListService.stripToggleHint(content);
}

TaskStats countTaskStats(String content, {bool skipQuotedLines = false}) {
  return _memoTaskListService.count(
    content,
    options: TaskListOptions(skipQuotedLines: skipQuotedLines),
  );
}

double calculateProgress(String content, {bool skipQuotedLines = false}) {
  return _memoTaskListService.progress(
    content,
    options: TaskListOptions(skipQuotedLines: skipQuotedLines),
  );
}

String toggleCheckbox(
  String rawContent,
  int checkboxIndex, {
  bool skipQuotedLines = false,
}) {
  return _memoTaskListService.toggle(
    rawContent,
    checkboxIndex,
    options: TaskListOptions(skipQuotedLines: skipQuotedLines),
  );
}

class MemoTaskListService {
  const MemoTaskListService();

  static final RegExp _whitespaceRegex = RegExp(r'\s+');
  static final RegExp _fenceRegex = RegExp(r'^\s*(```|~~~)');
  static final RegExp _unorderedTaskRegex = RegExp(
    r'^(\s*[-*+]\s+)\[( |x|X)\]',
  );
  static final RegExp _orderedOrQuotedTaskRegex = RegExp(
    r'^(\s*(?:>\s*)?(?:[-*+]|\d+[.)])\s+)\[( |x|X)\]',
  );

  String stripToggleHint(String content) {
    if (content.isEmpty) return content;

    final lines = content.split('\n');
    final filtered = lines
        .map((line) {
          final leadingWhitespace = line.substring(
            0,
            line.length - line.trimLeft().length,
          );
          final normalized = line.trim().replaceAll(_whitespaceRegex, '');
          if (normalized != _taskListToggleHintFullWidth &&
              normalized != _taskListToggleHintAscii) {
            return line;
          }
          return '$leadingWhitespace$_taskListTitle';
        })
        .toList(growable: false);

    return filtered.join('\n');
  }

  TaskStats count(
    String content, {
    TaskListOptions options = const TaskListOptions(),
  }) {
    final taskRegex = _taskRegex(options);
    var inFence = false;
    var total = 0;
    var checked = 0;

    for (final line in content.split('\n')) {
      if (_fenceRegex.hasMatch(line)) {
        inFence = !inFence;
        continue;
      }
      if (inFence) continue;
      if (options.skipQuotedLines && line.trimLeft().startsWith('>')) continue;

      final match = taskRegex.firstMatch(line);
      if (match == null) continue;

      total++;
      final mark = match.group(2) ?? '';
      if (mark.toLowerCase() == 'x') {
        checked++;
      }
    }

    return TaskStats(total: total, checked: checked);
  }

  double progress(
    String content, {
    TaskListOptions options = const TaskListOptions(),
  }) {
    final stats = count(content, options: options);
    if (stats.total == 0) return 0.0;
    return stats.checked / stats.total;
  }

  String toggle(
    String rawContent,
    int taskIndex, {
    TaskListOptions options = const TaskListOptions(),
  }) {
    final taskRegex = _taskRegex(options);
    var inFence = false;
    var index = 0;
    var offset = 0;
    final lines = rawContent.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_fenceRegex.hasMatch(line)) {
        inFence = !inFence;
        offset += line.length + (i == lines.length - 1 ? 0 : 1);
        continue;
      }

      final skipLine =
          inFence ||
          (options.skipQuotedLines && line.trimLeft().startsWith('>'));
      if (!skipLine) {
        final match = taskRegex.firstMatch(line);
        if (match != null) {
          if (index == taskIndex) {
            final leading = match.group(1) ?? '';
            final mark = match.group(2) ?? ' ';
            final newMark = mark.toLowerCase() == 'x' ? ' ' : 'x';
            final markOffset = offset + match.start + leading.length + 1;
            return rawContent.replaceRange(markOffset, markOffset + 1, newMark);
          }
          index++;
        }
      }

      offset += line.length + (i == lines.length - 1 ? 0 : 1);
    }

    return rawContent;
  }

  RegExp _taskRegex(TaskListOptions options) {
    return options.includeOrderedMarkers
        ? _orderedOrQuotedTaskRegex
        : _unorderedTaskRegex;
  }
}

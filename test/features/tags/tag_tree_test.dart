import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memos_flutter_app/features/tags/tag_tree.dart';
import 'package:memos_flutter_app/state/memos/memos_providers.dart';

void main() {
  test(
    'buildTagTree synthesizes missing path parents without mutating iteration',
    () {
      final tree = buildTagTree(const [
        TagStat(tag: 'project/alpha', path: 'project/alpha', count: 2),
        TagStat(tag: 'project/beta', path: 'project/beta', count: 1),
      ]);

      expect(tree, hasLength(1));
      expect(tree.single.path, 'project');
      expect(tree.single.count, 0);
      expect(tree.single.children.map((node) => node.path), [
        'project/alpha',
        'project/beta',
      ]);
    },
  );

  test('filterTagTree keeps ancestor chain for nested matches', () {
    final tree = buildTagTree(const [
      TagStat(tag: 'work', path: 'work', count: 3, tagId: 1),
      TagStat(
        tag: 'work/project',
        path: 'work/project',
        count: 2,
        tagId: 2,
        parentId: 1,
      ),
      TagStat(tag: 'home', path: 'home', count: 1, tagId: 3),
    ]);

    final result = filterTagTree(
      tree,
      (node) => node.path.toLowerCase().contains('project'),
    );

    expect(result.nodes, hasLength(1));
    expect(result.nodes.single.path, 'work');
    expect(result.nodes.single.children, hasLength(1));
    expect(result.nodes.single.children.single.path, 'work/project');
    expect(result.autoExpandedPaths, contains('work'));
  });

  testWidgets('TagTreeList shows selected marker and forwards expand taps', (
    tester,
  ) async {
    final tree = buildTagTree(const [
      TagStat(tag: 'work', path: 'work', count: 3, tagId: 1),
      TagStat(
        tag: 'work/project',
        path: 'work/project',
        count: 2,
        tagId: 2,
        parentId: 1,
      ),
    ]);
    String? toggledPath;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TagTreeList(
            nodes: tree,
            expandedPaths: const {'work'},
            onToggleExpanded: (path) => toggledPath = path,
            onSelect: (_) {},
            selectedPath: 'work/project',
            showSelectedLeadingCheck: true,
            textMain: Colors.black,
            textMuted: Colors.grey,
          ),
        ),
      ),
    );

    expect(find.text('project'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right).first);
    await tester.pump();

    expect(toggledPath, 'work');
  });

  testWidgets('TagTreeList hides nested tags until parent is expanded', (
    tester,
  ) async {
    final tree = buildTagTree(const [
      TagStat(tag: 'work', path: 'work', count: 3, tagId: 1),
      TagStat(
        tag: 'work/project',
        path: 'work/project',
        count: 1,
        tagId: 2,
        parentId: 1,
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TagTreeList(
            nodes: tree,
            onSelect: (_) {},
            textMain: Colors.black,
            textMuted: Colors.grey,
          ),
        ),
      ),
    );

    expect(find.text('work'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('project'), findsNothing);
  });

  testWidgets('TagTreeList keeps default text color even when tag has color', (
    tester,
  ) async {
    final tree = buildTagTree(const [
      TagStat(
        tag: 'work',
        path: 'work',
        count: 3,
        tagId: 1,
        colorHex: '#FF0000',
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TagTreeList(
            nodes: tree,
            onSelect: (_) {},
            textMain: Colors.black,
            textMuted: Colors.grey,
          ),
        ),
      ),
    );

    final label = tester.widget<Text>(find.text('work'));
    expect(label.style?.color, Colors.black);
  });
}

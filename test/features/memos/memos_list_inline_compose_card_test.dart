import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/features/image_preview/widgets/image_preview_tile.dart';
import 'package:memos_flutter_app/features/memos/compose_toolbar_shared.dart';
import 'package:memos_flutter_app/features/memos/note_input_sheet.dart';
import 'package:memos_flutter_app/features/memos/tag_autocomplete.dart';
import 'package:memos_flutter_app/features/memos/widgets/memos_list_inline_compose_card.dart';
import 'package:memos_flutter_app/i18n/strings.g.dart';
import 'package:memos_flutter_app/state/memos/memo_composer_controller.dart';
import 'package:memos_flutter_app/state/memos/memo_composer_state.dart';
import 'package:memos_flutter_app/state/memos/memos_providers.dart';
import 'package:memos_flutter_app/state/tags/tag_color_lookup.dart';

void main() {
  setUp(() => LocaleSettings.setLocale(AppLocale.en));

  testWidgets('renders composer text and gates submit when busy', (
    tester,
  ) async {
    final composer = MemoComposerController(initialText: 'hello');
    final focusNode = FocusNode();
    var submitCount = 0;
    addTearDown(() {
      focusNode.dispose();
      composer.dispose();
    });

    await tester.pumpWidget(
      _InlineComposeCardHarness(
        composer: composer,
        focusNode: focusNode,
        busy: false,
        onSubmit: () => submitCount++,
      ),
    );

    expect(find.text('hello'), findsOneWidget);
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('memos-inline-compose-send-button')),
    );
    await tester.pump();
    expect(submitCount, 1);

    await tester.pumpWidget(
      _InlineComposeCardHarness(
        composer: composer,
        focusNode: focusNode,
        busy: true,
        onSubmit: () => submitCount++,
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('memos-inline-compose-send-button')),
    );
    await tester.pump();
    expect(submitCount, 1);
  });

  testWidgets(
    'renders attachment and linked memo chips with delete callbacks',
    (tester) async {
      final composer = MemoComposerController();
      final focusNode = FocusNode();
      String? removedAttachmentUid;
      String? removedLinkedMemoName;
      addTearDown(() {
        focusNode.dispose();
        composer.dispose();
      });

      composer.addPendingAttachments([
        const MemoComposerPendingAttachment(
          uid: 'att-1',
          filePath: 'Z:/does-not-exist.png',
          filename: 'photo.png',
          mimeType: 'image/png',
          size: 42,
        ),
      ]);
      composer.addLinkedMemo(
        const MemoComposerLinkedMemo(name: 'memo-1', label: 'Memo 1'),
      );

      await tester.pumpWidget(
        _InlineComposeCardHarness(
          composer: composer,
          focusNode: focusNode,
          onRemoveAttachment: (uid) => removedAttachmentUid = uid,
          onRemoveLinkedMemo: (name) => removedLinkedMemoName = name,
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('inline-attachment-att-1')),
        findsOneWidget,
      );
      expect(find.text('Memo 1'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('inline-attachment-remove-att-1')),
      );
      await tester.pump();
      expect(removedAttachmentUid, 'att-1');

      final chip = find.byKey(
        const ValueKey<String>('inline-linked-memo-memo-1'),
      );
      tester.widget<InputChip>(chip).onDeleted!.call();
      expect(removedLinkedMemoName, 'memo-1');
    },
  );

  testWidgets('pending image preview uses single-axis cache fallback', (
    tester,
  ) async {
    _setUnitDevicePixelRatio(tester);
    final imageFile = await _writeTestSvg('inline-card-preview');
    final composer = MemoComposerController();
    final focusNode = FocusNode();
    addTearDown(() {
      focusNode.dispose();
      composer.dispose();
    });

    composer.addPendingAttachments([
      MemoComposerPendingAttachment(
        uid: 'att-image',
        filePath: imageFile.path,
        filename: 'photo.svg',
        mimeType: 'image/svg+xml',
        size: imageFile.lengthSync(),
      ),
    ]);

    await tester.pumpWidget(
      _InlineComposeCardHarness(composer: composer, focusNode: focusNode),
    );
    await tester.pump();

    final tile = tester.widget<ImagePreviewTile>(find.byType(ImagePreviewTile));
    expect(tile.cacheWidth, 93);
    expect(tile.cacheHeight, isNull);
    expect(tile.fit, BoxFit.cover);
    expect(
      find.byKey(const ValueKey<String>('inline-attachment-att-image')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('inline-attachment-remove-att-image')),
      findsOneWidget,
    );
  });

  test('note input pending preview uses single-axis cache fallback', () {
    final target = resolveNoteInputPendingImageThumbnailCacheTarget(
      tileSize: 62,
      devicePixelRatio: 1,
    );

    expect(target.width, 93);
    expect(target.height, isNull);
  });

  testWidgets('shows tag autocomplete and selects highlighted suggestion', (
    tester,
  ) async {
    final composer = MemoComposerController(initialText: '#wo');
    final focusNode = FocusNode();
    addTearDown(() {
      focusNode.dispose();
      composer.dispose();
    });
    composer.textController.selection = TextSelection.collapsed(
      offset: composer.text.length,
    );

    final tagStats = <TagStat>[
      const TagStat(tag: 'work', count: 10),
      const TagStat(tag: 'world', count: 5),
    ];

    await tester.pumpWidget(
      _InlineComposeCardHarness(
        composer: composer,
        focusNode: focusNode,
        tagStats: tagStats,
      ),
    );

    final field = find.byKey(
      const ValueKey<String>('memos-inline-compose-text-field'),
    );
    await tester.tap(field);
    await tester.showKeyboard(field);
    focusNode.requestFocus();
    composer.textController.selection = TextSelection.collapsed(
      offset: composer.text.length,
    );
    composer.syncTagAutocompleteState(tagStats: tagStats, hasFocus: true);
    await tester.pump();
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);
    expect(
      composer
          .currentTagSuggestions(tagStats, hasFocus: focusNode.hasFocus)
          .map((tag) => tag.path)
          .toList(),
      ['work', 'world'],
    );
    expect(composer.tagAutocompleteIndex, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(composer.tagAutocompleteIndex, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(composer.textController.text, '#world ');
  });

  testWidgets('tag autocomplete overlay removes root entry on focus loss', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'See #wo')
      ..selection = const TextSelection.collapsed(offset: 7);
    final focusNode = FocusNode();
    addTearDown(() {
      controller.dispose();
      focusNode.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: _TagAutocompleteOverlayHarness(
              controller: controller,
              focusNode: focusNode,
            ),
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);
    expect(find.text('#work'), findsOneWidget);

    focusNode.unfocus();
    await tester.pump();

    expect(focusNode.hasFocus, isFalse);
    expect(find.text('#work'), findsNothing);
  });

  testWidgets('gallery toolbar action clears focus before picker callback', (
    tester,
  ) async {
    final composer = MemoComposerController(initialText: '#wo');
    final focusNode = FocusNode();
    var pickGalleryCalled = false;
    addTearDown(() {
      focusNode.dispose();
      composer.dispose();
    });

    final tagStats = <TagStat>[
      const TagStat(tag: 'work', path: 'work', count: 10),
    ];

    await tester.pumpWidget(
      _InlineComposeCardHarness(
        composer: composer,
        focusNode: focusNode,
        tagStats: tagStats,
        toolbarPreferences: MemoToolbarPreferences(
          topRowItems: const [],
          bottomRowItems: [MemoToolbarActionId.gallery.itemId],
          hiddenItemIds: const {},
          customButtons: const [],
        ),
        onPickGallery: () {
          pickGalleryCalled = true;
          expect(focusNode.hasFocus, isFalse);
        },
      ),
    );

    final field = find.byKey(
      const ValueKey<String>('memos-inline-compose-text-field'),
    );
    await tester.tap(field);
    await tester.showKeyboard(field);
    focusNode.requestFocus();
    composer.textController.selection = TextSelection.collapsed(
      offset: composer.text.length,
    );
    composer.syncTagAutocompleteState(tagStats: tagStats, hasFocus: true);
    await tester.pump();
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);
    expect(find.text('#work'), findsOneWidget);

    await tester.tap(find.byTooltip('Gallery'));
    await tester.pump();

    expect(pickGalleryCalled, isTrue);
    expect(focusNode.hasFocus, isFalse);
    expect(find.text('#work'), findsNothing);
  });

  testWidgets('shows draft-box hint for blank composer when drafts exist', (
    tester,
  ) async {
    final composer = MemoComposerController();
    final focusNode = FocusNode();
    addTearDown(() {
      focusNode.dispose();
      composer.dispose();
    });

    await tester.pumpWidget(
      _InlineComposeCardHarness(
        composer: composer,
        focusNode: focusNode,
        pendingDraftCount: 3,
      ),
    );

    expect(
      find.text('Draft Box has unfinished drafts (3). Tap Draft Box to view.'),
      findsOneWidget,
    );
    expect(find.text('Write down your thoughts...'), findsNothing);
  });

  testWidgets('keeps default hint when current composer has attachments', (
    tester,
  ) async {
    final composer = MemoComposerController();
    final focusNode = FocusNode();
    addTearDown(() {
      focusNode.dispose();
      composer.dispose();
    });

    composer.addPendingAttachments([
      const MemoComposerPendingAttachment(
        uid: 'att-1',
        filePath: 'Z:/does-not-exist.png',
        filename: 'photo.png',
        mimeType: 'image/png',
        size: 42,
      ),
    ]);

    await tester.pumpWidget(
      _InlineComposeCardHarness(
        composer: composer,
        focusNode: focusNode,
        pendingDraftCount: 3,
      ),
    );

    expect(find.text('Write down your thoughts...'), findsOneWidget);
    expect(
      find.text('Draft Box has unfinished drafts (3). Tap Draft Box to view.'),
      findsNothing,
    );
  });

  testWidgets('does not show draft-box hint when composer already has text', (
    tester,
  ) async {
    final composer = MemoComposerController(initialText: 'hello');
    final focusNode = FocusNode();
    addTearDown(() {
      focusNode.dispose();
      composer.dispose();
    });

    await tester.pumpWidget(
      _InlineComposeCardHarness(
        composer: composer,
        focusNode: focusNode,
        pendingDraftCount: 3,
      ),
    );

    expect(
      find.text('Draft Box has unfinished drafts (3). Tap Draft Box to view.'),
      findsNothing,
    );
  });
}

void _setUnitDevicePixelRatio(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<File> _writeTestSvg(String prefix) async {
  final directory = Directory.systemTemp.createTempSync(prefix);
  addTearDown(() async {
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
  });
  final file = File('${directory.path}${Platform.pathSeparator}photo.svg');
  file.writeAsStringSync(
    '<svg xmlns="http://www.w3.org/2000/svg" width="4" height="1"></svg>',
  );
  return file;
}

class _InlineComposeCardHarness extends StatefulWidget {
  const _InlineComposeCardHarness({
    required this.composer,
    required this.focusNode,
    this.busy = false,
    this.pendingDraftCount = 0,
    this.tagStats = const <TagStat>[],
    this.toolbarPreferences,
    this.onSubmit,
    this.onRemoveAttachment,
    this.onRemoveLinkedMemo,
    this.onPickGallery,
  });

  final MemoComposerController composer;
  final FocusNode focusNode;
  final bool busy;
  final int pendingDraftCount;
  final List<TagStat> tagStats;
  final MemoToolbarPreferences? toolbarPreferences;
  final VoidCallback? onSubmit;
  final ValueChanged<String>? onRemoveAttachment;
  final ValueChanged<String>? onRemoveLinkedMemo;
  final VoidCallback? onPickGallery;

  @override
  State<_InlineComposeCardHarness> createState() =>
      _InlineComposeCardHarnessState();
}

class _InlineComposeCardHarnessState extends State<_InlineComposeCardHarness> {
  @override
  void initState() {
    super.initState();
    widget.composer.textController.addListener(_syncTagAutocomplete);
    widget.focusNode.addListener(_syncTagAutocomplete);
    _syncTagAutocomplete();
  }

  @override
  void didUpdateWidget(covariant _InlineComposeCardHarness oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.composer != widget.composer) {
      oldWidget.composer.textController.removeListener(_syncTagAutocomplete);
      widget.composer.textController.addListener(_syncTagAutocomplete);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_syncTagAutocomplete);
      widget.focusNode.addListener(_syncTagAutocomplete);
    }
    if (oldWidget.tagStats != widget.tagStats) {
      _syncTagAutocomplete();
    }
  }

  @override
  void dispose() {
    widget.composer.textController.removeListener(_syncTagAutocomplete);
    widget.focusNode.removeListener(_syncTagAutocomplete);
    super.dispose();
  }

  void _syncTagAutocomplete() {
    widget.composer.syncTagAutocompleteState(
      tagStats: widget.tagStats,
      hasFocus: widget.focusNode.hasFocus,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TranslationProvider(
      child: MaterialApp(
        locale: AppLocale.en.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 420,
              child: MemosListInlineComposeCard(
                composer: widget.composer,
                focusNode: widget.focusNode,
                pendingDraftCount: widget.pendingDraftCount,
                busy: widget.busy,
                locating: false,
                location: null,
                visibility: 'PRIVATE',
                visibilityTouched: false,
                visibilityLabel: 'Private',
                visibilityIcon: Icons.lock_outline,
                visibilityColor: Colors.red,
                isDark: false,
                tagStats: widget.tagStats,
                availableTemplates: const [],
                tagColorLookup: TagColorLookup(widget.tagStats),
                toolbarPreferences:
                    widget.toolbarPreferences ??
                    MemoToolbarPreferences.defaults,
                editorFieldKey: GlobalKey(),
                tagMenuKey: GlobalKey(),
                templateMenuKey: GlobalKey(),
                todoMenuKey: GlobalKey(),
                visibilityMenuKey: GlobalKey(),
                onSubmit: widget.onSubmit ?? () {},
                onRemoveAttachment: widget.onRemoveAttachment ?? (_) {},
                onOpenAttachment: (_) {},
                onRemoveLinkedMemo: widget.onRemoveLinkedMemo ?? (_) {},
                onRequestLocation: () {},
                onClearLocation: () {},
                onOpenTemplateMenu: () {},
                onPickGallery: widget.onPickGallery ?? () {},
                onPickFile: () {},
                onOpenLinkMemo: () {},
                onCaptureCamera: () {},
                onScanDocument: () {},
                onOpenDraftBox: () {},
                onOpenTodoMenu: () {},
                onOpenVisibilityMenu: () {},
                onCutParagraphs: () {},
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TagAutocompleteOverlayHarness extends StatefulWidget {
  const _TagAutocompleteOverlayHarness({
    required this.controller,
    required this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  State<_TagAutocompleteOverlayHarness> createState() =>
      _TagAutocompleteOverlayHarnessState();
}

class _TagAutocompleteOverlayHarnessState
    extends State<_TagAutocompleteOverlayHarness> {
  final _editorKey = GlobalKey();

  static const _tags = <TagStat>[TagStat(tag: 'work', path: 'work', count: 3)];

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 16, height: 1.35);
    return SizedBox(
      width: 320,
      height: 120,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          KeyedSubtree(
            key: _editorKey,
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              style: textStyle,
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
          TagAutocompleteOverlay(
            editorKey: _editorKey,
            focusNode: widget.focusNode,
            value: widget.controller.value,
            textStyle: textStyle,
            tags: _tags,
            tagColors: TagColorLookup(_tags),
            highlightedIndex: 0,
            onSelect: (_) {},
          ),
        ],
      ),
    );
  }
}

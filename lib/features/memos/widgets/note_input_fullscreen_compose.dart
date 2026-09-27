import 'package:flutter/material.dart';

import '../../../core/markdown_editing.dart';
import '../../../core/memoflow_palette.dart';
import '../../../data/models/memo_location.dart';
import '../../../platform/widgets/platform_controls.dart';
import '../../../state/memos/memo_composer_state.dart';
import '../../../state/memos/memos_providers.dart';
import '../../../state/tags/tag_color_lookup.dart';
import '../../memos/compose_toolbar_shared.dart';
import '../../memos/tag_autocomplete.dart';
import '../../../i18n/strings.g.dart';
import 'memo_compose_fullscreen_surface.dart';

class NoteInputFullscreenCompose extends StatelessWidget {
  const NoteInputFullscreenCompose({
    super.key,
    required this.isDark,
    required this.sheetColor,
    required this.chipBg,
    required this.chipText,
    required this.chipDelete,
    required this.visibilityLabel,
    required this.visibilityIcon,
    required this.visibilityColor,
    required this.tagSuggestions,
    required this.highlightedTagSuggestionIndex,
    required this.tagColorLookup,
    required this.activeTagQuery,
    required this.editorTextStyle,
    required this.toolbarPreferences,
    required this.toolbarActions,
    required this.editorHintText,
    required this.attachmentPreview,
    required this.linkedMemos,
    required this.location,
    required this.locating,
    required this.busy,
    required this.controller,
    required this.editorFocusNode,
    required this.editorFieldKey,
    required this.autoFocus,
    required this.deferredProgress,
    required this.hasPendingDeferredShareVideoTasks,
    required this.hasAttachmentsForSend,
    required this.expandCollapseKey,
    required this.closeKey,
    required this.topToolbarKey,
    required this.bottomToolbarKey,
    required this.sendButtonKey,
    required this.visibilityButtonKey,
    required this.onCollapse,
    required this.onClose,
    required this.onVisibilityPressed,
    required this.onSubmitOrVoice,
    required this.onRemoveLinkedMemo,
    required this.onRequestLocation,
    required this.onClearLocation,
    required this.onTagHighlight,
    required this.onTagSelect,
    required this.onEditorKeyEvent,
  });

  final bool isDark;
  final Color sheetColor;
  final Color chipBg;
  final Color chipText;
  final Color chipDelete;
  final String visibilityLabel;
  final IconData visibilityIcon;
  final Color visibilityColor;
  final List<TagStat> tagSuggestions;
  final int highlightedTagSuggestionIndex;
  final TagColorLookup tagColorLookup;
  final ActiveTagQuery? activeTagQuery;
  final TextStyle editorTextStyle;
  final MemoToolbarPreferences toolbarPreferences;
  final List<MemoComposeToolbarActionSpec> toolbarActions;
  final String editorHintText;
  final Widget attachmentPreview;
  final List<MemoComposerLinkedMemo> linkedMemos;
  final MemoLocation? location;
  final bool locating;
  final bool busy;
  final TextEditingController controller;
  final FocusNode editorFocusNode;
  final GlobalKey editorFieldKey;
  final bool autoFocus;
  final double? deferredProgress;
  final bool hasPendingDeferredShareVideoTasks;
  final bool hasAttachmentsForSend;
  final Key expandCollapseKey;
  final Key closeKey;
  final Key topToolbarKey;
  final Key bottomToolbarKey;
  final Key sendButtonKey;
  final GlobalKey visibilityButtonKey;
  final VoidCallback onCollapse;
  final VoidCallback onClose;
  final VoidCallback onVisibilityPressed;
  final VoidCallback onSubmitOrVoice;
  final ValueChanged<String> onRemoveLinkedMemo;
  final VoidCallback onRequestLocation;
  final VoidCallback onClearLocation;
  final ValueChanged<int> onTagHighlight;
  final void Function(ActiveTagQuery query, TagStat tag) onTagSelect;
  final FocusOnKeyEventCallback onEditorKeyEvent;

  @override
  Widget build(BuildContext context) {
    return MemoComposeFullscreenSurface(
      isDark: isDark,
      sheetColor: sheetColor,
      toolbarPreferences: toolbarPreferences,
      toolbarActions: toolbarActions,
      metadataChildren: [
        attachmentPreview,
        NoteInputLinkedMemoChips(
          linkedMemos: linkedMemos,
          chipBg: chipBg,
          chipText: chipText,
          chipDelete: chipDelete,
          busy: busy,
          onRemove: onRemoveLinkedMemo,
        ),
        NoteInputLocationState(
          location: location,
          locating: locating,
          chipBg: chipBg,
          chipText: chipText,
          chipDelete: chipDelete,
          busy: busy,
          onRequestLocation: onRequestLocation,
          onClearLocation: onClearLocation,
        ),
      ],
      editor: _FullscreenEditor(
        controller: controller,
        editorFocusNode: editorFocusNode,
        editorFieldKey: editorFieldKey,
        autoFocus: autoFocus,
        editorTextStyle: editorTextStyle,
        editorHintText: editorHintText,
        isDark: isDark,
        activeTagQuery: activeTagQuery,
        tagSuggestions: tagSuggestions,
        tagColorLookup: tagColorLookup,
        highlightedTagSuggestionIndex: highlightedTagSuggestionIndex,
        onTagHighlight: onTagHighlight,
        onTagSelect: onTagSelect,
        onEditorKeyEvent: onEditorKeyEvent,
      ),
      primaryAction: NoteInputFullscreenSendButton(
        key: sendButtonKey,
        isDark: isDark,
        busy: busy,
        deferredProgress: deferredProgress,
        hasPendingDeferredShareVideoTasks: hasPendingDeferredShareVideoTasks,
        hasAttachmentsForSend: hasAttachmentsForSend,
        controller: controller,
        onPressed: onSubmitOrVoice,
      ),
      expandCollapseKey: expandCollapseKey,
      closeKey: closeKey,
      topToolbarKey: topToolbarKey,
      bottomToolbarKey: bottomToolbarKey,
      visibilityButtonKey: visibilityButtonKey,
      visibilityLabel: visibilityLabel,
      visibilityIcon: visibilityIcon,
      visibilityColor: visibilityColor,
      busy: busy,
      onCollapse: onCollapse,
      onClose: onClose,
      onVisibilityPressed: onVisibilityPressed,
    );
  }
}

class NoteInputFullscreenSendButton extends StatelessWidget {
  const NoteInputFullscreenSendButton({
    super.key,
    required this.isDark,
    required this.busy,
    required this.deferredProgress,
    required this.hasPendingDeferredShareVideoTasks,
    required this.hasAttachmentsForSend,
    required this.controller,
    required this.onPressed,
  });

  final bool isDark;
  final bool busy;
  final double? deferredProgress;
  final bool hasPendingDeferredShareVideoTasks;
  final bool hasAttachmentsForSend;
  final TextEditingController controller;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final buttonEnabled = !busy && !hasPendingDeferredShareVideoTasks;
    final buttonColor = buttonEnabled
        ? MemoFlowPalette.primary
        : Theme.of(context).colorScheme.outline;
    return Tooltip(
      message: context.t.strings.legacy.msg_create_memo,
      child: InkResponse(
        onTap: buttonEnabled ? onPressed : null,
        radius: 17,
        child: SizedBox(
          width: 30,
          height: 30,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (deferredProgress != null)
                SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    value: deferredProgress,
                    strokeWidth: 2,
                    color: MemoFlowPalette.primary,
                    backgroundColor: MemoFlowPalette.primary.withValues(
                      alpha: 0.18,
                    ),
                  ),
                ),
              Center(
                child: busy
                    ? SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: buttonColor,
                        ),
                      )
                    : ValueListenableBuilder<TextEditingValue>(
                        valueListenable: controller,
                        builder: (context, value, _) {
                          final hasText = value.text.trim().isNotEmpty;
                          final showSend = hasText || hasAttachmentsForSend;
                          return Icon(
                            showSend ? Icons.send_rounded : Icons.graphic_eq,
                            size: showSend ? 17 : 18,
                            color: buttonColor,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NoteInputLinkedMemoChips extends StatelessWidget {
  const NoteInputLinkedMemoChips({
    super.key,
    required this.linkedMemos,
    required this.chipBg,
    required this.chipText,
    required this.chipDelete,
    required this.busy,
    required this.onRemove,
    this.padding = const EdgeInsets.only(bottom: 8),
  });

  final List<MemoComposerLinkedMemo> linkedMemos;
  final Color chipBg;
  final Color chipText;
  final Color chipDelete;
  final bool busy;
  final ValueChanged<String> onRemove;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (linkedMemos.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: linkedMemos
            .map(
              (memo) => InputChip(
                label: Text(
                  memo.label,
                  style: TextStyle(fontSize: 12, color: chipText),
                ),
                backgroundColor: chipBg,
                deleteIconColor: chipDelete,
                onDeleted: busy ? null : () => onRemove(memo.name),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class NoteInputLocationState extends StatelessWidget {
  const NoteInputLocationState({
    super.key,
    required this.location,
    required this.locating,
    required this.chipBg,
    required this.chipText,
    required this.chipDelete,
    required this.busy,
    required this.onRequestLocation,
    required this.onClearLocation,
    this.padding = const EdgeInsets.only(bottom: 8),
  });

  final MemoLocation? location;
  final bool locating;
  final Color chipBg;
  final Color chipText;
  final Color chipDelete;
  final bool busy;
  final VoidCallback onRequestLocation;
  final VoidCallback onClearLocation;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (locating) {
      return Padding(
        padding: padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              context.t.strings.legacy.msg_locating,
              style: TextStyle(fontSize: 12, color: chipText),
            ),
          ],
        ),
      );
    }
    final currentLocation = location;
    if (currentLocation == null) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: Align(
        alignment: Alignment.centerLeft,
        child: InputChip(
          avatar: Icon(Icons.place_outlined, size: 16, color: chipText),
          label: Text(
            currentLocation.displayText(fractionDigits: 6),
            style: TextStyle(fontSize: 12, color: chipText),
          ),
          backgroundColor: chipBg,
          deleteIconColor: chipDelete,
          onPressed: busy ? null : onRequestLocation,
          onDeleted: busy ? null : onClearLocation,
        ),
      ),
    );
  }
}

class _FullscreenEditor extends StatelessWidget {
  const _FullscreenEditor({
    required this.controller,
    required this.editorFocusNode,
    required this.editorFieldKey,
    required this.autoFocus,
    required this.editorTextStyle,
    required this.editorHintText,
    required this.isDark,
    required this.activeTagQuery,
    required this.tagSuggestions,
    required this.tagColorLookup,
    required this.highlightedTagSuggestionIndex,
    required this.onTagHighlight,
    required this.onTagSelect,
    required this.onEditorKeyEvent,
  });

  final TextEditingController controller;
  final FocusNode editorFocusNode;
  final GlobalKey editorFieldKey;
  final bool autoFocus;
  final TextStyle editorTextStyle;
  final String editorHintText;
  final bool isDark;
  final ActiveTagQuery? activeTagQuery;
  final List<TagStat> tagSuggestions;
  final TagColorLookup tagColorLookup;
  final int highlightedTagSuggestionIndex;
  final ValueChanged<int> onTagHighlight;
  final void Function(ActiveTagQuery query, TagStat tag) onTagSelect;
  final FocusOnKeyEventCallback onEditorKeyEvent;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: KeyedSubtree(
            key: editorFieldKey,
            child: Focus(
              canRequestFocus: false,
              onKeyEvent: onEditorKeyEvent,
              child: PlatformTextField(
                textFieldKey: const ValueKey<String>(
                  'note-input-fullscreen-text-field',
                ),
                controller: controller,
                focusNode: editorFocusNode,
                autofocus: autoFocus,
                inputFormatters: const [SmartEnterTextInputFormatter()],
                keyboardType: TextInputType.multiline,
                maxLines: null,
                expands: true,
                style: editorTextStyle,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: editorHintText,
                  hintStyle: TextStyle(
                    color: isDark
                        ? const Color(0xFF666666)
                        : Colors.grey.shade500,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (editorFocusNode.hasFocus &&
            activeTagQuery != null &&
            tagSuggestions.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: TagAutocompleteOverlay(
                editorKey: editorFieldKey,
                focusNode: editorFocusNode,
                value: controller.value,
                textStyle: editorTextStyle,
                tags: tagSuggestions,
                tagColors: tagColorLookup,
                highlightedIndex: highlightedTagSuggestionIndex,
                onHighlight: onTagHighlight,
                onSelect: (tag) => onTagSelect(activeTagQuery!, tag),
              ),
            ),
          ),
      ],
    );
  }
}

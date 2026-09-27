import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/memoflow_palette.dart';
import '../../state/memos/memos_providers.dart';
import '../../state/tags/tag_color_lookup.dart';

export '../../state/memos/memo_tag_autocomplete.dart';

const int kEditorTagSuggestionVisibleRows = 6;
const double _kTagAutocompleteGap = 8;
const double _kTagAutocompleteViewportPadding = 12;
const double _kTagAutocompleteRowHeight = 42;
const double _kTagAutocompletePanelPadding = 12;
const int _kTagAutocompleteMaxChars = 19;

class TagAutocompletePanel extends StatefulWidget {
  const TagAutocompletePanel({
    super.key,
    required this.tags,
    required this.tagColors,
    required this.highlightedIndex,
    required this.onSelect,
    this.onHighlight,
  });

  final List<TagStat> tags;
  final TagColorLookup tagColors;
  final int highlightedIndex;
  final ValueChanged<TagStat> onSelect;
  final ValueChanged<int>? onHighlight;

  @override
  State<TagAutocompletePanel> createState() => _TagAutocompletePanelState();
}

class _TagAutocompletePanelState extends State<TagAutocompletePanel> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _syncHighlightedIntoView(),
    );
  }

  @override
  void didUpdateWidget(covariant TagAutocompletePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.highlightedIndex != widget.highlightedIndex ||
        oldWidget.tags.length != widget.tags.length) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _syncHighlightedIntoView(),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _syncHighlightedIntoView() {
    if (!mounted || widget.tags.isEmpty || !_scrollController.hasClients) {
      return;
    }
    final index = widget.highlightedIndex
        .clamp(0, widget.tags.length - 1)
        .toInt();
    final targetTop = index * _kTagAutocompleteRowHeight;
    final targetBottom = targetTop + _kTagAutocompleteRowHeight;
    final viewportTop = _scrollController.offset;
    final viewportBottom =
        viewportTop + _scrollController.position.viewportDimension;

    double? nextOffset;
    if (targetTop < viewportTop) {
      nextOffset = targetTop;
    } else if (targetBottom > viewportBottom) {
      nextOffset = targetBottom - _scrollController.position.viewportDimension;
    }
    if (nextOffset == null) return;
    final clampedOffset = nextOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    if ((clampedOffset - _scrollController.offset).abs() < 1) return;
    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tags.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark
        ? MemoFlowPalette.cardDark
        : MemoFlowPalette.cardLight;
    final borderColor = isDark
        ? MemoFlowPalette.borderDark
        : MemoFlowPalette.borderLight;
    final textMain = isDark
        ? MemoFlowPalette.textDark
        : MemoFlowPalette.textLight;
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: SizedBox(
            height: _estimateTagAutocompleteHeight(widget.tags.length),
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              itemCount: widget.tags.length,
              itemExtent: _kTagAutocompleteRowHeight,
              physics: widget.tags.length > kEditorTagSuggestionVisibleRows
                  ? const ClampingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final stat = widget.tags[index];
                final isHighlighted = index == widget.highlightedIndex;
                final tagColorsForRow = widget.tagColors
                    .resolveChipColorsByPath(
                      stat.path,
                      surfaceColor: theme.colorScheme.surface,
                      isDark: isDark,
                    );
                final dotColor =
                    tagColorsForRow?.background ?? theme.colorScheme.primary;
                final displayLabel = _formatAutocompleteLabel(stat.path);
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onHover: (hovering) {
                      if (hovering) {
                        widget.onHighlight?.call(index);
                      }
                    },
                    onTap: () => widget.onSelect(stat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        color: isHighlighted
                            ? theme.colorScheme.primary.withValues(
                                alpha: isDark ? 0.16 : 0.10,
                              )
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '#$displayLabel',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isHighlighted
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: textMain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class TagAutocompleteOverlay extends StatefulWidget {
  const TagAutocompleteOverlay({
    super.key,
    required this.editorKey,
    required this.focusNode,
    required this.value,
    required this.textStyle,
    required this.tags,
    required this.tagColors,
    required this.highlightedIndex,
    required this.onSelect,
    this.onHighlight,
  });

  final GlobalKey editorKey;
  final FocusNode focusNode;
  final TextEditingValue value;
  final TextStyle textStyle;
  final List<TagStat> tags;
  final TagColorLookup tagColors;
  final int highlightedIndex;
  final ValueChanged<TagStat> onSelect;
  final ValueChanged<int>? onHighlight;

  @override
  State<TagAutocompleteOverlay> createState() => _TagAutocompleteOverlayState();
}

class _TagAutocompleteOverlayState extends State<TagAutocompleteOverlay> {
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncOverlayEntry());
  }

  @override
  void didUpdateWidget(covariant TagAutocompleteOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      widget.focusNode.addListener(_handleFocusChanged);
      _handleFocusChanged();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncOverlayEntry());
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChanged);
    _removeOverlayEntry();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!mounted) return;
    if (!widget.focusNode.hasFocus) {
      _removeOverlayEntry();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncOverlayEntry());
  }

  void _syncOverlayEntry() {
    if (!mounted) return;
    if (!widget.focusNode.hasFocus || widget.tags.isEmpty) {
      _removeOverlayEntry();
      return;
    }

    final overlay = Overlay.of(context, rootOverlay: true);
    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(builder: _buildOverlayEntry);
      overlay.insert(_overlayEntry!);
      return;
    }

    _overlayEntry!.markNeedsBuild();
  }

  void _removeOverlayEntry() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildOverlayEntry(BuildContext overlayContext) {
    final position = calculateTagAutocompletePosition(
      context: context,
      editorKey: widget.editorKey,
      value: widget.value,
      textStyle: widget.textStyle,
      tags: widget.tags,
      suggestionCount: widget.tags.length,
      useGlobalCoordinates: true,
    );
    if (position == null) return const SizedBox.shrink();

    return Positioned(
      left: position.left,
      top: position.top,
      child: InheritedTheme.captureAll(
        context,
        SizedBox(
          width: position.width,
          child: TagAutocompletePanel(
            tags: widget.tags,
            tagColors: widget.tagColors,
            highlightedIndex: widget.highlightedIndex,
            onHighlight: widget.onHighlight,
            onSelect: widget.onSelect,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

TagAutocompletePosition? calculateTagAutocompletePosition({
  required BuildContext context,
  required GlobalKey editorKey,
  required TextEditingValue value,
  required TextStyle textStyle,
  required List<TagStat> tags,
  required int suggestionCount,
  bool useGlobalCoordinates = false,
}) {
  final renderObject = editorKey.currentContext?.findRenderObject();
  if (renderObject is! RenderBox || !renderObject.hasSize) {
    return null;
  }

  final selection = value.selection;
  if (!selection.isValid || !selection.isCollapsed) {
    return null;
  }

  final caretOffset = selection.extentOffset
      .clamp(0, value.text.length)
      .toInt();
  final prefixText = value.text.substring(0, caretOffset);
  final availableWidth = renderObject.size.width;
  final panelWidth = _measureTagAutocompletePanelWidth(
    context: context,
    textStyle: textStyle,
    tags: tags,
    availableWidth: availableWidth,
  );
  final painter = TextPainter(
    text: TextSpan(text: prefixText, style: textStyle),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    locale: Localizations.maybeLocaleOf(context),
    maxLines: null,
  )..layout(maxWidth: math.max(availableWidth, 1));

  final caretLocalOffset = painter.getOffsetForCaret(
    TextPosition(offset: prefixText.length),
    Rect.zero,
  );
  final lineHeight = painter.preferredLineHeight;
  final maxCaretY = math.max(0.0, renderObject.size.height - lineHeight);
  final anchorLeft = caretLocalOffset.dx.clamp(
    0.0,
    math.max(0.0, availableWidth - panelWidth),
  );
  final anchorBottom = (caretLocalOffset.dy + lineHeight).clamp(
    lineHeight,
    maxCaretY + lineHeight,
  );

  final viewportSize = MediaQuery.sizeOf(context);
  final globalOrigin = renderObject.localToGlobal(Offset.zero);
  final panelHeight = _estimateTagAutocompleteHeight(suggestionCount);
  final baseOrigin = useGlobalCoordinates ? globalOrigin : Offset.zero;

  var left = baseOrigin.dx + anchorLeft;
  final overflowRight =
      globalOrigin.dx +
      anchorLeft +
      panelWidth +
      _kTagAutocompleteViewportPadding -
      viewportSize.width;
  if (overflowRight > 0) {
    left = math.max(baseOrigin.dx, left - overflowRight);
  }

  var top = baseOrigin.dy + anchorBottom + _kTagAutocompleteGap;
  final belowBottom =
      globalOrigin.dy + anchorBottom + _kTagAutocompleteGap + panelHeight;
  final viewportBottom = viewportSize.height - _kTagAutocompleteViewportPadding;
  if (belowBottom > viewportBottom) {
    top = math.max(
      0,
      baseOrigin.dy + anchorBottom - panelHeight - _kTagAutocompleteGap,
    );
  }

  return TagAutocompletePosition(left: left, top: top, width: panelWidth);
}

class TagAutocompletePosition {
  const TagAutocompletePosition({
    required this.left,
    required this.top,
    required this.width,
  });

  final double left;
  final double top;
  final double width;
}

double _estimateTagAutocompleteHeight(int suggestionCount) {
  final rows = math.max(
    1,
    math.min(suggestionCount, kEditorTagSuggestionVisibleRows),
  );
  return rows * _kTagAutocompleteRowHeight + _kTagAutocompletePanelPadding;
}

double _measureTagAutocompletePanelWidth({
  required BuildContext context,
  required TextStyle textStyle,
  required List<TagStat> tags,
  required double availableWidth,
}) {
  final longestLabel = tags.fold<String>('', (current, tag) {
    final limited = _formatAutocompleteLabel(tag.path);
    return limited.length > current.length ? limited : current;
  });
  final sample = longestLabel.isEmpty ? '#' : '#$longestLabel';
  final painter = TextPainter(
    text: TextSpan(text: sample, style: textStyle.copyWith(fontSize: 12)),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    locale: Localizations.maybeLocaleOf(context),
    maxLines: 1,
  )..layout();

  const chromeWidth = 72.0;
  const minWidth = 120.0;
  final desiredWidth = painter.width + chromeWidth;
  final safeAvailableWidth = math.max(1.0, availableWidth);
  final lowerBound = math.min(minWidth, safeAvailableWidth);
  return desiredWidth.clamp(lowerBound, safeAvailableWidth).toDouble();
}

String _formatAutocompleteLabel(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return trimmed;
  final runes = trimmed.runes.toList(growable: false);
  if (runes.length <= _kTagAutocompleteMaxChars) {
    return trimmed;
  }
  final visibleCount = (_kTagAutocompleteMaxChars - 3).clamp(1, 9999);
  return '${String.fromCharCodes(runes.take(visibleCount))}...';
}

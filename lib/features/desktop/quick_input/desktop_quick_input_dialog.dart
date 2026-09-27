import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/markdown_editing.dart';
import '../../../core/memo_template_renderer.dart';
import '../../../data/models/memo_template_settings.dart';
import '../../../state/settings/location_settings_provider.dart';
import '../../../state/settings/memo_template_settings_provider.dart';
import '../../../i18n/strings.g.dart';

class DesktopQuickInputDialog extends ConsumerStatefulWidget {
  const DesktopQuickInputDialog({
    super.key,
    this.initialText,
    this.onImagePressed,
    this.backgroundOverlayColor,
  });

  final String? initialText;
  final VoidCallback? onImagePressed;
  final Color? backgroundOverlayColor;

  static Future<String?> show(
    BuildContext context, {
    String? initialText,
    VoidCallback? onImagePressed,
    Color? backgroundOverlayColor,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierColor: backgroundOverlayColor,
      builder: (_) => DesktopQuickInputDialog(
        initialText: initialText,
        onImagePressed: onImagePressed,
        backgroundOverlayColor: backgroundOverlayColor,
      ),
    );
  }

  @override
  ConsumerState<DesktopQuickInputDialog> createState() =>
      _DesktopQuickInputDialogState();
}

class _DesktopQuickInputDialogState
    extends ConsumerState<DesktopQuickInputDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  final _templateMenuKey = GlobalKey();
  final _templateRenderer = MemoTemplateRenderer();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _canSubmit => _controller.text.trim().isNotEmpty;

  void _setControllerValue(TextEditingValue value) {
    setState(() {
      _controller.value = value;
    });
  }

  void _insertText(String value, {int? caretOffset}) {
    _setControllerValue(
      insertInlineSnippet(_controller.value, value, caretOffset: caretOffset),
    );
  }

  void _replaceText(String value) {
    _setControllerValue(
      _controller.value.copyWith(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
        composing: TextRange.empty,
      ),
    );
  }

  void _wrapSelection(String prefix, String suffix) {
    _setControllerValue(
      wrapMarkdownSelection(_controller.value, prefix: prefix, suffix: suffix),
    );
  }

  void _toggleBold() => _wrapSelection('**', '**');

  void _toggleItalic() => _wrapSelection('*', '*');

  void _toggleStrikethrough() => _wrapSelection('~~', '~~');

  void _toggleInlineCode() => _wrapSelection('`', '`');

  void _toggleUnderline() => _wrapSelection('<u>', '</u>');

  void _toggleHighlight() => _wrapSelection('==', '==');

  void _toggleBlockStyle(MarkdownBlockStyle style) {
    _setControllerValue(toggleBlockStyle(_controller.value, style));
  }

  void _toggleUnorderedList() =>
      _toggleBlockStyle(MarkdownBlockStyle.unorderedList);

  void _toggleOrderedList() =>
      _toggleBlockStyle(MarkdownBlockStyle.orderedList);

  void _toggleTaskList() => _toggleBlockStyle(MarkdownBlockStyle.taskList);

  void _toggleQuote() => _toggleBlockStyle(MarkdownBlockStyle.quote);

  void _toggleHeading1() => _toggleBlockStyle(MarkdownBlockStyle.heading1);

  void _toggleHeading2() => _toggleBlockStyle(MarkdownBlockStyle.heading2);

  void _toggleHeading3() => _toggleBlockStyle(MarkdownBlockStyle.heading3);

  void _insertDivider() {
    _setControllerValue(
      insertBlockSnippet(_controller.value, '---', caretOffset: 3),
    );
  }

  void _insertCodeBlock() {
    _setControllerValue(
      insertBlockSnippet(_controller.value, '```\n\n```', caretOffset: 4),
    );
  }

  void _insertInlineMath() {
    _setControllerValue(
      insertInlineSnippet(_controller.value, r'$$', caretOffset: 1),
    );
  }

  void _insertBlockMath() {
    const blockMath = '\$\$\n\n\$\$';
    _setControllerValue(
      insertBlockSnippet(_controller.value, blockMath, caretOffset: 3),
    );
  }

  void _insertTableTemplate() {
    const table =
        '| Column 1 | Column 2 |\n| --- | --- |\n| Value 1 | Value 2 |';
    _setControllerValue(
      insertBlockSnippet(_controller.value, table, caretOffset: 2),
    );
  }

  Future<void> _cutParagraphs() async {
    final result = cutParagraphs(_controller.value);
    if (result == null) return;
    try {
      await Clipboard.setData(ClipboardData(text: result.copiedText));
    } catch (_) {
      return;
    }
    _setControllerValue(result.value);
  }

  void _submit() {
    final content = _controller.text.trimRight();
    if (content.trim().isEmpty) return;
    Navigator.of(context).pop(content);
  }

  Future<void> _openTemplateMenuFromKey(
    GlobalKey key,
    List<MemoTemplate> templates,
  ) async {
    final target = key.currentContext;
    if (target == null) return;
    final overlay = Overlay.of(context).context.findRenderObject();
    final box = target.findRenderObject();
    if (overlay is! RenderBox || box is! RenderBox) return;

    final items = templates.isEmpty
        ? <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              enabled: false,
              child: Text(context.t.strings.legacy.msg_no_templates_yet),
            ),
          ]
        : templates
              .map(
                (template) => PopupMenuItem<String>(
                  value: template.id,
                  child: Text(template.name),
                ),
              )
              .toList(growable: false);

    final rect = Rect.fromPoints(
      box.localToGlobal(Offset.zero, ancestor: overlay),
      box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
    );
    final selectedId = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(rect, Offset.zero & overlay.size),
      items: items,
    );
    if (!mounted || selectedId == null) return;
    MemoTemplate? selected;
    for (final item in templates) {
      if (item.id == selectedId) {
        selected = item;
        break;
      }
    }
    if (selected == null) return;
    await _applyTemplate(selected);
  }

  Future<void> _applyTemplate(MemoTemplate template) async {
    final templateSettings = ref.read(memoTemplateSettingsProvider);
    final locationSettings = ref.read(locationSettingsProvider);
    final rendered = await _templateRenderer.render(
      templateContent: template.content,
      variableSettings: templateSettings.variables,
      locationSettings: locationSettings,
    );
    if (!mounted) return;
    _replaceText(rendered);
  }

  Widget _buildToolbarRow(List<Widget> children) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const SizedBox(width: 2),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templateSettings = ref.watch(memoTemplateSettingsProvider);
    final availableTemplates = templateSettings.enabled
        ? templateSettings.templates
        : const <MemoTemplate>[];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF171717) : const Color(0xFFF4F4F4);
    final border = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE6E6E6);
    final textMain = isDark ? const Color(0xFFF1F1F1) : const Color(0xFF222222);
    final textMuted = isDark
        ? const Color(0xFF8F8F8F)
        : const Color(0xFF9C9C9C);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, minHeight: 440),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 10, 8),
                child: Row(
                  children: [
                    Text(
                      'MemoFlow',
                      style: TextStyle(
                        fontSize: 34 / 1.8,
                        fontWeight: FontWeight.w700,
                        color: textMain,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: context.t.strings.legacy.msg_pin,
                      onPressed: null,
                      icon: Icon(Icons.push_pin_outlined, color: textMuted),
                    ),
                    IconButton(
                      tooltip: context.t.strings.legacy.msg_close,
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(Icons.close, color: textMuted),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    expands: true,
                    maxLines: null,
                    minLines: null,
                    style: TextStyle(
                      fontSize: 17,
                      color: textMain,
                      height: 1.45,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          context.t.strings.legacy.msg_write_current_thought,
                      hintStyle: TextStyle(color: textMuted),
                      border: InputBorder.none,
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildToolbarRow([
                            _ToolbarButton(
                              tooltip: context.t.strings.legacy.msg_bold,
                              onTap: _toggleBold,
                              icon: Icons.format_bold,
                            ),
                            _ToolbarButton(
                              tooltip: context
                                  .t
                                  .strings
                                  .settings
                                  .preferences
                                  .editorToolbar
                                  .actions
                                  .italic,
                              onTap: _toggleItalic,
                              icon: Icons.format_italic,
                            ),
                            _ToolbarButton(
                              tooltip: context
                                  .t
                                  .strings
                                  .settings
                                  .preferences
                                  .editorToolbar
                                  .actions
                                  .strikethrough,
                              onTap: _toggleStrikethrough,
                              icon: Icons.format_strikethrough,
                            ),
                            _ToolbarButton(
                              tooltip: context
                                  .t
                                  .strings
                                  .settings
                                  .preferences
                                  .editorToolbar
                                  .actions
                                  .inlineCode,
                              onTap: _toggleInlineCode,
                              icon: Icons.code,
                            ),
                            _ToolbarButton(
                              tooltip: context.t.strings.legacy.msg_underline,
                              onTap: _toggleUnderline,
                              icon: Icons.format_underlined,
                            ),
                            _ToolbarButton(
                              tooltip: context.t.strings.legacy.msg_highlight,
                              onTap: _toggleHighlight,
                              icon: Icons.highlight_alt,
                            ),
                            _ToolbarButton(
                              tooltip: context
                                  .t
                                  .strings
                                  .settings
                                  .preferences
                                  .editorToolbar
                                  .actions
                                  .bulletedList,
                              onTap: _toggleUnorderedList,
                              icon: Icons.format_list_bulleted,
                            ),
                            _ToolbarButton(
                              tooltip:
                                  context.t.strings.legacy.msg_ordered_list,
                              onTap: _toggleOrderedList,
                              icon: Icons.format_list_numbered,
                            ),
                            _ToolbarButton(
                              tooltip: context
                                  .t
                                  .strings
                                  .settings
                                  .preferences
                                  .editorToolbar
                                  .actions
                                  .taskList,
                              onTap: _toggleTaskList,
                              icon: Icons.check_box_outlined,
                            ),
                            _ToolbarButton(
                              tooltip: context
                                  .t
                                  .strings
                                  .settings
                                  .preferences
                                  .editorToolbar
                                  .actions
                                  .quote,
                              onTap: _toggleQuote,
                              icon: Icons.format_quote,
                            ),
                          ]),
                          const SizedBox(height: 6),
                          _buildToolbarRow([
                            _ToolbarButton(
                              tooltip: context
                                  .t
                                  .strings
                                  .settings
                                  .preferences
                                  .editorToolbar
                                  .actions
                                  .heading1,
                              onTap: _toggleHeading1,
                              icon: Icons.looks_one_outlined,
                            ),
                            _ToolbarButton(
                              tooltip: context
                                  .t
                                  .strings
                                  .settings
                                  .preferences
                                  .editorToolbar
                                  .actions
                                  .heading2,
                              onTap: _toggleHeading2,
                              icon: Icons.looks_two_outlined,
                            ),
                            _ToolbarButton(
                              tooltip: context
                                  .t
                                  .strings
                                  .settings
                                  .preferences
                                  .editorToolbar
                                  .actions
                                  .heading3,
                              onTap: _toggleHeading3,
                              icon: Icons.looks_3_outlined,
                            ),
                            _ToolbarButton(
                              tooltip: context
                                  .t
                                  .strings
                                  .settings
                                  .preferences
                                  .editorToolbar
                                  .actions
                                  .divider,
                              onTap: _insertDivider,
                              icon: Icons.horizontal_rule,
                            ),
                            _ToolbarButton(
                              tooltip: context.t.strings.legacy.msg_code_block,
                              onTap: _insertCodeBlock,
                              icon: Icons.data_object,
                            ),
                            _ToolbarButton(
                              tooltip: context
                                  .t
                                  .strings
                                  .settings
                                  .preferences
                                  .editorToolbar
                                  .actions
                                  .inlineMath,
                              onTap: _insertInlineMath,
                              icon: Icons.functions,
                            ),
                            _ToolbarButton(
                              tooltip: context
                                  .t
                                  .strings
                                  .settings
                                  .preferences
                                  .editorToolbar
                                  .actions
                                  .blockMath,
                              onTap: _insertBlockMath,
                              icon: Icons.calculate_outlined,
                            ),
                            _ToolbarButton(
                              tooltip: context
                                  .t
                                  .strings
                                  .settings
                                  .preferences
                                  .editorToolbar
                                  .actions
                                  .table,
                              onTap: _insertTableTemplate,
                              icon: Icons.table_chart_outlined,
                            ),
                            _ToolbarButton(
                              tooltip: context
                                  .t
                                  .strings
                                  .settings
                                  .preferences
                                  .editorToolbar
                                  .actions
                                  .cutParagraph,
                              onTap: _cutParagraphs,
                              icon: Icons.content_cut,
                            ),
                            _ToolbarButton(
                              tooltip: context.t.strings.legacy.msg_tag,
                              onTap: () => _insertText('#'),
                              icon: Icons.tag_outlined,
                            ),
                            _ToolbarButton(
                              buttonKey: _templateMenuKey,
                              tooltip: context.t.strings.legacy.msg_template,
                              onTap: () => _openTemplateMenuFromKey(
                                _templateMenuKey,
                                availableTemplates,
                              ),
                              icon: Icons.description_outlined,
                            ),
                            _ToolbarButton(
                              tooltip: context.t.strings.legacy.msg_image,
                              onTap: widget.onImagePressed,
                              icon: Icons.image_outlined,
                            ),
                            _ToolbarButton(
                              tooltip: context.t.strings.legacy.msg_link,
                              onTap: () => _insertText('@'),
                              icon: Icons.alternate_email_rounded,
                            ),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _canSubmit ? _submit : null,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(52, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    this.buttonKey,
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final Key? buttonKey;
  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? const Color(0xFFACACAC) : const Color(0xFF9C9C9C);
    return IconButton(
      key: buttonKey,
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 22),
      splashRadius: 18,
    );
  }
}

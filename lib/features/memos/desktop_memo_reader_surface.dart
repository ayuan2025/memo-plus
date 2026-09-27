import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/desktop/window_chrome_safe_area.dart';
import '../../core/memoflow_palette.dart';
import '../../data/models/local_memo.dart';
import '../../i18n/strings.g.dart';
import 'memo_compose_surface.dart';
import 'memo_detail_screen.dart';
import 'widgets/memo_reader_content.dart';

enum DesktopMemoReaderPresentation { centered, fullscreen }

class DesktopMemoReaderSurface extends StatefulWidget {
  const DesktopMemoReaderSurface({
    super.key,
    required this.memo,
    required this.presentation,
    required this.onClose,
    required this.onToggleFullscreen,
    required this.onEdit,
  });

  final LocalMemo memo;
  final DesktopMemoReaderPresentation presentation;
  final VoidCallback onClose;
  final VoidCallback onToggleFullscreen;
  final VoidCallback onEdit;

  @override
  State<DesktopMemoReaderSurface> createState() =>
      _DesktopMemoReaderSurfaceState();
}

class _DesktopMemoReaderSurfaceState extends State<DesktopMemoReaderSurface> {
  bool get _fullscreen =>
      widget.presentation == DesktopMemoReaderPresentation.fullscreen;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape) {
      return false;
    }
    if (ModalRoute.of(context)?.isCurrent == false) {
      return false;
    }
    if (_fullscreen) {
      widget.onToggleFullscreen();
    } else {
      widget.onClose();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? MemoFlowPalette.backgroundDark.withValues(alpha: 0.96)
        : MemoFlowPalette.backgroundLight.withValues(alpha: 0.96);
    final cardColor = isDark
        ? MemoFlowPalette.cardDark
        : MemoFlowPalette.cardLight;
    final borderColor = isDark
        ? MemoFlowPalette.borderDark
        : MemoFlowPalette.borderLight;
    final mediaSize = MediaQuery.sizeOf(context);
    final horizontalInset = mediaSize.width >= 1400 ? 48.0 : 24.0;
    final verticalInset = mediaSize.height >= 900 ? 32.0 : 20.0;
    final chromeInsets = defaultTargetPlatform == TargetPlatform.macOS
        ? resolveDesktopWindowChromeInsets(
            platform: defaultTargetPlatform,
            contentExtendsIntoTitleBar: true,
          )
        : const DesktopWindowChromeInsets.none();
    final headerChromeInsets = _fullscreen
        ? chromeInsets
        : const DesktopWindowChromeInsets.none();
    final centeredTopInset = chromeInsets.top > verticalInset
        ? chromeInsets.top
        : verticalInset;
    final header = Container(
      key: const ValueKey<String>('desktop-memo-reader-header'),
      height: 56 + headerChromeInsets.top,
      padding: EdgeInsetsDirectional.only(
        start: 20 + headerChromeInsets.leading,
        top: 8 + headerChromeInsets.top,
        end: 8 + headerChromeInsets.trailing,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              formatMemoReaderDisplayTime(widget.memo),
              key: const ValueKey<String>('desktop-memo-reader-title'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            key: const ValueKey<String>('desktop-memo-reader-edit'),
            tooltip: context.t.strings.legacy.msg_edit,
            onPressed: widget.onEdit,
            icon: const Icon(Icons.edit_rounded),
          ),
          PopupMenuButton<_DesktopMemoReaderMoreAction>(
            key: const ValueKey<String>('desktop-memo-reader-more'),
            tooltip: context.t.strings.legacy.msg_more,
            onSelected: (action) async {
              switch (action) {
                case _DesktopMemoReaderMoreAction.copy:
                  await Clipboard.setData(
                    ClipboardData(text: widget.memo.content),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.t.strings.legacy.msg_memo_copied),
                      duration: const Duration(milliseconds: 1200),
                    ),
                  );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<_DesktopMemoReaderMoreAction>(
                value: _DesktopMemoReaderMoreAction.copy,
                child: Text(context.t.strings.legacy.msg_copy),
              ),
            ],
          ),
          IconButton(
            key: const ValueKey<String>(
              'desktop-memo-reader-fullscreen-toggle',
            ),
            tooltip: _fullscreen
                ? context.t.strings.legacy.msg_restore_window
                : context.t.strings.legacy.msg_maximize,
            onPressed: widget.onToggleFullscreen,
            icon: Icon(
              _fullscreen
                  ? Icons.fullscreen_exit_rounded
                  : Icons.fullscreen_rounded,
            ),
          ),
          IconButton(
            key: const ValueKey<String>('desktop-memo-reader-close'),
            tooltip: context.t.strings.legacy.msg_close,
            onPressed: widget.onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );

    final reader = MemoDetailScreen(
      key: ValueKey<String>(
        'desktop-memo-reader-detail:${widget.memo.uid}:${widget.memo.contentFingerprint}',
      ),
      initialMemo: widget.memo,
      readOnly: true,
      embedded: true,
      showDocumentMetadata: false,
      showSupplementarySections: false,
    );
    final surface = MemoComposeSurface(
      backgroundColor: background,
      cardColor: cardColor,
      borderColor: borderColor,
      header: header,
      surfacePadding: _fullscreen
          ? EdgeInsets.zero
          : EdgeInsets.fromLTRB(
              horizontalInset,
              centeredTopInset,
              horizontalInset,
              verticalInset,
            ),
      maxCardWidth: _fullscreen ? null : 920,
      contentMaxWidth: 820,
      borderRadius: _fullscreen ? 0 : 24,
      showShadow: !_fullscreen,
      centerContentColumn: true,
      child: reader,
    );

    return Focus(
      autofocus: true,
      child: KeyedSubtree(
        key: ValueKey<String>(
          _fullscreen
              ? 'desktop-memo-reader-fullscreen-surface'
              : 'desktop-memo-reader-centered-surface',
        ),
        child: surface,
      ),
    );
  }
}

enum _DesktopMemoReaderMoreAction { copy }

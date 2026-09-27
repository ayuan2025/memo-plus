import 'package:flutter/material.dart';

import '../../../core/memoflow_palette.dart';
import '../../../i18n/strings.g.dart';

class NoteInputCompactHeader extends StatelessWidget {
  const NoteInputCompactHeader({
    super.key,
    required this.isDark,
    required this.busy,
    required this.expandButtonKey,
    required this.onExpand,
  });

  final bool isDark;
  final bool busy;
  final Key expandButtonKey;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const SizedBox(width: 40),
            Expanded(
              child: Center(
                child: Container(
                  width: 40,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            IconButton(
              key: expandButtonKey,
              tooltip: context.t.strings.legacy.msg_maximize,
              onPressed: busy ? null : onExpand,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              splashRadius: 18,
              icon: Icon(
                Icons.fullscreen_rounded,
                size: 22,
                color: MemoFlowPalette.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoteInputCompactSendButton extends StatelessWidget {
  const NoteInputCompactSendButton({
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
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final buttonShadowColor = buttonEnabled
        ? MemoFlowPalette.primary.withValues(alpha: isDark ? 0.3 : 0.4)
        : Colors.black.withValues(alpha: isDark ? 0.18 : 0.1);

    return GestureDetector(
      onTap: buttonEnabled ? onPressed : null,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: busy ? 0.98 : 1.0,
        child: SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (deferredProgress != null)
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: deferredProgress,
                    strokeWidth: 3,
                    color: MemoFlowPalette.primary,
                    backgroundColor: MemoFlowPalette.primary.withValues(
                      alpha: 0.18,
                    ),
                  ),
                ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: buttonColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: buttonShadowColor,
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: busy
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : ValueListenableBuilder<TextEditingValue>(
                          valueListenable: controller,
                          builder: (context, value, _) {
                            final hasText = value.text.trim().isNotEmpty;
                            final showSend = hasText || hasAttachmentsForSend;
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 160),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: child,
                                );
                              },
                              child: Icon(
                                showSend
                                    ? Icons.send_rounded
                                    : Icons.graphic_eq,
                                key: ValueKey<bool>(showSend),
                                color: Colors.white,
                                size: showSend ? 24 : 28,
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

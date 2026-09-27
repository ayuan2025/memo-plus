import 'package:flutter/material.dart';

import '../../../core/memoflow_palette.dart';

bool shouldShowFloatingCollapseForOffsets({
  required double viewportTop,
  required double viewportBottom,
  required double toggleTop,
  required double toggleBottom,
}) {
  if (toggleBottom > viewportTop && toggleTop < viewportBottom) return false;

  final graceDistance = viewportBottom - viewportTop;
  if (graceDistance <= 0) return true;

  if (toggleTop >= viewportBottom) {
    final distanceBelow = toggleTop - viewportBottom;
    return distanceBelow > graceDistance;
  }

  if (toggleBottom <= viewportTop) {
    final distanceAbove = viewportTop - toggleBottom;
    return distanceAbove > graceDistance;
  }

  return false;
}

bool shouldShowFloatingCollapseForToggle({
  required Rect viewportRect,
  required Rect toggleRect,
}) {
  return shouldShowFloatingCollapseForOffsets(
    viewportTop: viewportRect.top,
    viewportBottom: viewportRect.bottom,
    toggleTop: toggleRect.top,
    toggleBottom: toggleRect.bottom,
  );
}

class MemoFloatingCollapseButton extends StatelessWidget {
  const MemoFloatingCollapseButton({
    super.key,
    required this.visible,
    required this.scrolling,
    required this.label,
    required this.onPressed,
    this.size = 44,
    this.iconSize = 24,
  });

  final bool visible;
  final bool scrolling;
  final String label;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = MemoFlowPalette.primary;
    final iconColor = Colors.white;
    final shadowColor = MemoFlowPalette.primary.withValues(
      alpha: isDark ? 0.35 : 0.25,
    );

    return IgnorePointer(
      ignoring: !visible,
      child: ExcludeSemantics(
        excluding: !visible,
        child: Tooltip(
          message: label,
          excludeFromSemantics: true,
          child: Semantics(
            button: true,
            label: label,
            onTap: onPressed,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              offset: visible ? Offset.zero : const Offset(0, 0.16),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                opacity: visible ? (scrolling ? 0.34 : 0.96) : 0,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  scale: visible ? 1 : 0.85,
                  child: SizedBox.square(
                    dimension: size,
                    child: Material(
                      color: Colors.transparent,
                      elevation: 0,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onPressed,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: background,
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                                color: shadowColor,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.unfold_less_rounded,
                            size: iconSize,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class DesktopEmbeddedUtilitySurface extends StatelessWidget {
  const DesktopEmbeddedUtilitySurface({
    super.key,
    required this.title,
    required this.body,
    this.onBack,
    this.backTooltip,
    this.actions = const <Widget>[],
    this.bottomBar,
  });

  final Widget title;
  final Widget body;
  final VoidCallback? onBack;
  final String? backTooltip;
  final List<Widget> actions;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);
    final hasBack = onBack != null;

    return Column(
      key: const ValueKey<String>('desktop-embedded-utility-surface'),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: SizedBox(
            height: 56,
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                hasBack ? 8 : 24,
                0,
                16,
                0,
              ),
              child: Row(
                children: [
                  if (hasBack) ...[
                    IconButton(
                      key: const ValueKey<String>(
                        'desktop-embedded-utility-back',
                      ),
                      tooltip: backTooltip,
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: DefaultTextStyle.merge(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      child: title,
                    ),
                  ),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Row(mainAxisSize: MainAxisSize.min, children: actions),
                  ],
                ],
              ),
            ),
          ),
        ),
        Expanded(child: body),
        if (bottomBar != null) bottomBar!,
      ],
    );
  }
}

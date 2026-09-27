import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppleMobileShell extends StatelessWidget {
  const AppleMobileShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CupertinoTheme(
      data: CupertinoThemeData(
        brightness: Theme.of(context).brightness,
        primaryColor: Theme.of(context).colorScheme.primary,
      ),
      child: child,
    );
  }
}

class AppleTabletShell extends StatelessWidget {
  const AppleTabletShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.surface,
      child: CupertinoTheme(
        data: CupertinoThemeData(
          brightness: Theme.of(context).brightness,
          primaryColor: colorScheme.primary,
        ),
        child: child,
      ),
    );
  }
}

class AppleDesktopShell extends StatelessWidget {
  const AppleDesktopShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CupertinoTheme(
      data: CupertinoThemeData(
        brightness: theme.brightness,
        primaryColor: theme.colorScheme.primary,
      ),
      child: FocusTraversalGroup(child: child),
    );
  }
}

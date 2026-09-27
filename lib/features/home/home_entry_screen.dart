import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/home_navigation_preferences.dart';
import '../../platform/platform_target.dart';
import '../../platform/shells/apple_shells.dart';
import '../../state/settings/workspace_preferences_provider.dart';
import 'apple_tablet_home_shell.dart';
import 'home_bottom_nav_shell.dart';
import 'home_screen.dart';

class HomeEntryScreen extends ConsumerWidget {
  const HomeEntryScreen({super.key});

  static WidgetBuilder? debugClassicScreenBuilderOverride;
  static WidgetBuilder? debugBottomNavShellBuilderOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceLoaded = ref.watch(workspacePreferencesLoadedProvider);
    final homeNavigationPreferences = ref.watch(
      currentWorkspacePreferencesProvider.select(
        (prefs) => prefs.homeNavigationPreferences,
      ),
    );

    if (!workspaceLoaded) {
      return const _HomeEntryPlaceholder();
    }

    Widget wrapAppleShell(Widget child) {
      final target = resolvePlatformTarget(context);
      return switch (target) {
        PlatformTarget.iPhone => AppleMobileShell(child: child),
        PlatformTarget.iPad => AppleTabletShell(child: child),
        PlatformTarget.macOS => AppleDesktopShell(child: child),
        PlatformTarget.android ||
        PlatformTarget.windows ||
        PlatformTarget.linux ||
        PlatformTarget.web => child,
      };
    }

    final target = resolvePlatformTarget(context);
    if (target == PlatformTarget.iPad) {
      return wrapAppleShell(const AppleTabletHomeShell());
    }

    if (target == PlatformTarget.windows ||
        target == PlatformTarget.linux ||
        target == PlatformTarget.macOS) {
      final override = debugClassicScreenBuilderOverride;
      return wrapAppleShell(
        override != null ? override(context) : const HomeScreen(),
      );
    }

    if (homeNavigationPreferences.mode == HomeNavigationMode.bottomBar) {
      final override = debugBottomNavShellBuilderOverride;
      return wrapAppleShell(
        override != null ? override(context) : const HomeBottomNavShell(),
      );
    }

    final override = debugClassicScreenBuilderOverride;
    return wrapAppleShell(
      override != null ? override(context) : const HomeScreen(),
    );
  }
}

class _HomeEntryPlaceholder extends StatelessWidget {
  const _HomeEntryPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: const SizedBox.expand(),
    );
  }
}

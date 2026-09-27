import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/home_navigation_preferences.dart';
import '../../platform/platform_route.dart';
import '../../state/settings/workspace_preferences_provider.dart';
import '../../state/system/session_provider.dart';
import '../notifications/notifications_screen.dart';
import 'app_drawer.dart';
import 'app_drawer_destination_builder.dart';
import 'home_bottom_nav_shell.dart';
import 'home_navigation_host.dart';
import 'home_navigation_resolver.dart';
import 'home_root_destination_registry.dart';

class AppleTabletHomeShell extends ConsumerStatefulWidget {
  const AppleTabletHomeShell({super.key});

  @override
  ConsumerState<AppleTabletHomeShell> createState() =>
      _AppleTabletHomeShellState();
}

class _AppleTabletHomeShellState extends ConsumerState<AppleTabletHomeShell>
    implements HomeEmbeddedNavigationHost {
  static const double _kSidebarBreakpoint = 700;
  static const double _kSidebarWidth = 248;

  HomeRootDestination _activeDestination = HomeRootDestination.memos;
  String? _activeMemosTag;

  bool get _currentHasAccount =>
      ref.read(appSessionProvider).valueOrNull?.currentAccount != null;

  ResolvedHomeNavigationPreferences get _resolvedPreferences {
    final preferences = ref.read(
      currentWorkspacePreferencesProvider.select(
        (value) => value.homeNavigationPreferences,
      ),
    );
    return resolveHomeNavigationPreferences(
      preferences,
      hasAccount: _currentHasAccount,
    );
  }

  void _switchDestination(
    HomeRootDestination destination, {
    bool clearMemosTag = true,
  }) {
    if (_activeDestination == destination) {
      if (destination == HomeRootDestination.memos &&
          clearMemosTag &&
          _activeMemosTag != null) {
        setState(() => _activeMemosTag = null);
      }
      return;
    }
    setState(() {
      _activeDestination = destination;
      if (destination == HomeRootDestination.memos && clearMemosTag) {
        _activeMemosTag = null;
      }
    });
  }

  void _pushStandaloneRoute(BuildContext context, Widget route) {
    Navigator.of(context).push(
      buildPlatformPageRoute<void>(context: context, builder: (_) => route),
    );
  }

  Widget _buildStandaloneRouteForDrawer(
    BuildContext context,
    AppDrawerDestination destination,
  ) {
    final rootDestination = homeRootDestinationFromDrawerDestination(
      destination,
    );
    if (rootDestination != null) {
      return buildHomeRootScreen(
        context: context,
        destination: rootDestination,
        presentation: HomeScreenPresentation.standalone,
        navigationHost: this,
      );
    }
    return buildDrawerDestinationScreen(
      context: context,
      destination: destination,
      presentation: HomeScreenPresentation.standalone,
      navigationHost: this,
    );
  }

  @override
  void handleDrawerDestination(
    BuildContext context,
    AppDrawerDestination destination,
  ) {
    final rootDestination = homeRootDestinationFromDrawerDestination(
      destination,
    );
    if (rootDestination != null) {
      final resolved = _resolvedPreferences;
      if (resolved.visibleTabs.contains(rootDestination)) {
        _switchDestination(rootDestination);
        return;
      }
    }
    _pushStandaloneRoute(
      context,
      _buildStandaloneRouteForDrawer(context, destination),
    );
  }

  @override
  void handleDrawerTag(BuildContext context, String tag) {
    final normalized = tag.trim();
    setState(() {
      _activeDestination = _resolvedPreferences.fallbackDestinationFor(
        HomeRootDestination.memos,
      );
      _activeMemosTag = normalized.isEmpty ? null : normalized;
    });
  }

  @override
  void handleOpenNotifications(BuildContext context) {
    _pushStandaloneRoute(
      context,
      NotificationsScreen(
        presentation: HomeScreenPresentation.embeddedBottomNav,
        embeddedNavigationHost: this,
      ),
    );
  }

  @override
  void handleBackToPrimaryDestination(BuildContext context) {
    if (_activeMemosTag != null) {
      setState(() => _activeMemosTag = null);
      return;
    }
    _switchDestination(
      _resolvedPreferences.fallbackDestinationFor(HomeRootDestination.memos),
    );
  }

  @override
  void updateGlobalSwipeExclusionRects(
    HomeRootDestination destination,
    List<Rect> rects,
  ) {}

  @override
  void clearGlobalSwipeExclusionRects(HomeRootDestination destination) {}

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(
      currentWorkspacePreferencesProvider.select(
        (value) => value.homeNavigationPreferences,
      ),
    );
    final hasAccount = ref.watch(
      appSessionProvider.select(
        (value) => value.valueOrNull?.currentAccount != null,
      ),
    );
    final resolved = resolveHomeNavigationPreferences(
      preferences,
      hasAccount: hasAccount,
    );
    final activeDestination = resolved.fallbackDestinationFor(
      _activeDestination,
    );
    if (activeDestination != _activeDestination) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _switchDestination(activeDestination);
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _kSidebarBreakpoint) {
          return const HomeBottomNavShell();
        }
        return _AppleTabletSplitView(
          resolved: resolved,
          activeDestination: activeDestination,
          activeMemosTag: _activeMemosTag,
          navigationHost: this,
          onSelectDestination: _switchDestination,
        );
      },
    );
  }
}

class _AppleTabletSplitView extends StatelessWidget {
  const _AppleTabletSplitView({
    required this.resolved,
    required this.activeDestination,
    required this.activeMemosTag,
    required this.navigationHost,
    required this.onSelectDestination,
  });

  final ResolvedHomeNavigationPreferences resolved;
  final HomeRootDestination activeDestination;
  final String? activeMemosTag;
  final HomeEmbeddedNavigationHost navigationHost;
  final ValueChanged<HomeRootDestination> onSelectDestination;

  @override
  Widget build(BuildContext context) {
    final borderColor = CupertinoColors.separator.resolveFrom(context);
    return Row(
      children: [
        SizedBox(
          width: _AppleTabletHomeShellState._kSidebarWidth,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: CupertinoColors.systemGroupedBackground.resolveFrom(
                context,
              ),
              border: Border(right: BorderSide(color: borderColor)),
            ),
            child: SafeArea(
              right: false,
              child: _AppleTabletSidebar(
                resolved: resolved,
                activeDestination: activeDestination,
                onSelectDestination: onSelectDestination,
              ),
            ),
          ),
        ),
        Expanded(
          child: ColoredBox(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: SafeArea(
              left: false,
              child: IndexedStack(
                index: resolved.visibleTabs.indexOf(activeDestination),
                children: [
                  for (final destination in resolved.visibleTabs)
                    buildHomeRootScreen(
                      context: context,
                      destination: destination,
                      presentation: HomeScreenPresentation.embeddedBottomNav,
                      navigationHost: navigationHost,
                      memosTag: destination == HomeRootDestination.memos
                          ? activeMemosTag
                          : null,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AppleTabletSidebar extends StatelessWidget {
  const _AppleTabletSidebar({
    required this.resolved,
    required this.activeDestination,
    required this.onSelectDestination,
  });

  final ResolvedHomeNavigationPreferences resolved;
  final HomeRootDestination activeDestination;
  final ValueChanged<HomeRootDestination> onSelectDestination;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      children: [
        const SizedBox(height: 6),
        Text(
          'MemoFlow',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CupertinoTheme.of(
            context,
          ).textTheme.navLargeTitleTextStyle.copyWith(fontSize: 28),
        ),
        const SizedBox(height: 18),
        for (final destination in resolved.visibleTabs)
          _AppleTabletSidebarDestination(
            destination: destination,
            selected: destination == activeDestination,
            onTap: () => onSelectDestination(destination),
          ),
      ],
    );
  }
}

class _AppleTabletSidebarDestination extends StatelessWidget {
  const _AppleTabletSidebarDestination({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final HomeRootDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final definition = homeRootDestinationDefinition(destination);
    if (definition == null) {
      return const SizedBox.shrink();
    }
    final primary = CupertinoTheme.of(context).primaryColor;
    final labelColor = selected
        ? primary
        : CupertinoColors.label.resolveFrom(context);
    final background = selected
        ? primary.withValues(alpha: 0.12)
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: CupertinoButton(
        minimumSize: Size.zero,
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Semantics(
          selected: selected,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(definition.icon, size: 20, color: labelColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      definition.labelBuilder(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: labelColor,
                        fontSize: 16,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

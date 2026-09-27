import '../../data/models/app_preferences.dart';
import 'app_drawer.dart';
import 'home_navigation_host.dart';

enum HomeQuickActionNavigationKind {
  none,
  drawerDestination,
  desktopUtility,
  standaloneRoute,
}

class HomeQuickActionNavigationTarget {
  const HomeQuickActionNavigationTarget._({
    required this.kind,
    this.drawerDestination,
    this.desktopUtilityView,
  });

  const HomeQuickActionNavigationTarget.none()
    : this._(kind: HomeQuickActionNavigationKind.none);

  const HomeQuickActionNavigationTarget.drawer(AppDrawerDestination destination)
    : this._(
        kind: HomeQuickActionNavigationKind.drawerDestination,
        drawerDestination: destination,
      );

  const HomeQuickActionNavigationTarget.utility(DesktopHomeUtilityView utility)
    : this._(
        kind: HomeQuickActionNavigationKind.desktopUtility,
        desktopUtilityView: utility,
      );

  const HomeQuickActionNavigationTarget.route()
    : this._(kind: HomeQuickActionNavigationKind.standaloneRoute);

  final HomeQuickActionNavigationKind kind;
  final AppDrawerDestination? drawerDestination;
  final DesktopHomeUtilityView? desktopUtilityView;
}

HomeQuickActionNavigationTarget resolveHomeQuickActionNavigationTarget({
  required HomeQuickAction action,
  required bool useDesktopHomeNavigation,
}) {
  if (!useDesktopHomeNavigation) {
    return action == HomeQuickAction.none
        ? const HomeQuickActionNavigationTarget.none()
        : const HomeQuickActionNavigationTarget.route();
  }

  return switch (action) {
    HomeQuickAction.none => const HomeQuickActionNavigationTarget.none(),
    HomeQuickAction.monthlyStats =>
      const HomeQuickActionNavigationTarget.utility(
        DesktopHomeUtilityView.stats,
      ),
    HomeQuickAction.collections => const HomeQuickActionNavigationTarget.drawer(
      AppDrawerDestination.collections,
    ),
    HomeQuickAction.aiSummary => const HomeQuickActionNavigationTarget.drawer(
      AppDrawerDestination.aiSummary,
    ),
    HomeQuickAction.dailyReview => const HomeQuickActionNavigationTarget.drawer(
      AppDrawerDestination.dailyReview,
    ),
    HomeQuickAction.explore => const HomeQuickActionNavigationTarget.drawer(
      AppDrawerDestination.explore,
    ),
    HomeQuickAction.notifications =>
      const HomeQuickActionNavigationTarget.utility(
        DesktopHomeUtilityView.notifications,
      ),
    HomeQuickAction.resources => const HomeQuickActionNavigationTarget.drawer(
      AppDrawerDestination.resources,
    ),
    HomeQuickAction.archived => const HomeQuickActionNavigationTarget.drawer(
      AppDrawerDestination.archived,
    ),
  };
}

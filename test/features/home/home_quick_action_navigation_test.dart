import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/models/app_preferences.dart';
import 'package:memos_flutter_app/features/home/app_drawer.dart';
import 'package:memos_flutter_app/features/home/home_navigation_host.dart';
import 'package:memos_flutter_app/features/home/home_quick_action_navigation.dart';

void main() {
  test('desktop quick stats and notifications map to utility views', () {
    final stats = resolveHomeQuickActionNavigationTarget(
      action: HomeQuickAction.monthlyStats,
      useDesktopHomeNavigation: true,
    );
    final notifications = resolveHomeQuickActionNavigationTarget(
      action: HomeQuickAction.notifications,
      useDesktopHomeNavigation: true,
    );

    expect(stats.kind, HomeQuickActionNavigationKind.desktopUtility);
    expect(stats.desktopUtilityView, DesktopHomeUtilityView.stats);
    expect(notifications.kind, HomeQuickActionNavigationKind.desktopUtility);
    expect(
      notifications.desktopUtilityView,
      DesktopHomeUtilityView.notifications,
    );
  });

  test('desktop quick top-level actions map to drawer destinations', () {
    final expectedDestinations = <HomeQuickAction, AppDrawerDestination>{
      HomeQuickAction.aiSummary: AppDrawerDestination.aiSummary,
      HomeQuickAction.dailyReview: AppDrawerDestination.dailyReview,
      HomeQuickAction.collections: AppDrawerDestination.collections,
      HomeQuickAction.resources: AppDrawerDestination.resources,
      HomeQuickAction.archived: AppDrawerDestination.archived,
      HomeQuickAction.explore: AppDrawerDestination.explore,
    };

    for (final entry in expectedDestinations.entries) {
      final target = resolveHomeQuickActionNavigationTarget(
        action: entry.key,
        useDesktopHomeNavigation: true,
      );

      expect(target.kind, HomeQuickActionNavigationKind.drawerDestination);
      expect(target.drawerDestination, entry.value);
    }
  });

  test('non-desktop quick actions keep standalone route fallback', () {
    for (final action in HomeQuickAction.values) {
      final target = resolveHomeQuickActionNavigationTarget(
        action: action,
        useDesktopHomeNavigation: false,
      );

      if (action == HomeQuickAction.none) {
        expect(target.kind, HomeQuickActionNavigationKind.none);
      } else {
        expect(target.kind, HomeQuickActionNavigationKind.standaloneRoute);
      }
    }
  });
}

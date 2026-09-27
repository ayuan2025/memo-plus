import 'package:flutter/material.dart';

import '../../core/drawer_navigation.dart';
import '../../platform/platform_target.dart';
import '../../i18n/strings.g.dart';
import '../about/about_screen.dart';
import '../collections/collections_screen.dart';
import '../explore/explore_screen.dart';
import '../memos/draft_box_navigation_screen.dart';
import '../memos/memos_list_screen.dart';
import '../memos/recycle_bin_screen.dart';
import '../notifications/notifications_screen.dart';
import '../resources/resources_screen.dart';
import '../review/ai_summary_screen.dart';
import '../review/daily_review_screen.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';
import '../sync/sync_queue_screen.dart';
import '../tags/tags_screen.dart';
import 'app_drawer.dart';
import 'desktop_home_inline_compose_resize_capability.dart';
import 'home_navigation_host.dart';

bool shouldUseDesktopHomeUtilityDestination({
  required BuildContext context,
  required HomeScreenPresentation presentation,
  required HomeEmbeddedNavigationHost? navigationHost,
}) {
  if (navigationHost != null ||
      presentation == HomeScreenPresentation.embeddedBottomNav) {
    return false;
  }
  final target = resolvePlatformTarget(context);
  return target == PlatformTarget.macOS ||
      target == PlatformTarget.windows ||
      target == PlatformTarget.linux;
}

MemosListScreen buildDesktopHomeUtilityDestination({
  required BuildContext context,
  required DesktopHomeUtilityView utility,
  HomeScreenPresentation presentation = HomeScreenPresentation.standalone,
  HomeEmbeddedNavigationHost? navigationHost,
}) {
  return MemosListScreen(
    title: 'MemoFlow',
    state: 'NORMAL',
    showDrawer: true,
    enableCompose: true,
    presentation: presentation,
    embeddedNavigationHost: navigationHost,
    hidePrimaryComposeFab:
        presentation == HomeScreenPresentation.embeddedBottomNav,
    enableDesktopResizableHomeInlineCompose:
        shouldEnableDesktopHomeInlineComposeResize(
          platform: Theme.of(context).platform,
          presentation: presentation,
          navigationHost: navigationHost,
        ),
    initialDesktopUtilityView: utility,
  );
}

MemosListScreen buildDesktopHomeDayFilterDestination({
  required BuildContext context,
  required DateTime day,
  HomeScreenPresentation presentation = HomeScreenPresentation.standalone,
  HomeEmbeddedNavigationHost? navigationHost,
}) {
  final normalizedDay = DateTime(day.year, day.month, day.day);
  return MemosListScreen(
    title: 'MemoFlow',
    state: 'NORMAL',
    showDrawer: true,
    enableCompose: true,
    presentation: presentation,
    embeddedNavigationHost: navigationHost,
    hidePrimaryComposeFab:
        presentation == HomeScreenPresentation.embeddedBottomNav,
    enableDesktopResizableHomeInlineCompose:
        shouldEnableDesktopHomeInlineComposeResize(
          platform: Theme.of(context).platform,
          presentation: presentation,
          navigationHost: navigationHost,
        ),
    initialDesktopHomeDayFilter: normalizedDay,
  );
}

bool openDesktopHomeUtilityDestination({
  required BuildContext context,
  required DesktopHomeUtilityView utility,
  HomeScreenPresentation presentation = HomeScreenPresentation.standalone,
  HomeEmbeddedNavigationHost? navigationHost,
}) {
  if (!shouldUseDesktopHomeUtilityDestination(
    context: context,
    presentation: presentation,
    navigationHost: navigationHost,
  )) {
    return false;
  }
  closeDrawerThenPushReplacement(
    context,
    buildDesktopHomeUtilityDestination(
      context: context,
      utility: utility,
      presentation: presentation,
      navigationHost: navigationHost,
    ),
  );
  return true;
}

bool openDesktopHomeDayFilterDestination({
  required BuildContext context,
  required DateTime day,
  HomeScreenPresentation presentation = HomeScreenPresentation.standalone,
  HomeEmbeddedNavigationHost? navigationHost,
}) {
  if (!shouldUseDesktopHomeUtilityDestination(
    context: context,
    presentation: presentation,
    navigationHost: navigationHost,
  )) {
    return false;
  }
  closeDrawerThenPushReplacement(
    context,
    buildDesktopHomeDayFilterDestination(
      context: context,
      day: day,
      presentation: presentation,
      navigationHost: navigationHost,
    ),
    noAnimation: true,
  );
  return true;
}

void openNotificationsDrawerDestination({
  required BuildContext context,
  HomeEmbeddedNavigationHost? navigationHost,
  HomeScreenPresentation presentation = HomeScreenPresentation.standalone,
}) {
  if (navigationHost != null) {
    navigationHost.handleOpenNotifications(context);
    return;
  }
  if (openDesktopHomeUtilityDestination(
    context: context,
    utility: DesktopHomeUtilityView.notifications,
    presentation: presentation,
    navigationHost: navigationHost,
  )) {
    return;
  }
  closeDrawerThenPushReplacement(context, const NotificationsScreen());
}

Widget buildDrawerDestinationScreen({
  required BuildContext context,
  required AppDrawerDestination destination,
  HomeScreenPresentation presentation = HomeScreenPresentation.standalone,
  HomeEmbeddedNavigationHost? navigationHost,
}) {
  return switch (destination) {
    AppDrawerDestination.memos => MemosListScreen(
      title: 'MemoFlow',
      state: 'NORMAL',
      showDrawer: true,
      enableCompose: true,
      presentation: presentation,
      embeddedNavigationHost: navigationHost,
      hidePrimaryComposeFab:
          presentation == HomeScreenPresentation.embeddedBottomNav,
      enableDesktopResizableHomeInlineCompose:
          shouldEnableDesktopHomeInlineComposeResize(
            platform: Theme.of(context).platform,
            presentation: presentation,
            navigationHost: navigationHost,
          ),
    ),
    AppDrawerDestination.syncQueue =>
      shouldUseDesktopHomeUtilityDestination(
            context: context,
            presentation: presentation,
            navigationHost: navigationHost,
          )
          ? buildDesktopHomeUtilityDestination(
              context: context,
              utility: DesktopHomeUtilityView.syncQueue,
              presentation: presentation,
              navigationHost: navigationHost,
            )
          : SyncQueueScreen(
              presentation: presentation,
              embeddedNavigationHost: navigationHost,
            ),
    AppDrawerDestination.explore => ExploreScreen(
      presentation: presentation,
      embeddedNavigationHost: navigationHost,
    ),
    AppDrawerDestination.dailyReview => DailyReviewScreen(
      presentation: presentation,
      embeddedNavigationHost: navigationHost,
    ),
    AppDrawerDestination.aiSummary => AiSummaryScreen(
      presentation: presentation,
      embeddedNavigationHost: navigationHost,
    ),
    AppDrawerDestination.archived => MemosListScreen(
      title: context.t.strings.legacy.msg_archive,
      state: 'ARCHIVED',
      showDrawer: true,
      enableCompose: false,
      presentation: presentation,
      embeddedNavigationHost: navigationHost,
    ),
    AppDrawerDestination.collections => CollectionsScreen(
      embeddedNavigationHost: navigationHost,
    ),
    AppDrawerDestination.draftBox =>
      shouldUseDesktopHomeUtilityDestination(
            context: context,
            presentation: presentation,
            navigationHost: navigationHost,
          )
          ? buildDesktopHomeUtilityDestination(
              context: context,
              utility: DesktopHomeUtilityView.draftBox,
              presentation: presentation,
              navigationHost: navigationHost,
            )
          : DraftBoxNavigationScreen(
              presentation: presentation,
              embeddedNavigationHost: navigationHost,
            ),
    AppDrawerDestination.tags => TagsScreen(
      presentation: presentation,
      embeddedNavigationHost: navigationHost,
    ),
    AppDrawerDestination.resources => ResourcesScreen(
      presentation: presentation,
      embeddedNavigationHost: navigationHost,
    ),
    AppDrawerDestination.recycleBin => RecycleBinScreen(
      presentation: presentation,
      embeddedNavigationHost: navigationHost,
    ),
    AppDrawerDestination.stats =>
      shouldUseDesktopHomeUtilityDestination(
            context: context,
            presentation: presentation,
            navigationHost: navigationHost,
          )
          ? buildDesktopHomeUtilityDestination(
              context: context,
              utility: DesktopHomeUtilityView.stats,
              presentation: presentation,
              navigationHost: navigationHost,
            )
          : StatsScreen(
              presentation: presentation,
              embeddedNavigationHost: navigationHost,
            ),
    AppDrawerDestination.settings => SettingsScreen(
      presentation: presentation,
      embeddedNavigationHost: navigationHost,
    ),
    AppDrawerDestination.about => AboutScreen(
      presentation: presentation,
      embeddedNavigationHost: navigationHost,
    ),
  };
}

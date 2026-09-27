import 'package:flutter/material.dart';

import '../../data/models/home_navigation_preferences.dart';
import '../../i18n/strings.g.dart';
import '../collections/collections_screen.dart';
import '../explore/explore_screen.dart';
import '../home/app_drawer.dart';
import 'app_drawer_destination_builder.dart';
import '../memos/draft_box_navigation_screen.dart';
import '../memos/memos_list_screen.dart';
import '../resources/resources_screen.dart';
import '../review/ai_summary_screen.dart';
import '../review/daily_review_screen.dart';
import '../settings/settings_screen.dart';
import 'desktop_home_inline_compose_resize_capability.dart';
import 'home_navigation_host.dart';

typedef DebugHomeRootScreenBuilder =
    Widget? Function({
      required BuildContext context,
      required HomeRootDestination destination,
      required HomeScreenPresentation presentation,
      required HomeEmbeddedNavigationHost? navigationHost,
      String? memosTag,
    });

class HomeRootDestinationDefinition {
  const HomeRootDestinationDefinition({
    required this.destination,
    required this.drawerDestination,
    required this.icon,
    required this.labelBuilder,
  });

  final HomeRootDestination destination;
  final AppDrawerDestination drawerDestination;
  final IconData icon;
  final String Function(BuildContext context) labelBuilder;
}

const List<HomeRootDestinationDefinition> kHomeRootDestinationDefinitions = [
  HomeRootDestinationDefinition(
    destination: HomeRootDestination.memos,
    drawerDestination: AppDrawerDestination.memos,
    icon: Icons.notes_rounded,
    labelBuilder: _allMemosLabel,
  ),
  HomeRootDestinationDefinition(
    destination: HomeRootDestination.collections,
    drawerDestination: AppDrawerDestination.collections,
    icon: Icons.auto_stories_rounded,
    labelBuilder: _collectionsLabel,
  ),
  HomeRootDestinationDefinition(
    destination: HomeRootDestination.explore,
    drawerDestination: AppDrawerDestination.explore,
    icon: Icons.public,
    labelBuilder: _exploreLabel,
  ),
  HomeRootDestinationDefinition(
    destination: HomeRootDestination.dailyReview,
    drawerDestination: AppDrawerDestination.dailyReview,
    icon: Icons.explore,
    labelBuilder: _dailyReviewLabel,
  ),
  HomeRootDestinationDefinition(
    destination: HomeRootDestination.settings,
    drawerDestination: AppDrawerDestination.settings,
    icon: Icons.settings_outlined,
    labelBuilder: _settingsLabel,
  ),
  HomeRootDestinationDefinition(
    destination: HomeRootDestination.aiSummary,
    drawerDestination: AppDrawerDestination.aiSummary,
    icon: Icons.auto_awesome,
    labelBuilder: _aiSummaryLabel,
  ),
  HomeRootDestinationDefinition(
    destination: HomeRootDestination.draftBox,
    drawerDestination: AppDrawerDestination.draftBox,
    icon: Icons.inventory_2_outlined,
    labelBuilder: _draftBoxLabel,
  ),
  HomeRootDestinationDefinition(
    destination: HomeRootDestination.resources,
    drawerDestination: AppDrawerDestination.resources,
    icon: Icons.attach_file,
    labelBuilder: _attachmentsLabel,
  ),
  HomeRootDestinationDefinition(
    destination: HomeRootDestination.archived,
    drawerDestination: AppDrawerDestination.archived,
    icon: Icons.archive_outlined,
    labelBuilder: _archiveLabel,
  ),
];

DebugHomeRootScreenBuilder? debugHomeRootScreenBuilderOverride;

HomeRootDestinationDefinition? homeRootDestinationDefinition(
  HomeRootDestination destination,
) {
  for (final definition in kHomeRootDestinationDefinitions) {
    if (definition.destination == destination) {
      return definition;
    }
  }
  return null;
}

HomeRootDestination? homeRootDestinationFromDrawerDestination(
  AppDrawerDestination destination,
) {
  for (final definition in kHomeRootDestinationDefinitions) {
    if (definition.drawerDestination == destination) {
      return definition.destination;
    }
  }
  return null;
}

Widget buildHomeRootScreen({
  required BuildContext context,
  required HomeRootDestination destination,
  required HomeScreenPresentation presentation,
  required HomeEmbeddedNavigationHost? navigationHost,
  String? memosTag,
}) {
  final debugBuilder = debugHomeRootScreenBuilderOverride;
  if (debugBuilder != null) {
    final debugWidget = debugBuilder(
      context: context,
      destination: destination,
      presentation: presentation,
      navigationHost: navigationHost,
      memosTag: memosTag,
    );
    if (debugWidget != null) {
      return debugWidget;
    }
  }

  switch (destination) {
    case HomeRootDestination.none:
      return const SizedBox.shrink();
    case HomeRootDestination.memos:
      final effectiveMemosTag = memosTag?.trim();
      final hasMemosTag = effectiveMemosTag?.isNotEmpty ?? false;
      return MemosListScreen(
        title: hasMemosTag ? '#$effectiveMemosTag' : 'MemoFlow',
        state: 'NORMAL',
        tag: hasMemosTag ? effectiveMemosTag : null,
        showDrawer: true,
        enableCompose: true,
        showFilterTagChip: hasMemosTag,
        enableDesktopResizableHomeInlineCompose:
            shouldEnableDesktopHomeInlineComposeResize(
              platform: Theme.of(context).platform,
              presentation: presentation,
              navigationHost: navigationHost,
            ),
        presentation: presentation,
        embeddedNavigationHost: navigationHost,
        hidePrimaryComposeFab:
            presentation == HomeScreenPresentation.embeddedBottomNav,
      );
    case HomeRootDestination.collections:
      return CollectionsScreen(embeddedNavigationHost: navigationHost);
    case HomeRootDestination.explore:
      return ExploreScreen(
        presentation: presentation,
        embeddedNavigationHost: navigationHost,
      );
    case HomeRootDestination.dailyReview:
      return DailyReviewScreen(
        presentation: presentation,
        embeddedNavigationHost: navigationHost,
      );
    case HomeRootDestination.settings:
      return SettingsScreen(
        presentation: presentation,
        embeddedNavigationHost: navigationHost,
      );
    case HomeRootDestination.aiSummary:
      return AiSummaryScreen(
        presentation: presentation,
        embeddedNavigationHost: navigationHost,
      );
    case HomeRootDestination.draftBox:
      return shouldUseDesktopHomeUtilityDestination(
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
            );
    case HomeRootDestination.resources:
      return ResourcesScreen(
        presentation: presentation,
        embeddedNavigationHost: navigationHost,
      );
    case HomeRootDestination.archived:
      return MemosListScreen(
        title: context.t.strings.legacy.msg_archive,
        state: 'ARCHIVED',
        showDrawer: true,
        presentation: presentation,
        embeddedNavigationHost: navigationHost,
        hidePrimaryComposeFab:
            presentation == HomeScreenPresentation.embeddedBottomNav,
        enableDrawerOpenDragGesture:
            presentation != HomeScreenPresentation.embeddedBottomNav,
      );
  }
}

String _allMemosLabel(BuildContext context) =>
    context.t.strings.legacy.msg_memos;

String _collectionsLabel(BuildContext context) =>
    context.t.strings.collections.drawerLabel;

String _exploreLabel(BuildContext context) =>
    context.t.strings.legacy.msg_explore;

String _dailyReviewLabel(BuildContext context) =>
    context.t.strings.legacy.msg_random_review;

String _settingsLabel(BuildContext context) =>
    context.t.strings.legacy.msg_settings;

String _aiSummaryLabel(BuildContext context) =>
    context.t.strings.legacy.msg_ai_summary;

String _draftBoxLabel(BuildContext context) =>
    context.t.strings.legacy.msg_draft_box_title;

String _attachmentsLabel(BuildContext context) =>
    context.t.strings.legacy.msg_attachments;

String _archiveLabel(BuildContext context) =>
    context.t.strings.legacy.msg_archive;
